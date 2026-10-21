# JabLab — boks, Karate ve Taikyoku ilk sürüm içerik taslağı

Tarih: 2026-10-20. İncelenen kaynak checkpoint'i `92b55d9acb1ad368eabffaf71516a0ad0016c2ac`. Kaynak kimliği parent'ın freeze makbuzundan alındı; bu alt görev Git komutu çalıştırmadı. Listelenen 14 boks/rota/test/Karate/Taikyoku dosyasının SHA-256 değeri freeze envanteriyle eşleşti. Uygulama, SDK, native/cache veya Git yazımı yapılmadı. Buradaki metinler **uygulanmamış taslak**; yeni kaynak/test kabulü değildir.

Kullanıcının son ölçütü esas alındı: harici uzman incelemesi zorunlu yayın kapısı değil. Özgün, anlaşılır, temassız başlangıç öğretimi; gerçek video inceleme kaydı; anlamı bozan veya güvenlik bakımından belirsiz metinlerin giderilmesi gerekiyor. Bu değişiklik, kişisel sağlık sınırlamalarını veya doğrulanmamış teknik doğruluk sınırını kaldırmıyor. Hiçbir ders uzman onaylı, kişiye güvenli, fiziksel olarak doğru veya ustalık kanıtı diye sunulmamalı.

İlişkili eski kayıtlar `lifecycle-audit-2026-10-19/REPORT.tr.md:13` altındaki **MS-4/MS-5, JB3-P01/P02** ve önceki tam öğretim/medya işi **J-212**. Yeni aynı-konu kusur kaydı yaratmak yerine bu dosyalar o paketin güncel kabul ölçütüne bağlı içerik alt kanıtıdır. Eski rapordaki zorunlu uzman/öğrenci kabulü kısmı yeni kullanıcı kararıyla güncellenmeli; güvenlik ve gerçek test sınırları korunmalı.

## Envanter ve kapsam

`INVENTORY.json`, her ders için ID, satır, JSON yolu, hedef, önkoşul, uyarlama, durma belirtisi, kaynak bağı ve kapanış testini içerir. Ders sayısı fiziksel başarı veya test PASS sayısı değildir.

Toplam 65 güncel ders ID'si ve ayrıca 21 eski boks dersi kayıtlıdır; Taikyoku'nun 20 hareket sözleşmesi ders sayısına eklenmedi. Boksun 6 metin operasyonu, Karate/Taikyoku'nun 26 özgün görev taslağı ve eski engelleyici ifadelerin 14 altalanında 28 tam EN/TR metin düzeltmesi `DRAFT-CHANGES.json` içindedir. Kurs/genel UI sözleşme düzenlemeleri ayrıca aynı dosyanın `karate_taikyoku_package` alanında yer alır. Boksun 6 ve Karate/Taikyoku'nun 28 before değeri mevcut assetle birebir karşılaştırıldı; bu rapor bütünlüğü kontrolüdür, SDK testi değildir.

| Alan | Kaynak kapsamı | İncelenen / açık sınır |
|---|---|---|
| Solo boks | 8 modül, 39 EN/TR ders | Tüm ders hedef/adım/pratik/öz kontrol/uyarlama/durma metinleri statik okundu. Fiziksel uygulama ve SDK testi bu görevde yapılmadı. |
| Eski boks | 4 kurs, 21 ders; 10 drill, 18 progression kaydı | `library.json` ve `curriculum.json` envanteri çıkarıldı. Bunlar 39 dersin öz beyan ilerlemesiyle aynı kayıtlar değil. |
| Karate | 16 ders; kihon dizi hazırlığı | Ayrı alt inceleme ve somut uygulama taslağı aynı klasörün `karate-source/` altındadır. |
| Taikyoku Shodan JL | 10 ders, 20 hareket sözleşmesi | Yazılı sıra/yer planı/hatırlama öğretimi; kaynak görüntüsünün göstermediği yük, ayak pivot kenarı ve bilek ayrıntısı bilinmiyor. |
| Video | Mevcut dış referanslar + parent'ın yeni görsel makbuzları | Bu alt ajan video izlemedi. Metadata, sayfa metni veya transkript okuma izleme diye sayılmadı. |
| Gerçek cihaz / kişisel uygunluk | Erişim yok | Test edilmedi. Widget veya kaynak doğrulaması cihaz/beden kabulü değildir. |

