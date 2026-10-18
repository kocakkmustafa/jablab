# Native release hazırlığı · 18 Ekim 2026

İlk 12179f0 paketleme koşusundaki iki hata paketleme konfigürasyonundadır.
iOS komutundaki global provisioning profile override bütün Pods hedeflerine de
uygulandı (archive exit65). Android tarafında `pub get` dev eklentilerini içeren
Java registrant üretti; Flutter3.47.5 `--no-pub` ile release tooling yenilemesini
atladığından sonraki doğrudan offline Gradle bu dosyayı dev eklentileri çıkarılmış
release classpath ile derlemeye çalıştı (iki eksik Java paketi, AAB exit1).
Bu bulgular uygulamanın fiziksel doğruluğu veya cihaz kabulü değildir.

## iOS: yalnız Runner profili

Archive komutunda global `PROVISIONING_PROFILE_SPECIFIER=<UUID>` kullanmayın.
Bunun yerine mevcut archive argümanlarına şunları ekleyin:

```text
-xcconfig tool/app_store_signing.xcconfig
JABLAB_APP_STORE_PROFILE_UUID=9177d639-167a-4994-8238-fe4b1e3333a3
CODE_SIGN_STYLE=Manual
CODE_SIGN_IDENTITY=3F43D69DA6E09671E9BB7649F7B980C9AFF81355
DEVELOPMENT_TEAM=T5HZGYBWK8
```

xcconfig içindeki nested TARGET_NAME çözümlemesi mevcut profili yalnız Runner'a
bağlar. `PROVISIONING_PROFILE` eski alanı boş kalır. `-showBuildSettings -json`
ile gerçek okuma: Runner doğru UUID; 23 Pods ayar kaydının tamamı boş profil.
Bu metadata kontrolüdür; ikinci archive veya imza kabulü değildir. Gelecek
koşuda aynı ayar okuması archive öncesi kapı olmalıdır. Var olan profil ve
sertifika kullanılır; yeni anahtar/grant, provisioning güncellemesi ve upload yok.

## Android: release glue üretecini atlamayın

Offline `pub get --enforce-lockfile` ve release config-only hazırlığından sonra,
doğrudan `gradlew --offline ... bundleRelease` çağrısından hemen önce:

```sh
python3 tool/prepare_android_release.py \
  --flutter-root /opt/homebrew/share/flutter \
  --evidence /tmp/jablab-release-glue-UNIQUE
```

Araç kurulu Flutter3.47.5'in resmi `injectPlugins` fonksiyonunu
`releaseMode:true, androidPlatform:true` ile çalıştırır. Aynı CLI'nin Mustache
renderer bağlamı kullanılır. Native derleme, Gradle, pub get, key veya ağ çağrısı
yapılmaz; süreçte ağ kapalıdır. SDK iç API'si değişebileceği için başka Flutter
sürümünde kapı durur ve adapter yeniden incelenir.

Mevcut generated Java dosyası silinmeden yeni kanıt klasörüne byte eş yedeklenir.
Üretim eklentilerinin tam kümesi denetlenir; eksik üretim veya sızmış dev kaydı
hata verir. pubspec/lock/package-config/plugin-metadata girdileri değişmemelidir.
Mevcut gerçek kayıtta 9 üretim eklentisi kaldı; device_info_plus ve integration_test
release'ten çıktı. İki paket dev_dependencies içinde korunur. Sonraki pub get veya
debug/test tooling kaydı yeniden değiştirebilir; helper release Gradle'dan hemen
önce çalıştırılmalıdır. Üretilmiş Java Git'e alınmaz ve elle düzenlenmez.

## Kapsam ve kanıt

Bu düzeltme yalnız iki hazırlık aracı, xcconfig ve bu dokümandır. Uygulama/Dart
kullanıcı kodu, bağımlılık sürümleri, Core, anahtarlar ve cihazlar değişmedi.
3 dar Python kontrolü PASS; gerçek generated kayıt 9 üretim/0 dev PASS; iOS
Runner/Pods metadata kapsamı PASS. İkinci native build/archive/export yapılmadı.
Kanıt task-14/package-repair altındadır; ilk koşu task-14/package-current içinde
korunur. Yeniden deneme: düzeltilmiş kaynak, ortak lease altında tek iOS
archive/export ve tek offline Android AAB; en çok20dakika,8GiB disk guard,$0.
Başarılı paket olursa kimlik/sürüm/build/model/asset SHA ve imza eşliği ayrıca
ölçülür. Fiziksel cihaz, gerçek hesap ve mağaza gönderimi ayrı açık kapılardır.
