import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart';

import 'content_repository.dart';
import 'flutter_bundle_content_asset_reader.dart';
import 'lesson_media_source_pins_v2k.dart';
import 'solo_boxing_course.dart';

/// V2k closed QA source identity only; not a media acceptance signature.
const jablabMediaProductionManifestSha256 = jablabV2kSourcePinManifestSha256;
const _mediaRoot = 'assets/content/media/';
const _maxVideoBytes = 64 * 1024 * 1024;
const _maxCaptionBytes = 1024 * 1024;
const _maxTotalBytes = 512 * 1024 * 1024;
final _sha = RegExp(r'^[0-9a-f]{64}$');
final _time = RegExp(
  r'^(\d{2,}):([0-5]\d):([0-5]\d)\.(\d{3}) --> (\d{2,}):([0-5]\d):([0-5]\d)\.(\d{3})$',
);

@immutable
final class LessonMediaSourcePin {
  const LessonMediaSourcePin({
    required this.manifestSha256,
    required this.app,
    required this.assetId,
    required this.lessonId,
    required this.sceneId,
    required this.variantStem,
    required this.courseSourceSha256,
    required this.lessonCanonicalSha256,
    required this.productionSpecSha256,
    required this.sourceCueSha256,
    required this.idempotencyKey,
    required this.productionState,
    required this.sourcePinSha256,
  });

  final String manifestSha256, app, assetId;
  final String lessonId, sceneId, variantStem;
  final String courseSourceSha256, lessonCanonicalSha256;
  final String productionSpecSha256, sourceCueSha256;
  final String idempotencyKey, productionState, sourcePinSha256;

  String get key => '$lessonId\u0000$sceneId\u0000$variantStem';
}

@immutable
final class LessonMediaFile {
  const LessonMediaFile(this.path, this.bytes, this.sha256);
  final String path, sha256;
  final int bytes;
}

/// The future release generator must derive this from a separate accepted
/// bundle root. No release entry or generator output is currently installed.
@immutable
final class LessonMediaEntry {
  LessonMediaEntry({
    required this.source,
    required this.productionManifestSha256,
    required this.acceptanceReceiptSha256,
    required this.packageReceiptSha256,
    required this.video,
    required this.durationMs,
    required Map<String, LessonMediaFile> captions,
  }) : captions = Map.unmodifiable(captions);

  final LessonMediaSourcePin source;
  final String productionManifestSha256;
  final String acceptanceReceiptSha256, packageReceiptSha256;
  final LessonMediaFile video;
  final int durationMs;
  final Map<String, LessonMediaFile> captions;
}

@immutable
final class LessonCaptionCue {
  const LessonCaptionCue(this.start, this.end, this.text);
  final Duration start, end;
  final String text;
}

/// A local asset whose source, bytes and both caption tracks were inspected.
/// It is only reachable from the empty production catalogue or test injection
/// until an independently reviewed release catalogue is generated.
@immutable
final class InspectedLessonMedia {
  const InspectedLessonMedia._({
    required this.path,
    required this.duration,
    required this.captions,
  });

  final String path;
  final Duration duration;
  final Map<String, List<LessonCaptionCue>> captions;
  int get progressEffect => 0;
}

/// One explicit future publication gate. The shipping instance has no media.
/// `syntheticForTesting` is not an app acceptance path and is never used by
/// the production course screen.
final class LessonMediaCatalog {
  const LessonMediaCatalog.empty() : _entries = const [], _pins = const [];

  @visibleForTesting
  LessonMediaCatalog.syntheticForTesting({
    required List<LessonMediaEntry> entries,
    required List<LessonMediaSourcePin> sourcePins,
  }) : _entries = List.unmodifiable(entries),
       _pins = List.unmodifiable(sourcePins);

  final List<LessonMediaEntry> _entries;
  final List<LessonMediaSourcePin> _pins;

  bool get isEmpty => _entries.isEmpty;
  bool get releaseEligible => false;

