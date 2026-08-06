// ignore_for_file: avoid_print
import 'dart:io';

/// PLACEHOLDER-REGISTER üreteci (design turu, koordinatör 2026-08-06).
///
/// `lib/`de `// PLACEHOLDER(<kategori>): <eksik> — unblocked by: <ne bekliyor>`
/// biçimindeki her yorumu tarar ve `docs/design/PLACEHOLDER-REGISTER.md`'yi
/// BU TARAMADAN üretir — elle yazılmaz. Kategori: `asset` · `copy` · `data` ·
/// `flow` (Choreia'nın kapanış artefaktı, aile standardı).
///
/// **Kapı:** `unblocked by:` YOKSA exit 1. Bir placeholder "ne zaman
/// açılacağı belirsiz" bırakılırsa o, "kodda bekleyen not" ile "kullanıcıya
/// gerçekmiş gibi gösterilen sahte veri" arasındaki farkı siler — ikisi de
/// aynı görünür. `unblocked by` bu ayrımı ZORUNLU kılan tek satır.
///
/// Koşum: `dart tool/gen_placeholder_register.dart`
void main() {
  final RegExp marker = RegExp(
      r'PLACEHOLDER\((\w+)\):\s*(.+?)\s*—\s*unblocked by:\s*(.+)$');
  final RegExp markerNoUnblock = RegExp(r'PLACEHOLDER\((\w+)\):');

  final List<_Entry> entries = <_Entry>[];
  final List<String> violations = <String>[];

  final Directory libDir = Directory('lib');
  for (final FileSystemEntity f in libDir.listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final List<String> lines = f.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (!line.contains('PLACEHOLDER(')) continue;
      final RegExpMatch? m = marker.firstMatch(line);
      if (m != null) {
        entries.add(_Entry(
          category: m.group(1)!,
          missing: m.group(2)!,
          unblockedBy: m.group(3)!,
          file: f.path,
          line: i + 1,
        ));
      } else if (markerNoUnblock.hasMatch(line)) {
        violations.add('${f.path}:${i + 1}: $line');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('PLACEHOLDER-REGISTER KAPISI DÜŞTÜ — '
        '"unblocked by:" olmadan placeholder bırakılamaz:');
    for (final String v in violations) {
      stderr.writeln('  ✗ $v');
    }
    exit(1);
  }

  final StringBuffer out = StringBuffer()
    ..writeln('# PLACEHOLDER-REGISTER')
    ..writeln()
    ..writeln('> Bu dosya ELLE YAZILMAZ — `tool/gen_placeholder_register.dart`')
    ..writeln('> taramasının çıktısıdır. Kaynak: `lib/`deki `PLACEHOLDER(...)`')
    ..writeln('> yorumları. Yeniden üretmek için: '
        '`dart tool/gen_placeholder_register.dart`')
    ..writeln()
    ..writeln('Toplam: ${entries.length} · kategori kapısı: '
        '"unblocked by" olmayan HİÇBİRİ (varsa üretim exit 1 ile durur)')
    ..writeln();

  if (entries.isEmpty) {
    out.writeln('_Şu an kayıtlı placeholder yok._');
  } else {
    final Map<String, List<_Entry>> byCategory = <String, List<_Entry>>{};
    for (final _Entry e in entries) {
      byCategory.putIfAbsent(e.category, () => <_Entry>[]).add(e);
    }
    for (final String cat in byCategory.keys.toList()..sort()) {
      out.writeln('## `$cat`');
      out.writeln();
      for (final _Entry e in byCategory[cat]!) {
        out.writeln('- **${e.missing}**');
        out.writeln('  - unblocked by: ${e.unblockedBy}');
        out.writeln('  - kaynak: `${e.file}:${e.line}`');
      }
      out.writeln();
    }
  }

  File('docs/design/PLACEHOLDER-REGISTER.md').writeAsStringSync(out.toString());
  print('PLACEHOLDER-REGISTER.md üretildi — ${entries.length} kayıt.');
}

class _Entry {
  _Entry({
    required this.category,
    required this.missing,
    required this.unblockedBy,
    required this.file,
    required this.line,
  });

  final String category;
  final String missing;
  final String unblockedBy;
  final String file;
  final int line;
}
