/// Küçük-örneklem yüzdelik vakumu (H-62, F4 J-280'in dersi).
///
/// `CanonicalReference.dispersion`in kendisi (shared `motion_core`) sağlam
/// bir kapalı-form istatistik kullanır (dairesel standart sapma, TÜM n
/// noktasını sürekli bir formülle katar) — bu dosyanın çözdüğü sorun ORADA
/// DEĞİL. Sorun, APP-KATMANI rapor betiklerinin (`tool/build_*_reference.dart`
/// sınıfı) o dağılım değerlerini KARELER ARASINDA sıralayıp p90/medyan/maks
/// BASMASIYDI — ve her karenin dağılımının kendisi yalnız KATKI VEREN KAYNAK
/// SAYISI kadar örnekle hesaplanmıştı. Ölçülen vaka (F4, cross): 3 kaynak,
/// `trunk_tilt` p90=83,6° iken medyan=6,4° — p90 üç değerin yalnızca EN
/// BÜYÜĞÜ, gerçek 90. yüzdelik değil (n küçükken sıralı istatistik formül
/// olarak ÇALIŞIR ama ANLAMINI kaybeder).
library;

/// Bir yüzdelik hesaplamanın SONUCU — ya gerçek bir değer ya da ADIYLA
/// neden ölçülemediği. K8'in "bilmiyorum" ≠ "en düşük" ilkesinin istatistik
/// karşılığı: `null` dönmek de olurdu ama çağıran taraf NEDEN'i kaybederdi.
sealed class PercentileResult {
  const PercentileResult();
}

final class Measured extends PercentileResult {
  const Measured(this.value);
  final double value;
}

final class Unmeasured extends PercentileResult {
  const Unmeasured(this.n, this.minSources);
  final int n;
  final int minSources;

  String get reason =>
      'n=$n < $minSources — yüzdelik formül olarak çalışır ama '
      'küçük örneklemde birkaç değerin biri (özellikle p90/maks) sonucu '
      'domine eder; "temiz" değil "ölçülemedi" (H-62)';
}

/// [values]'ın [p] yüzdeliğini hesaplar — ama yalnız [contributingSources]
/// (KAYNAK sayısı, KARE sayısı DEĞİL) [minSources]'a ulaşıyorsa. Ulaşmazsa
/// [Unmeasured] döner; sessizce "en iyi tahminimiz" basmaz.
///
/// `contributingSources` ayrı bir parametre çünkü [values] genelde KARE
/// başına bir sayı taşır (onlarca/yüzlerce) — örneklem zayıflığının
/// kaynağı kare sayısı değil, her karenin ARKASINDAKİ bağımsız kaynak
/// sayısıdır (F4'ün ölçtüğü tam bu: 72 kare ama yalnızca 3 kaynak).
PercentileResult reliablePercentile(
  List<double> values,
  double p, {
  required int contributingSources,
  int minSources = 5,
}) {
  if (contributingSources < minSources) {
    return Unmeasured(contributingSources, minSources);
  }
  final List<double> sorted = List<double>.of(values)..sort();
  if (sorted.isEmpty) return Unmeasured(0, minSources);
  final int idx = (p * (sorted.length - 1)).round();
  return Measured(sorted[idx]);
}
