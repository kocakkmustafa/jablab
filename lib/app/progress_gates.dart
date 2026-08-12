// `SessionRecord` çekirdekten geliyor ama bu app'e `session_store.dart`
// üzerinden giriyor (J-095 yeniden-dışa-verme) — tüketiciler tek kapıdan
// okusun diye.
import 'session_store.dart';

/// İLERLEME KAPISI DEĞERLENDİRİCİSİ — kapı sisteminin eksik TÜKETİCİSİ
/// (J-208, koordinatör hükmü (B), 2026-08-12).
///
/// ## Neden bu dosya var
///
/// `curriculum.json` 16 ilerleme kapısı tanımlıyor ve bugüne kadar **hiçbiri
/// üretimde değerlendirilmiyordu**: dosya asset olarak paketleniyordu ama
/// `ContentRepository` onu hiç yüklemiyordu; `'gates'` anahtarını okuyan her
/// dosya bir TESTTİ (J-207, iki bağımsız yöntemle ölçüldü). Yani kapılar bir
/// İÇERİK BEYANIYDI, bir ürün davranışı değil.
///
/// Koordinatör hükmü: **önce tüketici.** Eksik üreticileri
/// (`setupCheckPassed`/`stanceHold`) yazmak, uzak ucu bağlı olmayan bir hatta
/// iki üretici daha eklemek olurdu — `COMBINATION_END` ile aynı ölü-mekanizma
/// sınıfı.
///
/// ## KAPSAM — dar ve kasıtlı (koordinatör sınırı)
///
/// YALNIZ **olay-sayımı** kapıları: `event` + `minCompletedAttempts`. Bugün
/// dört tane var (`jab` 30 · `cross` 30 · `guard` jab 40 · `range` jab 40) ve
/// bunlar tek KANITLANMIŞ-GÜVENLİ desen. Diğer üç sınıfa **dokunulmuyor** —
/// `withValidAnalysisRatio` (9 kapı, üreticisiz), `combination` (③ katmanı
/// `COMBINATION_END` riski açık), `minSeconds` (`stanceHold`, üreticisiz).
/// Kapsam dışı bir kapı için [evaluate] `null` döner: *değerlendirilmedi*,
/// "geçilemedi" DEĞİL. Sessizce `false` dönmek, ölçmediğimiz bir şeyi
/// başarısızlık diye raporlamak olurdu.
///
/// ## ⛔ NE YAPMAZ — kilit
///
/// Bu değerlendirici **hiçbir içeriği kilitlemez ya da açmaz.** İlerlemeyi
/// ÖLÇER ve GÖSTERİR, o kadar (koordinatör sınırı). Kilit davranışını
/// değiştirmek geri alması pahalı bir ürün kararıdır ve bu turun işi değil.
///
/// ## ÜÇÜNCÜ HÂL, TİP DÜZEYİNDE ZORUNLU
///
/// [GateEvidence.completedEvents] **nullable** döner ve bu bir kolaylık
/// değil, bu dosyanın asıl fikri: *saklanmamış bir sayaçtan SAYI DOĞMAZ*
/// (doc-75/2'nin kapı karşılığı). Bugün `SessionRecord` olay sayısı
/// TAŞIMIYOR — canlı aşamada gerçekten sayılan değer (`_countedEvents`) özet
/// ekranına verilip ekranla birlikte ÖLÜYOR. Bu durumda `0/30` göstermek
/// **yeni bir canlı yalan** olurdu: uygulama yumrukları saydı, sayıyı attı,
/// sonra kullanıcıya "hiç yapmadın" dedi. Onun yerine [GateNotEvaluable]
/// döner ve sebebini ADIYLA taşır.
sealed class GateVerdict {
  const GateVerdict();
}

/// Kapı GEÇİLDİ — ölçülen sayı gerekeni karşıladı.
final class GatePassed extends GateVerdict {
  const GatePassed({required this.measured, required this.required});

  final int measured;
  final int required;
}

/// Kapı henüz geçilmedi — ama [measured] GERÇEK bir ölçüm.
///
/// Bu hâl yalnız kanıt GERÇEKTEN okunabildiğinde kurulur. "Bilmiyorum"
/// buraya düşemez: onun yeri [GateNotEvaluable].
final class GateProgress extends GateVerdict {
  GateProgress({required this.measured, required this.required})
      : assert(measured >= 0, 'ölçülen sayı negatif olamaz'),
        assert(measured < required,
            'ölçülen gerekeni karşılıyorsa hâl GatePassed olmalı — iki hâl '
            'birbirinin yerine geçemez (doc-75/5)');

  final int measured;
  final int required;
}

