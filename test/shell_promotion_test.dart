import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `motion_shell` terfi kapısı (M-F-25) — mekanik denetim.
///
/// Standart §5: mekanik denetim betikle yapılır, LLM denetimiyle değil.
/// Kabuk sözleşmesi (`lib/shell_candidate/README.md`) burada zorlanır; aksi
/// hâlde bir sonraki dalgada "sadece bu sefer" bir alan terimi sızar ve
/// terfi turunda 5 app'in ortak katmanına boks sözlüğü taşınır.
void main() {
  final Directory dir = Directory('lib/shell_candidate');
  // ⚠️ YALNIZ `.dart` — BİLEREK, ve nedeni ADIYLA: `README.md` bu klasörün
  // KENDİ kuralını anlatırken yasaklı kelimeleri ÖRNEK olarak taşıyor
  // ("punch, jab, round, boxing gibi kelimeler geçmez"). O metin taransaydı
  // KURALIN KENDİSİ kuralı ihlal ederdi. Bu yazılı değildiyse bir gün biri
  // "kural kitabını temizleyeyim" diyip kuralı silebilirdi — ihlal DEĞİL,
  // kuralın KENDİSİ, ölçülmeden fark edilmezdi (orkestratörün bağımsız
  // taramasında yaşandı: `round`/`interval`/`punch` eşleşti, hepsi
  // README'de VEYA "adı bilerek 'round' değil" yorumlarında çıktı).
  final List<File> sources = dir
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();

  test('kabuk klasöründe kaynak dosya var', () {
    expect(sources, isNotEmpty);
  });

  group('terfi şartı #1 — alan sözlüğü yok', () {
    // Kelime sınırlı: `jablab_engine` içindeki "jab" eşleşmemeli, yoksa
    // denetim yanlış alarm verir ve yanlış alarm veren denetim kapatılır.
    final RegExp domainWords = RegExp(
      r'\b(punch|punches|jab|jabs|cross|hook|uppercut|guard|round|rounds|'
      r'boxing|boxer|kick|cello|violin|salsa|handstand|kata|stance)\b',
      caseSensitive: false,
    );

    for (final File f in sources) {
      test(f.uri.pathSegments.last, () {
        final List<String> offenders = <String>[];
        int lineNo = 0;
        for (final String line in f.readAsLinesSync()) {
          lineNo++;
          final String trimmed = line.trimLeft();
          // Açıklayıcı yorumlar serbest: kuralı ANLATAN cümle kuralı ihlal
          // etmez. Denetlenen şey API yüzeyi ve mantık.
          if (trimmed.startsWith('///') || trimmed.startsWith('//')) continue;
          if (domainWords.hasMatch(line)) {
            offenders.add('$lineNo: ${line.trim()}');
          }
        }
        expect(offenders, isEmpty,
            reason: 'kabuk kodunda alan sözlüğü sızıntısı:\n'
                '${offenders.join("\n")}');
      });
    }
  });

  test('terfi şartı #2 — app veya motor bağımlılığı yok', () {
    final List<String> offenders = <String>[];
    for (final File f in sources) {
      for (final String line in f.readAsLinesSync()) {
        final String t = line.trim();
        if (!t.startsWith('import ')) continue;
        if (t.contains('jablab_engine') ||
            t.contains("'../app/") ||
            t.contains('package:jablab/app/')) {
          offenders.add('${f.uri.pathSegments.last} → $t');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'kabuk app/motor katmanına bağımlı — terfi edemez:\n'
            '${offenders.join("\n")}');
  });

  test('terfi şartı #5 — dürüstlük değişmezleri kabukta kodlu', () {
    final String honesty =
        File('lib/shell_candidate/honesty_box.dart').readAsStringSync();
    expect(honesty, contains('assert'),
        reason: 'HonestyBox boş "ölçülmez" listesiyle çizilebiliyorsa '
            'dürüstlük kutusu bir söz değil süstür');

    final String scaffold =
        File('lib/shell_candidate/shell_scaffold.dart').readAsStringSync();
    expect(scaffold, contains('numericUnlocked'),
        reason: 'K8 kilidi (M-F-04) kabukta temsil edilmiyor');
  });
}
