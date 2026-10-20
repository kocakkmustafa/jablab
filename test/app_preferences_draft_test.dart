// Preference codec, serialized disk and controller fault contracts; no device or provider acceptance.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/app_preferences.dart';
import 'package:jablab/app/app_preferences_controller.dart';
import 'package:jablab/app/app_preferences_store.dart';

AppPreferencesCodec codec() => AppPreferencesCodec(
  supportedLocaleTags: const [
    'tr',
    'en',
    'es-419',
    'pt-BR',
    'de',
    'fr',
    'ja',
    'ar',
  ],
);

void main() {
  test('all explicit modes and device locale roundtrip with strict schema', () {
    final c = codec();
    for (final mode in AppThemePreference.values) {
      for (final locale in <String?>[null, 'tr', 'es-419', 'pt-BR', 'ar']) {
        final value = AppPreferences(theme: mode, localeTag: locale);
        expect(c.decode(c.encode(value)), value);
      }
    }
    final invalid = <Object?>[
      [],
      {'schemaVersion': 2, 'theme': 'dark', 'locale': 'tr'},
      {'schemaVersion': 1.0, 'theme': 'dark', 'locale': 'tr'},
      {'schemaVersion': 1, 'theme': 'auto', 'locale': 'tr'},
      {'schemaVersion': 1, 'theme': 'light', 'locale': 12},
      {'schemaVersion': 1, 'theme': 'light', 'locale': 'fr-CA'},
      {'schemaVersion': 1, 'theme': 'light', 'locale': 'ko'},
      {'schemaVersion': 1, 'theme': 'light', 'locale': null, 'other': true},
      {'schemaVersion': 1, 'theme': 'light'},
    ];
    for (final raw in invalid) {
      expect(
        () => c.decode(utf8.encode(jsonEncode(raw))),
        throwsFormatException,
      );
    }
    expect(
      () => c.decode(List.filled(AppPreferencesCodec.maxBytes + 1, 32)),
      throwsFormatException,
    );
    expect(() => c.decode([0xff]), throwsFormatException);
    expect(() => c.decode(utf8.encode('{')), throwsFormatException);
  });

  test(
    'fixed14 canonical tags become valid only with the actually enabled set',
    () {
      const tags = [
        'tr',
        'en',
        'es-419',
        'pt-BR',
        'de',
        'fr',
        'ja',
        'ar',
        'it',
        'ko',
        'id',
        'pl',
        'hi',
        'zh-Hans',
      ];
      final c = AppPreferencesCodec(supportedLocaleTags: tags);
      for (final tag in tags) {
        final value = AppPreferences(localeTag: tag);
        expect(c.decode(c.encode(value)), value);
      }
      expect(
        () => c.encode(const AppPreferences(localeTag: 'zh-Hant')),
        throwsFormatException,
      );
      expect(
        () => c.encode(const AppPreferences(localeTag: 'zh')),
        throwsFormatException,
      );
      expect(
        () => codec().encode(const AppPreferences(localeTag: 'ko')),
        throwsFormatException,
      );
    },
  );

  test(
    'file commits serialize and latest complete locale/theme pair survives restart',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final firstCommit = Completer<void>();
      var calls = 0;
      var inCommit = 0;
      var maxInCommit = 0;
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
        commitPrepared: (prepared, committed) async {
          inCommit++;
          if (inCommit > maxInCommit) {
            maxInCommit = inCommit;
          }
          calls++;
          if (calls == 1) {
            await firstCommit.future;
          }
          await prepared.rename(committed.path);
          inCommit--;
        },
      );
      final a = store.write(
        const AppPreferences(theme: AppThemePreference.dark, localeTag: 'ar'),
      );
      final b = store.write(
        const AppPreferences(
          theme: AppThemePreference.light,
          localeTag: 'pt-BR',
        ),
      );
      firstCommit.complete();
      expect((await a).kind, PreferencesWriteKind.committed);
      expect((await b).kind, PreferencesWriteKind.committed);
      expect(maxInCommit, 1);
      final reopened = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
      );
      final read = await reopened.read();
      expect(read.kind, PreferencesReadKind.loaded);
      expect(
        read.value,
        const AppPreferences(
          theme: AppThemePreference.light,
          localeTag: 'pt-BR',
        ),
      );
    },
  );

  test(
    'failed commit keeps all previous committed bytes; retry uses current pair',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final good = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
      );
      const before = AppPreferences(
        theme: AppThemePreference.dark,
        localeTag: 'tr',
      );
      expect((await good.write(before)).kind, PreferencesWriteKind.committed);
      final directory = Directory(
        '${support.path}/${FileAppPreferencesStore.directoryName}',
      );
      final oldFile = (await directory.list().toList())
          .whereType<File>()
          .single;
      final oldBytes = await oldFile.readAsBytes();
      final bad = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
        commitPrepared: (prepared, committed) async {
          throw const FileSystemException('injected before commit');
        },
      );
      expect(
        (await bad.write(
          const AppPreferences(
            theme: AppThemePreference.light,
            localeTag: 'ar',
          ),
        )).kind,
        PreferencesWriteKind.failed,
      );
      expect(await oldFile.readAsBytes(), orderedEquals(oldBytes));
      expect((await good.read()).value, before);
      expect(
        (await good.write(
          const AppPreferences(
            theme: AppThemePreference.system,
            localeTag: 'fr',
          ),
        )).kind,
        PreferencesWriteKind.committed,
      );
      expect((await good.read()).value, const AppPreferences(localeTag: 'fr'));
    },
  );

  test(
    'exception after commit is confirmed by exact immutable readback',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
        commitPrepared: (prepared, committed) async {
          await prepared.rename(committed.path);
          throw const FileSystemException('injected after commit');
        },
      );
      const desired = AppPreferences(
        theme: AppThemePreference.light,
        localeTag: 'ja',
      );
      expect((await store.write(desired)).kind, PreferencesWriteKind.committed);
      expect((await store.read()).value, desired);
    },
  );

  test(
    'corrupt latest falls back visibly; pending files are never read',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
      );
      const good = AppPreferences(
        theme: AppThemePreference.dark,
        localeTag: 'en',
      );
      await store.write(good);
      final directory = Directory(
        '${support.path}/${FileAppPreferencesStore.directoryName}',
      );
      await File(
        '${directory.path}/prefs-v1-0000000000000002.json',
      ).writeAsString('{');
      await File(
        '${directory.path}/pending-99-interrupted',
      ).writeAsBytes(codec().encode(const AppPreferences(localeTag: 'ar')));
      final read = await store.read();
      expect(read.kind, PreferencesReadKind.recovered);
      expect(read.value, good);
    },
  );

  test(
    'successful writes retain two valid generations; unrelated files are untouched',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
      );
      final marker = File('${support.path}/sessions.jsonl');
      await marker.writeAsString('preserve-training-data');
      for (final theme in [
        AppThemePreference.dark,
        AppThemePreference.light,
        AppThemePreference.system,
      ]) {
        expect(
          (await store.write(AppPreferences(theme: theme))).kind,
          PreferencesWriteKind.committed,
        );
      }
      final directory = Directory(
        '${support.path}/${FileAppPreferencesStore.directoryName}',
      );
      expect((await directory.list().toList()).whereType<File>().length, 2);
      expect(await marker.readAsString(), 'preserve-training-data');
    },
  );

  test(
    'invalid write is rejected before directory or saved data changes',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
      );
      expect(
        (await store.write(const AppPreferences(localeTag: 'unknown'))).kind,
        PreferencesWriteKind.failed,
      );
      expect(
        await Directory(
          '${support.path}/${FileAppPreferencesStore.directoryName}',
        ).exists(),
        false,
      );
    },
  );

  test(
    'oversized latest is bounded and recovered; excessive directory entries fail visibly',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'jablab-prefs-draft-',
      );
      addTearDown(() => support.delete(recursive: true));
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async => support,
      );
      const good = AppPreferences(
        theme: AppThemePreference.dark,
        localeTag: 'tr',
      );
      await store.write(good);
      final directory = Directory(
        '${support.path}/${FileAppPreferencesStore.directoryName}',
      );
      await File(
        '${directory.path}/prefs-v1-0000000000000002.json',
      ).writeAsBytes(List.filled(AppPreferencesCodec.maxBytes + 20, 32));
      final recovered = await store.read();
      expect(recovered.kind, PreferencesReadKind.recovered);
      expect(recovered.value, good);
      for (var i = 0; i < 33; i++) {
        await File(
          '${directory.path}/pending-interrupted-$i',
        ).writeAsString('');
      }
      expect((await store.read()).kind, PreferencesReadKind.invalid);
      expect(
        (await store.write(const AppPreferences(localeTag: 'ar'))).kind,
        PreferencesWriteKind.failed,
      );
      expect(
        codec().decode(
          await File(
            '${directory.path}/prefs-v1-0000000000000001.json',
          ).readAsBytes(),
        ),
        good,
      );
    },
  );

  test(
    'unavailable directory is explicit rather than silently reported missing',
    () async {
      final store = FileAppPreferencesStore(
        codec: codec(),
        supportDirectory: () async {
          throw const FileSystemException(
            'injected inaccessible support directory',
          );
        },
      );
      expect((await store.read()).kind, PreferencesReadKind.unavailable);
      expect(
        (await store.write(const AppPreferences(localeTag: 'tr'))).kind,
        PreferencesWriteKind.failed,
      );
    },
  );

  test(
    'late read never replaces explicit locale/theme draft or save state',
    () async {
      final delayed = Completer<PreferencesReadResult>();
      final store = _ControlledStore(read: () => delayed.future);
      final controller = AppPreferencesController(store: store, codec: codec());
      addTearDown(controller.dispose);
      final loading = controller.load();
      controller.selectTheme(AppThemePreference.dark);
      controller.selectLocale('ar');
      delayed.complete(
        const PreferencesReadResult(
          PreferencesReadKind.loaded,
          AppPreferences(theme: AppThemePreference.light, localeTag: 'en'),
        ),
      );
      await loading;
      expect(
        controller.value,
        const AppPreferences(theme: AppThemePreference.dark, localeTag: 'ar'),
      );
      expect(controller.readPhase, PreferencesReadPhase.ignoredAfterEdit);
      expect(store.writes.last.value, controller.value);
      store.writes[1].done.complete(
        const PreferencesWriteResult(PreferencesWriteKind.failed),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.savePhase, PreferencesSavePhase.failed);
      store.writes[0].done.complete(
        const PreferencesWriteResult(PreferencesWriteKind.committed),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.savePhase, PreferencesSavePhase.failed);
      expect(controller.dirty, true);
      final retry = controller.retrySave();
      expect(store.writes.last.value, controller.value);
      store.writes.last.done.complete(
        const PreferencesWriteResult(PreferencesWriteKind.committed),
      );
      await retry;
      expect(controller.savePhase, PreferencesSavePhase.saved);
      expect(controller.dirty, false);
    },
  );

  testWidgets(
    'bounded startup read settles, underlying late result cannot change first-root input',
    (tester) async {
      final delayed = Completer<PreferencesReadResult>();
      final store = _ControlledStore(read: () => delayed.future);
      final controller = AppPreferencesController(
        store: store,
        codec: codec(),
        readDeadline: const Duration(milliseconds: 50),
      );
      addTearDown(controller.dispose);
      var settled = false;
      final read = controller.load().then((_) {
        settled = true;
      });
      await tester.pump(const Duration(milliseconds: 51));
      await read;
      expect(settled, true);
      expect(controller.readPhase, PreferencesReadPhase.timedOut);
      expect(controller.value, const AppPreferences());
      await controller.retrySave();
      expect(
        store.writes,
        isEmpty,
      ); // Untouched failure cannot overwrite good disk.
      delayed.complete(
        const PreferencesReadResult(
          PreferencesReadKind.loaded,
          AppPreferences(theme: AppThemePreference.dark, localeTag: 'ar'),
        ),
      );
      await tester.pump();
      expect(controller.value, const AppPreferences());
      controller.selectTheme(
        AppThemePreference.system,
      ); // Explicit fallback choice is intent.
      expect(store.writes.length, 1);
      store.writes.single.done.complete(
        const PreferencesWriteResult(PreferencesWriteKind.committed),
      );
      await tester.pump();
    },
  );

  test(
    'read retry after an edit cannot replace draft; dispose ignores late status',
    () async {
      final first = Completer<PreferencesReadResult>();
      final store = _ControlledStore(read: () => first.future);
      final controller = AppPreferencesController(store: store, codec: codec());
      controller.selectLocale('ja');
      final loading = controller.load();
      first.complete(
        const PreferencesReadResult(
          PreferencesReadKind.loaded,
          AppPreferences(localeTag: 'tr'),
        ),
      );
      await loading;
      expect(controller.value.localeTag, 'ja');
      var notifications = 0;
      controller.addListener(() {
        notifications++;
      });
      controller.dispose();
      store.writes.single.done.complete(
        const PreferencesWriteResult(PreferencesWriteKind.committed),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 0);
    },
  );

  test(
    'write uncertainty is visible and does not mark dirty draft saved',
    () async {
      final store = _ControlledStore(
        read: () async =>
            const PreferencesReadResult(PreferencesReadKind.missing),
      );
      final controller = AppPreferencesController(store: store, codec: codec());
      addTearDown(controller.dispose);
      await controller.load();
      controller.selectTheme(AppThemePreference.dark);
      store.writes.single.done.complete(
        const PreferencesWriteResult(PreferencesWriteKind.uncertain),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.savePhase, PreferencesSavePhase.uncertain);
      expect(controller.dirty, true);
      expect(controller.value.theme, AppThemePreference.dark);
    },
  );
}

class _Write {
  _Write(this.value);
  final AppPreferences value;
  final done = Completer<PreferencesWriteResult>();
}

class _ControlledStore implements AppPreferencesStore {
  _ControlledStore({required Future<PreferencesReadResult> Function() read})
    : _read = read;
  final Future<PreferencesReadResult> Function() _read;
  @override
  Future<PreferencesReadResult> read() => _read();
  final writes = <_Write>[];
  @override
  bool get persistent => true;
  @override
  Future<PreferencesWriteResult> write(AppPreferences value) {
    final request = _Write(value);
    writes.add(request);
    return request.done.future;
  }
}
