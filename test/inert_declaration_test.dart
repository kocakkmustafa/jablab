import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ETKİSİZ BEYANLARIN TERS KAPISI (J-185, koordinatör hükmü B + D).
///
/// ## Neden ters
///
/// Alışılmış kapı bir kusurun **geri gelmesini** engeller. Bu ikisi tersini
/// yapar: bugün doğru olan bir **yokluk** iddiasını çiviler ve **iyi haber
/// geldiğinde öter.**
///
/// > **Bugün "okunmuyor" demek VAKUM-DOĞRU bir iddiadır.** Yarın biri onu
/// > bağlarsa, beyan **sessizce yalana döner** — ve kimse fark etmez,
/// > çünkü hiçbir şey kırılmaz.
///
/// İkisi de bir **beyan** taşıyor ve beyan **yanlış bir şey ürettirdi**:
///
/// | alan | muhatap | ne ürettirdi |
/// |---|---|---|
/// | `authoringFocus` (eski `errorFocus`) | **yazar** | yanlış bir **METİN** |
/// | `language` | **geliştirici** | yanlış bir **İŞ** (henüz olmadı) |
///
/// Birincisinin hikâyesi ölçülmüş: `errorFocus`un tüketicisi **sıfırdı**,
/// ama yazan ona bakıp `REAR_HAND_LOW`un en çok geçtiğini gördü ve `stance`
/// dersine *"the thing **we watch** most"* yazdı. İddia yanlıştı (motorda 5
/// kod eşit `high`, ve en çok fazda değerlendirilen rear hand değil) —
/// **ama yazan yalan söylemedi, doğru bir yere baktı.**
///
/// > **Ölü kod sessizdir; ölü beyan KONUŞUR.**
/// > Bir alan hiçbir şey yapmadan da ürünü etkileyebilir: **insana yön
/// > vererek.**
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Beyan metninin **doğru** olduğunu — yalnız durduğunu ve alanın hâlâ
///   tüketicisiz olduğunu.
/// * `authoringFocus`un **içeriğinin** iyi olduğunu; o bir yazarlık
///   tercihi ve bu kapı ona karışmaz.
void main() {
  Map<String, dynamic> read(String p) =>
      (jsonDecode(File(p).readAsStringSync()) as Map).cast<String, dynamic>();

  List<File> dartFiles() => <Directory>[Directory('lib'), Directory('packages')]
      .where((Directory d) => d.existsSync())
      .expand((Directory d) => d.listSync(recursive: true))
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();

  test('TERS KAPI — `authoringFocus` hâlâ DAVRANIŞA GİRMİYOR', () {
    final List<File> files = dartFiles();

    // VAKUM MUHAFIZI — tarama gerçekten Dart gördü mü?
    expect(files.length, greaterThan(20),
        reason: 'yalnız ${files.length} Dart dosyası tarandı — gezinme bozuk, '
            'bu kapının sonucu anlamsız');

    final List<String> consumers = files
        .where((File f) => f.readAsStringSync().contains('authoringFocus'))
        .map((File f) => f.path)
        .where((String p) => !p.endsWith('library.dart'))
        .toList();

    expect(consumers, isEmpty,
        reason: 'ARTIK OKUNUYOR — `authoringFocus` şu dosyalarda tüketiliyor:\n'
            '  ${consumers.join('\n  ')}\n\n'
            'BU İYİ HABER OLABİLİR, ama beyan artık yalan: '
            '`\$authoringFocusNote` "çalışma anında tüketicisi yoktur" diyor. '
            'Yapılacaklar: (a) notu güncelle (b) alanın ADI yetkisini yeniden '
            'beyan etsin — `authoringFocus` adı YAZARLIK notu demek, ürün '
            'davranışı sürüyorsa ad da değişmeli (c) J-177 kapısındaki '
            '"bu alandan iddia türetilemez" kuralını gözden geçir.');
  });

  test('`authoringFocus`un YETKİSİZLİĞİ alanın YANINDA yazılı', () {
    // M-F-396: bir boşluğun neden boş olduğu, boşluğun kendisiyle aynı
    // yerde yaşar. Not silinirse bir sonraki yazar aynı tuzağa düşer —
    // ve bu kez uyaran hiçbir şey olmaz.
    final Map<String, dynamic> lib = read('assets/content/library.json');
    final Map<dynamic, dynamic> boxing = (lib['disciplines'] as List<dynamic>)
        .firstWhere((dynamic d) => (d as Map)['id'] == 'boxing') as Map;
    final String? note = boxing[r'$authoringFocusNote'] as String?;

    expect(note, isNotNull,
        reason: 'yetkisizlik beyanı silinmiş — alan yeniden "ürün davranışı" '
            'gibi okunur ve bu tam olarak J-176 kusurunun mekanizmasıydı');
    expect(note!.toLowerCase(), contains('tüketicisi yoktur'),
        reason: 'beyan yumuşatılmış: alanın çalışma anında OKUNMADIĞI açıkça '
            'yazmalı — "şimdilik" ya da "henüz" değil, YOK');
  });

  test('TERS KAPI — `language` hâlâ OKUNMUYOR', () {
    final List<String> consumers = dartFiles()
        .where((File f) => RegExp(r"'language'|\blanguage\b\s*:")
            .hasMatch(f.readAsStringSync()))
        .map((File f) => f.path)
        .toList();

    expect(consumers, isEmpty,
        reason: 'ARTIK OKUNUYOR — `language` şurada tüketiliyor:\n'
            '  ${consumers.join('\n  ')}\n\n'
            'BU İYİ HABER: i18n geldi demektir. Yapılacak: iki içerik '
            'dosyasındaki `\$languageNote` beyanını KALDIR — o beyan '
            '"bu alan okunmuyor" diyor ve artık yanlış.');
  });

  test('`language`in okunmadığı GELİŞTİRİCİ diliyle yazılı', () {
    for (final String p in <String>[
      'assets/content/library.json',
      'assets/content/cues.en.json',
    ]) {
      final Map<String, dynamic> d = read(p);
      expect(d['language'], isNotNull, reason: '$p: alan kayıp');
      final String? note = d[r'$languageNote'] as String?;
      expect(note, isNotNull,
          reason: '$p: beyan silinmiş — bir sonraki geliştirici '
              '`cues.tr.json` ekleyip bu alana "tr" yazar ve dil '
              'değişeceğini sanır. Kusur METİN değil, YANLIŞ İŞ olur.');
      expect(note!.toLowerCase(), contains('okunmuyor'), reason: p);
    }
  });
}