Solo boks modülleri: başlangıç5, ayak çalışması5, düzler6, planlı savunma5, kavisli yumruk şekilleri5, kombinasyon5, raunt5, bütünleme3. Her ders özgün anlatım, en az iki adım ve öz kontrol, uyarlama, durma cümlesi, kaynak ve önceki ders önkoşulu taşıyor. Kurs günlüğü `self_report`; otomatik doğruluk, kuvvet, hız, savunma etkinliği veya sertifika üretmiyor.

`lib/app/select_page.dart:200` doğrudan solo kartını; `:206` boks disiplin yönlendirmesini ayrı solo kursa bağlıyor. `lib/app/jablab_app.dart:768` kaynak kabulü/hesap recovery/owner generation sınırlarıyla kursu açıyor. Karate ve Taikyoku girişleri `:869` ve `:908`; Taikyoku giriş kartı `lib/app/karate_course_page.dart:598`. Eski oturum yolu kaynakta korunuyor; production `lib/main.dart:113` üzerinden erişim kontrolü taşıyor. Bu taslak kamera veya satış açmaz; yeni ders ilerlemesini legacy sayaçlarla birleştirmez.

## Boks için dar değişiklikler

| ID / önem | Kanıt ve etki | Öneri / kapanış |
|---|---|---|
| BOX-DRAFT-01/02 — ilk sürüm güvenlik anlamı | `solo_boxing_course.v1.json:2540`, `boxing.rounds.personal_plan`: durma cümlesi “dur **ya da** planı değiştir” diyor; aynı dersin bitiş adımı belirti olursa hemen durmayı söylüyor. Kullanıcı belirtili çalışmayı daha kolay planla sürdürebilir diye okuyabilir. Fiziksel zarar gözlenmedi. | Önce çalışmayı durdur ve dinlen; plan değişikliğini sonraki rahat denemeye ayır. Belirti sürerken yeniden başlamayı önermeme. EN/TR exact before/after JSON'da. Gerçek derste her iki dilde aynı anlam, mevcut yerel progress ve39ID korunumu; byte/integrity pinleri ve dar kaynak-bound testler. |
| BOX-DRAFT-03/04/05 — anlam sınırı | `:2166`, `boxing.combinations.angle_exit` “eller yerinde, sonra ayaklar” sayımı. `toronto_small_angle_exit` kaynağı bütün boks hareketlerinde iki elin dönmesini bekleme kuralını desteklemiyor. Mevcut anlatım başlangıç için duraklı prova olarak makul. | Sayımı açıkça **bu duraklı öğrenme provası** diye etiketle; tekrar adımı ve ilk öz kontrolü eşleştir. Genel spor kuralı iddiası doğmasın. Fiziksel sıra görevini kaldırma. |
| BOX-DRAFT-06 — düşük öncelikli netlik | `:597`, `boxing.footwork.diagonal`: küçük adım ve X'i küçültme yönlendirmesine rağmen ilk pratikte her kol için “bir kol boyu” mesafe var. Tek büyük adım şeklinde yanlış okunabilir. | Sabit mesafe yerine tek rahat küçük çapraz adım + tabanı yeniden kurma + merkeze dönüş anlatımı. Sayısal açı/mesafe veya kişisel egzersiz dozu icat etme. Diğer safety maddelerini kapatmayı bekletmez. |

