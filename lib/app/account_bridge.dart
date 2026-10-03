import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'course_progress_io.dart';
import 'owner_resource_lifetime.dart';

/// Must match `MotionApp.jablab.name` when the shared account package is pinned.
const String motionAppId = 'jablab';

/// Existing local history remains the guest journal after sign-in/sign-out.
/// A transfer into an account needs an explicit user choice in a later flow.
const String guestSessionsFileName = 'sessions.jsonl';
const String guestSoloCourseFileName = 'course-jablab-guest.json';

final RegExp _accountIdPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String sessionFileNameFor(String? accountUserId) {
  if (accountUserId == null) return guestSessionsFileName;
  if (!_accountIdPattern.hasMatch(accountUserId)) {
    throw ArgumentError.value(accountUserId, 'accountUserId', 'Expected UUID');
  }
  return 'sessions-$motionAppId-${accountUserId.toLowerCase()}.jsonl';
}

File sessionFileFor(Directory support, String? accountUserId) =>
    File('${support.path}/${sessionFileNameFor(accountUserId)}');

String courseFileNameFor(String? accountUserId) {
  if (accountUserId == null) return guestSoloCourseFileName;
  if (!_accountIdPattern.hasMatch(accountUserId)) {
    throw ArgumentError.value(accountUserId, 'accountUserId', 'Expected UUID');
  }
  return 'course-$motionAppId-${accountUserId.toLowerCase()}.json';
}

File courseFileFor(Directory support, String? accountUserId) =>
    File('${support.path}/${courseFileNameFor(accountUserId)}');

/// Lists canonical app-owned account journals and unfinished atomic writes for
/// deletion-receipt reconciliation. Guest, malformed and symlink paths are
/// ignored, including when only a crash-left `.jsonl.tmp` file remains.
Future<Iterable<String>> localHistoryAccountIds({
  Directory? supportDirectory,
}) async {
  final Directory support =
      supportDirectory ?? await getApplicationSupportDirectory();
  if (!await support.exists()) return const <String>[];
  final Set<String> ids = <String>{};
  await for (final FileSystemEntity entity in support.list(
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final String name = entity.uri.pathSegments.last;
    final bool session = name.startsWith('sessions-$motionAppId-');
    final bool course = name.startsWith('course-$motionAppId-');
    if (!session && !course) continue;
    final String prefix = session
        ? 'sessions-$motionAppId-'
        : 'course-$motionAppId-';
    final String baseSuffix = session ? '.jsonl' : '.json';
    final String tmpSuffix = '$baseSuffix.tmp';
    final String suffix = name.endsWith(tmpSuffix) ? tmpSuffix : baseSuffix;
    if (!name.endsWith(suffix)) continue;
    final String id = name.substring(
      prefix.length,
      name.length - suffix.length,
    );
    if (!_accountIdPattern.hasMatch(id)) continue;
    final String canonical = session
        ? '${sessionFileNameFor(id)}${suffix == tmpSuffix ? '.tmp' : ''}'
        : '${courseFileNameFor(id)}${suffix == tmpSuffix ? '.tmp' : ''}';
    if (canonical == name) ids.add(id);
  }
  return ids.toList()..sort();
}

Future<void> _deleteRegularFileIfPresent(File file) async {
  if (await FileSystemEntity.type(file.path, followLinks: false) ==
      FileSystemEntityType.file) {
    await file.delete();
  }
}

/// Pass this to `MotionAccountPage.clearLocalData(userId)`. The explicit id
/// prevents account deletion from ever targeting the guest journal.
Future<void> clearLocalHistoryFor(
  String accountUserId, {
  Directory? supportDirectory,
  OwnerResourceRegistry? ownerRegistry,
  OwnerResourceLifetime? expectedLifetime,
  Future<Directory> Function()? supportDirectoryProvider,
}) {
  final String confirmedId = canonicalOwnerId(accountUserId)!;
  final OwnerResourceRegistry registry =
      ownerRegistry ?? defaultOwnerResourceRegistry;
  return registry.eraseConfirmed(confirmedId, () async {
    final Directory support =
        supportDirectory ??
        await (supportDirectoryProvider ?? getApplicationSupportDirectory)();
    final File file = sessionFileFor(support, confirmedId);
    await _deleteRegularFileIfPresent(file);
    await _deleteRegularFileIfPresent(File('${file.path}.tmp'));
    await deleteCourseProgressFile(courseFileFor(support, confirmedId));
  }, expectedLifetime: expectedLifetime);
}
