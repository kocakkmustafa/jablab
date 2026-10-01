import 'package:flutter/widgets.dart';

import 'ui_language.dart';

typedef _Copy = ({String en, String tr});

// Keep authored English content as the source of truth. A changed source
// string falls back to English until its Turkish translation is reviewed.
String _copy(
  BuildContext context,
  String id,
  String source,
  Map<String, _Copy> translations,
) {
  if (!UiLanguage.isTurkish(context)) return source;
  final _Copy? copy = translations[id];
  return copy != null && copy.en == source ? copy.tr : source;
}

const Map<String, _Copy> _courseTitles = <String, _Copy>{
  'boxing.foundations': (en: 'Foundations', tr: 'Temeller'),
  'boxing.footwork': (en: 'Footwork', tr: 'Ayak çalışması'),
  'boxing.conditioning': (
    en: 'Rounds and conditioning',
    tr: 'Rauntlar ve kondisyon',
  ),
  'boxing.intermediate': (en: 'Intermediate', tr: 'Orta seviye'),
};

const Map<String, _Copy> _courseGoals = <String, _Copy>{
  'boxing.foundations': (
    en: 'Build a stance and a jab you can repeat without thinking.',
    tr: 'Düşünmeden tekrarlayabileceğin bir duruş ve jab geliştir.',
  ),
  'boxing.footwork': (
    en: 'Move without losing the stance and balance Foundations built.',
    tr: 'Temeller bölümünde geliştirdiğin duruşu ve dengeyi kaybetmeden hareket et.',
  ),
  'boxing.conditioning': (
    en: "Work rounds without a bag. The app keeps time, counts what it can see, and stays quiet about what it can't.",
    tr: 'Kum torbası olmadan raunt çalış. Uygulama süre tutar, görebildiğini sayar ve göremediği konuda yorum yapmaz.',
  ),
  'boxing.intermediate': (
    en: 'One lesson is open: holding your shape through a long round. The other three are locked for three different reasons, and each names its own.',
    tr: 'Uzun bir rauntta formunu koruma dersi açık. Diğer üç ders farklı nedenlerle kapalı; her birinde nedeni yazıyor.',
  ),
};

const Map<String, _Copy> _lessonTitles = <String, _Copy>{
  'boxing.foundations.camera': (
    en: 'Camera and space',
    tr: 'Kamera ve çalışma alanı',
  ),
  'boxing.foundations.stance': (en: 'Stance and guard', tr: 'Duruş ve gard'),
  'boxing.foundations.jab': (en: 'The jab', tr: 'Jab'),
  'boxing.foundations.guard': (en: 'Holding the guard', tr: 'Gardı koruma'),
  'boxing.foundations.range': (
    en: 'Range and the straight line',
    tr: 'Mesafe ve düz hat',
  ),
  'boxing.foundations.cross': (en: 'The cross', tr: 'Cross'),
  'boxing.foundations.one_two': (en: 'The 1-2', tr: '1-2 kombinasyonu'),
  'boxing.foundations.first_round': (en: 'Your first round', tr: 'İlk rauntun'),
  'boxing.footwork.moving': (
    en: 'Moving without crossing your feet',
    tr: 'Ayakları çaprazlamadan hareket',
  ),
  'boxing.footwork.step_then_punch': (
    en: 'Step, then punch',
    tr: 'Önce adım, sonra yumruk',
  ),
  'boxing.conditioning.r3': (
    en: '3 x 3 minute rounds',
    tr: '3 x 3 dakikalık raunt',
  ),
  'boxing.conditioning.tempo': (en: 'Tempo control', tr: 'Tempo kontrolü'),
  'boxing.conditioning.r5': (en: 'Five minutes', tr: 'Beş dakika'),
  'boxing.conditioning.r10': (en: 'Ten minutes', tr: 'On dakika'),
  'boxing.conditioning.r20': (en: 'Twenty minutes', tr: 'Yirmi dakika'),
  'boxing.conditioning.hiit': (
    en: 'Interval burst',
    tr: 'Aralıklı yoğun çalışma',
  ),
  'boxing.conditioning.technique_round': (
    en: 'Technique round',
    tr: 'Teknik rauntu',
  ),
  'boxing.intermediate.combinations': (
    en: 'Longer combinations',
    tr: 'Daha uzun kombinasyonlar',
  ),
  'boxing.intermediate.counter': (
    en: 'Answering after defence',
    tr: 'Savunmadan sonra karşılık verme',
  ),
  'boxing.intermediate.footwork_combo': (
    en: 'Footwork with combinations',
    tr: 'Kombinasyonlarla ayak çalışması',
  ),
  'boxing.intermediate.fatigue': (
    en: 'Technique under fatigue',
    tr: 'Yorgunluk altında teknik',
  ),
};

const Map<String, _Copy> _lockedReasons = <String, _Copy>{
  'boxing.intermediate.combinations': (
    en: "Hooks and uppercuts aren't modelled here. We ran a real hook lesson through the app: it missed almost all of them, and the few it did register it labelled as jabs or crosses. Either way the number would be wrong, so we don't score combination order.",
    tr: 'Kroşe ve aparkat burada modellenmedi. Gerçek bir kroşe dersini uygulamada denedik: kroşelerin neredeyse tamamını kaçırdı; algıladıklarının birkaçını da jab veya cross olarak kaydetti. Sayı bu durumda yanlış olacağından kombinasyon sırasını puanlamıyoruz.',
  ),
  'boxing.intermediate.counter': (
    en: 'Answering a defence means answering an attack, and in shadow work there is no attack. We could time the movement you make on your own — but calling that a defensive reflex would be a lie about what we measured, not just an imprecise score.',
    tr: 'Savunmadan sonra karşılık vermek için önce bir saldırı gerekir; gölge boksta saldırı yok. Kendi başına yaptığın hareketi zamanlayabiliriz, ancak buna savunma refleksi demek ölçtüğümüz şeyi yanlış anlatır.',
  ),
  'boxing.intermediate.footwork_combo': (
    en: 'We can catch crossed feet: that is a fault, and faults are visible. Good footwork is a skill, and we have not collected takes from enough independent coaches to say what it looks like. Catching a fault and grading a skill are different jobs, and we will not let one stand in for the other.',
    tr: 'Çaprazlanan ayakları saptayabiliriz; bu görülebilir bir hatadır. İyi ayak çalışmasını tanımlamak içinse yeterli sayıda bağımsız antrenörün örneklerini toplamadık. Bir hatayı yakalamak ile beceriyi puanlamak farklı işlerdir; birini diğerinin yerine koymuyoruz.',
  ),
};

String courseTitle(BuildContext context, String id, String source) =>
    _copy(context, id, source, _courseTitles);

String courseGoal(BuildContext context, String id, String source) =>
    _copy(context, id, source, _courseGoals);

String lessonTitle(BuildContext context, String id, String source) =>
    _copy(context, id, source, _lessonTitles);

String? lessonLockedReason(BuildContext context, String id, String? source) =>
    source == null ? null : _copy(context, id, source, _lockedReasons);
