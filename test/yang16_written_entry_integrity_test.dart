import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_store.dart';
import 'package:jablab/app/owner_resource_lifetime.dart';
import 'package:jablab/app/select_page.dart';
import 'package:jablab/app/session_store.dart';
import 'package:jablab/app/tai_chi_course_page.dart';
import 'package:jablab/app/yang16_written_course_page.dart';
import 'package:motion_content/motion_content.dart';

import 'app_pump.dart';
import 'yang16_test_support.dart';

class _Overlay extends CachingAssetBundle {
  _Overlay(this.overrides);
  final Map<String,Uint8List> overrides;
  @override
  Future<ByteData> load(String key) async {
    final bytes = overrides[key];
    return bytes == null ? rootBundle.load(key) : ByteData.sublistView(bytes);
  }
}
Uint8List _tampered(String path) {
  final bytes = File(path).readAsBytesSync();
  final changed = Uint8List.fromList(bytes);
  changed[changed.length - 1] = bytes.last == 10 ? 32 : 10;
  return changed;
}
Future<void> _tap(WidgetTester t, String key) async {
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(target,500,scrollable:find.byType(Scrollable).first,maxScrolls:200);
  }
  await Scrollable.ensureVisible(t.element(target),alignment:0.5);
  await t.pumpAndSettle(); await t.tap(target.hitTestable()); await t.pump();
}
Future<void> _root(WidgetTester t, _History history, {ValueNotifier<String?>? owner,
  ValueNotifier<bool>? recovery, AssetBundle? bundle}) async {
  final directory = Directory.systemTemp.createTempSync('yang16-real-root-');
  addTearDown(() => directory.deleteSync(recursive:true));
  await t.runAsync(() => t.pumpWidget(JabLabApp(
    repository:ContentRepository(historyDirectoryOverride:directory,storeOverride:history,
      ownerRegistry:OwnerResourceRegistry(),contentBundleOverride:bundle),
    onboarding:const OnboardingStore(seenOverride:true),accountUserId:owner,accountRecovery:recovery)));
  await settleAppLoad(t);
}
Future<void> _tai(WidgetTester t) async {
  await _tap(t,'open-tai-chi-course');
  await settleUntil(t,find.byKey(const Key('tai-chi-course-list')));
  await t.pumpAndSettle();
}
Future<void> _yang(WidgetTester t) async {
  await _tai(t); await _tap(t,'open-yang16-written-course');
  await settleUntil(t,find.byKey(const Key('yang16-course-list'))); await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('actual Core-verified assets preserve all111 original lessons and their six exact pins', () async {
    const repository = ContentRepository();
    final yang = await repository.loadYang16WrittenCourse();
    expect(yang.targets,hasLength(24)); expect(yang.boundaries,hasLength(17));
    expect(yang.physicalPracticeAvailable,isFalse); expect(yang.reviewReadiness.values,everyElement(isFalse));
    final boxing = await repository.loadSoloBoxingCourse();
    final tai = await repository.loadTaiChiCourse(); final kick = await repository.loadKickboxingCourse();
    final karate = await repository.loadKarateCourse(); final muay = await repository.loadMuayThaiCourse();
    final kata = await repository.loadTaikyokuCourse();
    expect([boxing.lessons.length,tai.lessons.length,kick.lessons.length,karate.lessons.length,
      muay.lessons.length,kata.lessons.length],[39,14,16,16,16,10]);
    final pins = {
      ContentRepository.soloBoxingCourseAsset:'0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f',
      ContentRepository.taiChiCourseAsset:'c1d98507e9517daf6ccc514465ba98a44eb24a2c639a3968a6648869c372f47b',
      ContentRepository.kickboxingCourseAsset:'00b338d0de111ee240cdf1292611db2b8d6c3e5654800fc8967c5dfb52042fa3',
      ContentRepository.karateCourseAsset:'e9b3555f09a77eb20f5756ad4cefc647e2e32415b5f6f18bca7c80ef3b4b55b0',
      ContentRepository.muayThaiCourseAsset:'ee16b7fe958d45c08bdcef399147a2569d33b566110f3fc4675d2971ec403531',
      ContentRepository.taikyokuCourseAsset:'56ba6480867e8bf3481b1e5fbe1b11b9ef21970ed362e546c389790901f94f92',
    };
    for (final entry in pins.entries) {
      expect(computeSha256Hex(File(entry.key).readAsBytesSync()),entry.value);
    }
  });

  for (final path in [ContentRepository.yang16CourseAsset,ContentRepository.yang16MappingAsset]) {
    test('same-length tampering of $path is rejected by the actual Core bundle gate', () async {
      final repository = ContentRepository(contentBundleOverride:_Overlay({path:_tampered(path)}));
      await expectLater(repository.loadYang16WrittenCourse(),throwsA(isA<ContentException>()));
    });
    test('rebuilt Core manifest cannot replace the fixed reviewed $path bytes', () async {
      final changed = jsonDecode(File(path).readAsStringSync()) as Map<String,dynamic>;
      if (path == ContentRepository.yang16CourseAsset) {
        changed['reviewReadiness']['physicalMasteryAccepted'] = true;
      } else { changed['translatedFields'][0]['sha256'] = List.filled(64,'0').join(); }
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(changed)));
      final manifest = jsonDecode(File(ContentRepository.yang16IntegrityManifestAsset)
        .readAsStringSync()) as Map<String,dynamic>;
      final row = (manifest['assets'] as List).cast<Map<String,dynamic>>().singleWhere((v) => v['path'] == path);
      row['byteLength'] = bytes.length; row['sha256'] = computeSha256Hex(bytes);
      manifest['catalogDigest'] = computeCatalogDigest(manifest);
      final repository = ContentRepository(contentBundleOverride:_Overlay({path:bytes,
        ContentRepository.yang16IntegrityManifestAsset:Uint8List.fromList(utf8.encode(jsonEncode(manifest)))}));
      await expectLater(repository.loadYang16WrittenCourse(),throwsA(isA<ContentException>()
        .having((e) => e.error.code,'fixed reviewed byte pin',ContentErrorCode.hashMismatch)));
    });
  }

  for (final language in ['tr','en']) {
    for (final current in [false,true]) {
      testWidgets('real ${current ? "current boxing" : "first-run"} Tai Chi→Yang16→written target→back $language preserves original history', (t) async {
        t.platformDispatcher.localeTestValue = Locale(language);
        addTearDown(t.platformDispatcher.clearLocaleTestValue);
        final history = _History(current ? [_boxingRecord()] : []);
        await _root(t,history);
        expect(current ? find.byType(CoursePage) : find.byType(SelectPage),findsOneWidget);
        await _yang(t); await yangTap(t,'yang16-target-prepare');
        expect(find.byType(Yang16WrittenTargetPage),findsOneWidget);
        await yangPrepare(t,yangCourse().targets.first,language:language,correction:true);
        await yangTap(t,'yang16-report-written');
        await t.pageBack(); await t.pumpAndSettle(); await yangProgress(t,1);
        await t.pageBack(); await t.pumpAndSettle();
        expect(find.byKey(const Key('tai-chi-course-list')),findsOneWidget);
        await _tap(t,'tai-chi-lesson-1'); await t.pumpAndSettle();
        expect(find.byType(TaiChiLessonPage),findsOneWidget);
        await t.pageBack(); await t.pumpAndSettle(); await t.pageBack(); await t.pumpAndSettle();
        expect(current ? find.byType(CoursePage) : find.byType(SelectPage),findsOneWidget);
        expect(history.records,hasLength(current ? 1 : 0)); expect(history.appends,0);
        expect(t.takeException(),isNull);
      });
    }
  }

  for (final interruption in ['switch-owner','logout','guest-login','recovery']) {
    for (final targetOpen in [false,true]) {
      testWidgets('real root $interruption retires Yang16 ${targetOpen ? "target" : "overview"} and Tai Chi parent', (t) async {
        final owner = ValueNotifier<String?>(interruption == 'guest-login' ? null
          : '11111111-1111-4111-8111-111111111111');
        final recovery = ValueNotifier<bool>(false);
        addTearDown(owner.dispose); addTearDown(recovery.dispose);
        final history = _History([]); await _root(t,history,owner:owner,recovery:recovery); await _yang(t);
        if (targetOpen) { await yangTap(t,'yang16-target-prepare'); }
        if (interruption == 'recovery') { recovery.value = true; }
        else { owner.value = interruption == 'logout' ? null : '22222222-2222-4222-8222-222222222222'; }
        await t.pump();
        await settleUntil(t,interruption == 'recovery' ? find.text('Account recovery is required.')
          : find.byKey(const Key('open-tai-chi-course'))); await t.pumpAndSettle();
        expect(find.byType(Yang16WrittenCoursePage,skipOffstage:false),findsNothing);
        expect(find.byType(Yang16WrittenTargetPage,skipOffstage:false),findsNothing);
        expect(find.byType(TaiChiCoursePage,skipOffstage:false),findsNothing);
        expect(history.appends,0); expect(t.takeException(),isNull);
      });
    }
  }

  for (final interruption in ['owner','recovery','lifecycle','back']) {
    testWidgets('retained real Tai Chi entry cannot open Yang16 after $interruption interruption', (t) async {
      final owner = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
      final recovery = ValueNotifier<bool>(false);
      addTearDown(owner.dispose); addTearDown(recovery.dispose);
      await _root(t,_History([]),owner:owner,recovery:recovery); await _tai(t);
      await _tapShow(t,'open-yang16-written-course');
      final stale = t.widget<Yang16WrittenEntryCard>(find.byType(Yang16WrittenEntryCard)).onOpen;
      if (interruption == 'owner') { owner.value = '22222222-2222-4222-8222-222222222222'; }
      else if (interruption == 'recovery') { recovery.value = true; }
      else if (interruption == 'lifecycle') { yangPause(t); }
      else { await t.pageBack(); }
      stale(); await t.pump();
      if (interruption == 'owner') {
        await settleUntil(t,find.byKey(const Key('open-tai-chi-course')));
      }
      await t.pumpAndSettle();
      expect(find.byType(Yang16WrittenCoursePage,skipOffstage:false),findsNothing);
      if (interruption == 'lifecycle') { yangResume(t); await t.pumpAndSettle(); }
      else { stale(); await t.pumpAndSettle(); }
      expect(find.byType(Yang16WrittenCoursePage,skipOffstage:false),findsNothing);
      expect(t.takeException(),isNull);
    });
  }

  for (final path in [ContentRepository.yang16CourseAsset,ContentRepository.yang16MappingAsset]) {
    testWidgets('a corrupt actual $path blocks only the new course, with no retry or progress claim', (t) async {
      final history = _History([]); await _root(t,history,bundle:_Overlay({path:_tampered(path)}));
      await _tai(t); await _tap(t,'open-yang16-written-course');
      await settleUntil(t,find.byKey(const Key('yang16-load-failure'))); await t.pumpAndSettle();
      expect(find.byKey(const Key('yang16-course-list')),findsNothing);
      expect(find.byKey(const Key('yang16-written-progress')),findsNothing);
      expect(find.byKey(const Key('yang16-retry')),findsNothing);
      await t.pageBack(); await t.pumpAndSettle();
      expect(find.byKey(const Key('tai-chi-course-list')),findsOneWidget);
      expect(history.appends,0); expect(t.takeException(),isNull);
    });
  }
}

Future<void> _tapShow(WidgetTester t,String key) async {
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(target,500,scrollable:find.byType(Scrollable).first,maxScrolls:200);
  }
  await Scrollable.ensureVisible(t.element(target)); await t.pumpAndSettle();
}
SessionRecord _boxingRecord() => SessionRecord(lessonId:'boxing.foundations.jab',
  completedAt:DateTime.utc(2026,8,1),workedSeconds:30,unitsCompleted:1,
  plannedUnits:2,unitLabel:'round',lessonClass:'unscored');
class _History implements SessionStore {
  _History(this.records); final List<SessionRecord> records; int appends = 0;
  @override
  Future<void> append(SessionRecord record) async { appends++; records.add(record); }
  @override
  Future<List<SessionRecord>> recent({int? limit}) async => records;
  @override
  Future<int> unreadableRecords() async => 0;
  @override
  Future<int> workedSecondsFor(String lessonId) async => records.where((r) => r.lessonId == lessonId)
    .fold<int>(0,(sum,r) => sum+r.workedSeconds);
}
