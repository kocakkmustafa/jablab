import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ANDROID RELEASE İMZASI — sessiz debug-imzası GERİ GELEMEZ (J-215).
///
/// ## Neden bir kapı, neden Dart tarafında
///
/// Kusur bir Gradle satırıydı (`signingConfig = signingConfigs.getByName("debug")`)
/// ve sınıfı bu üründe tanıdık: **sessiz-hiçlik.** `flutter build appbundle`
/// başarılı görünür, dosya oluşur, **debug anahtarıyla imzalanmıştır** ve Play
/// onu REDDEDER. Kusur ancak yüklemede görünür — yani en pahalı yerde.
///
/// Gradle tarafındaki panzehir (release görev grafiğinde gürültülü durma)
/// **doğru yerde** ama **kendi kapısı yok**: bir sonraki Flutter şablon
/// güncellemesi ya da bir "hızlıca release alayım" düzeltmesi o satırı geri
/// koyabilir ve **hiçbir test ötmez** — release yolu commit kapısında
/// koşmuyor. Bu dosya o boşluğu kapatır: **kaynak metni** denetler.
///
/// ⚠️ NE ÖLÇMÜYOR: Gradle'ın gerçekten durduğunu. O davranış gerçek bir
/// release koşumuyla doğrulandı (J-215 kanıtı); burada denetlenen, o
/// mekanizmanın **yerinde durduğu.** İkisi ayrı sorular ve ikisi de gerekli.
void main() {
  final File gradle = File('android/app/build.gradle.kts');

  test('POZİTİF KONTROL — dosya okunuyor ve beklenen yapıyı taşıyor', () {
    // Bir "yok" bulgusu, aracın o şeyi BULABİLDİĞİ kanıtlanmadan
    // raporlanmaz. Dosya boş/yanlış yolda olsaydı aşağıdaki iki test
    // vakum-doğru geçerdi.
    expect(gradle.existsSync(), isTrue, reason: 'build.gradle.kts bulunamadı');
    final String src = gradle.readAsStringSync();
    expect(src, contains('buildTypes'),
        reason: 'dosya okundu ama Gradle yapısı yok — yol ya da içerik bozuk, '
            'aşağıdaki sonuçlar ANLAMSIZ olurdu');
    expect(src, contains('release'), reason: 'release blok yok');
  });

  test('🔴 SESSİZ DEBUG İMZASI YOK — release, debug anahtarına düşmüyor', () {
    final List<String> offenders = <String>[
      for (final String line in gradle.readAsLinesSync())
        // Yorumlar serbest: kuralı ANLATAN satır kuralı ihlal etmez (aynı
        // ayrım `shell_promotion_test` ve ratio kapısında da var).
        if (!line.trimLeft().startsWith('//') &&
            RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\(\s*"debug"\s*\)')
                .hasMatch(line))
          line.trim(),
    ];
    expect(offenders, isEmpty,
        reason: 'release build type DEBUG anahtarıyla imzalanıyor — üretilen '
            'artefakt Play tarafından REDDEDİLİR ve bunu build ANINDA hiçbir '
            'şey söylemez (sessiz-hiçlik). Panzehir: key.properties yoksa '
            'release görevini GÜRÜLTÜLÜ durdur, debug\'a DÜŞME.');
  });

  test('🔒 GÜRÜLTÜLÜ DURMA MEKANİZMASI YERİNDE', () {
    final String src = gradle.readAsStringSync();
    // Üçü birden: koşul (anahtar yoksa) · tetik (release görev grafiği) ·
    // sonuç (build durur). Biri düşerse kusur sessizleşir.
    expect(src, contains('hasKeystore'),
        reason: 'anahtar-var-mı koşulu kaybolmuş');
    expect(src, contains('taskGraph.whenReady'),
        reason: 'release görev grafiği kancası kaybolmuş — kapı hiç '
            'ateşlenmez, yokluk yeniden SESSİZLEŞİR');
    expect(src, contains('GradleException'),
        reason: 'kapı artık build\'i DURDURMUYOR — uyarı basıp devam etmek, '
            'reddedilecek artefaktı yine üretmek olurdu');
  });

  test('⛔ SIR DEPOYA GİREMEZ — key.properties ve keystore git-dışı', () {
    // Kapının yan etkisi: kurucu bir keystore ürettiğinde onu yanlışlıkla
    // commit etmek MÜMKÜN OLMAMALI.
    final String ignore = File('android/.gitignore').readAsStringSync();
    for (final String pat in <String>['key.properties', '*.keystore', '*.jks']) {
      expect(ignore, contains(pat),
          reason: '$pat .gitignore\'da değil — imza sırrı depoya sızabilir');
    }
    // Ve bugün gerçekten yoklar (izlenen içerikte).
    expect(File('android/key.properties').existsSync(), isFalse,
        reason: 'key.properties çalışma ağacında VAR — içeriği sır, bu '
            'testin kendisi onu okumaz ama varlığı beklenmiyor');
  });
}
