import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab_engine/jablab_engine.dart';

import 'app_pump.dart';

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

      // Kurs başına "x ders" sayacı: kapalı listedeki her kursun ders sayısı =
      // kaynaktaki ders sayısı − o kursun kamera dersleri; boş kurs kalmaz.
      final Map<String, int> expected = <String, int>{
        for (final ShellCourse c in open.items.expand(
          (ShellItem i) => i.courses,
        ))
          c.id: c.lessons
              .where((ShellLesson l) => !cameraIds.contains(l.id))
              .length,
      };
      for (final ShellCourse c in closed.items.expand(
        (ShellItem i) => i.courses,
      )) {
        expect(c.lessons.length, expected[c.id], reason: c.id);
        expect(c.lessons, isNotEmpty, reason: '${c.id} boş kurs listelenmez');
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

  test('kurs sayacı: yalnız görünen dersi olan kurslar sayılır', () {
    final ShellLibrary open = repo.toShell(
      library,
      cameraLessonsAvailable: true,
    );
    final ShellLibrary closed = repo.toShell(
      library,
      cameraLessonsAvailable: false,
    );
    for (final ShellItem i in closed.items) {
      final ShellItem o = open.items.firstWhere((ShellItem x) => x.id == i.id);
      final int expectedCourses = o.courses
          .where(
            (ShellCourse c) =>
                c.lessons.any((ShellLesson l) => !cameraIds.contains(l.id)),
          )
          .length;
      expect(i.courses.length, expectedCourses, reason: i.id);
    }
    // Tamamen kamera dersi olan kurslar var (footwork, conditioning).
    final Set<String> openIds = open.items
        .expand((ShellItem i) => i.courses)
        .map((ShellCourse c) => c.id)
        .toSet();
    final Set<String> closedIds = closed.items
        .expand((ShellItem i) => i.courses)
        .map((ShellCourse c) => c.id)
        .toSet();
    expect(openIds.difference(closedIds), isNotEmpty);
  });

  for (final bool cameraOn in <bool>[true, false]) {
    testWidgets(
      'kaldığın yer: gizli (kamera) ders kayıtlıyken kamera=$cameraOn',
      (WidgetTester t) async {
        final _Store store = _Store(cameraIds.first);
        await t.runAsync(() async {
          await t.pumpWidget(
            JabLabApp(
              key: ValueKey<Object>('$cameraOn'),
              onboarding: const OnboardingStore(seenOverride: true),
              repository: ContentRepository(
                storeOverride: store,
                ownerRegistry: OwnerResourceRegistry(),
              ),
              cameraLessonsAvailable: cameraOn,
            ),
          );
        });
        await settleAppLoad(t);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        if (cameraOn) {
          // Bugünkü davranış: kayıtlı ders kurs sayfasına iner.
          expect(find.byType(CoursePage), findsOneWidget);
          expect(
            t.widget<CoursePage>(find.byType(CoursePage)).resumeLesson?.id,
            cameraIds.first,
          );
        } else {
          // Ders listede yok → kurs bulunamaz → Sayfa A, çökme yok.
          expect(find.byType(CoursePage), findsNothing);
          expect(find.byType(SelectPage), findsOneWidget);
        }
      },
    );
  }
}

class _Store implements SessionStore {
  _Store(String lessonId)
    : _records = <SessionRecord>[
        SessionRecord(
          lessonId: lessonId,
          completedAt: DateTime.utc(2026, 8, 4),
          workedSeconds: 540,
          unitsCompleted: 3,
          plannedUnits: 3,
          unitLabel: 'round',
          lessonClass: 'unscored',
        ),
      ];
  final List<SessionRecord> _records;
  @override
  Future<void> append(SessionRecord record) async => _records.add(record);
  @override
  Future<List<SessionRecord>> recent({int? limit}) async => _records;
  @override
  Future<int> unreadableRecords() async => 0;
  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
}
