// Report-only definitions. UNRUN: apply after V1's exact source overlay first.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/self_guided_practice.dart';
import 'package:jablab/app/self_guided_practice_panel.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/tai_chi_course_page.dart';
import 'package:jablab/app/yang16_preparation_course.dart';
import 'package:jablab/app/yang16_written_course_page.dart';

import 'app_pump.dart';
import 'yang16_test_support.dart' show yangCourse, yangPause, yangResume;

// Only the preparation manifest await is controlled. The actual repository,
// Core manifest/hash validation, preparation decoder and root routes still run.
// Exact manifest/course bytes come from the applied source, never a synthetic
// receipt or altered course. Other banks use the normal Flutter root bundle.
class _PreparationBundle extends CachingAssetBundle {
  final requests = <Completer<ByteData>>[];
  final successfullyCompleted = <int>{};
  int preparationAssetReads = 0;
  bool closed = false;

  @override
  Future<ByteData> load(String key) async {
    if (key == ContentRepository.yang16PreparationManifestAsset) {
      final request = Completer<ByteData>();
      requests.add(request);
      return request.future;
    }
    if (key == ContentRepository.yang16PreparationAsset) {
      preparationAssetReads++;
      return ByteData.sublistView(File(key).readAsBytesSync());
    }
    return rootBundle.load(key);
  }

  void succeed(int index) {
    successfullyCompleted.add(index);
    requests[index].complete(ByteData.sublistView(File(
      ContentRepository.yang16PreparationManifestAsset,
    ).readAsBytesSync()));
  }

  void fail(int index) {
    requests[index].completeError(StateError('Controlled preparation read failure'));
  }

  void finishPendingAfterUnmount() {
    for (var index = 0; index < requests.length; index++) {
      if (!requests[index].isCompleted) succeed(index);
    }
  }
}

class _History implements SessionStore {
  int appends = 0;

  @override
  Future<void> append(SessionRecord record) async {
    appends++;
  }

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => <SessionRecord>[];

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
}

// Same 40 x 50 ms real-I/O ceiling as app_pump.dart, with an explicit failure.
// A controlled pending preparation request is never awaited by this helper.
Future<void> _until(
  WidgetTester tester,
  bool Function() ready,
  String description,
) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump();
    if (ready()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
  }
  throw TestFailure('Bounded root state did not become ready: $description');
}

// Close before the widget-test body's pending-timer invariant is checked.
// Real Core has a 5s Future.timeout for both manifest and asset reads. Current
// Core reads each successful asset once for verification and once for decode.
// No timer is disabled/extended; all owned futures must finish in this body.
Future<void> _closeRoot(
  WidgetTester tester,
  _PreparationBundle bundle,
) async {
  if (bundle.closed) return;
  await tester.pumpWidget(const SizedBox.shrink());
  bundle.finishPendingAfterUnmount();
  await _until(
    tester,
    () => bundle.preparationAssetReads == bundle.successfullyCompleted.length * 2,
    'all successful owned preparations completed validation and validated read',
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  bundle.closed = true;
}

Future<void> _show(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  Finder? activeBody;
  for (final bodyKey in [
    'yang16-target-body',
    'yang16-course-list',
    'tai-chi-course-list',
  ]) {
    final body = find.byKey(Key(bodyKey));
    if (body.evaluate().isNotEmpty) {
      activeBody = body;
      break;
    }
  }
  final scrollable = activeBody == null
      ? find.byType(Scrollable).first
      : find.descendant(of: activeBody, matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: scrollable,
      maxScrolls: 40,
    );
  }
  expect(target, findsOneWidget, reason: key);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.2);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _show(tester, key);
  await tester.tap(find.byKey(Key(key)).hitTestable());
  await tester.pump();
}

Future<_History> _root(
  WidgetTester tester,
  _PreparationBundle bundle, {
  ValueNotifier<String?>? owner,
}) async {
  final directory = Directory.systemTemp.createTempSync('yang-preparation-root-');
  final history = _History();
  addTearDown(() => directory.deleteSync(recursive: true));
  // Fallback only: every successful test body also awaits _closeRoot in finally.
  addTearDown(() => _closeRoot(tester, bundle));
  await tester.runAsync(() => tester.pumpWidget(JabLabApp(
    repository: ContentRepository(
      historyDirectoryOverride: directory,
      storeOverride: history,
      ownerRegistry: OwnerResourceRegistry(),
      contentBundleOverride: bundle,
    ),
    onboarding: const OnboardingStore(seenOverride: true),
    accountUserId: owner,
  )));
  await settleAppLoad(tester);
  expect(find.byType(JabLabApp), findsOneWidget);
  return history;
}

