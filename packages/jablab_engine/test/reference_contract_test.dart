import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'external_reference_gate.dart';

/// Referans-tüketim sözleşmesi denetimi (M-F-63).
///
/// İki tarafı birden sınar:
///   (a) **artefakt tarafı** — sentetik `motion-core/reference@1` örneğinin
///       taşıdığı bayraklar okunabiliyor ve anlamlandırılıyor mu;
///   (b) **kendi config'im** — ürettiğim referansı sunarken sözleşmeyi
///       çiğniyor muyum.
///
/// Kanonik metin okundu (M-F-63 teslimatı): `coordinator-main/docs/
/// 50-REFERANS-TUKETIM-SOZLESMESI.md`, 10 kural. Kural numaraları aşağıda
/// ve kardeş dosyalarda açıkça anılıyor:
///   1,2,3 → `reference_binding_test.dart` (kural 1/2/3 başlıklı testler)
///   4     → `reference_binding_test.dart` (PEAK checkpoint)
///   5     → kapsam dışı: JabLab'ın stance referansı TEK duruş, çevrim yok
///   6     → `reference_binding_test.dart` (provisional + n<5 hatırlatıcı)
///   7,8   → bu dosya (ayna güveni · PROVISIONAL ≠ sistematik yanlılık)
///   9     → `shell_test.dart` (özet coached-not-scored başlığı + sebebi)
///   10    → `cues_test.dart` (power/force/kph replikte geçemez)
void main() {
  final File? artifactFile = externalReferenceSkipReason == null
      ? externalReferenceArtifact('reference-sample-synthetic.json')
      : null;

  final Map<String, dynamic> cfg = (jsonDecode(
              File('../../assets/rulesets/boxing@1.0.0.json').readAsStringSync())
          as Map)
      .cast<String, dynamic>();
  final Map<String, dynamic> stance =
      ((cfg['references'] as Map)['stance'] as Map).cast<String, dynamic>();

  Map<String, dynamic> allJoints() => <String, dynamic>{
        ...(stance['scoredJoints'] as Map).cast<String, dynamic>(),
        ...(stance['coachedOnlyJoints'] as Map).cast<String, dynamic>(),
      };

  group('kendi referansımın sunumu', () {
    test('[floor|variance] KIRPILMIŞ sınır "ölçülen" diye sunulamaz', () {
      // 8,0 tabana, 45,0 tavana kırpılmış değerlerdir. Bunları
      // measuredDispersionDeg adıyla sunmak, bilmediğimiz bir şeyi biliyormuş
      // gibi göstermek: gerçek dağılım "8'den küçük" / "45'ten büyük", o kadar.
      const double floor = 8.0, ceiling = 45.0;
      for (final MapEntry<String, dynamic> e in allJoints().entries) {
        final Map<String, dynamic> j = (e.value as Map).cast<String, dynamic>();
        final double v = (j['measuredDispersionDeg'] as num).toDouble();
        final String? src = j['toleranceSource'] as String?;
        expect(src, isNotNull,
            reason: '${e.key}: tolerans kaynağı beyan edilmemiş');
        if ((v - floor).abs() < 1e-9) {
          expect(src, 'floor',
              reason: '${e.key}: tam tabanda ama "$src" diye sunuluyor');
        } else if ((v - ceiling).abs() < 1e-9) {
          expect(src, 'ceiling',
              reason: '${e.key}: tam tavanda ama "$src" diye sunuluyor');
        } else {
          expect(src, 'variance',
              reason: '${e.key}: kırpılmamış ama "$src" diye sunuluyor');
        }
        if (src != 'variance') {
          expect(j[r'$sourceWhy'], isNotNull,
              reason: '${e.key}: kırpılmış değerin gerekçesi yazılmamış');
        }
      }
    });

    test('[floor|variance] KOVA kararları değişmedi — sunum düzeltmesi', () {
      // Sunumu düzeltirken kapsamı kaydırmak kolay olurdu. Taban zaten eşiğin
      // altında, tavan üstünde: karar aynı kalmalı.
      final Map<String, dynamic> scored =
          (stance['scoredJoints'] as Map).cast<String, dynamic>();
      final Map<String, dynamic> coached =
          (stance['coachedOnlyJoints'] as Map).cast<String, dynamic>();
      for (final dynamic j in scored.values) {
        expect((j as Map)['toleranceSource'], isNot('ceiling'),
            reason: 'tavana kırpılmış eklem skorlanıyor — dağılım >45°');
      }
      for (final dynamic j in coached.values) {
        final Map<String, dynamic> m = (j as Map).cast<String, dynamic>();
        if (m['toleranceSource'] != 'floor') continue;
        expect(m['demotedBy'], isNotNull,
            reason: 'tabana kırpılmış eklem koçlanıyor ama gerekçesiz');
      }
    });

    test('[PROVISIONAL] tolerans KESİN diye sunulamaz', () {
      // n=3 ile üretilmiş bir tolerans geçicidir. "provisional" etiketi
      // dururken kesin bir tolerans iddiası taşımak, örneklem yetersizliğini
      // gizler.
      expect(stance['toleranceStatus'], 'provisional');
      expect(stance[r'$toleranceCaveat'] ?? stance[r'$scoringStatistic'],
          isNotNull,
          reason: 'provisional ama uyarı metni yok');
    });
  });

  group('artefakt sözleşmesi (motion-core/reference@1)', () {
    test('artefakt okunabiliyor ve şema sürümü BEKLENEN', () {
      expect(artifactFile!.existsSync(), isTrue,
          reason: 'artefakt yok: ${artifactFile.path}');
      final Map<String, dynamic> a =
          (jsonDecode(artifactFile.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      expect(a['schema'], 'motion-core/reference@1');
    });

    test('[mirrorGapMeasured=false] TARAF-BAĞIMLI hüküm YOK', () {
      final Map<String, dynamic> a =
          (jsonDecode(artifactFile!.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      final Map<String, dynamic> result =
          (a['result'] as Map).cast<String, dynamic>();
      // Ayna boşluğu ÖLÇÜLMEDİYSE, sol/sağ eşleştirmesinin doğruluğu
      // bilinmiyor demektir; lead/rear ayrımına dayanan her hüküm dayanaksız
      // kalır. J-034'ün artefakt düzlemindeki karşılığı.
      final bool measured = result['mirrorGapMeasured'] as bool;
      if (!measured) {
        fail('bu artefaktta mirrorGapMeasured=false — taraf-bağımlı hüküm '
            'üretmek yasak; tüketici tarafı bu dalı uygulamalı');
      }
      expect(measured, isTrue);
      expect(result['mirrorConfident'], isNotNull);
    });

    test('[ATTESTED] beyan edilmemiş take DIŞLANMIŞ olarak raporlanır', () {
      final Map<String, dynamic> a =
          (jsonDecode(artifactFile!.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      expect(a['measurementProvenance'], isNotNull);
      final Map<String, dynamic> result =
          (a['result'] as Map).cast<String, dynamic>();
      // Dışlananlar SESSİZCE düşmez, listeyle raporlanır — dışlama oranı
      // sağlık metriğinin (M-F-52) artefakt tarafı.
      for (final String k in <String>[
        'excludedOutlierIds',
        'excludedIneligibleIds',
        'excludedUnattestedIds'
      ]) {
        expect(result[k], isA<List<dynamic>>(),
            reason: '$k listesi yok — dışlama sessizleşir');
      }
      final int excluded = <String>[
        'excludedOutlierIds',
        'excludedIneligibleIds',
        'excludedUnattestedIds'
      ].fold(0, (int s, String k) => s + (result[k] as List<dynamic>).length);
      final int contributing = result['contributingTakes'] as int;
      expect(contributing + excluded, (a['takes'] as List<dynamic>).length,
          reason: 'katkı + dışlanan ≠ aday take — bir take sessizce kayboldu');
    });

    test('[floor|variance] artefakt perJointSource TAŞIYOR', () {
      final Map<String, dynamic> a =
          (jsonDecode(artifactFile!.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      final Map<String, dynamic> tol =
          (a['tolerance'] as Map).cast<String, dynamic>();
      final Map<String, dynamic> src =
          (tol['perJointSource'] as Map).cast<String, dynamic>();
      final Map<String, dynamic> share =
          (tol['floorBoundShare'] as Map).cast<String, dynamic>();
      expect(src.keys.toSet(), share.keys.toSet(),
          reason: 'kaynak ve taban-payı eklem kümeleri farklı');
      for (final MapEntry<String, dynamic> e in src.entries) {
        final double s = (share[e.key] as num).toDouble();
        if (e.value == 'floor') {
          expect(s, greaterThan(0),
              reason: '${e.key}: floor deniyor ama taban payı sıfır');
        }
      }
      // Bu sentetik örnekte HER eklem tabana kırpılmış: gerçek bir referansta
      // bu, "hiçbir şey ölçülmedi" demektir. Tüketici bunu fark etmeli.
      final int floorCount =
          src.values.where((dynamic v) => v == 'floor').length;
      expect(floorCount, src.length,
          reason: 'sentetik örnek beklenenden farklı — denetim varsayımı '
              'güncellenmeli');
    });
  }, skip: externalReferenceSkipReason);

  group('tüketici tarafı — ürettiğim bayrağı kim okuyor', () {
    /// Config'in yaprak anahtarları (belge notları hariç).
    Set<String> leafKeys(dynamic node) {
      final Set<String> out = <String>{};
      void walk(dynamic n) {
        if (n is Map) {
          for (final MapEntry<dynamic, dynamic> e in n.entries) {
            final String k = e.key as String;
            if (k.startsWith(r'$')) continue;
            if (e.value is Map || e.value is List) {
              walk(e.value);
            } else {
              out.add(k);
            }
          }
        } else if (n is List) {
          for (final dynamic v in n) {
            walk(v);
          }
        }
      }
      walk(node);
      return out;
    }

    test('[M-F-63] OKUNMAYAN alan BEYAN EDİLMİŞ olmalı', () {
      // J-039 üreticiyi sordu ("bunu kim söyleyecek"); bu onun tüketici
      // tarafı ("bunu kim okuyor"). Okunmayan bir alan, config'i okuyan
      // herkese çalışıyormuş gibi görünür — integrity bloğunda üç denetim
      // duruyordu, biri çalışıyordu.
      final StringBuffer code = StringBuffer();
      for (final String dir in <String>['lib/src', 'tool', '../../lib/app']) {
        final Directory d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final FileSystemEntity f in d.listSync(recursive: true)) {
          if (f is File && f.path.endsWith('.dart')) {
            code.write(f.readAsStringSync());
          }
        }
      }
      final String blob = code.toString();
      // Üç durum: ÜRÜN kodu okuyor · YALNIZ test okuyor · kimse okumuyor.
      // İkincisini birincisiyle karıştırmak çalışmayan bir davranışa güvenmek,
      // üçüncüsüyle karıştırmak da bir kapıyı silmek olur.
      final StringBuffer testCode = StringBuffer();
      for (final FileSystemEntity f in Directory('test').listSync()) {
        if (f is File && f.path.endsWith('.dart')) {
          testCode.write(f.readAsStringSync());
        }
      }
      final String testBlob = testCode.toString();

      Set<String> leaves(String key) =>
          ((cfg[key] as Map).cast<String, dynamic>().keys)
              .where((String k) => !k.startsWith(r'$'))
              .expand((String k) => k.endsWith('*')
                  ? <String>[]
                  : <String>[k.split('.').last])
              .toSet();
      final Set<String> declaredLeaves = <String>{
        ...leaves(r'$unreadFields'),
        ...leaves(r'$testEnforcedFields'),
      };

      final List<String> undeclared = <String>[];
      for (final String k in leafKeys(cfg)) {
        if (blob.contains("'$k'") || blob.contains('"$k"')) continue;
        if (declaredLeaves.contains(k)) continue;
        // Testin okuduğu alanlar ayrı sınıf; blok beyanıyla ("references.
        // stance.*") kapsanıyorlar.
        if (testBlob.contains("'$k'") || testBlob.contains('"$k"')) continue;
        undeclared.add(k);
      }
      expect(undeclared, isEmpty,
          reason: 'kod okumuyor ve beyan da edilmemiş: $undeclared — '
              'config okuyan bunların çalıştığını sanır');
    });

    test('[M-F-63] BEYAN BAYATLAMASIN — okunmaya başlayan alan listeden çıkar',
        () {
      // Ters yön. Bir alan bağlandığında beyan silinmezse, dosya "ölü" derken
      // alan canlı olur; bir sonraki oturum onu güvenle silmeye kalkar.
      final StringBuffer code = StringBuffer();
      for (final String dir in <String>['lib/src', 'tool']) {
        final Directory d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final FileSystemEntity f in d.listSync(recursive: true)) {
          if (f is File && f.path.endsWith('.dart')) {
            code.write(f.readAsStringSync());
          }
        }
      }
      final String blob = code.toString();
      final Map<String, dynamic> declared =
          (cfg[r'$unreadFields'] as Map).cast<String, dynamic>();
      final List<String> nowRead = <String>[];
      for (final String path in declared.keys) {
        if (path.startsWith(r'$')) continue;
        final String leaf = path.split('.').last;
        if (leaf == '*') continue;
        if (blob.contains("'$leaf'") || blob.contains('"$leaf"')) {
          nowRead.add(path);
        }
      }
      expect(nowRead, isEmpty,
          reason: 'okunmaya başlamış ama hâlâ "okunmuyor" diye beyanlı: '
              '$nowRead');
    });

    test('[birim] maxInterFrameWristTravel BİRİMİ beyan edilmiş', () {
      // Aile bulgusu: birim kuralı yapılandıran her düzlemde geçerli. Bu eşik
      // 30fps'te kalibre edildi; 60fps'te aynı hareket kare başına yarı
      // mesafe üretir ve denetim sessizce iki kat gevşer.
      final Map<String, dynamic> integrity =
          (cfg['integrity'] as Map).cast<String, dynamic>();
      expect(integrity[r'$maxInterFrameWristTravelUnits'], isNotNull);
      expect(integrity[r'$maxInterFrameWristTravelUnits'] as String,
          contains('dt-NORMALIZE'),
          reason: 'bağlanınca dt-normalize şartı beyanda geçmeli');
    });
  });

  group('gerçek stance artefaktı — sözleşme kuralları', () {
    final File? real = externalReferenceSkipReason == null
        ? externalReferenceArtifact('reference-boxing-stance.json')
        : null;

    Map<String, dynamic> load() =>
        (jsonDecode(real!.readAsStringSync()) as Map).cast<String, dynamic>();

    test('[kural 7] mirrorConfident=false → TARAF-BAĞIMLI hüküm YASAK', () {
      final Map<String, dynamic> result =
          (load()['result'] as Map).cast<String, dynamic>();
      expect(result['mirrorConfident'], isFalse,
          reason: 'artefakt değişmiş — bu testin dayandığı durum kalkmış');

      // Sözleşme: bu artefakttan türeyen hiçbir lead/rear hükmü verilemez.
      // Ürün config'i bu artefakta BAĞLI DEĞİL (kendi pencere-seçici aracımla
      // üretildi), ve bağlanmadığı config'te açıkça yazılı olmalı — yoksa bir
      // sonraki oturum "referans artefaktı var" deyip bağlar.
      final Map<String, dynamic> src =
          (stance['sourceArtifact'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      expect(src['boundTo'], isNot('reference-boxing-stance.json'),
          reason: 'taraf-bağımlı tablo, ayna güveni olmayan artefakta bağlanmış');
      expect(src[r'$whyNotBound'], isNotNull,
          reason: 'artefakt neden bağlanmadığı yazılmamış');
    });

    test('[kural 8] PROVISIONAL istatistikseldir, UYGUNLUĞU örtmez', () {
      final Map<String, dynamic> a = load();
      expect(a['measurementProvenance'], 'PROVISIONAL');
      // Kural 8: kaynak-uygunluk referans KURULMADAN çözülür, provisional'a
      // devredilemez. Bu artefakt --allow-unattested ile üretildi: üç take de
      // `unattested`. Yani provisional etiketi burada İKİ ayrı eksiği birden
      // taşıyor gibi görünüyor — tüketici bunu ayırt etmek zorunda.
      final List<dynamic> takes = a['takes'] as List<dynamic>;
      final int unattested = takes
          .where((dynamic t) => (t as Map)['eligibility'] == 'unattested')
          .length;
      expect(unattested, takes.length,
          reason: 'artefakt değişmiş — uygunluk beyanı gelmiş olabilir');
      // Bu yüzden ürüne bağlanamaz: eksik olan örneklem değil, KAYNAK BEYANI.
      final Map<String, dynamic> src =
          (stance['sourceArtifact'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      expect(src[r'$whyNotBound'] as String, contains('unattested'));
    });

    test('[kural 6] provisional artefakt KESİN hüküm iddiası taşımaz', () {
      final Map<String, dynamic> a = load();
      expect((a['result'] as Map)['contributingTakes'], lessThan(5),
          reason: 'n≥5 olduysa yeniden-hesap günü gelmiş');
      expect((a['gates'] as Map)['minSources'], greaterThanOrEqualTo(3),
          reason: 'M-C-04: ≥3 bağımsız kaynak');
    });

    test('[kural 3] güvenilmez eklem coached_only tarafında karşılanıyor', () {
      final List<dynamic> unreliable =
          ((load()['result'] as Map)['unreliableJoints'] as List<dynamic>);
      final Map<String, dynamic> coached =
          (stance['coachedOnlyJoints'] as Map).cast<String, dynamic>();
      for (final dynamic j in unreliable) {
        final String name = (j as String)
            .replaceFirst('left_', 'lead_')
            .replaceFirst('right_', 'rear_');
        final String alt = j
            .replaceFirst('left_', 'rear_')
            .replaceFirst('right_', 'lead_');
        // Ayna güveni yok: iki eşleme de kabul edilir. Hangisi olursa olsun
        // eklem KOÇLANAN tarafta olmalı — güvenilmez bir eklemin skorlanması
        // taraf sorusundan bağımsız olarak yasak.
        expect(coached.containsKey(name) || coached.containsKey(alt), isTrue,
            reason: '$j artefaktta güvenilmez ama üründe skorlanıyor olabilir');
      }
    });
  }, skip: externalReferenceSkipReason);
}
