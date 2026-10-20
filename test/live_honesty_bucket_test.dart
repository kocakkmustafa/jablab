// Real appearance consumers, bounded palette/paint and original behavior witnesses; physical/native acceptance is separate.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/design_tokens.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/shell_candidate/live_surface.dart'
    show LiveCoachSurface, LiveState;
import 'package:jablab/shell_candidate/shell_models.dart';

const _brightnesses = <Brightness>[Brightness.light, Brightness.dark];
JPalette _palette(Brightness b) =>
    b == Brightness.dark ? JPalette.dark : JPalette.light;

// Independent semantic oracle: do not call accentFor/themeFor in expectations.
Color _bucketColor(LiveHonestyBucket bucket, JPalette p) => switch (bucket) {
  LiveHonestyBucket.yours => p.observation,
  LiveHonestyBucket.ours => p.inkMuted,
  LiveHonestyBucket.none => p.inkSubtle,
};
IconData _bucketIcon(LiveHonestyBucket bucket) => switch (bucket) {
  LiveHonestyBucket.yours => Icons.center_focus_strong_outlined,
  LiveHonestyBucket.ours => Icons.sync_problem_outlined,
  LiveHonestyBucket.none => Icons.videocam_off_outlined,
};

Widget _host(Brightness b, Widget child) => MaterialApp(
  locale: const Locale('en'),
  theme: jablabTheme(Brightness.light),
  darkTheme: jablabTheme(Brightness.dark),
  themeMode: b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  themeAnimationDuration: Duration.zero,
  home: child,
);

int _expectText(WidgetTester t, Finder finder, TextStyle expected) {
  expect(finder, findsOneWidget, reason: 'a missing consumer cannot pass');
  expect(
    t.widget<Text>(finder).style,
    expected,
    reason: 'exact role, family, size, weight and geometry are required',
  );
  return 1;
}