/// Kapı BUGÜN DEĞERLENDİRİLEMİYOR — ve sebebi adıyla taşınıyor.
///
/// ⚠️ Bu hâl bir hata değil, bir ÖLÇÜM: kapının beklediği kanıt kalıcı
/// katmanda yok. Sayı üretmiyoruz çünkü ölçmedik.
final class GateNotEvaluable extends GateVerdict {
  const GateNotEvaluable({required this.event, required this.reason});

  /// Kapının beklediği olay adı (`jab`, `cross`, …).
  final String event;

  /// NEDEN değerlendirilemiyor — kullanıcıya değil, çağırana. Yüzey metni
  /// app'in sesiyle ayrıca yazılır (doc-75/5: ham `detail` sızmaz).
  final String reason;
}

/// Kapının ihtiyaç duyduğu kanıtı sağlayan kaynak.
abstract interface class GateEvidence {
  /// [event] adlı olay bugüne kadar kaç kez TAMAMLANDI?
  ///
  /// **`null` = ÖLÇÜLMEDİ/SAKLANMADI — `0` DEĞİL.** Ayrım bu arayüzün varlık
  /// sebebi: `0` *"ölçtük, hiç yoktu"* demektir ve bu ürün onu yalnız
  /// gerçekten ölçtüğünde söyler.
  int? completedEvents(String event);
}

/// Kaydedilmiş seanslardan türeyen kanıt — ve bugün NEDEN boş döndüğü.
///
/// ## ⚠️ BU BİR TASLAK DEĞİL, DOĞRU BİR UYGULAMA
///
/// [completedEvents] bugün her olay için `null` dönüyor, ve bu bir yer
/// tutucu değil: `SessionRecord` şemasında olay sayısı diye bir alan YOK
/// (`lessonId`/`completedAt`/`workedSeconds`/`unitsCompleted`/`plannedUnits`/
/// `unitLabel`/`lessonClass`/`unmeasuredUnits`). `unitsCompleted` TUR sayar,
/// yumruk değil — onu yumruk sayısı yerine okumak iki farklı olguyu
/// karıştırmak olurdu.
///
/// **İKİNCİ ve BAĞIMSIZ engel:** dört kapı dersinin (`jab`/`cross`/`guard`/
/// `range`) hiçbirinde tur ya da aralık planı yok, ve `SessionScreen._record`
/// plansız derste erken dönüyor — yani bu dersler bugün **hiç kayıt
/// yazmıyor.** Kanıt alanı eklense bile bu ders için satır oluşmazdı.
///
/// İkisi de kapandığında bu sınıf gerçek sayı döndürmeye **kendiliğinden**
/// başlar; değerlendiricinin geri kalanı değişmez. Bunun böyle olduğu
/// `progress_gates_test`in POZİTİF İKİZİYLE kanıtlanıyor — yoksa yalnız
/// "değerlendirilemez" diyebilen bir mekanizma sevk etmiş olurduk ve
/// bozukluğu fark edilmezdi.
class RecordedGateEvidence implements GateEvidence {
  const RecordedGateEvidence(this.records);

  final List<SessionRecord> records;

  /// Kanıtın bugün neden yok olduğu — [GateNotEvaluable.reason]a geçer.
  static const String schemaGap =
      'SessionRecord olay sayısı taşımıyor (canlı sayım özet ekranıyla '
      'birlikte ölüyor) VE dört kapı dersi plansız olduğu için hiç kayıt '
      'yazmıyor — iki bağımsız engel, J-208';

  @override
  int? completedEvents(String event) => null;
}

/// Bir dersin ilerleme kapısını değerlendirir.
///
/// `null` döner = **bu kapı bu turun kapsamında değil** (olay-sayımı değil)
/// ya da ders için kapı tanımlı değil. Kapsam dışını `false`/`0` diye
/// raporlamak, ölçmediğimiz bir şeye hüküm vermek olurdu.
GateVerdict? evaluateEventGate(
  Map<String, dynamic> curriculum,
  String lessonId,
  GateEvidence evidence,
) {
  final Object? progression = curriculum['progression'];
  if (progression is! Map) return null;
  final Object? node = progression[lessonId];
  if (node is! Map) return null;
  final Object? gates = node['gates'];
  if (gates is! List) return null;

  for (final Object? raw in gates) {
    if (raw is! Map) continue;
    final Object? event = raw['event'];
    final Object? required = raw['minCompletedAttempts'];
    // KAPSAM: yalnız olay-sayımı. `minSeconds`/`minOccurrences`/
    // `combination`/`sessionMinutes` bilerek atlanıyor (sınıf dokümanı).
    if (event is! String || required is! int) continue;

    final int? measured = evidence.completedEvents(event);
    if (measured == null) {
      return GateNotEvaluable(
          event: event, reason: RecordedGateEvidence.schemaGap);
    }
    return measured >= required
        ? GatePassed(measured: measured, required: required)
        : GateProgress(measured: measured, required: required);
  }
  return null;
}
