import 'dart:io';

import 'package:jablab_engine/jablab_engine.dart';
import 'package:motion_core/motion_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// UYDURULMUŞ GÜRÜLTÜ MODELİYLE FAZ MAKİNESİ REGRESYONU (J-187).
///
/// ## ⛔ BU BİR KANIT DEĞİLDİR — adı bunu söylüyor
///
/// J-184 şunu ölçtü: *"gerçek veriden bir seans çıkar"* diyen artefakt
/// **yok**. Bu test o boşluğu **kapatmaz** ve kapatıyormuş gibi
/// okunmamalıdır. Kurucu brifinde **kanıt sayılmaz.**
///
/// Kapattığı şey daha küçük ve daha dürüst bir boşluk: bugün faz makinesi
/// **yalnız pürüzsüz** sentetik girdide sınanıyor, yani **onu gürültüde
/// bozacak bir değişiklik hiçbir kapıya yakalanmıyor.** Bu test o
/// regresyonu yakalar — ve **yalnız onu.**
///
/// > **Bir eşik icat etmiyorum ama bir GİRDİ icat ediyorum, ve ikisi de
/// > türetimini taşımalıdır.**
///
/// ## Gürültü modeli — UYDURMA, parametreleri açık
///
/// * **Dağılım:** düzgün (uniform), `±[_noiseAmplitude]` normalize koordinat
/// * **Genlik:** `0.004` — 1920×1080'de yatayda ≈ **7,7 piksel**
/// * **Üreteç:** sabit tohumlu LCG (test kararlılığı için; rastgelelik
///   yok, aynı diziyi üretir)
/// * **NEREDEN GELDİ:** **hiçbir yerden.** Gerçek kameranın gürültü
///   karakteri **ölçülmedi**. Bu sayı, "landmark'lar birkaç piksel
///   titrer" sezgisinden yazıldı ve **sezgi bir kaynak değildir.**
/// * **Neye dokunmuyor:** görünürlük (`visibility`) ve `z` — yalnız `x`/`y`
///   titriyor. Gerçek gürültü büyük olasılıkla güveni de düşürür; bu
///   model **iyimser**, ve iyimser bir model **kolay bir sınavdır.**
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Gerçek gürültüye dayanıklılığı — model uydurma.
/// * Cihazı, ışığı, kare düşmesini, ısınmayı.
/// * Hükümlerin **doğruluğunu**; yalnız faz makinesinin **bir denemeyi
///   tamamlayabildiğini.**
void main() {
  final RuleSet rules = loadBoxingRuleSet();

  const double noiseAmplitude = 0.004;

  /// Sabit tohumlu doğrusal eşleyici — `Math.random` yok, çünkü kırmızı
  /// bir testin **tekrar üretilebilir** olması gerekir.
  int seed = 20260807;
  double next() {
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return (seed / 0x7FFFFFFF) * 2 - 1; // [-1, 1]
  }

  PoseFrame jitter(PoseFrame f) => PoseFrame(
        tUs: f.tUs,
        modelVersion: f.modelVersion,
        landmarks: f.landmarks
            .map((PoseLandmark l) => PoseLandmark(
                  l.x + next() * noiseAmplitude,
                  l.y + next() * noiseAmplitude,
                  l.z,
                  l.visibility,
                ))
            .toList(growable: false),
      );

  test('UYDURULMUŞ gürültü modeliyle — faz makinesi denemeyi TAMAMLIYOR', () {
    final List<PoseFrame> clean = sequence(<SyntheticKeyframe>[
      SyntheticKeyframe(0, guardPose),
      SyntheticKeyframe(200000, guardPose),
      SyntheticKeyframe(320000, extendedPose),
      SyntheticKeyframe(520000, guardPose),
      SyntheticKeyframe(750000, guardPose),
    ]);

    // VAKUM MUHAFIZI — dizi gerçekten kuruldu mu?
    expect(clean.length, greaterThan(15),
        reason: 'yalnız ${clean.length} kare üretildi — dizi kurulamadı, '
            'bu testin sonucu anlamsız');

    final StrikingEngine e = StrikingEngine(
      ruleSet: rules,
      calibrationMapped: true,
      provenance: const <String, String>{
        'poseModelVariant': 'synthetic+invented-noise',
        'calibrationProfileId': 'test',
      },
    );
    AttemptDigest? digest;
    for (final PoseFrame f in clean) {
      digest ??= e.process(jitter(f)).completedAttempt;
    }

    expect(digest, isNotNull,
        reason: 'faz makinesi UYDURULMUŞ ±$noiseAmplitude gürültüde bir '
            'denemeyi tamamlayamıyor. Bu, gerçek gürültüde bozulduğunun '
            'KANITI DEĞİL — ama pürüzsüz girdide geçip burada düşen bir '
            'değişiklik, faz makinesinin gürültü toleransını DARALTMIŞ '
            'demektir ve sebebi araştırılmalı.');
    expect(digest!.outcome, AttemptOutcome.completed);
  });

  test('POZİTİF KONTROL — gürültü GERÇEKTEN uygulanıyor', () {
    // Kapının kendisi ölçülüyor: yukarıdaki yeşil, `jitter`ın hiçbir şey
    // yapmamasından da doğabilirdi ve o zaman test pürüzsüz girdiyi
    // "gürültülü" diye sınamış olurdu — bu gecenin vakum-doğru kapı
    // sınıfının ta kendisi.
    final PoseFrame f = sequence(<SyntheticKeyframe>[
      SyntheticKeyframe(0, guardPose),
      SyntheticKeyframe(100000, guardPose),
    ]).first;
    final PoseFrame j = jitter(f);
    int moved = 0;
    for (int i = 0; i < f.landmarks.length; i++) {
      if ((f.landmarks[i].x - j.landmarks[i].x).abs() > 1e-9) moved++;
    }
    expect(moved, f.landmarks.length,
        reason: 'gürültü $moved/${f.landmarks.length} landmark\'a uygulandı '
            '— jitter çalışmıyor, test pürüzsüz girdiyi sınıyor');
  });

  test('GERÇEK GÜRÜLTÜ ÖLÇÜLÜNCE BU MODEL DEĞİŞTİRİLMELİ', () {
    // Choreia'nın "iyi haberi de söyleyen kapı" deseni. Uydurma model,
    // hiçbir şey onu zorlamazsa KALICI olur ve bir gün "gürültü sınandı"
    // diye okunur. Gerçek bir gürültü profili artefaktı belirdiği an bu
    // test kırmızıya döner ve ne yapılacağını söyler.
    final List<String> profiles = Directory('test/golden')
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last)
        .where((String n) => n.contains('noise'))
        .toList();

    expect(profiles, isEmpty,
        reason: 'GERÇEK GÜRÜLTÜ PROFİLİ GELMİŞ: $profiles\n\n'
            'BU İYİ HABER. Yapılacaklar: (a) yukarıdaki UYDURULMUŞ modeli '
            'ölçülmüş profille DEĞİŞTİR (b) test adından "UYDURULMUŞ" '
            'kelimesini kaldır (c) o an bu test bir REGRESYON kapısı '
            'olmaktan çıkıp gerçek bir DAYANIKLILIK kapısı olur ve '
            'kurucu brifinde kanıt sayılabilir — bugün sayılamaz.');
  });
}