  Future<InspectedLessonMedia?> inspect({
    required AssetBundle bundle,
    required SoloBoxingCourse course,
    required SoloLesson lesson,
    required String sceneId,
    required String variantStem,
  }) async {
    if (kReleaseMode ||
        _entries.isEmpty ||
        course.id != 'jablab.solo_boxing' ||
        course.lessons.where((item) => item.id == lesson.id).length != 1) {
      return null;
    }
    final key = '${lesson.id}\u0000$sceneId\u0000$variantStem';
    final entries = _entries.where((entry) => entry.source.key == key);
    final pins = _pins.where((pin) => pin.key == key);
    if (entries.length != 1 || pins.length != 1 || !_catalogSizeIsSafe()) {
      return null;
    }
    final entry = entries.single;
    final pin = pins.single;
    if (!_sourceMatches(entry.source, pin) ||
        !_closedQaSourceMembership(pin) ||
        entry.productionManifestSha256 != jablabMediaProductionManifestSha256 ||
        ![
          pin.courseSourceSha256,
          pin.lessonCanonicalSha256,
          pin.productionSpecSha256,
          pin.sourceCueSha256,
          entry.acceptanceReceiptSha256,
          entry.packageReceiptSha256,
        ].every(_sha.hasMatch) ||
        !_fileShape(entry.video, '$variantStem.mp4', _maxVideoBytes) ||
        entry.durationMs <= 0 ||
        entry.captions.keys.toSet().difference({'tr', 'en'}).isNotEmpty ||
        entry.captions.length != 2) {
      return null;
    }
    for (final language in const ['tr', 'en']) {
      final caption = entry.captions[language];
      if (caption == null ||
          !_fileShape(
            caption,
            '$variantStem.$language.vtt',
            _maxCaptionBytes,
          )) {
        return null;
      }
    }

    try {
      final checkedCourse = await ContentRepository(
        contentBundleOverride: bundle,
      ).loadSoloBoxingCourse();
      if (checkedCourse.id != course.id ||
          checkedCourse.version != course.version ||
          checkedCourse.lessons.where((item) => item.id == lesson.id).length !=
              1) {
        return null;
      }
      final reader = FlutterBundleContentAssetReader(bundle: bundle);
      final courseBytes = await reader.read(
        ContentRepository.soloBoxingCourseAsset,
      );
      if (computeSha256Hex(courseBytes) != pin.courseSourceSha256 ||
          !_lessonMatches(courseBytes, lesson.id, pin.lessonCanonicalSha256)) {
        return null;
      }
      final video = await reader.read(entry.video.path);
      if (!_bytesMatch(video, entry.video, _maxVideoBytes) ||
          !_mp4Signature(video)) {
        return null;
      }
      final captions = <String, List<LessonCaptionCue>>{};
      for (final language in const ['tr', 'en']) {
        final file = entry.captions[language]!;
        final bytes = await reader.read(file.path);
        if (!_bytesMatch(bytes, file, _maxCaptionBytes)) return null;
        final cues = _parseVtt(bytes, language, entry.durationMs);
        if (cues == null) return null;
        captions[language] = cues;
      }
      return InspectedLessonMedia._(
        path: entry.video.path,
        duration: Duration(milliseconds: entry.durationMs),
        captions: Map.unmodifiable(captions),
      );
    } catch (_) {
      // A missing or changed asset leaves the written lesson available.
      return null;
    }
  }

  bool _catalogSizeIsSafe() {
    var total = 0;
    final keys = <String>{};
    final paths = <String>{};
    for (final entry in _entries) {
      if (!keys.add(entry.source.key)) return false;
      final stem = entry.source.variantStem;
      if (entry.durationMs <= 0 ||
          entry.captions.length != 2 ||
          !_fileShape(entry.video, '$stem.mp4', _maxVideoBytes)) {
        return false;
      }
      for (final language in const ['tr', 'en']) {
        final caption = entry.captions[language];
        if (caption == null ||
            !_fileShape(caption, '$stem.$language.vtt', _maxCaptionBytes)) {
          return false;
        }
      }
      for (final file in [entry.video, ...entry.captions.values]) {
        if (!paths.add(file.path) || file.bytes <= 0) return false;
        total += file.bytes;
        if (total > _maxTotalBytes) return false;
      }
    }
    return true;
  }
}

bool _sourceMatches(LessonMediaSourcePin a, LessonMediaSourcePin b) =>
    a.manifestSha256 == b.manifestSha256 &&
    a.app == b.app &&
    a.assetId == b.assetId &&
    a.lessonId == b.lessonId &&
    a.sceneId == b.sceneId &&
    a.variantStem == b.variantStem &&
    a.courseSourceSha256 == b.courseSourceSha256 &&
    a.lessonCanonicalSha256 == b.lessonCanonicalSha256 &&
    a.productionSpecSha256 == b.productionSpecSha256 &&
    a.sourceCueSha256 == b.sourceCueSha256 &&
    a.idempotencyKey == b.idempotencyKey &&
    a.productionState == b.productionState &&
    a.sourcePinSha256 == b.sourcePinSha256;

