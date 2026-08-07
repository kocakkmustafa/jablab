import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// BANT LİSTESİ TEK KAYNAKTAN TÜRER (J-144, koordinatör hükmü 09:24).
///
/// ## Ölçülen kusur
///
/// İki ekran kendi bant üçlüsünü **elle** yazıyordu ve ikisi FARKLIYDI:
/// özet `Stance·Balance·Footwork`, Sayfa B `Guard discipline·Punch
/// mechanics·Balance`. Üstelik:
///
/// * **`Stance` kaynakta HİÇ YOKTU** — elle yazılan liste, kaynağın
///   bilmediği bir öğe icat etmişti;
/// * **`Guard discipline` PUANLANMIYOR** ama *"Scores are shown as bands
///   **until the thresholds are calibrated**"* başlığının altındaydı.
///   Sayfa A'nın dürüstlük kutusu aynı anda *"detected and coached, but
///   **NOT graded**. Coaches disagree"* diyordu.
///
/// İki iddia aynı anda doğru olamaz, ve hangisinin doğru olduğu **ölçülmüş**:
/// `references.stance.coachedOnlyJoints.rear_forearm` dağılımı **45° tavana
/// kırpılı**. Bu bir **kalibrasyon eksikliği değil, referans
/// uzlaşmazlığı** — kalibrasyonla **kapanmaz**. Yani o başlık guard için
/// **karşılıksız bir vaatti** (M-F-186), bant listesine gizlenmiş hâli.
///
/// ## Ölü beyan çelişkiyi GİZLEDİ
///
/// Kaynak liste (`scoreComponents`) **okunmuyordu**. Okunsaydı iki yüzey
/// orada buluşur ve uyuşmazlık görünürdü; okunmadığı için **her yüzey
/// kendi üçlüsünü icat etti**. Adı da yanlıştı ve kanıtı kendi içindeydi:
/// `trackingConfidence` listedeydi ve o asla puanlanmaz → `trackedComponents`.
void main() {
  late RuleSet boxing;

  setUpAll(() async {
    final ({dynamic library, dynamic boxing}) c =
        await const ContentRepository().load();
    boxing = c.boxing as RuleSet;
  });

  test('PUANLANMAYAN bileşen bant listesinde YOK', () {
    final Map<String, String> bands =
        const ContentRepository().gradedBands(boxing);
    final List<String> leaked = boxing.trackedComponents
        .where((TrackedComponent c) => !c.graded)
        .map((TrackedComponent c) => c.displayName)
        .where(bands.containsKey)
        .toList();
    expect(leaked, isEmpty,
        reason: 'puanlanmayan bileşen(ler) bant listesinde: $leaked. Bant '
            'başlığı "until the thresholds are calibrated" diyor; '
            'puanlanmayan bir bileşen için bu KARŞILIKSIZ BİR VAAT (J-144)');
  });

  test('NEGATİF İKİZ — PUANLANAN bileşen bant listesinde VAR', () {
    // M-F-337. Yalnız yukarıdaki ölçülseydi, bant listesinin **tamamen
    // boşalması** da kapıyı geçerdi: hiçbir puanlanmayan bileşen yok,
    // çünkü hiçbir bileşen yok. Kapı bir iddiayı değil bir SESSİZLİĞİ
    // korurdu.
    final Map<String, String> bands =
        const ContentRepository().gradedBands(boxing);
    final List<TrackedComponent> graded = boxing.gradedComponents;
    expect(graded, isNotEmpty,
        reason: 'hiçbir bileşen puanlanmıyor — J-144 guard\'ı çıkardı, '
            'listeyi boşaltmadı');
    for (final TrackedComponent c in graded) {
      expect(bands.containsKey(c.displayName), isTrue,
          reason: '${c.id} puanlanıyor ama bant listesinde yok');
    }
  });

  test('PUANLANMAYAN her bileşen İSİMLİ gerekçe taşıyor', () {
    // Parser zaten FIRLATIYOR (sebepsiz `graded:false` kabul etmiyor) — bu
    // test o sözleşmenin kaldırılmadığını ölçüyor. Sebepsiz bir sınır,
    // kullanıcıya "bir gün belki" diye okunur ve bu ürünün tamamı o
    // okumaya karşı yazıldı.
    for (final TrackedComponent c in boxing.trackedComponents) {
      if (c.graded) continue;
      expect(c.gradedWhyNot, isNotNull, reason: c.id);
      expect(c.gradedWhyNot!.trim(), isNotEmpty, reason: c.id);
    }
  });

  test('gerekçeler VAAT DİLİ taşımıyor', () {
    // Gerekçe kullanıcıya gösterilebilir bir cümle; "yet"/"soon" onu bir
    // zaman taahhüdüne çevirir. Guard'ınki özellikle kritik: o sınır
    // kalibrasyonla KAPANMAZ, yani bir bekleme değil bir KARAR.
    final RegExp promise = RegExp(
        r'\b(yet|soon|coming|planned|will be|for now|currently)\b',
        caseSensitive: false);
    for (final TrackedComponent c in boxing.trackedComponents) {
      final String? why = c.gradedWhyNot;
      if (why == null) continue;
      expect(promise.hasMatch(why), isFalse,
          reason: '${c.id}: gerekçe vaat dili taşıyor → "$why"');
    }
  });
}
