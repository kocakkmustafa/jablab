/// Seans geçmişi — **artık çekirdekten geliyor** (J-095, motion_core 0.11.0).
///
/// ## Ne oldu
///
/// `SessionRecord` · `SessionStore` · `JsonlSessionStore` ve yerel üç-hâl
/// modelim (`HistoryFailure` + `isPartial`) burada YAŞIYORDU. Üç hat
/// (JabLab · Gravita · Choreia) aynı semantiğe bağımsız yakınsadı, üçler
/// kuralı SEMANTİKTE doldu ve sözleşme çekirdeğe terfi etti
/// (`HistoryReadStatus`, M-F-254). Bu dosya artık o tipleri **yeniden
/// dışa veriyor**: tüketicilerin import satırı değişmesin diye — değişen
/// şey nereden geldiği, ne olduğu değil.
///
/// **WIDGET terfi ETMEDİ**: görsel yüzey her app'in kendi sesidir. Kullanıcıya
/// gösterilen cümleler hâlâ bu app'te (`jablab_app.dart`), çekirdekte değil.
///
/// ## Göç: v1 kayıtları KAYIP DEĞİL
///
/// Benim yazdığım satırlar `v:1` ve `roundsCompleted`/`plannedRounds`
/// taşıyordu; çekirdek şeması `v:2` ve `unitsCompleted`/`plannedUnits`.
/// Çekirdek v1'i **okuyor** (`SessionRecord.fromV1Json`) ve okunabilir bir
/// satırı asla kayıp saymıyor — aksi hâlde adopsiyon günü her eski kullanıcı
/// geçmişini "kısmen okunamadı" diye görürdü: düzeltmek için kurduğum
/// mekanizmanın kendi kurbanı olurdu.
library;

export 'package:motion_core/motion_core.dart'
    show
        HistoryOk,
        HistoryPartial,
        HistoryReadStatus,
        HistoryUnavailable,
        JsonlSessionStore,
        SessionStoreWriteLease,
        SessionStoreRetiredException,
        SessionRecord,
        SessionStore;

import 'package:motion_core/motion_core.dart';

/// Kaydedilmiş seansların OLGU özeti (F-4/J-066) — **app katmanında kalır.**
///
/// Çekirdeğe çıkmadı ve çıkmamalı: burada bir SUNUM kararı var (saniye
/// gösterilmez, "3 recorded, 1 stopped early" gibi cümleler) ve o cümleler
/// app'in sesi. Çekirdek OKUMA sözleşmesini taşıyor, konuşma biçimini değil.
///
/// Hüküm YOK: "iyi/kötü" diyen tek alan bile yok. Alanların hepsi kameradan
/// bağımsız ölçülebilen şeyler — K8 kilidi bunları kapatmaz (K8 SKORU
/// kapatır, olguyu değil).
final class RecordedSummary {
  const RecordedSummary({
    required this.sessions,
    required this.completed,
    required this.workedSeconds,
    required this.status,
  });

  final int sessions;
  final int completed;
  final int workedSeconds;

  /// Okuma hâli — **çekirdeğin sözleşmesi** (`HistoryOk` · `HistoryPartial(n)`
  /// · `HistoryUnavailable`). Yerel `isPartial` bayrağının yerini aldı:
  /// bayrak "kısmi mi" sorusunu cevaplıyordu, tip "hangi hâlde" sorusunu
  /// cevaplıyor ve üçüncü hâli (açılamama) da taşıyor.
  ///
  /// [HistoryUnavailable] BU NESNEDE bulunamaz — açılamayan geçmişten sayı
  /// doğmaz (doc-75 değişmez 2, "totals-nullable"): o hâlde çağıran hiç
  /// `RecordedSummary` KURMAZ. Tip bunu engelleyemiyor; `from` sözleşmesi
  /// engelliyor (istisna yolu ayrı).
  final HistoryReadStatus status;

  int get stoppedEarly => sessions - completed;

  /// İnsan-okur süre. Saniye GÖSTERİLMEZ: bir antrenman süresinde saniye
  /// hassasiyeti bilgi taşımaz, yalnız kesinlik izlenimi verir.
  ///
  /// ## ⚠️ SIFIR İKİ FARKLI OLGUYU ANLATIYORDU (J-257)
  ///
  /// `17 sn` çalışan bir kullanıcı **`0 min`** görüyordu — hiç çalışmayanla
  /// **birebir aynı dize**. İki ayrı olgu tek değere düşüyordu:
  ///  * `workedSeconds == 0` → gerçekten hiçbir şey yapılmadı,
  ///  * `0 < workedSeconds < 60` → **yapıldı**, ama bir dakikadan kısa.
  ///
  /// Çıplak `0`ın *"hiç yapmadın"* diye okunması bu defterin **J-096**'da
  /// zaten bedelini ödediği sınıf (orada *"sıfır yumruk attın"* idi).
  /// Gerçek bir seansta ölçüldü: 17 saniyelik koşum diske `workedSeconds:17`
  /// yazdı, ilerleme kutusu **`Time worked: 0 min`** bastı.
  ///
  /// ⛔ Saniye hâlâ GÖSTERİLMİYOR — yukarıdaki gerekçe sağlam. Değişen tek
  /// şey, **yapılmış bir işin yapılmamış gibi okunmaması.**
  String get workedLabel {
    // Sıfır-olmayan ama bir dakikadan kısa: iş VAR, süresi yuvarlanamıyor.
    if (workedSeconds > 0 && workedSeconds < 60) return 'under a minute';
    final int m = workedSeconds ~/ 60;
    if (m < 60) return '$m min';
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  /// Depoyu okur. **Fırlatabilir** — ve fırlatması gerekir: açılamayan bir
  /// geçmişten sıfır-dolu bir özet dönmek, dosya-açamamayı "0 seans, 0 dk"
  /// diye render ettirirdi (doc-75/2). Yanlış çıktı gizlenmez, HİÇ OLUŞMAZ.
  static Future<RecordedSummary> from(SessionStore store) async {
    final List<SessionRecord> all = await store.recent();
    int worked = 0;
    int done = 0;
    for (final SessionRecord r in all) {
      worked += r.workedSeconds;
      if (r.isComplete) done++;
    }
    return RecordedSummary(
      sessions: all.length,
      completed: done,
      workedSeconds: worked,
      // Hâl, kayıp SAYISINDAN türetilir; 0 → ok, n>0 → partial. Açılamama
      // buradan ÜRETİLEMEZ (yukarıdaki fırlatma yolu).
      status: HistoryReadStatus.of(await store.unreadableRecords()),
    );
  }
}
