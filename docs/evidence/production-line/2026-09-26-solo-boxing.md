# JabLab solo boks: içerik, ilerleme ve sentetik olay kapısı

Tarih: 2026-09-26  
Taban HEAD: `d7a974f914741f1d5fe83ee0e10cd19fffa093e7`  
Durum: yerel kaynak ve widget doğrulaması; cihaz, model eğitimi veya mağaza kabulü değildir.

## Olay mantığı ölçümü

Değişiklik öncesinde aynı gard→aşağı düz kol→gard sentetik dizisi 250 ms
ve 300 ms yükselmede `jab` üretiyordu. 500 ms varyantı zaman aşımından
reddediliyordu. Kol düzlüğü tek başına yönü ayıramıyordu.

`MeasureCalculator` artık omuzdan bileğe görüntü düzlemindeki aşağı yönlü
bileşeni aynı karenin kol uzunluğuna böler: `wristDropRatio`. `jab` ve
`cross` PEAK fazında geçici `<0.5` koşulu eklendi. Bu oran derinlik,
yumruk kuvveti/hızı, klinik eklem açısı veya hedef doğruluğu değildir.
Deneme kaydına `eventLogicRevision: wrist-drop-2d@1` eklenir; miras
`boxing@1.0.0` dosya kimliği içinde yeni olay politikası ayırt edilir.

`packages/jablab_engine/test/event_negative_control_gate_test.dart`:

| Sentetik vaka | Beklenen | Gözlenen |
|---|---|---|
| Gard | olay yok | olay yok |
| Aşağı kol salınımı 250 ms | olay yok | olay yok |
| Aşağı kol salınımı 300 ms | olay yok | olay yok |
| Aşağı kol salınımı 500 ms | olay yok | olay yok |
| Düz jab 120 ms | bir jab | bir jab |
| Düz jab 180 ms | bir jab | bir jab |
| Düz jab 250 ms | bir jab | bir jab |

Yedi vaka, **0 yanlış olumlu olay**, **0 kayıp/fazladan pozitif olay**.
Bunlar tek el yapımı iskelet geometrisidir; kişi/cihaz/duruş çeşitliliği
ve bağımsız etiketli holdout yoktur. Bazı negatif diziler hâlâ
`ATTEMPT_ABORTED`/gard duruşu sorunları üretir; olay sayımı düzeltildi,
negatif harekete geri bildirim doğruluğu doğrulanmadı. Yatay ve kameraya
doğru diğer hareketlerin gerçek dünya ayrımı kapanmadı. Kamera ustalık
puanı bu kursta açılmaz. Eski YouTube hasat golden'ları yeni eğitim veya
olay kabulü için kullanılmadı.

## Tam öğretim yolu

`assets/content/solo_boxing_course.v1.json` bir özgün TR/EN solo kurs
taşır. Eski 21 dersin ve kamera kayıtlarının kimlikleri korunur. Yeni
kurs sekiz modül ve 39 ders içerir:

| Modül | Ders |
|---|---:|
| Alan, duruş, gard, nefes, tabana dönüş | 5 |
| İleri/geri, yan, çapraz, pivot, giriş/çıkış | 5 |
| Jab, dönüş, çift jab, arka düz, toparlanma, 1–2 | 6 |
| Mesafe, kapama, küçük karşılama/parry, slip, roll | 5 |
| Ön/arka kroşe, ön/arka aparkat, hedef seviyesi | 5 |
| Kısa kombinasyon, planlı savunma/dönüş, açılı çıkış | 5 |
| Kaliteli kısa çalışma, hareket, hayali hedef, tempo, plan | 5 |
| Zincir gözden geçirme, iki prova rauntu, bağımsız raunt | 3 |

