import 'dart:convert';
import 'dart:io';
import 'support/local_core_intake.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/pose_model.dart';

/// PİNLİ poz modeli kapısı (J-072 · sözleşme §6 · M-L-01).
///
/// Aile kuralı: *"her build, buradaki SHA-256'yı doğrular; hash tutmuyorsa
/// build durur."* Model ikilisi git'te olmadığı için (9,4 MB, aile
/// `.gitignore`ı ile hizalı) kapı burada duruyor.
///
/// **Neden `modelId` bir dize karşılaştırmasından fazlası:** jab eklem
/// tablosu (J-061) `pose_landmarker_full/float16/1`in ürettiği açılardan
/// türetildi. Başka bir bundle ile koşmak, tabloyu ait olmadığı bir modele
/// uygulamak olur — ekranda hiçbir şey değişmez, hükümler sessizce yanlışlar.
void main() {
  test('modelId, REFERANSLARI ÜRETEN fixture modelVersion ile BİREBİR aynı',
      () {
    // Kanıt hasat fixture'ının kendisinden okunuyor; elle yazılmış bir
    // sabitten değil. Referans ve runtime aynı modeli göstermezse eklem
    // tablosu başka bir modelin açılarına uygulanır.
    final File fixture = File('/Users/mustafakaankocak/motion-harvest/jablab/'
        'landmarks/umI6jNMVG-s.full.json');
    if (!fixture.existsSync()) {
      markTestSkipped('hasat fixture\'ı bu makinede yok — modelVersion '
          'karşılaştırması atlandı (SESSİZ GEÇMEDİ)');
      return;
    }
    // Fixture 33 MB: tümünü decode etmek yerine baştaki meta alanını
    // okuyoruz. Pencere 2 KB — alan 558. baytta duruyor ve anahtar sırası
    // değişebilir; 400 bayt yetmiyordu (ilk koşumda tam bu yüzden kırıldı).
    final RandomAccessFile raf = fixture.openSync();
    final String head = utf8.decode(raf.readSync(2048), allowMalformed: true);
    raf.closeSync();
    final Match? m =
        RegExp(r'"modelVersion"\s*:\s*"([^"]+)"').firstMatch(head);
    expect(m, isNotNull,
        reason: 'fixture başında modelVersion bulunamadı — biçim değişmiş');
    expect(PoseModelPin.modelId, m!.group(1),
        reason: 'runtime modeli referansları üreten modelden FARKLI; '
            'eklem tablosu artık ait olmadığı bir modele uygulanıyor');
  });

  test('sürüm segmenti PİNLİ — `latest` yazılamaz', () {
    // ÖLÇÜLDÜ (M-L-01): `full` varyantında latest ≠ 1, AYNI BOYUT farklı
    // hash. Boyut değişmediği için kaza gözden kaçar.
    expect(PoseModelPin.versionSegment, '1');
    expect(PoseModelPin.modelId, contains('/float16/1'));
    expect(PoseModelPin.modelId.contains('latest'), isFalse);
    expect(PoseModelPin.assetPath.contains('latest'), isFalse);
  });

  test('model dosyası VARSA SHA-256 tutuyor (yoksa İSİMLİ atlanır)', () {
    final File f = File(PoseModelPin.assetPath);
    if (!f.existsSync()) {
      // Sessizce geçmek, hash kapısını hiç yoktan sayardı. Atlama SEBEBİYLE
      // görünür ve ne yapılacağını söylüyor.
      markTestSkipped('model asset yok: ${PoseModelPin.assetPath} — '
          '`./tool/fetch_pose_model.sh` koşulmalı (indirir + SHA doğrular)');
      return;
    }
    final String got = sha256.convert(f.readAsBytesSync()).toString();
    expect(got, PoseModelPin.sha256,
        reason: 'model ikilisi beklenen bundle DEĞİL. Bu sessiz-yanlış '
            'sınıfının en pahalısı: aynı boyutta farklı bir bundle '
            '(latest≠1, M-L-01) tüm eklem açılarını kaydırır ve hiçbir '
            'ekran bunu göstermez.');
  });

  test('asset pubspec\'te BEYAN EDİLMİŞ — yoksa çalışma zamanında yok', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/models/'),
        reason: 'asset bildirilmemişse rootBundle onu bulamaz ve harness '
            'model yükleyemez');
  });

  test('model ikilisi git\'te İZLENMİYOR (aile kuralıyla hizalı)', () {
    if (File('pubspec_overrides.yaml').existsSync()) {
      final receipt = verifyIntake();
      final model = receipt['model'] as Map<String, dynamic>;
      expect(model['path'], PoseModelPin.assetPath);
      expect(model['ignored'], isTrue);
      expect(model['tracked'], isFalse);
      expect(File('.gitignore').readAsStringSync(), contains('assets/models/*.task'));
      return;
    }
    final ProcessResult r = Process.runSync(
        'git', <String>['check-ignore', PoseModelPin.assetPath]);
    expect(r.exitCode, 0,
        reason: '9,4 MB\'lık ikili izlenmeye başlamış — aile kuralı `.task` '
            'dosyalarını git dışında tutuyor, pin URL+SHA olarak yaşar');
  });

  test('fetch betiği pinli URL ve hash\'i TAŞIYOR', () {
    // Betik ile Dart sabiti ayrı yerlerde yaşıyor; biri güncellenip diğeri
    // kalırsa "doğrulandı" diyen bir kapı yanlış dosyayı onaylar.
    // YORUM SATIRLARI ÇIKARILIR: betik `latest`in NİYE yasak olduğunu
    // anlatıyor ve o açıklama yasağın kendisine takılmamalı. Kapı KODU
    // denetler, gerekçeyi değil.
    final String sh = File('tool/fetch_pose_model.sh')
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('#'))
        .join('\n');
    expect(sh, contains(PoseModelPin.sha256));
    expect(sh, contains('float16/\${VERSION}'));
    expect(sh, contains('VERSION="1"'));
    expect(RegExp(r'float16/latest').hasMatch(sh), isFalse,
        reason: 'betikte `latest` yolu görünüyor');
  });

  test('JSON kaçış denetimi — sabitler biçim bozmuyor', () {
    // Ufak ama gerçek: modelId zarf provenance dizesine gömülüyor.
    expect(jsonDecode(jsonEncode(PoseModelPin.modelId)),
        PoseModelPin.modelId);
  });
}
