import 'support/local_core_intake.dart';

import 'package:flutter_test/flutter_test.dart';

/// İKİ KİLİT DOSYASI, TEK PİN — J-030'un kalıcı hâli.
///
/// `packages/jablab_engine/pubspec.yaml`'daki `motion_core` pinini
/// yükseltmek `dart pub get`'i HEM engine paketinde HEM app kökünde ister;
/// biri atlanırsa iki katman farklı çekirdek sürümüyle SESSİZCE yeşil
/// görünür (J-030: motor testleri yeni sürümle, Flutter testleri eski
/// sürümle koşuyordu — fark ancak derleme hatası olarak patladı). Bu test
/// o günü beklemeden kırar: iki `pubspec.lock`'un `motion_core` için
/// çözdüğü `resolved-ref` birebir aynı olmalı.
void main() {
  test('app kökü ve jablab_engine paketi AYNI motion_core sürümünü çözüyor',
      () {
    final String? appRef =
        _resolvedRef(lockForAudit('pubspec.lock'));
    final String? engineRef = _resolvedRef(
        lockForAudit('packages/jablab_engine/pubspec.lock'));

    expect(appRef, isNotNull,
        reason: 'pubspec.lock içinde motion_core.resolved-ref bulunamadı');
    expect(engineRef, isNotNull,
        reason: 'packages/jablab_engine/pubspec.lock içinde '
            'motion_core.resolved-ref bulunamadı');
    expect(appRef, engineRef,
        reason: 'İKİ KİLİT DOSYASI FARKLI SÜRÜM ÇÖZÜYOR: app kökü $appRef, '
            'jablab_engine $engineRef. Pin yükseltmesi her iki kökte de '
            '`pub get` ister (J-030) — birini atladın.');
  });
}

/// `<indent>motion_core:` bloğundaki `resolved-ref:` değerini döner.
/// Blok, aynı girintide yeni bir üst-seviye anahtar görülünce biter.
String? _resolvedRef(String lockYaml) {
  final List<String> lines = lockYaml.split('\n');
  int i = 0;
  while (i < lines.length && lines[i] != '  motion_core:') {
    i++;
  }
  if (i == lines.length) return null;
  for (int j = i + 1; j < lines.length; j++) {
    final String line = lines[j];
    if (RegExp(r'^  \S').hasMatch(line)) break; // yeni üst-seviye anahtar
    final Match? m = RegExp(r'^\s*resolved-ref:\s*(\S+)').firstMatch(line);
    if (m != null) return m.group(1);
  }
  return null;
}
