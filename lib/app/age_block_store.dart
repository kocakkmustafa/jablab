import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Device-local, durable "under the minimum age" block for the shared Motion
/// account page (Core 5832031 `MotionAccountPage(ageBlocked, onAgeBlocked)`).
///
/// Once the Core age gate reports an under-age declaration, sign-up stays
/// closed on this device across restarts. A failed read starts unblocked:
/// the server still refuses an under-13 declaration (`P0013`), so this flag
/// only keeps the local form from being offered again.
class AgeBlockStore {
  AgeBlockStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const String fileName = 'motion_age_blocked';

  final Future<Directory> Function() _directory;
  bool _blocked = false;

  bool get blocked => _blocked;

  Future<File> _file() async =>
      File('${(await _directory()).path}${Platform.pathSeparator}$fileName');

  /// Bounded read before the first frame; any failure leaves it unblocked.
  Future<void> load({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      _blocked = await (await _file()).exists().timeout(timeout);
    } on Object {
      _blocked = false;
    }
  }

  /// Marks this device blocked in memory at once, then persists it.
  Future<void> markBlocked() async {
    _blocked = true;
    try {
      final File file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString('1', flush: true);
    } on Object {
      // The in-memory block still holds for this run.
    }
  }
}
