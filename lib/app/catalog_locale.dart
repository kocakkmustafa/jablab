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
      'Solo boks kursunu kamera olmadan oku ve çalış. '
      'Kursa yazılı ipuçları ve kendi öz kontrollerin rehberlik eder; '
      'bu sürümde canlı kamera koçluğu kapalıdır.',
  'kickboxing':
      'Tekmeler bu sürümün ölçüm kurallarında yok. Motor vuruş '
      'duruşunu ve kol açılarını okur; baş hizasına çıkan bacak farklı bir '
      'ölçümdür. Bunu geliştirip antrenörlerle doğrulamadık.',
  'tai_chi':
      'Yavaş formlar hareket bulanıklığını azaltabilir; kameranın hareketi okuyabildiğini garanti etmez. Ayrıca 24 formu değerlendirmek için kabul edilmiş uzman referansımız ve doğrulanmış kamera koşullarımız yok. Kendi görüşümüze dayanarak puan vermiyoruz; bu form için kamera geri bildirimi kullanılamıyor.',
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
  'This course records your own practice report. No automatic camera punch count is produced in this release.':
      'Bu kurs kendi çalışma beyanını kaydeder. Bu sürümde otomatik kamera yumruk sayımı üretilmez.',
  'Combination order and timing are not assessed automatically in this release. Written and self-reported practice do not verify them.':
      'Bu sürümde kombinasyon sırası ve zamanlaması otomatik değerlendirilmez. Yazılı çalışma ve öz beyan bunları doğrulamaz.',
  'Stance width, crossed feet and balance are not graded by the camera in this release.':
      'Bu sürümde duruş genişliği, çaprazlanan ayaklar ve denge kamera tarafından puanlanmaz.',
  'Guard hand position is not detected or coached automatically in this release. The course provides written cues and your own self-checks.':
      'Bu sürümde gard elinin konumu otomatik algılanmaz veya koçlukla yönlendirilmez. Kurs yazılı ipuçları ve kendi öz kontrollerini sunar.',
  'Tempo is self-selected in the current solo course. No camera speed measurement or tempo band is produced here.':
      'Mevcut solo kursta tempo kullanıcı tarafından seçilir. Burada kamera hız ölçümü veya tempo bandı üretilmez.',
};

const Map<String, String> _boxingNotMeasured = <String, String>{
  'Punch force or power — a camera cannot measure force, and we will not pretend otherwise':
      'Yumruk kuvveti veya gücü — kamera kuvveti ölçemez; ölçüyormuş gibi davranmıyoruz.',
  'Punch mechanics are studied through written paths, practice tasks and self-checks. This course does not automatically grade the arm path or certify technique.':
      'Yumruk mekaniği, hareket yollarının yazılı açıklamaları, çalışma görevleri ve öz kontrollerle ele alınır. Bu kurs kolun izlediği yolu otomatik puanlamaz ve tekniğin doğruluğunu onaylamaz.',
  'Hook and uppercut technique — not modelled. We ran a real hook lesson through the app: it missed almost every hook, and the handful it did register it counted as jabs or crosses. We would rather say that than let a wrong number look right.':
      'Kroşe ve aparkat tekniği — modellenmedi. Gerçek bir kroşe dersinde uygulama neredeyse tüm kroşeleri kaçırdı; algıladığı birkaçını jab veya cross saydı. Yanlış bir sayıyı doğruymuş gibi göstermek yerine bunu açıkça söylüyoruz.',
  'Head movement quality (slip / duck / roll) — reaction skills need an opponent':
      'Baş hareketinin kalitesi (kaçınma / eğilme / sıyrılma) — tepki becerisi için rakip gerekir.',
  'No camera analysis runs in the current solo course. A missing observation is not evidence of a correct technique.':
      'Mevcut solo kursta kamera analizi çalışmaz. Gözlem yokluğu doğru teknik kanıtı değildir.',
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