/// Checks only source-row membership. The shipping catalogue remains empty;
/// a matching pin cannot authorize media bytes, rights, release or progress.
bool _closedQaSourceMembership(LessonMediaSourcePin pin) {
  if (pin.manifestSha256 != jablabV2kSourcePinManifestSha256 ||
      pin.app != 'jablab' ||
      pin.productionState != 'PREPRODUCTION_UNGENERATED' ||
      !jablabV2kClosedQaSourcePinHashes.contains(pin.sourcePinSha256)) {
    return false;
  }
  final identity = <String, Object>{
    'manifestSHA256': pin.manifestSha256,
    'app': pin.app,
    'courseSourceSHA256': pin.courseSourceSha256,
    'lessonId': pin.lessonId,
    'lessonCanonicalSHA256': pin.lessonCanonicalSha256,
    'assetId': pin.assetId,
    'sceneId': pin.sceneId,
    'variantStem': pin.variantStem,
    'productionSpecSHA256': pin.productionSpecSha256,
    'sourceCueSHA256': pin.sourceCueSha256,
    'idempotencyKey': pin.idempotencyKey,
    'productionState': pin.productionState,
  };
  return computeSha256Hex(
        Uint8List.fromList(utf8.encode(canonicalJsonEncode(identity))),
      ) ==
      pin.sourcePinSha256;
}

bool _fileShape(LessonMediaFile file, String suffix, int limit) {
  if (file.bytes <= 0 || file.bytes > limit || !_sha.hasMatch(file.sha256)) {
    return false;
  }
  try {
    PathPolicy.validate(file.path);
  } catch (_) {
    return false;
  }
  return file.path == '$_mediaRoot$suffix';
}

bool _bytesMatch(Uint8List bytes, LessonMediaFile file, int limit) =>
    bytes.isNotEmpty &&
    bytes.length <= limit &&
    bytes.length == file.bytes &&
    computeSha256Hex(bytes) == file.sha256;

bool _lessonMatches(Uint8List bytes, String id, String expectedSha) {
  final root = jsonDecode(utf8.decode(bytes));
  if (root is! Map<String, dynamic> || root['modules'] is! List) return false;
  final matches = <Map<String, dynamic>>[];
  for (final module in root['modules'] as List) {
    if (module is! Map<String, dynamic> || module['lessons'] is! List) {
      return false;
    }
    for (final lesson in module['lessons'] as List) {
      if (lesson is Map<String, dynamic> && lesson['id'] == id) {
        matches.add(lesson);
      }
    }
  }
  return matches.length == 1 &&
      computeSha256Hex(
            Uint8List.fromList(
              utf8.encode(canonicalJsonEncode(matches.single)),
            ),
          ) ==
          expectedSha;
}

bool _mp4Signature(Uint8List bytes) =>
    bytes.length >= 12 &&
    bytes[4] == 0x66 &&
    bytes[5] == 0x74 &&
    bytes[6] == 0x79 &&
    bytes[7] == 0x70;

List<LessonCaptionCue>? _parseVtt(
  Uint8List bytes,
  String locale,
  int durationMs,
) {
  final text = utf8.decode(bytes);
  if (text.contains('\r') ||
      text.contains('\ufeff') ||
      text.contains('\u0000')) {
    return null;
  }
  final header = 'WEBVTT - Motion locale=$locale\n\n';
  if (!text.startsWith(header)) return null;
  final body = text.substring(header.length).replaceFirst(RegExp(r'\n+$'), '');
  if (body.isEmpty) return null;
  final cues = <LessonCaptionCue>[];
  var lastEnd = 0;
  for (final block in body.split('\n\n')) {
    final lines = block.split('\n');
    if (lines.length < 2 || lines.any((line) => line.trim().isEmpty)) {
      return null;
    }
    final match = _time.firstMatch(lines.first);
    if (match == null) return null;
    int ms(int at) =>
        ((int.parse(match.group(at)!) * 60 + int.parse(match.group(at + 1)!)) *
                    60 +
                int.parse(match.group(at + 2)!)) *
            1000 +
        int.parse(match.group(at + 3)!);
    final start = ms(1), end = ms(5);
    if (end <= start || start < lastEnd || end > durationMs) return null;
    for (final line in lines.skip(1)) {
      if (line.contains('<') ||
          line.contains('>') ||
          line.contains('-->') ||
          line.runes.any((rune) => rune < 32 && rune != 9)) {
        return null;
      }
    }
    cues.add(
      LessonCaptionCue(
        Duration(milliseconds: start),
        Duration(milliseconds: end),
        lines.skip(1).join('\n'),
      ),
    );
    lastEnd = end;
  }
  return List.unmodifiable(cues);
}
