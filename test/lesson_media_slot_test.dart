import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/lesson_media_catalog.dart';
import 'package:jablab/app/lesson_media_slot.dart';
import 'package:jablab/app/lesson_media_source_pins_v2k.dart';
import 'package:jablab/app/solo_boxing_course.dart';
import 'package:motion_content/motion_content.dart';

final class _OverlayBundle extends CachingAssetBundle {
  _OverlayBundle(this.overlay);
  final Map<String, Uint8List> overlay;
  final List<String> loadedKeys = [];
  Future<void> Function(String)? beforeLoad;

  @override
  Future<ByteData> load(String key) async {
    loadedKeys.add(key);
    final gate = beforeLoad;
    if (gate != null) await gate(key);
    final bytes = overlay[key];
    return bytes == null ? rootBundle.load(key) : ByteData.sublistView(bytes);
  }
}

final class _Fixture {
  _Fixture() {
    final sourceBytes = File(
      'assets/content/solo_boxing_course.v1.json',
    ).readAsBytesSync();
    course = SoloBoxingCourse.fromJsonString(utf8.decode(sourceBytes));
    lesson = course.lessons.first;
    final json = jsonDecode(utf8.decode(sourceBytes)) as Map<String, dynamic>;
    final module = (json['modules'] as List).first as Map<String, dynamic>;
    final lessonJson = (module['lessons'] as List).first;
    final qa =
        jsonDecode(
              File(
                'test/fixtures/jablab_v2k_source_pins_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final qaLesson = (qa['lessons'] as List).cast<Map<String, dynamic>>().first;
    final qaScene = (qaLesson['scenes'] as List)
        .cast<Map<String, dynamic>>()
        .first;
    final qaVariant = (qaScene['variants'] as List)
        .cast<Map<String, dynamic>>()
        .first;
    assert(qaLesson['lessonId'] == lesson.id);
    pin = LessonMediaSourcePin(
      manifestSha256: qa['manifestSHA256'] as String,
      app: qaLesson['app'] as String,
      assetId: qaLesson['assetId'] as String,
      lessonId: lesson.id,
      sceneId: qaScene['sceneId'] as String,
      variantStem: qaVariant['stem'] as String,
      courseSourceSha256: computeSha256Hex(sourceBytes),
      lessonCanonicalSha256: computeSha256Hex(
        Uint8List.fromList(utf8.encode(canonicalJsonEncode(lessonJson))),
      ),
      productionSpecSha256: qaScene['productionSpecSHA256'] as String,
      sourceCueSha256: qaScene['sourceCueSHA256'] as String,
      idempotencyKey: qaScene['idempotencyKey'] as String,
      productionState: qaScene['productionState'] as String,
      sourcePinSha256: qaVariant['sourcePinSHA256'] as String,
    );
    video = Uint8List.fromList([
      0,
      0,
      0,
      12,
      0x66,
      0x74,
      0x79,
      0x70,
      0x69,
      0x73,
      0x6f,
      0x6d,
    ]);
    tr = Uint8List.fromList(
      utf8.encode(
        'WEBVTT - Motion locale=tr\n\n'
        '00:00:00.000 --> 00:00:00.800\nGardı göster\n',
      ),
    );
    en = Uint8List.fromList(
      utf8.encode(
        'WEBVTT - Motion locale=en\n\n'
        '00:00:00.000 --> 00:00:00.800\nShow your guard\n',
      ),
    );
    final stem = 'assets/content/media/${pin.variantStem}';
    bundle = _OverlayBundle({
      '$stem.mp4': video,
      '$stem.tr.vtt': tr,
      '$stem.en.vtt': en,
    });
    entry = LessonMediaEntry(
      source: pin,
      productionManifestSha256: jablabMediaProductionManifestSha256,
      acceptanceReceiptSha256: 'c' * 64,
      packageReceiptSha256: 'd' * 64,
      video: _file('$stem.mp4', video),
      durationMs: 1000,
      captions: {
        'tr': _file('$stem.tr.vtt', tr),
        'en': _file('$stem.en.vtt', en),
      },
    );
  }

  late final SoloBoxingCourse course;
  late final SoloLesson lesson;
  late final LessonMediaSourcePin pin;
  late final LessonMediaEntry entry;
  late final Uint8List video, tr, en;
  late final _OverlayBundle bundle;

  LessonMediaFile _file(String path, Uint8List bytes) =>
      LessonMediaFile(path, bytes.length, computeSha256Hex(bytes));

  LessonMediaCatalog catalog([List<LessonMediaEntry>? entries]) =>
      LessonMediaCatalog.syntheticForTesting(
        entries: entries ?? [entry],
        sourcePins: [pin],
      );

  LessonMediaSourcePin changedPin({
    String? manifestSha256,
    String? sceneId,
    String? productionSpecSha256,
    String? sourceCueSha256,
    String? idempotencyKey,
    String? sourcePinSha256,
  }) => LessonMediaSourcePin(
    manifestSha256: manifestSha256 ?? pin.manifestSha256,
    app: pin.app,
    assetId: pin.assetId,
    lessonId: pin.lessonId,
    sceneId: sceneId ?? pin.sceneId,
    variantStem: pin.variantStem,
    courseSourceSha256: pin.courseSourceSha256,
    lessonCanonicalSha256: pin.lessonCanonicalSha256,
    productionSpecSha256: productionSpecSha256 ?? pin.productionSpecSha256,
    sourceCueSha256: sourceCueSha256 ?? pin.sourceCueSha256,
    idempotencyKey: idempotencyKey ?? pin.idempotencyKey,
    productionState: pin.productionState,
    sourcePinSha256: sourcePinSha256 ?? pin.sourcePinSha256,
  );

  LessonMediaCatalog catalogForPin(LessonMediaSourcePin candidate) =>
      LessonMediaCatalog.syntheticForTesting(
        entries: [
          LessonMediaEntry(
            source: candidate,
            productionManifestSha256: jablabMediaProductionManifestSha256,
            acceptanceReceiptSha256: entry.acceptanceReceiptSha256,
            packageReceiptSha256: entry.packageReceiptSha256,
            video: entry.video,
            durationMs: entry.durationMs,
            captions: entry.captions,
          ),
        ],
        sourcePins: [candidate],
      );

  String calculatedPinSha(LessonMediaSourcePin candidate) => computeSha256Hex(
    Uint8List.fromList(
      utf8.encode(
        canonicalJsonEncode({
          'manifestSHA256': candidate.manifestSha256,
          'app': candidate.app,
          'courseSourceSHA256': candidate.courseSourceSha256,
          'lessonId': candidate.lessonId,
          'lessonCanonicalSHA256': candidate.lessonCanonicalSha256,
          'assetId': candidate.assetId,
          'sceneId': candidate.sceneId,
          'variantStem': candidate.variantStem,
          'productionSpecSHA256': candidate.productionSpecSha256,
          'sourceCueSHA256': candidate.sourceCueSha256,
          'idempotencyKey': candidate.idempotencyKey,
          'productionState': candidate.productionState,
        }),
      ),
    ),
  );

  Future<InspectedLessonMedia?> inspect([LessonMediaCatalog? catalog]) =>
      (catalog ?? this.catalog()).inspect(
        bundle: bundle,
        course: course,
        lesson: lesson,
        sceneId: pin.sceneId,
        variantStem: pin.variantStem,
      );
}

final class _FakePort implements LessonPlaybackPort {
  final calls = <String>[];
  final ValueNotifier<Duration> time = ValueNotifier(Duration.zero);
  Completer<void>? pauseGate;
  Completer<void>? playGate;
  Completer<void>? initializeGate;
  void Function()? onInitialize;
  void Function()? onPlay;
  void Function()? onPause;

  @override
  ValueListenable<Duration> get position => time;

  @override
  double get aspectRatio => 16 / 9;

  @override
  Widget buildVideo() => const ColoredBox(color: Colors.black);

  @override
  Future<Duration?> initializeMuted() {
    calls.add('initialize-muted');
    onInitialize?.call();
    final gate = initializeGate;
    if (gate != null) {
      return gate.future.then((_) => const Duration(milliseconds: 1000));
    }
    return Future<Duration?>.value(const Duration(milliseconds: 1000));
  }

  @override
  Future<void> play() {
    calls.add('play');
    onPlay?.call();
    return playGate?.future ?? Future<void>.value();
  }

  @override
  Future<void> pause() {
    calls.add('pause');
    onPause?.call();
    return pauseGate?.future ?? Future<void>.value();
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipping catalogue has no media', () async {
    final fixture = _Fixture();
    expect(await fixture.inspect(const LessonMediaCatalog.empty()), isNull);
  });

  test(
    'test-only asset inspection binds course, bytes and both languages',
    () async {
      final fixture = _Fixture();
      final media = await fixture.inspect();
      expect(media, isNotNull);
      expect(media!.path, fixture.entry.video.path);
      expect(media.captions['tr']!.single.text, 'Gardı göster');
      expect(media.captions['en']!.single.text, 'Show your guard');
      expect(media.progressEffect, 0);
    },
  );

  test(
    'closed QA rejects v2d/v2g manifest and relabelled old source',
    () async {
      final fixture = _Fixture();
      expect(
        jablabMediaProductionManifestSha256,
        jablabV2kSourcePinManifestSha256,
      );
      expect(await fixture.inspect(), isNotNull);
      for (final oldManifest in [
        'deb767cc1060cb475bf5664e0c662b44b0a0ad8318288b4e65faa3c472cb6324',
        '21008cbf5a58d01c3ef4a12c879f1b6da4e8d8ea5111f8340d53d35f9ec02c8b',
        '5399b0fd21bd7148de9c845ecaf288e391fef4c6e2ae98503fd9134fd39e8628',
      ]) {
        final old = fixture.changedPin(manifestSha256: oldManifest);
        expect(await fixture.inspect(fixture.catalogForPin(old)), isNull);
      }
      for (final oldSpec in [
        '61854b5dc96f2a7e303bf692670d1354e0a8ce493e9a51cf66d0f8e8b5e493d2',
        '5260039a567198b2c90149da0e39cf53cc67b0dfa833fd4f5ae9901c3c6565a3',
      ]) {
        final relabelled = fixture.changedPin(
          productionSpecSha256: oldSpec,
          idempotencyKey: 'motion-media-v1:$oldSpec',
        );
        expect(
          await fixture.inspect(fixture.catalogForPin(relabelled)),
          isNull,
        );
        final forged = fixture.changedPin(
          productionSpecSha256: oldSpec,
          idempotencyKey: 'motion-media-v1:$oldSpec',
          sourcePinSha256: fixture.calculatedPinSha(relabelled),
        );
        expect(forged.sourcePinSha256, isNot(relabelled.sourcePinSha256));
        expect(await fixture.inspect(fixture.catalogForPin(forged)), isNull);
      }
      final fakePin = fixture.changedPin(sourcePinSha256: '0' * 64);
      expect(await fixture.inspect(fixture.catalogForPin(fakePin)), isNull);
    },
  );

  test(
    'changed media, missing subtitle and duplicate scene fail closed',
    () async {
      final fixture = _Fixture();
      fixture.bundle.overlay[fixture.entry.video.path] = Uint8List.fromList([
        ...fixture.video.sublist(0, 11),
        0,
      ]);
      expect(await fixture.inspect(), isNull);
      fixture.bundle.overlay[fixture.entry.video.path] = fixture.video;
      fixture.bundle.overlay.remove(fixture.entry.captions['en']!.path);
      expect(await fixture.inspect(), isNull);
      expect(
        await fixture.inspect(fixture.catalog([fixture.entry, fixture.entry])),
        isNull,
      );
    },
  );

  test('caption timing outside the inspected video is rejected', () async {
    final fixture = _Fixture();
    final badCaption = Uint8List.fromList(
      utf8.encode(
        'WEBVTT - Motion locale=tr\n\n'
        '00:00:00.000 --> 00:00:01.500\nGardı göster\n',
      ),
    );
    final trPath = fixture.entry.captions['tr']!.path;
    fixture.bundle.overlay[trPath] = badCaption;
    final invalid = LessonMediaEntry(
      source: fixture.pin,
      productionManifestSha256: jablabMediaProductionManifestSha256,
      acceptanceReceiptSha256: 'c' * 64,
      packageReceiptSha256: 'd' * 64,
      video: fixture.entry.video,
      durationMs: 1000,
      captions: {
        'tr': LessonMediaFile(
          trPath,
          badCaption.length,
          computeSha256Hex(badCaption),
        ),
        'en': fixture.entry.captions['en']!,
      },
    );
    expect(await fixture.inspect(fixture.catalog([invalid])), isNull);
  });

  test('caller cannot swap caption path during async inspection', () async {
    final fixture = _Fixture();
    final originalTr = fixture.entry.captions['tr']!;
    final callerCaptions = <String, LessonMediaFile>{
      'tr': originalTr,
      'en': fixture.entry.captions['en']!,
    };
    final entry = LessonMediaEntry(
      source: fixture.pin,
      productionManifestSha256: jablabMediaProductionManifestSha256,
      acceptanceReceiptSha256: 'c' * 64,
      packageReceiptSha256: 'd' * 64,
      video: fixture.entry.video,
      durationMs: 1000,
      captions: callerCaptions,
    );
    final wrongPath = 'assets/other-media/${fixture.pin.variantStem}.tr.vtt';
    fixture.bundle.overlay[wrongPath] = fixture.tr;
    final videoLoadStarted = Completer<void>();
    final resumeVideoLoad = Completer<void>();
    fixture.bundle.beforeLoad = (key) async {
      if (key == entry.video.path) {
        videoLoadStarted.complete();
        await resumeVideoLoad.future;
      }
    };

    final inspection = fixture.inspect(fixture.catalog([entry]));
    await videoLoadStarted.future.timeout(const Duration(seconds: 10));
    callerCaptions['tr'] = LessonMediaFile(
      wrongPath,
      originalTr.bytes,
      originalTr.sha256,
    );
    expect(entry.captions['tr'], same(originalTr));
    expect(
      () => entry.captions['tr'] = callerCaptions['tr']!,
      throwsUnsupportedError,
    );
    resumeVideoLoad.complete();

    final media = await inspection;
    expect(media, isNotNull);
    expect(media!.captions['tr']!.single.text, 'Gardı göster');
    expect(fixture.bundle.loadedKeys, isNot(contains(wrongPath)));
  });

  test('an unselected wrong-root row closes the whole catalog', () async {
    final fixture = _Fixture();
    final otherPin = fixture.changedPin(sceneId: 'unselected-scene');
    final wrongStem = 'assets/content/other/${otherPin.variantStem}';
    final malformed = LessonMediaEntry(
      source: otherPin,
      productionManifestSha256: jablabMediaProductionManifestSha256,
      acceptanceReceiptSha256: 'c' * 64,
      packageReceiptSha256: 'd' * 64,
      video: fixture._file('$wrongStem.mp4', fixture.video),
      durationMs: 1000,
      captions: {
        'tr': fixture._file('$wrongStem.tr.vtt', fixture.tr),
        'en': fixture._file('$wrongStem.en.vtt', fixture.en),
      },
    );
    final catalog = fixture.catalog([fixture.entry, malformed]);

    expect(await fixture.inspect(catalog), isNull);
    expect(fixture.bundle.loadedKeys, isEmpty);
  });

  testWidgets('production lesson slot does not create a player', (
    tester,
  ) async {
    final fixture = _Fixture();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot.empty(
            course: fixture.course,
            lesson: fixture.lesson,
            locale: 'tr',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('solo-media-play-pause')), findsNothing);
    expect(find.byKey(const Key('solo-media-caption')), findsNothing);
  });

