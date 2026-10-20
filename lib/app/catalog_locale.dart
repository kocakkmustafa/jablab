import 'package:flutter/widgets.dart';

import 'ui_language.dart';

/// Display copy is keyed by stable catalog IDs; English source data and
/// measurement contracts remain the canonical input.
const Map<String, String> _turkishTitles = <String, String>{
  'boxing': 'Boks',
  'kickboxing': 'Kickboks',
  'tai_chi': 'Tai Chi',
  'karate': 'Karate — Kihon ve Kata',
  'muay_thai': 'Muay Thai',
  'taekwondo': 'Taekwondo',
  'mma_striking': 'Karma dövüş — ayakta vuruş',
  'wing_chun': 'Wing Chun — tek kişilik formlar',
};

const Map<String, String> _turkishBlurbs = <String, String>{
  'boxing':
      'Telefonu karşına koyup gölge boksu yap. Köşendeki koç gard, '
      'duruş ve denge hakkında konuşur; kum torbası ve sensör gerekmez.',
  'kickboxing':
      'Tekmeler bu sürümün ölçüm kurallarında yok. Motor vuruş '
      'duruşunu ve kol açılarını okur; baş hizasına çıkan bacak farklı bir '
      'ölçümdür. Bunu geliştirip antrenörlerle doğrulamadık.',
  'tai_chi':
      'Burada engel kamera değil; yavaş formlarda hareket bulanıklığı '
      'azdır. Eksik olan uzman referansıdır: 24 formun doğru icrasını '
      'karşılaştırabileceğimiz bir kaynak yok. Kendi görüşümüzle puan vermiyoruz.',
  'karate':
      'Kata, birkaç dakika boyunca zeminde ilerleyen bir dizidir. '
      'Vücudu izliyoruz, ancak odadaki konumunu zaman içinde izlemiyoruz. '
      'Formu tanımlayan bu kısmı ölçemiyoruz.',
  'muay_thai':
      'Dirsek ve diz vuruşlarında uzuvlar gövdenin önünde üst üste '
      'gelir. Boks için kullandığımız güven kapısı da bu kareleri reddeder; '
      'şimdi açmak, okuyamadığımız karelere puan vermek olur.',
  'taekwondo':
      'Dönerek ve sıçrayarak yapılan tekmeler yön değiştirir ve '
      'yerden kesilir. Motor kare başına tek yön ve dik duruş bekler; dönüşü '
      'okuyacak ikinci ölçüm yolu kurulmadı.',
  'mma_striking':
      'Bu disiplin boks, kickboks ve Muay Thai kurallarını '
      'birleştirir. Şu anda yalnız boks kural setimiz var; diğer ikisini '
      'uygulamadık.',
  'wing_chun':
      'Tek kişilik formlar kamera için uygun, ancak uzman referansı '
      'eksik. Tahta manken formu ayrı bir nedenle dışarıda: manken ekipmandır; '
      'motor vücudu izler, etkileştiği nesneyi değil.',
};

String catalogTitle(BuildContext context, String id, String english) =>
    UiLanguage.text(context, en: english, tr: _turkishTitles[id] ?? english);

String catalogBlurb(BuildContext context, String id, String english) =>
    UiLanguage.text(context, en: english, tr: _turkishBlurbs[id] ?? english);

const Map<String, String> _boxingMeasured = <String, String>{
  'Punch events and count — a fact from the phase machine, not a grade':
      'Yumruk olayları ve sayısı — hareket evrelerinden çıkan bir olgu; not değil.',
  'Combination order and timing, for the punches we model. A combination built from hooks or uppercuts is not ordered, because those punches are not recognised in the first place':
      'Modellediğimiz yumruklar için kombinasyon sırası ve zamanlaması. Kroşe veya aparkat içeren bir kombinasyonun sırasını belirlemiyoruz; bu yumrukları baştan tanımıyoruz.',
  'Stance width, crossed feet, balance — these are graded':
      'Duruş genişliği, çaprazlanan ayaklar ve denge — bunlar değerlendirilir.',
  'Guard hand position — detected and coached, but NOT graded. Coaches disagree about it: across our reference takes the rear forearm spread past 45 degrees, and we do not know how far past. We will flag a dropping hand; we will not put a number on it':
      'Gard elinin konumu algılanır ve hakkında yönlendirme verilir; puanlanmaz. Referans kayıtlarımızda arka önkol 45 derecenin ötesine açılıyor, ancak antrenörler kabul edilebilir sınırda uzlaşmıyor. Düşen eli belirtiriz; buna sayı vermeyiz.',
  'Tempo as a band (controlled / brisk / fast), based on the observed time from extension to peak, not pixel speed. The session summary shows the most frequent band among completed attempts with a valid tempo observation.':
      'Tempo, uzanma evresinden tepe evresine gözlenen süreye dayanan bir bant olarak gösterilir (kontrollü / tempolu / hızlı); piksel hızı değildir. Seans özeti, geçerli tempo gözlemi olan tamamlanmış denemelerde en sık görülen bandı gösterir.',
};

const Map<String, String> _boxingNotMeasured = <String, String>{
  'Punch force or power — a camera cannot measure force, and we will not pretend otherwise':
      'Yumruk kuvveti veya gücü — kamera kuvveti ölçemez; ölçüyormuş gibi davranmıyoruz.',
  'Punch mechanics — the path your arm takes is coached, not graded. We do have reference takes for the jab, so this is not a gap in our data: the arm is simply where coaches disagree most, and the lead arm most of all.':
      'Yumruk mekaniği — kolunun izlediği yol için yönlendirme verilir, puan verilmez. Jab için referans kayıtlarımız var; sorun veri eksikliği değil. Antrenörlerin en çok ayrıştığı konu kolun, özellikle de ön kolun hareketidir.',
  'Hook and uppercut technique — not modelled. We ran a real hook lesson through the app: it missed almost every hook, and the handful it did register it counted as jabs or crosses. We would rather say that than let a wrong number look right.':
      'Kroşe ve aparkat tekniği — modellenmedi. Gerçek bir kroşe dersinde uygulama neredeyse tüm kroşeleri kaçırdı; algıladığı birkaçını jab veya cross saydı. Yanlış bir sayıyı doğruymuş gibi göstermek yerine bunu açıkça söylüyoruz.',
  'Head movement quality (slip / duck / roll) — reaction skills need an opponent':
      'Baş hareketinin kalitesi (kaçınma / eğilme / sıyrılma) — tepki becerisi için rakip gerekir.',
  'Anything while your body is out of frame or tracking confidence is low — the app says so instead of guessing':
      'Vücudun kadraj dışında veya takip güveni düşükken yapılanlar — uygulama tahmin yürütmek yerine bunu bildirir.',
};

List<String> catalogMeasured(
  BuildContext context,
  String id,
  List<String> source,
) => _catalogHonesty(context, id, source, _boxingMeasured);

List<String> catalogNotMeasured(
  BuildContext context,
  String id,
  List<String> source,
) => _catalogHonesty(context, id, source, _boxingNotMeasured);

List<String> _catalogHonesty(
  BuildContext context,
  String id,
  List<String> source,
  Map<String, String> translations,
) {
  if (id != 'boxing') return source;
  return source
      .map(
        (String english) => UiLanguage.text(
          context,
          en: english,
          tr: translations[english] ?? english,
        ),
      )
      .toList(growable: false);
}
