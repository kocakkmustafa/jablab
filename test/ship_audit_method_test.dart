import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// YAYIN ENGELİ DENETİM YÖNTEMİ'nin kendi kapısı (J-216).
///
/// ## Neden bir yöntem belgesinin kapısı olur
///
/// Bu belge, dört hattın aynı denetimi yeniden icat etmemesi için yazıldı.
/// Ama bir yöntem belgesi de **bayatlar** — ve en sinsi bayatlama biçimi
/// *"kalem eklendi, pozitif kontrolü yazılmadı"*: liste büyür, güven artar,
/// ve kontrolsüz kalemin ürettiği her *"sıfır"* **doğrulanmamış** olur.
/// Bugünün kendi kuralı: ***bir "yok" bulgusu, aracın ARADIĞIN ŞEYİ
/// bulabildiği kanıtlanmadan raporlanmaz.*** Kapı bunu belgeye uygular.
///
/// Emsal: `PLACEHOLDER-REGISTER`ın `unblocked by` kapısı — orada da
/// belgenin kendisi değil, **satırlarının eksiksizliği** zorlanıyor.
void main() {
  final File doc = File('docs/gates/YAYIN-ENGELI-DENETIM-YONTEMI.md');

  /// Denetim tablolarının TÜM satırları — başlık ve ayraç hariç.
  ///
  /// ⚠️ **BİRDEN FAZLA TABLO taranıyor, ve bu bir düzeltme.** İlk hâli
  /// yalnız İLK tabloyu okuyordu; belgeye 13. ve 14. kalemler **ayrı
  /// tablolar** olarak eklenince o iki kalem kapının **dışında** kaldı —
  /// yani liste, onu denetleyen kapının göremediği yerde büyüdü. Tam da bu
  /// kapının önlemek için var olduğu şey. *Bir kapının kapsamı, denetlediği
  /// belgenin BÜYÜME BİÇİMİYLE birlikte değişir; sabit bir çapa yetmez.*
  List<List<String>> auditRows() {
    final List<String> lines = doc.readAsLinesSync();
    final List<int> starts = <int>[
      for (int i = 0; i < lines.length; i++)
        if (lines[i].startsWith('| # | katman | soru |')) i,
    ];
    expect(
      starts,
      isNotEmpty,
      reason:
          'denetim tablosunun başlığı bulunamadı — belge yeniden '
          'yapılandırılmış olabilir, bu kapının sonucu ANLAMSIZ olurdu',
    );
    final List<List<String>> rows = <List<String>>[];
    for (final int start in starts) {
      for (int i = start + 2; i < lines.length; i++) {
        final String l = lines[i].trim();
        if (!l.startsWith('|')) break;
        final List<String> cells = l
            .split('|')
            .map((String c) => c.trim())
            .toList();
        rows.add(cells.sublist(1, cells.length - 1));
      }
    }
    return rows;
  }

  test('POZİTİF KONTROL — belge okunuyor ve tablo dolu', () {
    expect(doc.existsSync(), isTrue, reason: 'yöntem belgesi yok');
    final List<List<String>> rows = auditRows();
    // Vakum muhafızı: boş bir tablo, aşağıdaki her şeyi sessizce geçirirdi.
    expect(
      rows.length,
      greaterThanOrEqualTo(15),
      reason:
          'yalnız ${rows.length} denetim kalemi okundu — ayrıştırma '
          'bozuk ya da tablo daraldı; iki durumda da sonuç anlamsız',
    );
    expect(
      rows.first.length,
      6,
      reason: 'sütun sayısı değişmiş — kapı yanlış sütunu okuyor olabilir',
    );
  });

  test('🔒 HER KALEMİN POZİTİF KONTROLÜ VAR — kontrolsüz kalem eklenemez', () {
    final List<String> missing = <String>[];
    for (final List<String> r in auditRows()) {
      final String id = r[0];
      final String control = r[4];
      // Bilerek bırakılmış "—" kabul edilir AMA yalnız ölçüm OLMAYAN
      // kalemlerde (ör. sürüm: bir karar, bir arama değil) ve gerekçesi
      // hücrede yazılı olmalı.
      final bool isNamedNonMeasurement =
          control.startsWith('—') && control.length > 5;
      if (control.isEmpty || (control == '—' && !isNamedNonMeasurement)) {
        missing.add(id);
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'şu kalemlerin POZİTİF KONTROLÜ yazılmamış: $missing — '
          'kontrolsüz bir kalemin ürettiği her "sıfır" doğrulanmamıştır, '
          've bu belge tam da onu önlemek için var',
    );
  });

  test('🔒 HER KALEM ÜÇ SINIFTAN BİRİNE ATANMIŞ', () {
    const List<String> known = <String>['hat-yereli', 'çekirdek', 'kurucu'];
    final List<String> bad = <String>[];
    for (final List<String> r in auditRows()) {
      final String cls = r[5];
      if (!known.any((String k) => cls.contains(k))) bad.add('${r[0]}: $cls');
    }
    expect(
      bad,
      isEmpty,
      reason:
          'sınıfı tanınmayan kalem(ler): $bad — sınıflandırma '
          'şeması hat-yereli/çekirdek/kurucu; sınıfsız bir kalem '
          'kimin işi olduğu bilinmeden kuyrukta bekler',
    );
  });

  test('🔒 ŞABLON KAYNAKLI KALEMLER ADIYLA DURUYOR', () {
    // Temel kural: beş hatta da aynı olan kusur hat düzeyinde ölçülemez.
    // O yüzden şablondan gelen kalemler tek tek listede olmalı; biri
    // düşerse bir sonraki hat onu "zaten şablon" diye atlayabilir.
    final String src = doc.readAsStringSync();
    for (final String item in <String>[
      'imza',
      'PrivacyInfo',
      'ikon',
      'izin metni',
      'targetSdk',
    ]) {
      expect(
        src,
        contains(item),
        reason:
            '"$item" şablon kaynaklı bir denetim kalemi ve belgeden '
            'düşmüş — şablon satırları ayrı kalem olmazsa görünmez olur',
      );
    }
    // Ve yöntemin kendi sınırı yazılı kalmalı: aile taraması adımı.
    expect(
      src.toLowerCase(),
      contains('aile'),
      reason:
          'yöntemin son adımı (aile çapraz-taraması) düşmüş — '
          'hat-içi denetim şablon kusurlarını YAPISAL olarak göremez',
    );
  });
}
