// Real appearance consumers, bounded palette/paint and original behavior witnesses; physical/native acceptance is separate.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/design_tokens.dart';
import 'package:jablab/app/live_honesty.dart';
import 'package:jablab/app/skeleton_overlay.dart';
import 'package:jablab/app/solo_boxing_course_page.dart';
import 'package:jablab/shell_candidate/live_surface.dart';
import 'package:motion_core/motion_core.dart' show Lm, PoseLandmark;

Widget _host(Brightness brightness, Widget child) => MaterialApp(
  locale: const Locale('en'),
  theme: jablabTheme(Brightness.light),
  darkTheme: jablabTheme(Brightness.dark),
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  themeAnimationDuration: Duration.zero,
  home: Scaffold(body: Center(child: child)),
);

Widget _preview(
  List<PoseLandmark> landmarks, {
  JCameraCanvasAppearance? appearance,
  LiveState state = LiveState.noVerdict,
}) => SizedBox(
  width: 320,
  height: 320,
  child: SkeletonPreview(
    state: state,
    analysisRunning: false,
    skeleton: landmarks,
    bucket: LiveHonestyBucket.none,
    canvasAppearance: appearance,
  ),
);

CustomPainter _painter(WidgetTester tester) {
  final overlay = find.byKey(const Key('skeleton-overlay'));
  expect(overlay, findsOneWidget);
  final painter = tester.widget<CustomPaint>(overlay).painter;
  expect(painter, isNotNull);
  return painter!;
}

JCameraCanvasAppearance _withObservation(Color observation) {
  final dark = JCameraCanvasAppearance.dark;
  return JCameraCanvasAppearance(
    background: dark.background,
    gradientTop: dark.gradientTop,
    captionScrim: dark.captionScrim,
    captionStyle: dark.captionStyle,
    observation: observation,
    neutralIcon: dark.neutralIcon,
    noAnalysisIcon: dark.noAnalysisIcon,
  );
}

void _expectCaptionAfterPaint(WidgetTester tester) {
  final root = find.byType(SkeletonPreview);
  expect(root, findsOneWidget);
  final stackFinder = find.descendant(of: root, matching: find.byType(Stack));
  expect(stackFinder, findsOneWidget);
  final stack = tester.widget<Stack>(stackFinder);
  expect(stack.children.length, 3,
      reason: 'placeholder, skeleton and foreground caption must all exist');
  final paintIndices = <int>[];
  final captionIndices = <int>[];
  for (var i = 0; i < stack.children.length; i++) {
    final child = stack.children[i];
    if (child.key == const Key('skeleton-overlay')) {
      paintIndices.add(i);
    }
    final captionWithin = find.descendant(
      of: find.byWidget(child),
      matching: find.byKey(const Key('camera-caption-scrim')),
    );
    if (child.key == const Key('camera-caption-scrim') ||
        captionWithin.evaluate().isNotEmpty) {
      captionIndices.add(i);
    }
  }
  expect(paintIndices, <int>[1]);
  expect(captionIndices, <int>[2],
      reason: 'a correctly styled caption below the skeleton is insufficient');
  expect(captionIndices.single, greaterThan(paintIndices.single));
}

