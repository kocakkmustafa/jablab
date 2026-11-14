// JAB-P1-02: kamera özelliği kapalıyken (jablabCameraCoachingAvailable=false)
// Android bildirimi CAMERA iznini ve kamera uses-feature satırlarını
// istemez. motion_camera eklentisinin kendi bildirimi CAMERA ekler; birleşik
// bildirimde çıkması için uygulama bildirimi `tools:node="remove"` taşır.
// Kamera açılırken geri ekleme: docs/camera/ANDROID-CAMERA-IZNI.tr.md
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  // Yorum satırlarındaki anılar sayılmasın.
  final String live = manifest.replaceAll(
    RegExp(r'<!--.*?-->', dotAll: true),
    '',
  );
  final List<String> tags = RegExp(
    r'<uses-(?:permission|feature)\b[^>]*>',
  ).allMatches(live).map((m) => m.group(0)!).toList();
  final List<String> cameraTags = tags
      .where(
        (t) =>
            t.contains('android.permission.CAMERA') ||
            t.contains('android.hardware.camera'),
      )
      .toList();

  test('CAMERA izni ve kamera uses-feature yalnız remove olarak geçer', () {
    for (final String t in cameraTags) {
      expect(t, contains('tools:node="remove"'), reason: t);
    }
  });

  test('CAMERA izni için remove satırı var (eklenti birleşimini keser)', () {
    expect(
      cameraTags.any((t) => t.contains('android.permission.CAMERA')),
      isTrue,
    );
  });

  test('iki uses-feature (camera, camera.autofocus) için remove var', () {
    for (final String name in <String>[
      'android.hardware.camera',
      'android.hardware.camera.autofocus',
    ]) {
      final List<String> match = tags
          .where(
            (t) =>
                t.startsWith('<uses-feature') &&
                t.contains('android:name="$name"'),
          )
          .toList();
      expect(match, hasLength(1), reason: name);
      expect(match.single, contains('tools:node="remove"'), reason: name);
    }
  });

  test('tools ad alanı bildirildi', () {
    expect(
      live,
      contains('xmlns:tools="http://schemas.android.com/tools"'),
    );
  });

  test('INTERNET izni korunur', () {
    expect(live, contains('android.permission.INTERNET'));
  });
}
