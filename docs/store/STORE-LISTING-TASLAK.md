# Güncel mağaza metni girişi · 17 Ekim 2026

Yayıma hazırlanacak TR/EN metinlerin kaynağı [listing.json](listing.json) ve
[listing.tr-TR.json](listing.tr-TR.json) dosyalarıdır. Güncel dar kurs kapsamı
**39 ders / 8 modül solo boks**; kurs varlık kimliği ve hashleri JSON içindeki `$` kaynak notlarındadır.
Temassız öz kayıt; sparring, otomatik yumruk sayımı ve abonelik satışı kabulü yoktur.

Kurs ilerlemesi kullanıcının kendi çalışma kaydıdır; ustalık veya fiziksel öğretim
kabulü değildir. Hesap ve destek/gizlilik metinleri güncel JSON'dan alınır.
Yerel metin, eski ekran görüntüsü veya kaynak testi mağazada kaydedildiği, güncel
imzalı pakette bulunduğu ya da fiziksel cihazda kabul edildiği anlamına gelmez.
Bu bakımda mağaza paneline yazılmadı ve yükleme yapılmadı.

## Tarihsel araştırma · aşağıdaki metni yayın metni olarak kullanmayın

Aşağıdaki eski katalog/kamera incelemesi kendi tarihinin kanıtıdır. Eski “bugün”,
“sıradaki” ve simge onayı ifadeleri güncel yayın durumu değildir; yukarıdaki iki
JSON ve kaynaklarına bağlı güncel kabul kullanılır.

# JabLab mağaza liste içeriği — kaynak taslağı

## Güncel kapsam — 2026-10-02

Mağazaya aktarılacak metnin tek kaynağı `docs/store/listing.json` ve
`docs/store/listing.tr-TR.json` dosyalarının dış alanlarıdır. `$` önekli
alanlar tarihsel araştırma/denetim fişleridir; mağaza metnine taşınmaz.
Bu doküman provider güncellemesi, mağaza onayı veya submit makbuzu değildir.

Güncel içerik 39 özgün TR/EN metin dersi /8 modüldür: duruş ve gard,
ayak işi, düz ve kavisli yumruk şekilleri, planlı savunma, kombinasyon ve
bağımsız temassız rauntlar. İlerleme kullanıcı öz beyanıdır ve guest/hesap
kapsamında yalnız cihazda saklanır. Motion hesabı isteğe bağlıdır.
Gerçek gösterim videosu, canlı kamera koçluğu, otomatik yumruk sayımı ve
abonelik satışı bu sürümde açık değildir. Ustalık, yumruk hızı/gücü veya
kişisel güvenli teknik sonucu iddia edilmez.

| Alan | Güncel kaynak / aktarım kuralı |
|---|---|
| ASC name/subtitle/promotionalText/keywords | İngilizce `listing.json.appStore`; subtitle: `Build a solo boxing practice` |
| TR alanları | `listing.tr-TR.json`; kaynaktaki metni dil bazında aktar |
| Play shortDescription | İlgili locale dosyasının `playStore.shortDescription` alanı |
| Description | İlgili locale dosyasının `description` alanı; 39 ders, öz beyan, kamera/video/satış kapalı sınırı korunur |
| Kamera gerekçesi | `ios/Runner/Info.plist` ile kaynak eşliği; gerçek izin/native kabulü ayrı |
| Yaş/hedef kitle | Ortak güncel Motion18+ hedef kararı merkezde; eski4+/Everyone tahmini tarihsel olup provider sonucunu belirlemez |

## Kaynak ve yayın kapıları

Kurs JSON'u `assets/content/solo_boxing_course.v1.json`: SHA-256
`0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f`.
2026-09-26 `$coursePreparation20260926` fişleri kendi tarihi için korunur;
bugünkü kaynak veya paket kabulü olarak kullanılmaz. `tool/generate_solo_boxing_course.py --check`
çıkış0 ile kursun üretici eşliği doğrulandı. Güncel bağımsız statik kurs
incelemesinde39 benzersiz ders/8modül, bağlı önkoşullar ve kaynak ID'leri
okundu; öğretmen, gerçek medya ve fiziksel form kabulü açık.

`test/store_listing_test.dart` canlı dış metinlerin öz beyan/kamera kapalı
sınırını ve provider karakter alanlarını denetler. Eski MEASURED/WATCHED
başlıkları bugün description aktarım talimatı değildir. Son imzalı aday,
TR/EN ekran görüntüsü, support/privacy/account-deletion URL'leri,
reviewer hesabı ve talimatı, birleşik privacy/manifest ve mağaza formları
ayrı makbuzla kabul edilir. Kaynak testi mağaza kabulü sayılmaz.

## Tarihsel denetim — 2026-08-12

Aşağıdaki ölçüm eski canlı/ölçüm vaatlerinin düzeltme kökenini korur;
güncel dış liste ve yayın talimatı üstteki bölümdür.

## 🔴 DÜZELTME (koordinatör çapraz kontrolü, 2026-08-12)

İlk taslak `MEASURED AND GRADED` altında *"Combination order and timing, for
the punches we model"* diyordu. Koordinatör J-162/163'ün açık sorusuna
(`COMBINATION_END` motorda geçiyor mu) bağlı olduğunu işaretledi ve
gönderim öncesi kesin ölçüm istedi. **Ölçüm KESİN sonuç verdi — şüpheden
kötü:**

* `WRONG_HAND_FOR_COMBINATION` / `COMBINATION_ORDER_ERROR` ikisi de
  `evaluateAt:["COMBINATION_END"]` istiyor (`boxing@1.0.0.json`).
* `COMBINATION_END` motor kodunda (`lib/` + `packages/jablab_engine/`)
  **sıfır** yerde geçiyor (pozitif kontrollü grep).
* Koşul alanı `sequenceMismatch` (`striking_engine.dart` `_Ctx`) **tek
  yerde deklare edilip hiçbir yerde atanmıyor.**
* `evaluateAt` dispatch'i gerçek faz kimlikleriyle eşleşiyor
  (`GUARD_READY`/`EXTENSION`/`PEAK`/`RETRACTION`/`GUARD_RECOVERED`) —
  `COMBINATION_END` bunların hiçbiri değil.

**Sonuç: bu iki hata KALICI ERİŞİLEMEZ.** İddia `WHAT WE DO NOT MEASURE`ye
taşındı. `test/store_listing_test.dart`e bu taşımanın geri alınmasını
engelleyen bir regresyon testi eklendi.

⚠️ **Ayrı ve daha büyük bulgu — bu turda dokunulmadı:** aynı aşırı-iddia
`boxing.foundations.one_two` dersinin **canlı** öğretme metninde de var
(*"We watch the order and the timing between the two"*). Bu, mağaza
metninden ayrı — zaten SEVK EDİLMİŞ uygulama içeriği. Koordinatöre ayrıca
raporlandı.

## ⚠️ Bu taslağın ÖLÇMEDİĞİ şey

* **Metnin ASC/Play karakter sınırlarını TAM karşıladığını** — kabaca
  hesaplandı, kesin sayaç mağazanın kendi arayüzünde.
* **Ekran görüntülerini** — ayrı kalem, cihaz/sim turuna bağlı.
* **Yaş derecelendirmesinin NİHAİ sonucunu** — yalnız gerekçe yazıldı,
  mağazanın kendi sorgu formu doldurulmadı (ASC erişimi yok).