Her derste özgün iki dilde öğretim adımları, çalışma, öz denetim, daha
kolay seçenek, durma işareti, kaynak bağlantısı, önceki ön koşul ve özel
AI çekim brifi vardır. Temas, partner, torba, sparring, tepki savunması
ve profesyonel ustalık bu öğretim yoluna dahil değildir. Önerilen kısa
süreler/tekrarlar kullanıcı tarafından azaltılabilir; tıbbi güvenlik
kararı verilmez. Gebelik, sakatlık ve kronik durum için genel bilgi ve
uzmanla kişisel sınırları görüşme metni gösterilir. Gebelikte temaslı
boks tavsiye edilmez.

İlk açılış `SelectPage` ve mevcut `CoursePage` içinde görünür kart kursu
açar. JabLab'ın mevcut renk, cam panel ve yazı tokenları kullanılır.
Modül ilerlemesi, toplam 39 ders, sıradaki ders, kaynaklar ve öz denetim
ekranı çalışır. `viewed`, `practised`, `selfReportedComplete` ayrı
durumlardır. Öz denetim ve çalışma bildirimi olmadan tamamlama yazılmaz.
Kayıt konuk/UUID hesap ve içerik sürümüne ayrılır, aynı dosya için seri
kuyrukta geçici dosya üzerinden atomik yazılır; hesap değişimi eski
hesabın toplamını kaldırır. Hesap silme eski depo izinlerini iptal eder,
aktif yazmanın arkasında temizler; eski sayfa dosyayı yeniden oluşturamaz. Hesap
silme mevcut yerel temizleme akışında kurs dosyasını ve `.tmp` kalıntısını
da kapsar. Bozuk dosya sıfır ilerleme gibi gösterilmez.

## Birincil kaynaklar ve kullanım sınırı

