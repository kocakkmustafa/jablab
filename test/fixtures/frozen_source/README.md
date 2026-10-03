# Immutable historical selection fixture

Seven exact-byte evidence files, totaling 1,306,610 bytes, from the internal
YULAlab final-v4 selection. Core archive: 805,638 bytes, 329 regular source files,
2,729,905 source bytes. No model or historical app archive is copied.

Original source roots below the canonical YULAlab workspace:

- `scratch/2026-10-01-release-week-dispatch/lanes/motion_core/`:
  `MOTION-CORE-FINAL-v4-source.manifest.json`, `.patch`, `-source.tar.gz`.
- `scratch/2026-10-01-release-week-dispatch/lanes/jablab/core-adoption-v4/`:
  `SELECTION-RECEIPT.json`, `package-uri-probe.dart`, `app/pubspec.lock`, and
  `app/packages/jablab_engine/pubspec.lock`. Locks are renamed here without edits.

The seven SHA-256 seals are constants in `test/support/frozen_source_fixture.dart`.
Generated configs rebase the consistent historical lock root; original receipts
and locks remain byte-identical. The VM probe resolves URIs without executing
archived Core libraries. Default checks validate snapshots, not live acceptance.

License provenance: internal YULAlab Motion Core/JabLab code and evidence;
package pubspecs declare `publish_to: none`. The archive's
`packages/motion_camera/LICENSE` says `TODO: Add your license here.` No public
redistribution license is established or claimed. Original notices are retained;
this fixture is for internal repository validation, not redistribution approval.

Live historical and aggregate obligations: `tool/FROZEN-SOURCE-VALIDATION.md`.
