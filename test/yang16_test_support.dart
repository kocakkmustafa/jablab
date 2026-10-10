import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/yang16_written_course.dart';
import 'package:jablab/app/yang16_written_course_page.dart';

Yang16WrittenCourse yangCourse() => Yang16WrittenCourse.fromVerifiedStrings(
  File(ContentRepository.yang16CourseAsset).readAsStringSync(),
  File(ContentRepository.yang16MappingAsset).readAsStringSync(),
);

String yangText(Yang16Copy copy, String language) => language == 'tr' ? copy.tr : copy.en;

Future<void> yangOpen(WidgetTester t, {ValueNotifier<String?>? owner,
  ValueNotifier<bool>? admission, NavigatorObserver? observer,
  Future<Yang16WrittenCourse> Function()? loader, double scale = 1}) async {
  final load = loader ?? () async => yangCourse();
  await t.pumpWidget(MaterialApp(
    navigatorObservers: observer == null ? [] : [observer],
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context)
      .copyWith(textScaler: TextScaler.linear(scale)), child: child!),
    home: Builder(builder: (context) => Scaffold(body: TextButton(
      child: const Text('Open'), onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => Yang16WrittenCoursePage(
          loader: load, accountUserId: owner, resourceAdmission: admission)),
      ),
    ))),
  ));
  await t.tap(find.text('Open'));
  if (loader == null) { await t.pumpAndSettle(); } else { await t.pump(); }
}

Future<void> yangShow(WidgetTester t, String key, {bool fromTop = true}) async {
  final body = find.byKey(Key(find.byKey(const Key('yang16-target-body')).evaluate().isNotEmpty
    ? 'yang16-target-body' : 'yang16-course-list'));
  final scrollable = find.descendant(of: body, matching: find.byType(Scrollable)).first;
  if (fromTop) { t.state<ScrollableState>(scrollable).position.jumpTo(0); await t.pump(); }
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(target, 200, scrollable: scrollable, maxScrolls: 1500);
  }
  await Scrollable.ensureVisible(t.element(target), alignment: 0.1);
  await t.pumpAndSettle();
}

Future<void> yangTap(WidgetTester t, String key) async {
  await yangShow(t, key);
  await t.tap(find.byKey(Key(key)).hitTestable());
  await t.pumpAndSettle();
}

Future<void> yangWrite(WidgetTester t, String key, String value) async {
  await yangShow(t, key);
  await t.enterText(find.byKey(Key(key)), value);
  t.testTextInput.hide();
  await t.pumpAndSettle();
}

Future<void> yangExact(WidgetTester t, String key, Yang16Copy copy, String language) async {
  await yangShow(t, key);
  expect(t.widget<Text>(find.byKey(Key(key))).data, yangText(copy, language));
  expect(t.takeException(), isNull, reason: 'Text layout at $key');
}

Future<void> yangDisabled(WidgetTester t, String key) async {
  await yangShow(t, key);
  expect(t.widget<TextButton>(find.byKey(Key(key))).onPressed, isNull);
}

// Inspect the supplied children as well as mounted/semantics-visible widgets:
// a lazy ListView must not make a present answer look hidden merely offscreen.
bool yangHasChildKey(WidgetTester t, String key) {
  final list = t.widget<ListView>(find.byKey(const Key('yang16-target-body')));
  bool contains(Widget widget) {
    if (widget.key == Key(key)) return true;
    if (widget is Padding) return contains(widget.child!);
    return false;
  }
  return (list.childrenDelegate as SliverChildListDelegate).children.any(contains);
}

Future<void> yangPrepare(WidgetTester t, Yang16Target target, {String language = 'en',
  bool correction = false}) async {
  await yangTap(t, 'yang16-toggle-reading');
  await yangWrite(t, 'yang16-own-answer', correction ? 'Incomplete own reconstruction.'
    : yangText(target.answer, language));
  await yangTap(t, 'yang16-compare-answer');
  if (correction) {
    await yangTap(t, 'yang16-needs-correction');
    await yangWrite(t, 'yang16-own-correction', yangText(target.correction, language));
    await yangTap(t, 'yang16-start-retest');
    await yangWrite(t, 'yang16-retest-answer', yangText(target.answer, language));
    await yangTap(t, 'yang16-compare-answer');
  }
  for (var i = 0; i < target.facts.length; i++) { await yangTap(t, 'yang16-fact-$i'); }
}

Future<void> yangProgress(WidgetTester t, int count) async {
  await yangShow(t, 'yang16-written-progress');
  expect(t.widget<Text>(find.byKey(const Key('yang16-written-progress'))).data,
    contains('$count/24'));
}

void yangPause(WidgetTester t) {
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    t.binding.handleAppLifecycleStateChanged(state);
  }
}
void yangResume(WidgetTester t) {
  for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    t.binding.handleAppLifecycleStateChanged(state);
  }
}

class YangPushObserver extends NavigatorObserver {
  VoidCallback? next;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final action = next; next = null; action?.call();
  }
}