- [Boxing Canada başlangıç el kitabı](https://boxingcanada.org/wp-content/uploads/2025/01/Instruction-Beginners-Reference-Manual-EN.pdf): duruş→ayak çalışması→jab/düz yumruk→savunma/kombinasyon sırası. Metin özgün biçimde yazıldı.
- [Boxing Canada Competition Introduction](https://boxingcanada.org/wp-content/uploads/2025/06/Competition-Introduction-manual-EN.pdf): sonraki teknik ve planlama bağlamı; yarışma/sparring kursa alınmadı.
- [England Boxing Level 1](https://www.englandboxing.org/wp-content/uploads/2022/03/EB_Boxing-Coaching-Handbook-Part-1_v8-002.pdf): temel duruş, gard, ayak, yumruk/savunma ve gölge boksu.
- [ACOG gebelikte egzersiz](https://www.acog.org/womens-health/faqs/exercise-during-pregnancy): genel sağlık ve temaslı spor/fall-risk sınırları; kişiye özel program yok.
- [CDC yetişkin aktivitesi](https://www.cdc.gov/physical-activity-basics/adding-adults/index.html): beceriye uygun aktivite, takip ve eforu uyarlama. Eski `/adults/index.html` 404 olduğundan güncel adresle değiştirildi.

Bu beş resmî URL aynı gün HTTP 200 ile okundu. Boxing Canada ve England
Boxing PDF bölüm başlıkları ağ akışından metin olarak kontrol edildi;
diske kaynak PDF/video kaydedilmedi. Kaynaklara bağlantı vermek, medya
yeniden dağıtım/eğitim lisansı sağladığı anlamına gelmez.

## Yerel doğrulama

- Motor: `dart test test/event_negative_control_gate_test.dart test/negative_motion_rejection_test.dart test/engine_test.dart test/measures_test.dart test/fallback_liveness_test.dart test/depth_sweep_test.dart -r expanded` → **31 PASS**.
- App: içerik, ilerleme, kurs widget akışı, hesap köprüsü, Türkçe katalog ve gezinme sözleşmesi → **30 PASS**.
- Widget: ilk katalogdan kurs, gerçek kontrolle çalışma/iki öz denetim/tamamlama, dosyadan tekrar okuma, hesap değişiminde eski ilerlemenin kaldırılması geçti.
- Dosya yarışı: iki ayrı depodan sekiz eşzamanlı çalışma kaydı sekiz olarak tekrar okundu; hesap silme sonrası bekleyen/eski depo yazması ve `.tmp` kalıntısı geri gelmedi.
- Gezilebilirlik kapısı yeni iki rotayı gerçekten yürüdü: **8 ayrı ekran = 2 kök + 6 push**; gevşek sayım **13**. Belge ve kapı güncellendi.
- Değişen app dosyaları ve yeni testlere Flutter analiz → **0 sorun**. Değişen motor dosyaları ve testlerine Dart analiz → **0 sorun**.
- `python3 tool/generate_solo_boxing_course.py --check` → üretici ile JSON aynı.
- Tam motor suite önce denendi: mevcut `reference-boxing-jab.json` yokluğuna bağlı 13 referans testi kırıldı. Shared `motion-core` artefaktı üretilmedi/değiştirilmedi; odaklı suite bu engelden bağımsız geçti.

## AI medya için sonraki kapı

39 dersteki `mediaBrief` toplu çekim manifestidir; demo dosyaları henüz
üretilmedi. Her özgün demo için önce/yan/üç çeyrek uygun açı, tam hareket
ve kontrollü dönüş, normal hız + kısa yavaş tekrar, TR/EN altyazı ve
reduced-motion alternatifi hazırlanmalı. Sayısal form/hız/kuvvet ölçeri,
rakip, darbe ve ustalık rozeti kullanılmamalı. AI kişinin el/bilek/dirsek
ve ayak anatomisi, iki taraf tutarlılığı ve teknik sırası nitelikli boks
antrenörü incelemeden yayınlanmamalı. AI demo eğitim/holdout verisi olarak
sayılmaz. Sonrasında cihaz okuma/ilerleme, erişilebilirlik ve mağaza
incelemesi gerekir.

## Depolama ve WIP makbuzu

Video, görüntü, ses veya eğitim veri seti indirilmedi; geçici medya
dosyası yok, scratch medya kullanımı **0 bayt**. Kaynaklar ağ akışından
okundu. Widget/unit test geçici dizinleri test teardown ile kaldırıldı.
`.github/workflows/checks.yml` önceden var olan WIP olarak korundu.
Provider, Vault, ortak core, simülatör, commit, push, imzalama veya deploy
işlemi yapılmadı.


## Root içerik ve son uygulama kabulü

Bağımsız içerik incelemesi sonrası rear-hand catch ile kısa dış parry
ayrı kurulum/eylem/geri gard adımlarıyla öğretildi. Başlangıç gard
dersine parmakları yumuşak kapama, başparmağı dışarıda tutma ve
bileği rahat önkolla hizalama eklendi. Generator ve mediaBrief uyumlu.
Son asset SHA-256 `88dff18822d8427ea75f3ece941d63e80aa0f57c4365c4537d9be90f7c83a64f`.

Kök tam app süiti **447 PASS /1 mevcut SKIP**; analiz temiz. Kurs/UI/
mağaza kopyası odaklı9test ve eski kapı açıklamasının gerçek kaydırma
yoluyla18testi geçti. Yeni kurs kartı sonrası açıklama ekrandan
silinmedi; lazy-list testinde kullanıcı kaydırması eklendi.

Native iPhone iOS27 course smoke: gerçek asset ve path-provider altında
yalnız teste ait UUID kapsamı, ilk ders practice/selfcheck/completion,
yeni store ve ekran okuması1/39, başka hesapta0/39 ve hesap silme sonrası
eski store reddi PASS. Türkçe BackButton ve ana ListView ile yürür;
provider Auth veya fiziksel boks geçerliliği kanıtı değildir.
Log: `scratch/2026-09-26-motion-courses/jablab-ios-course-final.log`.
Android kabulü yanındaki kök merkezi makbuzda ayrıca kaydedilir.
