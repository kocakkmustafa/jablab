import 'dart:convert';
import 'self_guided_practice.dart';

/// Separate original preparation, not a new revision of Angela form mechanics.
final class Yang16PreparationCourse {
  Yang16PreparationCourse._(Map<String, dynamic> map) {
    if (map['schemaVersion'] is! int ||
        map['schemaVersion'] != 1 ||
        map['id'] != 'jablab.yang16_original_preparations.v1' ||
        map.length != 4 ||
        map['sourceIds'] is! List ||
        map['practices'] is! List) {
      throw const FormatException('Wrong Yang preparation bank');
    }
    sourceIds = List.unmodifiable((map['sourceIds'] as List).cast<String>());
    if (sourceIds.length != 2 ||
        sourceIds.toSet().length != 2 ||
        !sourceIds.contains('TC-ANGELA16') ||
        !sourceIds.contains('TC-PAULLAM-FIRST')) {
      throw const FormatException('Unknown original preparation sources');
    }
    final decoded = [
      for (final value in map['practices'] as List)
        SelfGuidedPractice.decode(value),
    ];
    const expected = [
      'prepare',
      'm01',
      'm02',
      'm03',
      'm04',
      'm05',
      'm06',
      'm07',
      'm08',
      'm09',
      'm10',
      'm11',
      'm12',
      'm13',
      'm14',
      'm15',
      'm16',
      'return',
    ];
    if (decoded.length != expected.length) {
      throw const FormatException('Incomplete original preparation');
    }
    for (var i = 0; i < expected.length; i++) {
      decoded[i].requireBinding(expected[i], sourceIds);
    }
    practices = Map.unmodifiable({
      for (final practice in decoded) practice.lessonId: practice,
    });
  }
  factory Yang16PreparationCourse.fromJsonString(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Expected bank');
      }
      return Yang16PreparationCourse._(value);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed original preparation');
    }
  }
  late final List<String> sourceIds;
  late final Map<String, SelfGuidedPractice> practices;
  SelfGuidedPractice? forTarget(String id) => practices[id];
}
