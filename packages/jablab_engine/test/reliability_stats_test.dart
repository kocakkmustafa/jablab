import 'package:jablab_engine/jablab_engine.dart';
import 'package:test/test.dart';

void main() {
  test('yeterli kaynakta gerçek yüzdelik döner', () {
    final PercentileResult r = reliablePercentile(
      <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      0.9,
      contributingSources: 5,
    );
    expect(r, isA<Measured>());
    expect((r as Measured).value, 9);
  });

  test('varsayılan eşiğin (5) altında Unmeasured döner, sessizce değil', () {
    final PercentileResult r = reliablePercentile(
      <double>[1, 2, 3],
      0.9,
      contributingSources: 3,
    );
    expect(r, isA<Unmeasured>());
    expect((r as Unmeasured).n, 3);
    expect(r.minSources, 5);
    expect(r.reason, contains('n=3'));
  });

  test(
      '🔒 SABOTAJ — F4nin GERÇEK vakası: n=3, p90 tek değerin dominasyonu '
      '(bu KORUNMASAYDI ne olurdu)', () {
    // Gerçek ölçüm (trunk_tilt, F4): p90=83.6° medyan=6.4° — üç değerden
    // yalnızca EN BÜYÜĞÜ p90 diye basılıyordu. Aynı deseni burada üretip
    // KORUMANIN devrede olduğunu kanıtlıyoruz.
    const List<double> trunkTiltDeg = <double>[6.1, 6.4, 83.6];
    final PercentileResult guarded =
        reliablePercentile(trunkTiltDeg, 0.9, contributingSources: 3);
    expect(guarded, isA<Unmeasured>(),
        reason: 'korumasız kalsaydı bu satır Measured(83.6) dönerdi — '
            'tek bir aykırı değeri "90. yüzdelik" diye sunmak');

    // Kapının GERÇEKTEN ısırdığının kanıtı: korumayı KAPAT (minSources:0,
    // yani sabotaj), aynı veriyle GERÇEKTEN 83.6 çıktığını gör.
    final PercentileResult sabotajli = reliablePercentile(
      trunkTiltDeg,
      0.9,
      contributingSources: 3,
      minSources: 0,
    );
    expect(sabotajli, isA<Measured>());
    expect((sabotajli as Measured).value, 83.6,
        reason: 'korumanın KAPALI hâli gerçekten yanlış sayıyı üretmeli — '
            'üretmiyorsa bu test hiçbir şey kanıtlamıyor demektir');
  });

  test('boş liste de Unmeasured döner (0/0 çökmesi yok)', () {
    final PercentileResult r =
        reliablePercentile(<double>[], 0.9, contributingSources: 10);
    expect(r, isA<Unmeasured>());
  });
}
