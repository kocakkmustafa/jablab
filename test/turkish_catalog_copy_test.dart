import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_locale.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/rehearse_material.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_screen.dart';
import 'package:jablab/app/session_narrator.dart';
import 'package:jablab/app/teach_material.dart';
import 'package:jablab/app/teach_locale.dart';
import 'package:jablab/app/ui_language.dart';
import 'package:jablab/app/why_not_locale.dart';
import 'package:jablab/shell_candidate/shell_models.dart';
import 'package:jablab/shell_candidate/library_pages.dart' show WhyNotPage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ShellLibrary> loadLibrary(WidgetTester tester) async {
    late ShellLibrary library;
    await tester.runAsync(() async {
      const ContentRepository repository = ContentRepository();
      library = repository.toShell((await repository.load()).library);
    });
    return library;
  }

  Future<Map<String, String>> loadAuthoredTeach(WidgetTester tester) async {
    late String raw;
    await tester.runAsync(() async {
      raw = await rootBundle.loadString(ContentRepository.libraryAsset);
    });
    final Map<String, dynamic> catalog =
        jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, String> bodies = <String, String>{};
    for (final dynamic discipline in catalog['disciplines'] as List<dynamic>) {
      for (final dynamic course
          in (discipline as Map<String, dynamic>)['courses'] as List<dynamic>) {
        for (final dynamic lesson
            in (course as Map<String, dynamic>)['lessons'] as List<dynamic>) {
          final Map<String, dynamic> row = lesson as Map<String, dynamic>;
          if (row['teach'] case final String body when body.isNotEmpty) {
            bodies[row['id'] as String] = body;
          }
        }
      }
    }
    return bodies;
  }

  testWidgets('Turkish catalog keeps live and closed discipline copy Turkish', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    final ShellLibrary library = await loadLibrary(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectPage(
          library: library,
          onOpenCourse: (_) {},
          onOpenWhyNot: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boks'), findsOneWidget);
    expect(find.text('4 kurs'), findsOneWidget);
    expect(find.text('Kickboks'), findsOneWidget);
    expect(
      find.textContaining('Tekmeler bu sürümün ölçüm kurallarında yok'),
      findsOneWidget,
    );
    expect(find.textContaining('4 courses'), findsNothing);

    await tester.tap(find.byKey(const Key('item-kickboxing')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bu disiplin açık değil'), findsOneWidget);
    expect(find.text('KAPALI'), findsWidgets);
  });

  testWidgets('Turkish boxing honesty keeps measured limits accurate', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    final ShellLibrary library = await loadLibrary(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectPage(
          library: library,
          onOpenCourse: (_) {},
          onOpenWhyNot: () {},
          onOpenSettings: () {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('item-boxing')));
    await tester.pumpAndSettle();

    expect(find.text('Neleri ölçer'), findsOneWidget);
    expect(find.text('Neleri ölçmez'), findsOneWidget);
    expect(find.textContaining('Yumruk olayları ve sayısı'), findsOneWidget);
    expect(find.textContaining('Yumruk kuvveti veya gücü'), findsOneWidget);
  });

  testWidgets('Turkish honesty onboarding uses translated explanation', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    final ShellLibrary library = await loadLibrary(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          library: library,
          onDone: () {},
          onOpenWhyNot: () {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Telefon kamerası bunların bir kısmını'),
      findsOneWidget,
    );
    expect(
      find.textContaining('A single camera sees shape and timing'),
      findsNothing,
    );
  });

  testWidgets(
    'Turkish boxing course shows localized metadata and lock reason',
    (WidgetTester tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
      addTearDown(
        () => tester.binding.platformDispatcher.clearLocaleTestValue(),
      );

      final ShellLibrary library = await loadLibrary(tester);
      final ShellItem boxing = library.items.firstWhere(
        (ShellItem item) => item.id == 'boxing',
      );
      final ShellCourse foundations = boxing.courses.firstWhere(
        (ShellCourse course) => course.id == 'boxing.foundations',
      );
      final ShellCourse intermediate = boxing.courses.firstWhere(
        (ShellCourse course) => course.id == 'boxing.intermediate',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CoursePage(
            course: foundations,
            onStart: (_) {},
            onOpenSettings: () {},
          ),
        ),
      );
      expect(find.text('Temeller'), findsOneWidget);
      expect(
        find.textContaining('Düşünmeden tekrarlayabileceğin'),
        findsOneWidget,
      );
      expect(find.text('Kamera ve çalışma alanı'), findsOneWidget);
      expect(find.text('Camera and space'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: CoursePage(
            course: intermediate,
            onStart: (_) {},
            onOpenSettings: () {},
          ),
        ),
      );
      expect(find.text('Orta seviye'), findsOneWidget);
      expect(
        find.textContaining('Kroşe ve aparkat burada modellenmedi'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Changed English source is shown instead of stale translation', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Text(
            courseTitle(context, 'boxing.foundations', 'Foundations revised'),
          ),
        ),
      ),
    );
    expect(find.text('Foundations revised'), findsOneWidget);
    expect(find.text('Temeller'), findsNothing);
  });

  testWidgets('Turkish scope page translates all authored exclusions', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    final ShellLibrary library = await loadLibrary(tester);
    late List<ShellExclusion> translated;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            translated = whyNotExclusions(context, library.exclusions);
            return WhyNotPage(
              library: library,
              title: UiLanguage.text(
                context,
                en: "Why isn't my art here?",
                tr: 'Disiplinim neden burada yok?',
              ),
              intro: whyNotIntro(context, library.whyNotIntro),
              exclusions: translated,
            );
          },
        ),
      ),
    );

    expect(translated, hasLength(12));
    for (int index = 0; index < translated.length; index++) {
      expect(translated[index].reason, isNot(library.exclusions[index].reason));
    }
    expect(find.text('Disiplinim neden burada yok?'), findsOneWidget);
    expect(
      find.textContaining('Telefon kamerası bunların bir kısmını'),
      findsOneWidget,
    );
    expect(find.textContaining('Tek kişiyi gören kamera'), findsOneWidget);
  });

  testWidgets('Changed exclusion rationale falls back to its source', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    late ShellExclusion translated;
    const ShellExclusion changed = ShellExclusion(
      'Brazilian Jiu-Jitsu',
      'A new rationale that has not been reviewed for translation.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            translated = whyNotExclusions(context, <ShellExclusion>[
              changed,
            ]).single;
            return Text(translated.reason);
          },
        ),
      ),
    );
    expect(translated.title, changed.title);
    expect(find.text(changed.reason), findsOneWidget);
  });

  testWidgets(
    'Turkish lesson heading stays localized after course navigation',
    (WidgetTester tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
      addTearDown(
        () => tester.binding.platformDispatcher.clearLocaleTestValue(),
      );

      final ShellLibrary library = await loadLibrary(tester);
      final ShellLesson cameraLesson = library.items
          .firstWhere((ShellItem item) => item.id == 'boxing')
          .courses
          .firstWhere((ShellCourse course) => course.id == 'boxing.foundations')
          .lessons
          .first;
      late CueBook cues;
      final Map<String, String> authored = await loadAuthoredTeach(tester);
      await tester.runAsync(() async {
        cues = await const ContentRepository().loadCues();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: SessionScreen(
            lesson: cameraLesson,
            cues: cues,
            coachedNotScored: const <String>[
              'Lead elbow angle',
              'Rear guard hand position',
            ],
            bands: const <String, String>{'Stance': '—', 'Balance': '—'},
            plan: null,
            teachMaterial: TeachMaterialText(
              body: authored['boxing.foundations.camera']!,
            ),
            rehearseMaterial: const RehearseMaterialNone(
              reason:
                  'This lesson does not drill a named technique — the '
                  'shape itself is the work. Move through it slowly and '
                  'stay in frame.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kamera ve çalışma alanı'), findsWidgets);
      expect(find.text('Camera and space'), findsNothing);
      expect(find.textContaining('Her yöne iki adım'), findsOneWidget);
      expect(find.textContaining('Stand where you can'), findsNothing);
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('çalışılan şey duruşun kendisi'),
        findsOneWidget,
      );
      expect(find.textContaining('This lesson does not drill'), findsNothing);
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
      expect(find.text('Duruş'), findsOneWidget);
      expect(find.text('Denge'), findsOneWidget);
      expect(find.text('Stance'), findsNothing);
      expect(find.text('Balance'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('• Öndeki dirseğin açısı'),
        140,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('• Öndeki dirseğin açısı'), findsOneWidget);
      expect(find.text('• Arkadaki gard elinin konumu'), findsOneWidget);
    },
  );

  testWidgets(
    'All authored Boxing teach bodies have source-matched Turkish copy',
    (WidgetTester tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
      addTearDown(
        () => tester.binding.platformDispatcher.clearLocaleTestValue(),
      );
      final Map<String, String> authored = await loadAuthoredTeach(tester);
      late Map<String, String> translated;
      late String changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              translated = <String, String>{
                for (final MapEntry<String, String> entry in authored.entries)
                  entry.key: localizedTeachBody(
                    context,
                    entry.key,
                    entry.value,
                  ),
              };
              final String original = authored['boxing.foundations.camera']!;
              changed = localizedTeachBody(
                context,
                'boxing.foundations.camera',
                '$original Edited source',
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(authored, hasLength(18));
      expect(translated.keys, containsAll(authored.keys));
      for (final MapEntry<String, String> entry in authored.entries) {
        expect(translated[entry.key], isNot(entry.value), reason: entry.key);
        expect(translated[entry.key], isNotEmpty, reason: entry.key);
        expect(
          translated[entry.key]!.split('\n\n'),
          hasLength(entry.value.split('\n\n').length),
          reason: 'Paragraphs missing for ${entry.key}',
        );
      }
      expect(
        changed,
        '${authored['boxing.foundations.camera']!} Edited source',
      );
    },
  );
}