Future<void> _openTarget(WidgetTester tester, String id) async {
  await _tap(tester, 'open-tai-chi-course');
  await _until(
    tester,
    () => find.byKey(const Key('tai-chi-course-list')).evaluate().isNotEmpty,
    'actual Tai Chi overview',
  );
  expect(find.byType(TaiChiCoursePage), findsOneWidget);
  await _show(tester, 'open-yang16-written-course');
  final entry = tester.widget<ListTile>(
    find.byKey(const Key('open-yang16-written-course')),
  );
  expect(
    (entry.subtitle! as Text).data,
    'Angela Plarre presentation · written form order only · 18 sections and 6 final targets',
  );
  await _tap(tester, 'open-yang16-written-course');
  await _until(
    tester,
    () => find.byKey(const Key('yang16-course-list')).evaluate().isNotEmpty,
    'actual Yang written overview',
  );
  expect(
    tester.widget<Yang16WrittenCoursePage>(
      find.byType(Yang16WrittenCoursePage),
    ).preparationLoader,
    isNotNull,
  );
  await _tap(tester, 'yang16-target-$id');
  await _until(
    tester,
    () => find.byType(Yang16WrittenTargetPage).evaluate().isNotEmpty,
    'actual written target $id',
  );
}

Yang16WrittenTargetPage _targetPage(WidgetTester tester) =>
    tester.widget<Yang16WrittenTargetPage>(find.byType(Yang16WrittenTargetPage));

// Inspect the supplied ListView children as well as the mounted widget tree.
// A lazy/offscreen panel must never make a stale definition look absent.
SelfGuidedPracticePanel? _declaredPanel(WidgetTester tester) {
  final list = tester.widget<ListView>(
    find.byKey(const Key('yang16-target-body')),
  );
  final children =
      (list.childrenDelegate as SliverChildListDelegate).children;
  final panels = children.whereType<SelfGuidedPracticePanel>().toList();
  expect(panels.length, lessThanOrEqualTo(1));
  return panels.isEmpty ? null : panels.single;
}

void _noPreparation(WidgetTester tester) {
  expect(_targetPage(tester).practice, isNull);
  expect(_declaredPanel(tester), isNull);
  expect(find.byType(SelfGuidedPracticePanel), findsNothing);
}

Future<void> _writtenReadable(WidgetTester tester, String id) async {
  final target = yangCourse().targets.singleWhere((target) => target.id == id);
  expect(_targetPage(tester).target.id, id);
  await _show(tester, 'yang16-target-title');
  expect(
    tester.widget<Text>(find.byKey(const Key('yang16-target-title'))).data,
    target.title.en,
  );
  await _show(tester, 'yang16-reading-0');
  expect(
    tester.widget<Text>(find.byKey(const Key('yang16-reading-0'))).data,
    target.reading.first.en,
  );
  await _show(tester, 'yang16-physical-blocked');
  expect(
    tester.widget<Text>(find.byKey(const Key('yang16-physical-blocked'))).data,
    'Written review and published optional beginner tasks are separate. No checkbox, written answer or self-report validates personal technique or suitability.',
  );
}

Future<void> _realBoundPanel(WidgetTester tester, String id) async {
  final bank = Yang16PreparationCourse.fromJsonString(
    File(ContentRepository.yang16PreparationAsset).readAsStringSync(),
  );
  final expected = bank.forTarget(id)!;
  final page = _targetPage(tester);
  expect(page.target.id, id);
  expect(page.practice?.lessonId, id);
  expect(page.practice?.sourceReviewReceiptId, expected.sourceReviewReceiptId);
  expect(page.practice?.sourceReview, PracticeSourceReview.videoSegments);
  expect(page.practice?.verifiedTechnique, isFalse);
  expect(page.practice?.progressEffect, 0);
  await _show(tester, 'self-guided-practice-panel');
  expect(find.byType(SelfGuidedPracticePanel), findsOneWidget);
  final panel = tester.widget<SelfGuidedPracticePanel>(
    find.byType(SelfGuidedPracticePanel),
  );
  expect(panel.practice, same(page.practice));
  expect(panel.practice.lessonId, id);
  expect(panel.attempt, PracticeAttempt.unrecorded);
  await _show(tester, 'self-guided-task');
  expect(
    tester.widget<Text>(find.byKey(const Key('self-guided-task'))).data,
    expected.task.en,
  );
  await _show(tester, 'self-guided-safety');
  expect(
    tester.widget<Text>(find.byKey(const Key('self-guided-safety'))).data,
    expected.safety.en,
  );
}

String _writtenProgress(WidgetTester tester) {
  final list = tester.widget<ListView>(find.byKey(
    const Key('yang16-course-list'),
    skipOffstage: false,
  ));
  final children =
      (list.childrenDelegate as SliverChildListDelegate).children;
  final progress = children.singleWhere(
    (child) => child.key == const Key('yang16-written-progress'),
  ) as Text;
  return progress.data!;
}