  testWidgets(
    'test-only player starts muted before play, captions follow time',
    (tester) async {
      final fixture = _Fixture();
      final port = _FakePort();
      final account = ValueNotifier<String?>('account-a');
      addTearDown(account.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonMediaSlot(
              catalog: fixture.catalog(),
              bundle: fixture.bundle,
              course: fixture.course,
              lesson: fixture.lesson,
              sceneId: fixture.pin.sceneId,
              variantStem: fixture.pin.variantStem,
              locale: 'tr',
              accountUserId: account,
              portFactory: (_) => port,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final play = find.byKey(const Key('solo-media-play-pause'));
      expect(play, findsOneWidget);
      expect(port.calls, isEmpty);
      await tester.tap(play);
      await tester.pumpAndSettle();
      expect(port.calls.take(2).toList(), ['initialize-muted', 'play']);
      port.time.value = const Duration(milliseconds: 500);
      await tester.pump();
      expect(find.text('Gardı göster'), findsOneWidget);
      account.value = 'account-b';
      await tester.pump();
      expect(port.calls, contains('dispose'));
      expect(play, findsNothing);
    },
  );

  testWidgets('background return rechecks lesson but never autoplays', (
    tester,
  ) async {
    final fixture = _Fixture();
    final first = _FakePort();
    final second = _FakePort();
    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            portFactory: (_) => created++ == 0 ? first : second,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final play = find.byKey(const Key('solo-media-play-pause'));
    await tester.tap(play);
    await tester.pumpAndSettle();
    expect(first.calls, contains('play'));
    final observer =
        tester.state(find.byType(LessonMediaSlot)) as WidgetsBindingObserver;
    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(first.calls, contains('dispose'));
    expect(play, findsNothing);
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(play, findsOneWidget);
    expect(created, 1);
    await tester.tap(play);
    await tester.pumpAndSettle();
    expect(second.calls.take(2).toList(), ['initialize-muted', 'play']);
  });

  testWidgets('pending pause blocks a second command until it finishes', (
    tester,
  ) async {
    final fixture = _Fixture();
    final port = _FakePort();
    final gate = Completer<void>();
    port.pauseGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            portFactory: (_) => port,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('solo-media-play-pause'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(port.calls.where((call) => call == 'pause'), hasLength(1));
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.play_arrow)),
      findsOneWidget,
    );
  });

