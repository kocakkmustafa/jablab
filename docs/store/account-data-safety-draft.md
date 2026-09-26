# Motion hesabı bağlanınca mağaza gizlilik beyanı taslağı — JabLab

Durum (2026-09-25): Motion üretim şeması ve SMTP kuruldu; gerçek
e-posta teslimi gözlendi. Kurucu ilk sürümde ücretli kamera oturumlarını ve
abonelik satışını erteledi. Mağaza veri formları ve iPhone kabulü ayrıca
doğrulanacak; bu dosya konsolda onaylanmış nihai beyan değildir.

**2026-09-26 kaynak uzlaştırması:** Yukarıdaki sağlayıcı/SMTP satırları
2026-09-25 tarihli kayıttır; bu tur canlı sağlayıcı sonucu yeniden ölçülmedi.
Mevcut ilk kurs, yerel ilerleme ve native izin dosyaları kontrol edildi.
Mağaza formlarının final paket/SDK ve sağlayıcı kabulü ayrıca yapılır.

| Veri | Mevcut hesap tasarımı | Beyan adayı |
|---|---|---|
| E-posta | Kayıt, giriş, doğrulama ve parola kurtarma için Supabase Auth'a gönderilir | Apple: `NSPrivacyCollectedDataTypeEmailAddress`; Play: Personal info / Email address; hesaba bağlı, uygulama işlevi |
| Görünen ad | Kullanıcı isteğe bağlı kaydeder; Motion profilinde sunucuya gönderilir | Apple: `NSPrivacyCollectedDataTypeName`; Play: Personal info / Name; isteğe bağlı, hesaba bağlı, uygulama işlevi |
| Ortak hesap ID'si | Oturum ve uygulamaya özel yerel veri ayrımı için kullanılır | Apple: `NSPrivacyCollectedDataTypeUserID`; Play: Personal info / User IDs; hesaba bağlı, uygulama işlevi |
| Satın alma geçmişi | İlk sürümde satış ve satın alma doğrulaması kapalı; uygulama işlem geçmişi göndermez | İlk sürüm Apple/Play veri beyanına girmez; satış açılırsa yeniden değerlendirilir |
| Kamera görüntüsü ve eklem noktaları | Cihazda işlenir; hesap servisine gönderilmez | Görüntü yükleme beyanı yok; canlı SDK ve ağ trafiği release öncesi tekrar denetlenmeli |
| Solo boks kursu ilerlemesi | `solo_boxing_progress.dart` konuk/hesap kapsamına ayrılmış yerel JSON yazar; görüntüleme, çalışma ve öz beyan kayıtları Motion hesabına senkronize edilmez | Cihaz dışına gönderilmediği için Apple/Play “collected” beyanına girmez; ders bitirme ustalık puanı değildir |
| Seans geçmişi | Kullanıcıya ayrılmış yerel JSONL dosyasında kalır; guest geçmişi girişte devralınmaz | Sunucuya aktarılmadığı sürece Apple/Play “collected” tanımına girmez; manifestte yerel geçmiş için ayrı collected data türü yoktur |
| Mikrofon/ses | İlk kurs mikrofon kullanmaz; iOS mikrofon gerekçesi ve Android `RECORD_AUDIO` yoktur | Ses collected beyanı yoktur; Ostinato'nun isteğe bağlı mikrofon kararı JabLab'a uygulanmaz |

Kaynakta iOS `PrivacyInfo.xcprivacy` üç Apple hesap veri tipini `Linked=true`, `Tracking=false`, `PurposeAppFunctionality` ile beyan eder; Android INTERNET ve exact `com.yulalab.jablab://auth/callback` kaydı var. Tracking false kalır. Mikrofon API'si kullanılmadığı sürece mikrofon izni eklenmez. Supabase ve native eklentilerin birleşik Xcode privacy raporu, Android manifest merge ve gerçek mağaza formları ayrı release kapısıdır. Hesap silme uzakta başarılı olduktan sonra yalnız ilgili kullanıcıya ait yerel seans dosyası silinir; sunucu hatasında yerel dosya korunur.

2026-09-26 kontrolde `account_bridge.dart` hesap silmede yerel kurs JSON'unu
ve seans JSONL'ini birlikte kapsar. Çözümlenen `motion_account` paketindeki
`motion_release_policy.dart` değeri `motionPaidFeaturesAvailable=false`;
satış/üyelik ve paid-session girişleri kapalıdır. Apple manifestinde
purchase-history türü yoktur. Hesap e-posta/ID'si ve isteğe bağlı görünen
adın sağlayıcıya gönderimi, yerel kurs kaydından ayrı veri işlemidir.

[Apple](https://developer.apple.com/app-store/app-privacy-details/) ve
[Google Play](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
yalnız cihazda kalan işlem/kaydın collection beyanı gerektirmediğini açıklar.
Cihaz dışına gönderilen türetilmiş veri veya SDK trafiği ayrı değerlendirilir.
Kaynaklar: `lib/main.dart`, `lib/app/solo_boxing_progress.dart`,
`lib/app/account_bridge.dart`, native izin dosyaları ve gizlilik manifesti.

Kaynak: [Apple privacy manifest](https://developer.apple.com/documentation/BundleResources/describing-data-use-in-privacy-manifests), [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469).