Future<void> _oldPreparationFinished(
  WidgetTester tester,
  _PreparationBundle bundle,
) async {
  final priorReads = bundle.preparationAssetReads;
  bundle.succeed(0);
  await _until(
    tester,
    () => bundle.preparationAssetReads > priorReads,
    'old controlled preparation reached the real validated asset reader',
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const <Locale>[Locale('en')];
    addTearDown(
      TestWidgetsFlutterBinding.instance.platformDispatcher.clearLocalesTestValue,
    );
  });

  testWidgets('real root pending preparation keeps the exact written target readable', (tester) async {
    final bundle = _PreparationBundle();
    final history = await _root(tester, bundle);
    try {
      await _openTarget(tester, 'prepare');
      expect(bundle.requests, hasLength(1));
      expect(bundle.requests.single.isCompleted, isFalse);
      await _writtenReadable(tester, 'prepare');
      _noPreparation(tester);
      expect(history.appends, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await _closeRoot(tester, bundle);
    }
  });

  testWidgets('real root preparation error keeps written reading and independent answer usable', (tester) async {
    final bundle = _PreparationBundle();
    final history = await _root(tester, bundle);
    try {
      await _openTarget(tester, 'prepare');
      expect(bundle.requests, hasLength(1));
      bundle.fail(0);
      await tester.pumpAndSettle();
      await _writtenReadable(tester, 'prepare');
      _noPreparation(tester);
      await _tap(tester, 'yang16-toggle-reading');
      await _show(tester, 'yang16-original-prompt');
      expect(
        tester.widget<Text>(find.byKey(const Key('yang16-original-prompt'))).data,
        yangCourse().targets.first.prompt.en,
      );
      await _show(tester, 'yang16-own-answer');
      expect(
        tester.widget<TextField>(find.byKey(const Key('yang16-own-answer'))).enabled,
        isTrue,
      );
      const answer = 'My independent written reconstruction remains available.';
      await tester.enterText(find.byKey(const Key('yang16-own-answer')), answer);
      expect(
        tester.widget<TextField>(find.byKey(const Key('yang16-own-answer'))).controller!.text,
        answer,
      );
      tester.testTextInput.hide();
      await tester.pump();
      await _show(tester, 'yang16-compare-answer');
      expect(
        tester.widget<TextButton>(find.byKey(const Key('yang16-compare-answer'))).onPressed,
        isNotNull,
      );
      expect(_targetPage(tester).practice, isNull);
      expect(history.appends, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await _closeRoot(tester, bundle);
    }
  });

  testWidgets('real root owner retirement rejects old completion and binds a fresh different target', (tester) async {
    final bundle = _PreparationBundle();
    final owner = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
    addTearDown(owner.dispose);
    final history = await _root(tester, bundle, owner: owner);
    try {
      await _openTarget(tester, 'prepare');
      expect(bundle.requests, hasLength(1));
      owner.value = '22222222-2222-4222-8222-222222222222';
      await _until(
        tester,
        () => find.byType(Yang16WrittenCoursePage, skipOffstage: false).evaluate().isEmpty &&
            find.byType(Yang16WrittenTargetPage, skipOffstage: false).evaluate().isEmpty &&
            find.byType(TaiChiCoursePage, skipOffstage: false).evaluate().isEmpty &&
            find.byKey(const Key('open-tai-chi-course')).evaluate().isNotEmpty,
        'retired old owner routes and admitted new root',
      );
      await _openTarget(tester, 'm01');
      expect(bundle.requests, hasLength(2));
      await _oldPreparationFinished(tester, bundle);
      await _writtenReadable(tester, 'm01');
      _noPreparation(tester);
      expect(bundle.requests[1].isCompleted, isFalse);
      bundle.succeed(1);
      await _until(tester, () => _targetPage(tester).practice != null, 'new owner preparation');
      await _realBoundPanel(tester, 'm01');
      final progressBefore = _writtenProgress(tester);
      expect(
        progressBefore,
        '0/24 full written targets self-reported this visit; optional attempts do not change this count.',
      );
      await _tap(tester, 'self-guided-attempt-attempted');
      await tester.pumpAndSettle();
      final attempt = tester.widget<RadioGroup<PracticeAttempt>>(find.descendant(
        of: find.byType(SelfGuidedPracticePanel),
        matching: find.byType(RadioGroup<PracticeAttempt>),
      ));
      expect(attempt.groupValue, PracticeAttempt.attempted);
      expect(_writtenProgress(tester), progressBefore);
      expect(_writtenProgress(tester), contains('0/24'));
      expect(history.appends, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await _closeRoot(tester, bundle);
    }
  });

  testWidgets('real root pause invalidates pending generation and only fresh resume completion adds its panel', (tester) async {
    final bundle = _PreparationBundle();
    final history = await _root(tester, bundle);
    try {
      await _openTarget(tester, 'prepare');
      expect(bundle.requests, hasLength(1));
      yangPause(tester);
      await tester.pump();
      _noPreparation(tester);
      yangResume(tester);
      await _until(tester, () => bundle.requests.length == 2, 'fresh resume preparation request');
      await _oldPreparationFinished(tester, bundle);
      await _writtenReadable(tester, 'prepare');
      _noPreparation(tester);
      expect(bundle.requests[1].isCompleted, isFalse);
      bundle.succeed(1);
      await _until(tester, () => _targetPage(tester).practice != null, 'current resumed preparation');
      await _realBoundPanel(tester, 'prepare');
      expect(history.appends, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await _closeRoot(tester, bundle);
    }
  });
}
