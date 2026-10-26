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
        expect(
          offenders,
          isEmpty,
          reason:
              'kabuk kodunda alan sözlüğü sızıntısı:\n'
              '${offenders.join("\n")}',
        );
      });
    }
  });

  // ⚠️ ADLANDIRILMIŞ İSTİSNA (2026-10-26, JAB-03) — liste değil, envanter.
  // `e6cb808` (20 Ekim) 14 dil çalışma zamanını kurdu; kabuk metinleri o
  // gün app'in kaynak-anahtarlı kataloğuna (`ui_language.dart`) ve ipucu
  // çevirisine (`cue_locale.dart`) bağlandı. Kabuğun terfisi README'de
  // donmuş (motion_shell çekirdekte doğmadı; JabLab bu bileşenleri artık
  // çağırmıyor). Bu iki import TERFİ ENGELİDİR ve aşağıdaki testte adıyla
  // sayılır: terfi turunda yerelleştirme motion_shell'den enjekte edilmeden
  // bu dosyalar taşınamaz. Başka her app/motor importu yine kırmızıdır.
  const Map<String, Set<String>> localizationRuntime = <String, Set<String>>{
    'session_flow.dart': <String>{"import '../app/ui_language.dart';"},
    'live_surface.dart': <String>{
      "import '../app/ui_language.dart';",
      "import '../app/cue_locale.dart';",
    },
  };

  test('terfi şartı #2 — app veya motor bağımlılığı yok', () {
    final List<String> offenders = <String>[];
    for (final File f in sources) {
      final String name = f.uri.pathSegments.last;
      for (final String line in f.readAsLinesSync()) {
        final String t = line.trim();
        if (!t.startsWith('import ')) continue;
        if (localizationRuntime[name]?.contains(t) ?? false) continue;
        if (t.contains('jablab_engine') ||
            t.contains("'../app/") ||
            t.contains('package:jablab/app/')) {
          offenders.add('${f.uri.pathSegments.last} → $t');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'kabuk app/motor katmanına bağımlı — terfi edemez:\n'
          '${offenders.join("\n")}',
    );
  });

  test('terfi engeli — yerelleştirme importları envanterle birebir', () {
    // İstisna sessizce büyüyemez ya da bayatlayamaz: dosyalardaki app
    // yerelleştirme importları tam olarak yukarıdaki envanterdir.
    final Map<String, Set<String>> found = <String, Set<String>>{};
    for (final File f in sources) {
      final Set<String> imports = f
          .readAsLinesSync()
          .map((String l) => l.trim())
          .where(
            (String t) =>
                t == "import '../app/ui_language.dart';" ||
                t == "import '../app/cue_locale.dart';",
          )
          .toSet();
      if (imports.isNotEmpty) found[f.uri.pathSegments.last] = imports;
    }
    expect(found, localizationRuntime);
  });

  test('terfi şartı #5 — dürüstlük değişmezleri kabukta kodlu', () {
    final String honesty = File(
      'lib/shell_candidate/honesty_box.dart',
    ).readAsStringSync();
    expect(
      honesty,
      contains('assert'),
      reason:
          'HonestyBox boş "ölçülmez" listesiyle çizilebiliyorsa '
          'dürüstlük kutusu bir söz değil süstür',
    );

    final String scaffold = File(
      'lib/shell_candidate/shell_scaffold.dart',
    ).readAsStringSync();
    expect(
      scaffold,
      contains('numericUnlocked'),
      reason: 'K8 kilidi (M-F-04) kabukta temsil edilmiyor',
    );
  });
}