Durma taslağı, [NHS'nin 24 Haziran 2026 gözden geçirilmiş egzersiz güvenliği metnindeki](https://www.nhs.uk/live-well/exercise/how-to-warm-up-before-exercising/) ağrı/iyi hissetmeme halinde hemen durma ve kalıcı/endişelendiren belirtilerde sağlık desteği sınırıyla uyumludur. Ülkeye özel NHS telefon numarası ürüne taşınmadı. Bu, kullanıcının bireysel tanı veya egzersiz reçetesi değildir.

Diğer boks derslerinde mevcut temassız/kuvvet yok/sert eklem kilidi yok/küçük hareket/alternatif/durma sınırları korunmalı. Özellikle parry, cover, slip ve roll görevleri planlı şekil provasıdır; rakip yumruğundan kaçış başarısını kanıtlamaz. Raunt dakikaları UI tahminleri veya seçilebilir üst sınırlardır; genel sağlık kılavuzunu kişisel zorunlu boks dozu diye aktarma.

## Karate ve Taikyoku için gerçek uygulama içeriği

Mevcut Karate dersleri ayrıntılı yazılı kihon/KA-P1 öğrenmesi sunuyor; ancak bütün fiziksel görevler “gelecekte eğitmenle” şeklinde koşullu. `karate_course_page.dart:130` bütün fiziksel pratiği kapatıyor, `:167` görevleri geleceğe etiketliyor, `:630` eğitmen/gösterim/kişisel feedback bekliyor. Bu yüzden yalnız “eğitmen gerekmiyor” başlığını değiştirmek kullanıcının istediği uygulama öğretimini tamamlamaz.

`karate-source/DRAFT-CHANGES.json` içindeki16 Karate görevi şu somut kapsamı ekler: boş alan ve sıradan adım; rahat ayrı ayak/nötr giriş-çıkış; başparmağı dışta tutan yumuşak el kapama; kendi yana sakin hikite; kısa düz el yolu ve dönüş; yalnız tek gözlem/düzeltme; ayrı izlerde kısa ön hazırlık ve çıkış; arka ayağın kendi izinde geçişi; **adım-dur-el-dur** aynı-yan çalışma; küçük aşağı-dış kol yolu ve kendi-yanda toparlama; sıradan küçük yürüyüşle sağa yönelme; kâğıt yer planı; KA-P1'in iki yarısı ve duraklı birleşimi; yazılı ile gerçek deneneni ayrı bildirme. Her biri EN/TR özgün talimat, tek gözlem, durma, dinlenme ve yazılı alternatif taşır. Destek elini bırakmayı gerektiren görev seçilmez; sert sıkma, darbe, partner, yük, tam hız veya zorla duruş derinliği eklenmez.

10 Taikyoku görevi açılış,1–4,5–8,9–12,13–16,17–20, kapanış, bölüm birleştirme, tek sınır düzeltmesi ve dürüst sonuç ayrımını kapsar. Uzun sola dönüşler önce eller dinlenirken küçük sıradan yürüyüş adımları ve yer planıyla ayrılır; sabit ayak üstünde gövde/diz burulması öğretilmez. Ara duraklar, adım–el ayrılığı, rahat ayak genişliği ve küçük selam **başlangıç uyarlaması** diye adlandırılır; bunlar videodaki standart kata performansı diye sunulmaz.20. teknikten sonra yeni yumruk veya boks gardı eklenmez. A açılış/kapanışı, B hareket uçları/geçişleri ve B'nin bilinmeyen kapanış ayağı ayrı kalır.

Dar uygulama sözleşmesi:

1. Strict schema'ya bilinçli yeni `selfPractice` alanı ekle: scope, instruction, observe, writtenAlternative, stopPolicy, dosePolicy, validationMeaning, sourceReviewReceipts. Karate'de mevcut `physical_task` içeriği somut görevle yenilenebilir; UI başlığı isteğe bağlı temassız öz çalışma olur. Taikyoku'da ders başına yeni talimat/gözlem görünür olur.
2. `selfPracticeAvailable` (yayınlanmış yönerge var) ile `physicalTechniqueValidated` (kişisel/fiziksel doğruluk kabul edildi) ayrı olsun. Mevcut `physicalPracticeAvailable=false` getter'ı sayfalarda kullanılmıyor; yalnız küçük test/caller kümesiyle adı ve anlamı açıkça düzenlensin. Herhangi bir yeni `true`, sağlık veya teknik onayı anlamına gelmesin.
3. `releaseReadiness.*=false`, Karate P0–P6 false, Taikyoku accepted false ve20 sözleşmedeki `footContact/wristRotation/loading=null`, `BClosingInwardFootOrder=null` aynen korunsun. Mevcut parser'lar doğrulanmamış bayrağı true yapmayı reddediyor (`karate_course.dart:112–124`, `taikyoku_shodan_course.dart:192–194`). Yeni pratik yayımlamak için bu kanıt alanlarını sahteleştirmek gerekmiyor.
4. Ders/kursta mevcut ID'ler, yazılı yanıt-anahtar-düzeltme-tekrar ve bu ziyaretin yazılı sayacı korunur. Fiziksel deneme bunu artırmaz; yeni kalıcı veri deposu gerekmez. Durdum/denemedim ve gözlem belirsizliği normal sonuçlardır. Kamera, satış ve Core değişmez.
5. İlgili global engel/gelecekte-eğitmen metinleri öğretim/düzeltme/tekrar alanlarında yeni kapsamla çelişmeyecek şekilde eşleştirilmeli. `literalMeaningCorrections` 14 altalan/28 tam dil değeri için exact JSON pointer ve before/after verir. Sorular, mevcut Karate answer_key ve Taikyoku correct_choice_id değiştirilmez; zaten uygun ts02..09 gözlem/bilinmeyen/yazılı sonuçları korunur. Yazılı sıra cevabı, bir küçük fiziksel uyarlamaya izin vermek için gevşetilmemeli. Byte/manuscript/manifest ve reviewed-text fixture yeni exact kaynakla birlikte bağlanmalı.

Bu taslak fiziksel kaynak kabulünü bekliyor: mevcut A `jH6bv4GDpp0` ve B `kta8JS_pXFs` bu alt görevde web fetch error verdi; video oynatılmadı. Assette tarihsel sessiz/timestamp gözlem iddiaları bulunuyor, ancak `13f7bdaa...` referans onay raporu erişilebilir yerel audit/Documents envanterinde bulunamadı. Yeni parent görsel makbuzu varsa yalnız gördüğü aralık ve eyleme bağlanmalı. Video kabulü teknik ailesi/kata bölümü düzeyindedir; kapsam, alan, durma ve yazılı sonuç cümleleri için uygun birincil metin ile özgün uyarlama ayrımı yeterli olabilir. Her cümle için ayrı video kapısı üretilmedi. Bu eksiklik uzman zorunluluğu değildir; **gerçekte incelenmeyeni incelendi diye söylememe** sınırıdır. JKA ücretli görüntüleme materyali, ücretsiz fragman veya üretici makalesi tam teknik video incelemesi yerine sayılmadı; video kopyalanmadı.

## Kaynak ve medya kanıtı

Production medya kataloğu boş: `lib/app/lesson_media_catalog.dart:107`, `releaseEligible=false` `:120`, release modunda içerik döndürmeme `:129`; solo ders sayfası `LessonMediaSlot.empty` kullanıyor `solo_boxing_course_page.dart:895`. `mediaBrief` bir üretim tarifidir, kurulu video değildir. Kullanıcının bizim videoyu inceleyerek içerik hazırlama talebi, izinli orijinal olmayan videoyu ürüne kopyalama talebi sayılmadı.

Mevcut [DVIDS Hook](https://www.dvidshub.net/video/756773/hook), [Lead Hand Punch](https://www.dvidshub.net/video/756778/lead-hand-punch) ve [Uppercut](https://www.dvidshub.net/video/756817/uppercut) sayfaları 2020 tarihli TECOM/Bruce Hardcastle MCMAP B-roll'ları, sırasıyla5/4/5 saniye ve PUBLIC DOMAIN etiketi taşıyor. Bu kaynaklar tam başlangıç dersi veya evrensel spor boks modeli değil. Lead Hand Punch adı “jab” olarak değiştirilmedi. [DVIDS koşulları](https://www.dvidshub.net/about/copyright) kişi hakları, marka ve kurum desteği izlenimi vermeme sınırını koruyor. Bu işte video indirilmedi, ürüne/reklama kopyalanmadı.

Tarihsel `app/docs/DVIDS-BOXING-REFERENCES.tr.md` mevcut yerel edinim/hash/PTS/görüntü inceleme izini gösteriyor. Yeni parent makbuzu `../video-review/DVIDS-LEAD-HAND-PUNCH.json`, gerçek browser oynatımındaki belirli3.266–4.337s görsel anlarını, gard→uzatma→geri toplama gözlemini kaydediyor; ses veya kesintisiz tam izleme iddiası taşımıyor. Diğer iki yeni parent makbuzu `DVIDS-HOOK.json` (3.582–5.027s seçili anlar) ve `DVIDS-UPPERCUT.json` (3.614–4.933s seçili anlar) aynı sınırlı yöntemle kısa bükülü-yay ve yukarı-yol/geri-toplama gözlemini kaydeder. Hiçbiri ses veya kesintisiz tam izleme iddiası taşımaz. Bu gözlemler yalnız ilgili kısa gösterimleri destekler. Bu alt ajanın kendi gözlem sayısı0.

MyBoxingCoach'ın kendi [jab](https://www.myboxingcoach.com/punching-how-to-throw-a-jab/), [duruş](https://www.myboxingcoach.com/stance-and-on-guard/), [arka düz](https://www.myboxingcoach.com/how-to-throw-a-right-cross/) ve [ileri/geri ayak çalışması](https://www.myboxingcoach.com/footwork-moving-in-and-out/) sayfalarında üreticinin anlatımı ve video gömmeleri bulundu. Sayfa metinleri okundu; web oynatıcı erişimi JavaScript/internal error verdi veya açılmadı. İzlenmedi. Hak devri/üründe çoğaltma izni saptanmadı. [Yumruk](https://www.myboxingcoach.com/boxing-skills/learn-how-to-box-punching/), [blok/parry](https://www.myboxingcoach.com/boxing-skills/learn-how-to-box-block-punc/) ve [baş hareketi](https://www.myboxingcoach.com/boxing-skills/learn-how-to-box-body-movement/) üretici dizinleri, kalan teknik aileler için izlenecek adayları sağlıyor; dizin sayfası video incelemesi değildir. Birebir transcript/kadraj/öğretim kopyalanmadı.

[England Boxing haftalık shadow boxing kaynağı](https://www.englandboxing.org/news_articles/england-boxing-shadow-boxing-drills-week-four/) yarışmacı/youth bağlamı taşıyor. Temaya odaklanma fikri ayrı değerlendirilebilir; önerdiği set süreleri ve taktik zorluk yeni başlayana aktarılmadı. [Handbook PDF](https://www.englandboxing.org/wp-content/uploads/2022/03/EB_Boxing-Coaching-Handbook-Part-1_v8-002.pdf) erişilebilir; bu alt görev açılış kapsamını okudu,158sayfanın tamamını görsel incelemiş saymadı.

İki BoxingCanada kaynak URL'si bugün PDF yerine “Coming Soon” HTML döndürüyor. Geçmiş yerel kopya güncel web incelemesi sayılmamalı. ACOG URL'si webde402 Payment Required verdi; sınır aşılmadı. [CDC sayfası](https://www.cdc.gov/physical-activity-basics/adding-adults/index.html) erişildi; yeteneğe uygun seçim ve kronik durumda sağlık görüşü sınırı var. Katalogdaki her dış bağlantının kapanışta çalışır kaynak kaydı/alternatif birincil referans kontrolü gerekiyor; bu geçici link kaybı tek başına mevcut özgün metnin yanlışlığını ispatlamıyor.

## Test kabulü ve devir

Her dersin ayrı kapanış tanımı `INVENTORY.json` içinde `closing_test` alanında. Yeni testlerin tamamı **PROPOSED_UNRUN**. Kaynak incelemesi ve JSON bütünlüğü, başarılı SDK koşusu diye aktarılmadı.

| Kontrol | Mevcut tanım / gereken kapanış | Bu alt görev sonucu |
|---|---|---|
|39ID, 8 modül, bilingual öğretim ve önkoşul | `test/solo_boxing_course_test.dart:12`; eksik çeviri/kaynak/schema reddi `:42` | Tanımlar okundu; runtime UNRUN |
| Exact course bytes/pin ve bozuk içerikte fail closed | `test/solo_boxing_course_integrity_test.dart:113` ve devamı | Hash freeze ile eşleşti; SDK UNRUN; taslak uygulanırsa pin+fixture yeniden bağlanmalı |
| Hazırlık/gerçek öz beyan etkileşimi | `test/solo_boxing_course_page_test.dart`, hook taze oturum, tek/iki raunt, lifecycle, owner/progress | Seçili akış tanımları okundu;39dersin tamamına otomatik etkileşim kapsamı iddiası yok |
| Kamera kapalı yazılı rota | `test/written_courses_camera_off_test.dart:63`, TR/EN ilk dersler | Tanım okundu; production/native cihaz kabulü değil |
| Değişen personal_plan + angle_exit + diagonal | Exact ders route'larında EN/TR bütün yeni cümle, stop/adaptation/check görünümü; reset/reopen/owner korunumu | Yeni dar kaynak-bound test planı gerekli, UNRUN |
| Gerçek video kaynak görseli | Parent'ın timestamp/URL/izlenen bölüm/sınır makbuzları | Üç DVIDS parent makbuzu mevcut; spor boksunun kalan aileleri ve Karate kaynakları devirde açık |
| Fiziksel hareket / ağrı / kamera doğruluğu / hız / kuvvet | Gerçek cihaz veya insan uygulaması ve ayrı ölçüm gerekir | Test edilmedi; bu sürümün otomatik iddiası değil |

Uygulama sırası: explicit kaynak izni iadesinden sonra yalnız parent tek-yazar dar içerik/schema/UI paketi; ID ve mevcut yerel ilerlemeyi koruma; exact byte/manuscript/manifest pinlerini güncelleme; ardından tek SDK kuyruğunda kaynak-bound statik ve dar widget/regression planı. Önceki PASS'ler yeni kaynak kabulüne eklenmez. Kaynak hâlâ frozen iken yalnız bu rapor/taslaklar hazırlandı.

Boks metinleri `tool/generate_solo_boxing_course.py` içinde de bulunuyor; yalnız asset JSON değişirse yeniden üretim geri alabilir. Kurs SHA'sı `assets/motion_content/manifest.json`, source-slice/projection, `media_source_projection_pin.dart`, v2h/v2k kapalı QA fixture'ları ve giriş bütünlüğü testlerinde de bağlı. Exact bağımlı yol listesi `DRAFT-CHANGES.json:source_generation_note` alanında. Kapalı QA kimliklerini yeni kaynağa dürüstçe bağlamak gerekir; bu işlem kurulu/üretilmiş/izinli medya veya releaseEligible kabulü oluşturmaz. Bu alt görev hiçbir generator çalıştırmadı.

Kalan işlerin durumu: içerik taslakları **hazır, uygulanmadı**; yeni görsel video incelemesi **parent koordinasyonunda kısmi**, Karate A/B görsel kabulü **PENDING**; gerçek cihaz ve fiziksel doğruluk **UNRUN**; kaynak hâlâ frozen olduğu için uygulama/SDK kapanışı **NOT_APPLIED/UNRUN**; build/sign/push/deploy **bu görevin kapsamı dışında**. Ret veya belirsiz çalıştırma olmadı; ACOG ve oynatıcı web erişim hataları kaydedildi, başka araçla aşılmadı.

Sonraki uygulanabilir kaynak taslağı [patch-draft/README.tr.md](patch-draft/README.tr.md) altında hazırdır: 12 dosyalık source-bound yama, 26 görev asset/manifest paketi, ortak panel adaptörleri ve 7 UNRUN test tanımı. Bu ek uygulamaya yazılmadı; root daha yeni5c05 checkpoint'inde SDK freeze bildirdi. Önceki analiz envanteri, uygulanmış schema2 veya test kabulü diye yeniden etiketlenmedi.