void main() {
  test('üç kovanın açık ve koyu palet rolleri opak ve birbirinden farklı', () {
    for (final brightness in _brightnesses) {
      final p = _palette(brightness);
      final base = jablabTheme(brightness);
      final colors = <Color>{};
      for (final bucket in LiveHonestyBucket.values) {
        final expected = _bucketColor(bucket, p);
        expect(bucket.accentFor(base), expected);
        expect(expected.a, 1.0, reason: 'required label roles are opaque');
        colors.add(expected);
      }
      expect(colors.length, LiveHonestyBucket.values.length);
    }
    // Transitional getter is checked separately, never used as the UI oracle.
    expect(LiveHonestyBucket.yours.accent, JColors.cool);
    expect(LiveHonestyBucket.ours.accent, JColors.ink2);
    expect(LiveHonestyBucket.none.accent, JColors.ink3);
  });

  test('üç kova belirli ve birbirinden farklı ikonlarını korur', () {
    final icons = <IconData>{};
    for (final bucket in LiveHonestyBucket.values) {
      expect(bucket.icon, _bucketIcon(bucket));
      icons.add(bucket.icon);
    }
    expect(icons.length, LiveHonestyBucket.values.length);
  });

  test('üç opak kova rolü iki zeminde de 3:1 matematik eşiğini korur', () {
    for (final brightness in _brightnesses) {
      final p = _palette(brightness);
      for (final bucket in LiveHonestyBucket.values) {
        expect(
          _contrast(_over(_bucketColor(bucket, p), p.ground), p.ground),
          greaterThanOrEqualTo(3.0),
          reason: '$brightness / $bucket',
        );
      }
    }
  });

  test(
    'tipografi rolü ve eski punto/geometri sözleşmesi iki palette korunur',
    () {
      for (final brightness in _brightnesses) {
        final p = _palette(brightness);
        final text = JTypography(p);
        final styles = <String, (TextStyle, TextStyle)>{
          'body': (text.body, JText.body.copyWith(color: p.ink)),
          'bodyMuted': (
            text.bodyMuted,
            JText.bodyMuted.copyWith(color: p.inkMuted),
          ),
          'label': (text.label, JText.label.copyWith(color: p.observation)),
          'mono': (text.mono, JText.mono.copyWith(color: p.inkMuted)),
          'correction': (
            text.correction,
            JText.correction.copyWith(color: p.ink),
          ),
          'pageTitle': (text.pageTitle, JText.pageTitle.copyWith(color: p.ink)),
          'clock': (text.clock, JText.clock.copyWith(color: p.ink)),
        };
        expect(styles.length, 7);
        for (final entry in styles.entries) {
          final actual = entry.value.$1;
          expect(actual, entry.value.$2, reason: '$brightness / ${entry.key}');
          final size = actual.fontSize ?? 14;
          final bold =
              (actual.fontWeight?.value ?? 400) >= FontWeight.w700.value;
          final threshold = (size >= 24 || (bold && size >= 18.66)) ? 3.0 : 4.5;
          expect(
            _contrast(_over(actual.color!, p.ground), p.ground),
            greaterThanOrEqualTo(threshold),
            reason: '$brightness / ${entry.key}: uniform role/background math',
          );
        }
      }
    },
  );

  test(
    'sabit kamera altyazısı scrim ile okunur; scrim yokluğu negatif ikizdir',
    () {
      final canvas = JCameraCanvasAppearance.dark;
      final gradientTop = _over(canvas.gradientTop, canvas.background);
      final brightestJoint = _blend(canvas.observation, .85, gradientTop);
      final scrimmed = _over(canvas.captionScrim, brightestJoint);
      final caption = _over(canvas.captionStyle.color!, scrimmed);
      expect(_contrast(caption, scrimmed), greaterThanOrEqualTo(4.5));
      final noScrim = _over(canvas.captionStyle.color!, brightestJoint);
      expect(
        _contrast(noScrim, brightestJoint),
        lessThan(4.5),
        reason: 'the scrim-free negative twin remains distinguishable',
      );
      // Real Stack order has a separate witness; arithmetic is not native raster.
    },
  );

  testWidgets(
    'gerçek karşılama, kilitli metadata ve devam eylemi paleti kullanır',
    (t) async {
      t.view.physicalSize = const Size(1200, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      const library = ShellLibrary(
        title: 'Appearance fixture',
        items: <ShellItem>[],
        exclusions: <ShellExclusion>[],
      );
      const open = ShellLesson(
        id: 'appearance-open',
        title: 'Appearance open lesson',
        minutes: 3,
      );
      const locked = ShellLesson(
        id: 'appearance-locked',
        title: 'Appearance locked lesson',
        minutes: 9,
        lockedReason: 'Appearance locked reason',
      );
      const course = ShellCourse(
        id: 'appearance-course',
        title: 'Appearance course',
        lessons: <ShellLesson>[open, locked],
      );
      for (final brightness in _brightnesses) {
        final p = _palette(brightness);
        var checked = 0;
        await t.pumpWidget(
          _host(
            brightness,
            OnboardingPage(
              library: library,
              onDone: () {},
              onOpenWhyNot: () {},
            ),
          ),
        );
        expect(find.byKey(const Key('onboarding-welcome')), findsOneWidget);
        checked += _expectText(
          t,
          find.text('THE CORNER'),
          JText.label.copyWith(color: p.observation),
        );
        checked += _expectText(
          t,
          find.text('Boxing practice\nyou can do alone.'),
          JText.pageTitle.copyWith(color: p.ink),
        );
        checked += _expectText(
          t,
          find.textContaining('Learn solo boxing through'),
          JText.body.copyWith(color: p.ink),
        );
        checked += _expectText(
          t,
          find.textContaining('Course progress stays on this device'),
          JText.bodyMuted.copyWith(color: p.inkMuted),
        );
        final next = find.byKey(const Key('onboarding-next'));
        expect(next, findsOneWidget);
        checked += _expectText(
          t,
          find.descendant(of: next, matching: find.byType(Text)),
          JText.body.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
        );
        final button = t.widget<FilledButton>(next);
        expect(
          button.style!.backgroundColor!.resolve(<WidgetState>{}),
          p.accent,
        );
        expect(
          button.style!.foregroundColor!.resolve(<WidgetState>{}),
          p.onAccent,
        );
        expect(
          t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          p.ground,
        );

        final started = <String>[];
        await t.pumpWidget(
          _host(
            brightness,
            CoursePage(
              course: course,
              isCurrent: true,
              resumeLesson: open,
              recorded: const <String, String>{'Sessions': '2 recorded'},
              recordedNote: 'Appearance fixture note',
              onStart: (lesson) => started.add(lesson.id),
              onOpenSettings: () {},
            ),
          ),
        );
        final lockedRow = find.byKey(const Key('lesson-appearance-locked'));
        final openRow = find.byKey(const Key('lesson-appearance-open'));
        expect(lockedRow, findsOneWidget);
        expect(openRow, findsOneWidget);
        checked += _expectText(
          t,
          find.text(locked.title),
          JText.body.copyWith(color: p.inkMuted, fontWeight: FontWeight.w600),
        );
        checked += _expectText(
          t,
          find.byKey(const Key('locked-why-appearance-locked')),
          JText.bodyMuted.copyWith(color: p.inkMuted, fontSize: 12.5),
        );
        checked += _expectText(
          t,
          find.descendant(of: lockedRow, matching: find.text('9 min')),
          JText.mono.copyWith(color: p.inkMuted),
        );
        checked += _expectText(
          t,
          find.text(open.title),
          JText.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
        );
        checked += _expectText(
          t,
          find.descendant(of: openRow, matching: find.text('3 min')),
          JText.mono.copyWith(color: p.observation),
        );
        checked += _expectText(
          t,
          find.byKey(const Key('recorded-heading')),
          JText.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
        );
        checked += _expectText(
          t,
          find.byKey(const Key('recorded-vs-judged-note')),
          JText.bodyMuted.copyWith(color: p.inkMuted),
        );
        checked += _expectText(
          t,
          find.text('Sessions'),
          JText.body.copyWith(color: p.ink, fontSize: 14),
        );
        checked += _expectText(
          t,
          find.text('2 recorded'),
          JText.body.copyWith(
            color: p.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );
        checked += _expectText(
          t,
          find.byKey(const Key('recorded-note')),
          JText.bodyMuted.copyWith(color: p.inkMuted),
        );
        final resume = find.byKey(const Key('resume-lesson'));
        expect(resume, findsOneWidget);
        checked += _expectText(
          t,
          find.descendant(of: resume, matching: find.byType(Text)),
          TextStyle(
            color: p.onJudgement,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        );
        final resumeBox = find.ancestor(
          of: resume,
          matching: find.byWidgetPredicate((widget) {
            if (widget is! DecoratedBox || widget.child is! Material) {
              return false;
            }
            final child = (widget.child as Material).child;
            return child is InkWell && child.key == const Key('resume-lesson');
          }),
        );
        expect(resumeBox, findsOneWidget);
        expect(
          (t.widget<DecoratedBox>(resumeBox).decoration as BoxDecoration).color,
          p.judgement,
        );
        expect(t.widget<InkWell>(lockedRow).onTap, isNull);
        final lockedIcon = find.descendant(
          of: lockedRow,
          matching: find.byIcon(Icons.lock_outline),
        );
        expect(lockedIcon, findsOneWidget);
        expect(t.widget<Icon>(lockedIcon).color, p.inkSubtle);
        expect(t.widget<Icon>(lockedIcon).size, 22);
        expect(
          checked,
          16,
          reason: '5 onboarding + 11 course texts; zero sites cannot pass',
        );
        await t.ensureVisible(resume);
        await t.tap(resume);
        expect(started, <String>[
          open.id,
        ], reason: 'resume action is preserved');
        expect(t.takeException(), isNull);
      }
    },
  );

  test('sönük ama okunur hiyerarşi iki palette de en az iki kat ayrışır', () {
    for (final brightness in _brightnesses) {
      final p = _palette(brightness);
      final primary = _contrast(_over(p.ink, p.ground), p.ground);
      final muted = _contrast(_over(p.inkMuted, p.ground), p.ground);
      expect(primary, greaterThan(muted * 2));
      expect(muted, greaterThanOrEqualTo(4.5));
    }
  });

  test('hiçbir kova hüküm ya da hata/eylem tonuna dönüşmez', () {
    for (final brightness in _brightnesses) {
      final p = _palette(brightness);
      for (final bucket in LiveHonestyBucket.values) {
        expect(_bucketColor(bucket, p), isNot(p.judgement));
        expect(_bucketColor(bucket, p), isNot(p.accent));
      }
    }
  });

  testWidgets('no-verdict yüzeyine rol, ikon ve susma semantiği ulaşır', (
    t,
  ) async {
    for (final brightness in _brightnesses) {
      final p = _palette(brightness);
      for (final bucket in LiveHonestyBucket.values) {
        final base = jablabSessionThemeFor(jablabTheme(brightness));
        await t.pumpWidget(
          _host(
            brightness,
            Theme(
              data: bucket.themeFor(base),
              child: Scaffold(
                body: LiveCoachSurface(
                  state: LiveState.noVerdict,
                  eventCount: null,
                  noVerdictReason: 'appearance-no-verdict',
                  preview: SkeletonPreview(
                    state: LiveState.noVerdict,
                    bucket: bucket,
                    analysisRunning: false,
                  ),
                ),
              ),
            ),
          ),
        );
        final noVerdict = find.byKey(const Key('live-no-verdict'));
        expect(noVerdict, findsOneWidget);
        final icon = find.descendant(
          of: noVerdict,
          matching: find.byIcon(Icons.visibility_off_outlined),
        );
        expect(icon, findsOneWidget);
        final actual = t.widget<Icon>(icon);
        expect(actual.color, _bucketColor(bucket, p));
        expect(actual.color!.a, 1.0);
        expect(actual.size, 20);
        expect(actual.color, isNot(p.judgement));
        expect(actual.color, isNot(p.accent));
        expect(actual.color, isNot(jablabTheme(brightness).colorScheme.error));
        expect(Theme.of(t.element(icon)).brightness, brightness);
        expect(JPalette.fromTheme(Theme.of(t.element(icon))), same(p));
        _expectText(
          t,
          find.text('appearance-no-verdict'),
          JText.body.copyWith(color: p.ink),
        );
        expect(find.byKey(const Key('live-cue')), findsNothing);
        expect(find.byKey(const Key('live-clean')), findsNothing);
        expect(find.byKey(const Key('event-count')), findsNothing);
      }
    }
  });

  testWidgets(
    'parametresiz kamera iki temada koyu; üç ikon ve analiz koşulu korunur',
    (t) async {
      for (final brightness in _brightnesses) {
        for (final bucket in LiveHonestyBucket.values) {
          for (final running in <bool>[false, true]) {
            await t.pumpWidget(
              _host(
                brightness,
                Scaffold(
                  body: SizedBox(
                    width: 320,
                    height: 320,
                    child: SkeletonPreview(
                      state: LiveState.noVerdict,
                      bucket: bucket,
                      analysisRunning: running,
                      // Deliberately omit canvasAppearance: production default path.
                    ),
                  ),
                ),
              ),
            );
            final preview = find.byType(SkeletonPreview);
            expect(preview, findsOneWidget);
            expect(t.widget<SkeletonPreview>(preview).canvasAppearance, isNull);
            expect(Theme.of(t.element(preview)).brightness, brightness);
            final icon = find.descendant(
              of: preview,
              matching: find.byIcon(_bucketIcon(bucket)),
            );
            expect(icon, findsOneWidget);
            expect(
              t.widget<Icon>(icon).color,
              _bucketColor(bucket, JPalette.dark),
            );
            expect(t.widget<Icon>(icon).size, 28);
            expect(t.widget<Icon>(icon).color, isNot(JPalette.dark.judgement));
            final caption = find.byKey(const Key('camera-preview-placeholder'));
            _expectText(
              t,
              caption,
              JText.mono.copyWith(color: JPalette.dark.inkMuted, fontSize: 11),
            );
            expect(
              t.widget<Text>(caption).data,
              running
                  ? 'Camera preview is left out on purpose — analysis runs without it'
                  : 'Camera preview is left out on purpose',
            );
            final scrim = find.byKey(const Key('camera-caption-scrim'));
            expect(scrim, findsOneWidget);
            expect(
              (t.widget<DecoratedBox>(scrim).decoration as BoxDecoration).color,
              JPalette.dark.ground.withValues(alpha: .81),
            );
            final gradients = find.descendant(
              of: preview,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is DecoratedBox &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).gradient
                        is LinearGradient,
              ),
            );
            expect(gradients, findsOneWidget);
            final gradient =
                (t.widget<DecoratedBox>(gradients).decoration as BoxDecoration)
                        .gradient!
                    as LinearGradient;
            expect(gradient.colors, <Color>[
              JPalette.dark.shadow.withValues(alpha: .55),
              JPalette.dark.ground,
            ]);
          }
        }
      }
    },
  );
}

/// Alfa taşıyan bir rengi zemine BİNDİRİR. Kontrast, ekranda gerçekten
/// oluşan renkten hesaplanmalı: `ink` yarı saydamken `ink`in kendi
/// parlaklığını ölçmek, ölçmediğimiz bir pikseli ölçmek olurdu.
Color _over(Color fg, Color bg) {
  double c(double f, double b) => f * fg.a + b * (1 - fg.a);
  return Color.from(
    alpha: 1,
    red: c(fg.r, bg.r),
    green: c(fg.g, bg.g),
    blue: c(fg.b, bg.b),
  );
}

/// WCAG 2.x bağıl parlaklık ve kontrast oranı — formül standardın kendisi
/// (sRGB doğrusallaştırma + 0.2126/0.7152/0.0722 ağırlıkları), burada
/// uydurulmuş hiçbir katsayı yok.
double _luminance(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// [fg]i [alpha] ile [bg] üstüne bindirir. `_over`den farkı: alfayı
/// rengin kendisinden değil AÇIKÇA alması — scrim gibi katmanları
/// modellerken alfa bir kompozisyon parametresidir, rengin özelliği değil.
Color _blend(Color fg, double alpha, Color bg) {
  final double a = alpha * fg.a;
  double c(double f, double b) => f * a + b * (1 - a);
  return Color.from(
    alpha: 1,
    red: c(fg.r, bg.r),
    green: c(fg.g, bg.g),
    blue: c(fg.b, bg.b),
  );
}
