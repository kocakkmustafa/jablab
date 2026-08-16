/// Standing Striking Engine — JabLab'ın ayakta-vuruş analiz motoru.
///
/// **Branş-bağımsızdır (ADR-004).** Motor kodunda "jab", "cross", "orthodox"
/// gibi hiçbir boks terimi sabit değildir; teknikler, fazlar, eşikler ve hata
/// kodları versiyonlu config'ten (`assets/rulesets/boxing@1.x.json`) gelir.
/// Kickboks/Muay Thai aynı motora **yeni bir config** ile takılır — kickboks
/// ön-hasat ölçümü bunu doğruladı: beş ölçülebilir branş farkının dördü
/// mevcut ölçülerle karşılanıyor, beşincisi (`frontFootLoadRatio`) eklendi.
///
/// Motor **lead/rear** ile konuşur, left/right ile değil (M-F-06): modelin
/// taraf etiketine ham güvenilmez, taraf geometrik kurulur.
library;

export 'src/library.dart';
export 'src/measures.dart';
export 'src/reliability_stats.dart';
export 'src/ruleset.dart';
export 'src/stance.dart';
export 'src/striking_engine.dart';