void main() {
  testWidgets('course entry follows a live palette change and keeps its action',
      (tester) async {
    var opened = 0;
    for (final brightness in <Brightness>[Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(_host(
        brightness,
        SoloCourseEntryCard(onOpen: () { opened++; }),
      ));
      await tester.pump();
      final titleFinder = find.text('SOLO BOXING PATH');
      expect(titleFinder, findsOneWidget);
      final title = tester.widget<Text>(titleFinder);
      final p = brightness == Brightness.dark ? JPalette.dark : JPalette.light;
      expect(title.style, JText.body.copyWith(
        color: p.observation, fontWeight: FontWeight.w700,
      ));
      expect(Theme.of(tester.element(titleFinder)).brightness, brightness);
      expect(find.byKey(const Key('open-solo-boxing-course')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('open-solo-boxing-course')));
    expect(opened, 1);
  });

  testWidgets('real Stack keeps caption last; repaint tracks only drawing inputs',
      (tester) async {
    final landmarks = List<PoseLandmark>.filled(
      33, const PoseLandmark(.5, .5, 0, 1),
    );
    // Null appearance uses the production default, unlike the old witness.
    await tester.pumpWidget(_host(Brightness.light, _preview(landmarks)));
    final lightPainter = _painter(tester);
    _expectCaptionAfterPaint(tester);
    await tester.pumpWidget(_host(Brightness.dark, _preview(landmarks)));
    final darkPainter = _painter(tester);
    _expectCaptionAfterPaint(tester);
    expect(darkPainter.shouldRepaint(lightPainter), isFalse,
        reason: 'app brightness alone does not alter the fixed dark canvas');

    final changed = _withObservation(const Color(0xFFCCDDEE));
    await tester.pumpWidget(_host(
      Brightness.dark, _preview(landmarks, appearance: changed),
    ));
    final changedPainter = _painter(tester);
    _expectCaptionAfterPaint(tester);
    expect(changedPainter.shouldRepaint(darkPainter), isTrue,
        reason: 'same list and state; only the observation paint color changed');

    await tester.pumpWidget(_host(
      Brightness.dark,
      _preview(landmarks, appearance: changed, state: LiveState.clean),
    ));
    final statePainter = _painter(tester);
    expect(statePainter.shouldRepaint(changedPainter), isTrue,
        reason: 'the existing state/scene-alpha invalidation is preserved');
    await tester.pumpWidget(_host(
      Brightness.dark,
      _preview(List<PoseLandmark>.of(landmarks),
        appearance: changed, state: LiveState.clean),
    ));
    expect(_painter(tester).shouldRepaint(statePainter), isTrue,
        reason: 'the existing landmark-list invalidation is preserved');
  });

  testWidgets('controlled joint pixel uses observation color and scene alpha',
      (tester) async {
    // Isolate one left-wrist joint. Its bone is vertical at x=20; all other
    // joints are far away. Pixel (22,20) is inside radius 3.2, outside width
    // 2.2, and contains no text, scrim, gradient, image or native camera.
    final landmarks = List<PoseLandmark>.filled(
      33, const PoseLandmark(.8, .8, 0, 1),
    );
    landmarks[Lm.leftWrist] = const PoseLandmark(.2, .2, 0, 1);
    landmarks[Lm.leftElbow] = const PoseLandmark(.2, .4, 0, 1);
    const background = Color(0xFF102030);
    final defaultColor = JCameraCanvasAppearance.dark.observation;
    final changedColor = const Color(0xFFCC4422);
    final pixels = <Color>[];
    for (final spec in <(LiveState, Color, double)>[
      (LiveState.noVerdict, defaultColor, .45),
      (LiveState.noVerdict, changedColor, .45),
      (LiveState.clean, changedColor, .85),
    ]) {
      await tester.pumpWidget(_host(
        Brightness.light,
        _preview(landmarks, appearance: _withObservation(spec.$2),
          state: spec.$1),
      ));
      final painter = _painter(tester);
      // Use the actual preview's painter; no mirrored drawing implementation.
      final pixel = await tester.runAsync<Color>(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(background, BlendMode.src);
        painter.paint(canvas, const Size(100, 100));
        final picture = recorder.endRecording();
        try {
          final image = await picture.toImage(100, 100);
          try {
            final ByteData? bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            expect(bytes, isNotNull);
            final data = bytes!;
            final offset = (20 * 100 + 22) * 4;
            return Color.fromARGB(
              data.getUint8(offset + 3), data.getUint8(offset),
              data.getUint8(offset + 1), data.getUint8(offset + 2),
            );
          } finally {
            image.dispose();
          }
        } finally {
          picture.dispose();
        }
      });
      expect(pixel, isNotNull);
      final actual = pixel!;
      final expected = Color.alphaBlend(
        spec.$2.withValues(alpha: spec.$3), background,
      );
      // Two 8-bit steps allow alpha quantization, not a wrong color role.
      for (final pair in <(double, double)>[
        (actual.r, expected.r), (actual.g, expected.g),
        (actual.b, expected.b), (actual.a, expected.a),
      ]) {
        expect((pair.$1 - pair.$2).abs(), lessThanOrEqualTo(2 / 255));
      }
      expect(actual, isNot(background), reason: 'a missing draw cannot pass');
      pixels.add(actual);
    }
    expect(pixels[0], isNot(pixels[1]),
        reason: 'hard-coded paint color must not pass observation changes');
    expect(pixels[1], isNot(pixels[2]),
        reason: 'no-verdict and clean retain different scene alpha');
    // This definition is UNRUN. It is neither a glyph/golden test nor full
    // caption-overlap, blur, native raster, camera or device acceptance.
  });
}
