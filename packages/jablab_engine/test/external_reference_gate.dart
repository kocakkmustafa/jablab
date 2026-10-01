import 'dart:io';

/// Historical reference artifacts are research inputs, not repository fixtures.
/// A clean checkout can run the portable engine suite; this evidence comparison
/// runs only when the caller explicitly supplies the original artifact folder.
const String externalReferenceRootKey = 'JABLAB_REFERENCE_ARTIFACT_DIR';

String? get externalReferenceSkipReason {
  final String? root = Platform.environment[externalReferenceRootKey];
  if (root != null && root.trim().isNotEmpty) return null;
  return 'NO_CALL: external reference artifacts were not supplied via '
      '$externalReferenceRootKey; source/model acceptance remains open';
}

File externalReferenceArtifact(String basename) {
  final String? root = Platform.environment[externalReferenceRootKey];
  if (root == null || root.trim().isEmpty) {
    throw StateError('NO_CALL: $externalReferenceRootKey is unset');
  }
  return File('$root/$basename');
}
