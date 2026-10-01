import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'media_source_projection_contract.dart';

const _maxEnvelopeBytes = 12 * 1024 * 1024;

Future<Uint8List> _readEnvelope() async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stdin) {
    if (builder.length + chunk.length > _maxEnvelopeBytes) {
      throw const FormatException('source byte envelope is oversized');
    }
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Uint8List _field(Map<String, dynamic> envelope, String name) {
  final value = envelope[name];
  if (value is! String) {
    throw FormatException('missing source byte field: $name');
  }
  return base64.decode(value);
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1 || arguments.single != '--check-bytes') {
    stderr.writeln(
      'Use python3 tool/check_media_source_projection.py --check '
      'from the JabLab app root.',
    );
    exitCode = 64;
    return;
  }
  try {
    final decoded = jsonDecode(utf8.decode(await _readEnvelope()));
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({
          'slice',
          'projection',
          'course',
          'fixture',
        }).isNotEmpty ||
        decoded.length != 4) {
      throw const FormatException('source byte envelope fields changed');
    }
    checkPinnedJabLabSourceProjection(
      sliceBytes: _field(decoded, 'slice'),
      projectionBytes: _field(decoded, 'projection'),
      courseBytes: _field(decoded, 'course'),
      qaFixtureBytes: _field(decoded, 'fixture'),
    );
    stdout.writeln(
      'PASS_PINNED_SOURCE_BYTES_ONLY_RELEASE_CLOSED jablab 39/292/292/0',
    );
  } on Object catch (error) {
    stderr.writeln('JabLab source projection rejected: $error');
    exitCode = 1;
  }
}
