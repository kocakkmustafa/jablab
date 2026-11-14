import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';

/// JAB-P1-03 (FARKLILASMA-4.3a G5): kamera koçluğu KAPALIYKEN `usesCamera`
/// dersleri kütüphane listesinde görünmez; bayrak açıkken bugünkü davranış.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ContentRepository repo = ContentRepository();
  late Library library;
  late Set<String> cameraIds;
  late Set<String> allIds;

  Iterable<ShellLesson> shellLessons(ShellLibrary s) => s.items
      .expand((ShellItem i) => i.courses)
      .expand((ShellCourse c) => c.lessons);

  setUpAll(() async {
    library = (await repo.load()).library;
    // Kaynak sayım: library.json'dan, repository'den bağımsız.
    final Map<String, dynamic> raw =
        (jsonDecode(File('assets/content/library.json').readAsStringSync())
                as Map)
            .cast<String, dynamic>();
    cameraIds = <String>{};
    allIds = <String>{};
    void walk(Object? n) {
      if (n is Map) {
        final Object? lessons = n['lessons'];
        if (lessons is List) {
          for (final Object? l in lessons) {
            if (l is Map && l['id'] is String) {
              allIds.add(l['id'] as String);
              if (l['usesCamera'] == true) cameraIds.add(l['id'] as String);
            }
          }
        }
        n.values.forEach(walk);
      } else if (n is List) {
        n.forEach(walk);
      }
    }

    walk(raw);
  });

  test('kaynak sayım: library.json 17 usesCamera dersi taşıyor', () {
    expect(cameraIds.length, 17);
  });

  test('bayrak KAPALI: usesCamera dersleri listede YOK', () {
    final ShellLibrary s = repo.toShell(library, cameraLessonsAvailable: false);
    final Set<String> ids = shellLessons(
      s,
    ).map((ShellLesson l) => l.id).toSet();
    expect(ids.intersection(cameraIds), isEmpty);
    expect(cameraIds.length, 17);
  });

  test('bayrak AÇIK: usesCamera dersleri listede VAR (bugünkü davranış)', () {
    final ShellLibrary s = repo.toShell(library, cameraLessonsAvailable: true);
    final Set<String> ids = shellLessons(
      s,
    ).map((ShellLesson l) => l.id).toSet();
    expect(ids.containsAll(cameraIds), isTrue);
  });

  test(
    'sayaçlar tutarlı: gizlenen dersler toplamdan/kurs sayacından çıkar',
    () {
      final ShellLibrary open = repo.toShell(
        library,
        cameraLessonsAvailable: true,
      );
      final ShellLibrary closed = repo.toShell(
        library,
        cameraLessonsAvailable: false,
      );
      final int openTotal = shellLessons(open).length;
      final int closedTotal = shellLessons(closed).length;
      expect(openTotal - closedTotal, cameraIds.length);

      // Kurs başına "x ders" sayacı = kapalı listedeki gerçek ders sayısı =
      // açık sayı eksi o kursun kamera dersleri.
      final Map<String, int> openPer = <String, int>{
        for (final ShellCourse c in open.items.expand(
          (ShellItem i) => i.courses,
        ))
          c.id: c.lessons.length,
      };
      for (final ShellCourse c in closed.items.expand(
        (ShellItem i) => i.courses,
      )) {
        final int hiddenInCourse = c.lessons.isEmpty
            ? 0
            : openPer[c.id]! - c.lessons.length;
        expect(
          c.lessons.where((ShellLesson l) => cameraIds.contains(l.id)),
          isEmpty,
        );
        expect(hiddenInCourse, greaterThanOrEqualTo(0));
      }
      // Hiçbir kapalı-liste dersi kamera nedeniyle kilitli görünmüyor.
      expect(
        shellLessons(closed).where(
          (ShellLesson l) =>
              l.lockedReason != null && l.lockedReason!.contains('camera'),
        ),
        isEmpty,
      );
    },
  );

  test('gizli dersin kaydı (son ders) kalan listeyi bozmaz', () {
    final ShellLibrary closed = repo.toShell(
      library,
      cameraLessonsAvailable: false,
    );
    final Set<String> visible = shellLessons(
      closed,
    ).map((ShellLesson l) => l.id).toSet();
    // "Kaldığın yer" gizli dersi bulamaz → eşleşme yok, çökme yok.
    final String hidden = cameraIds.first;
    expect(visible.contains(hidden), isFalse);
    expect(visible.length, allIds.length - cameraIds.length);
  });
}