  testWidgets('retirement waits for an unfinished pause', (tester) async {
    final fixture = _Fixture();
    final port = _FakePort();
    final gate = Completer<void>();
    port.pauseGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            portFactory: (_) => port,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('solo-media-play-pause'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    final observer =
        tester.state(find.byType(LessonMediaSlot)) as WidgetsBindingObserver;
    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pump();
    expect(port.calls, isNot(contains('dispose')));
    gate.complete();
    await tester.pumpAndSettle();
    expect(port.calls.last, 'dispose');
  });

  testWidgets('synchronous account revocation waits for the pending play', (
    tester,
  ) async {
    final fixture = _Fixture();
    final account = ValueNotifier<String?>('first');
    final port = _FakePort();
    final gate = Completer<void>();
    port.playGate = gate;
    port.onPlay = () => account.value = 'second';
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            accountUserId: account,
            portFactory: (_) => port,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('solo-media-play-pause')));
    await tester.pump();
    expect(port.calls, contains('play'));
    expect(port.calls, isNot(contains('dispose')));

    gate.complete();
    await tester.pumpAndSettle();
    expect(port.calls.last, 'dispose');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    account.dispose();
  });

  testWidgets('synchronous account revocation in factory retires its port', (
    tester,
  ) async {
    final fixture = _Fixture();
    final account = ValueNotifier<String?>('first');
    final port = _FakePort();
    var creations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            accountUserId: account,
            portFactory: (_) {
              creations++;
              account.value = 'second';
              return port;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('solo-media-play-pause')));
    await tester.pumpAndSettle();
    expect(creations, 1);
    expect(port.calls, contains('dispose'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    account.dispose();
  });

  testWidgets('synchronous account revocation waits for initialization', (
    tester,
  ) async {
    final fixture = _Fixture();
    final account = ValueNotifier<String?>('first');
    final port = _FakePort();
    final gate = Completer<void>();
    port.initializeGate = gate;
    port.onInitialize = () => account.value = 'second';
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            accountUserId: account,
            portFactory: (_) => port,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('solo-media-play-pause')));
    await tester.pump();
    expect(port.calls, contains('initialize-muted'));
    expect(port.calls, isNot(contains('dispose')));

    gate.complete();
    await tester.pumpAndSettle();
    expect(port.calls.last, 'dispose');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    account.dispose();
  });

  testWidgets('synchronous account revocation waits for pending pause', (
    tester,
  ) async {
    final fixture = _Fixture();
    final account = ValueNotifier<String?>('first');
    final port = _FakePort();
    final gate = Completer<void>();
    port.pauseGate = gate;
    port.onPause = () => account.value = 'second';
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            accountUserId: account,
            portFactory: (_) => port,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('solo-media-play-pause'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(port.calls, contains('pause'));
    expect(port.calls, isNot(contains('dispose')));

    gate.complete();
    await tester.pumpAndSettle();
    expect(port.calls.last, 'dispose');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    account.dispose();
  });

  testWidgets('new route waits for the prior native player to retire', (
    tester,
  ) async {
    final fixture = _Fixture();
    final first = _FakePort();
    final second = _FakePort();
    final gate = Completer<void>();
    var created = 0;
    Widget route() => MaterialApp(
      home: Scaffold(
        body: LessonMediaSlot(
          catalog: fixture.catalog(),
          bundle: fixture.bundle,
          course: fixture.course,
          lesson: fixture.lesson,
          sceneId: fixture.pin.sceneId,
          variantStem: fixture.pin.variantStem,
          locale: 'tr',
          portFactory: (_) => created++ == 0 ? first : second,
        ),
      ),
    );
    await tester.pumpWidget(route());
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('solo-media-play-pause'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    first.pauseGate = gate;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(route());
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(created, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(first.calls.last, 'dispose');
    expect(created, 2);
    expect(second.calls, contains('play'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(second.calls.last, 'dispose');
  });

  testWidgets('hung native play cannot hold retirement forever', (
    tester,
  ) async {
    final fixture = _Fixture();
    final port = _FakePort();
    final gate = Completer<void>();
    port.playGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMediaSlot(
            catalog: fixture.catalog(),
            bundle: fixture.bundle,
            course: fixture.course,
            lesson: fixture.lesson,
            sceneId: fixture.pin.sceneId,
            variantStem: fixture.pin.variantStem,
            locale: 'tr',
            portFactory: (_) {
              created++;
              return port;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('solo-media-play-pause')));
    await tester.pump();
    expect(port.calls, contains('play'));
    final observer =
        tester.state(find.byType(LessonMediaSlot)) as WidgetsBindingObserver;
    observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pump();
    expect(port.calls, isNot(contains('dispose')));
    await tester.pump(const Duration(seconds: 3));
    expect(port.calls, contains('pause'));
    expect(port.calls, contains('dispose'));
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    gate.complete();
    await tester.pumpAndSettle();
    expect(created, 1);
    expect(find.byKey(const Key('solo-media-play-pause')), findsNothing);
  });
}
