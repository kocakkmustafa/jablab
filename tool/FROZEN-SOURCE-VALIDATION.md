# Portable and historical obligations

Default `flutter test` validates the seven sealed fixtures, all 329 source bytes,
both actual Dart VM graphs and four wrong-path/identity negatives. The same
assertions run directly through `dart --packages=.dart_tool/package_config.json
 tool/check_frozen_source_fixture.dart`. Portable PASS alone cannot accept a release. The lane runner passes the sealed
candidate identity to the checker and requires its exact structured completion
report (seven fixtures, 329 files, both VM graphs, four negatives) before issuing
a receipt. Aggregate requires that report too. Missing output from a no-op
executable cannot pass; this does not authenticate arbitrary malicious executables.

The explicit historical suite is `tool/historical_source_selection_test.dart`.
It preserves all six original obligations: docs transition negatives; external
source seals and actual selected 329 files; actual VM resolution; original path
configs/locks; canonical pins/copied guards/receipt; real canonical HEAD/index
and ignored 9,398,198-byte historical model hash. Set
`JABLAB_HISTORY_WORKSPACE` to the provisioned real workspace. Missing history
fails, never skips. No original approval proof is changed.

Run `python3 tool/frozen_source_release_gate.py <portable|historical|aggregate>`.
Every lane requires `--manifest <sealed manifest>` and
`--candidate-identity <reviewed identity>`. Manifest rows are sorted
`[relative_path, sha256]` pairs covering all candidate source files. Identity is
SHA-256 of Python `json.dumps(rows, sort_keys=True)` bytes. Keep manifest,
receipts and logs outside the candidate. Stdout is the JSON receipt; stderr is
command output. `--dart` and `--flutter` select available supported executables.
The runner never changes global SDK/settings or accesses a remote service.

Aggregate additionally takes `--portable-receipt` and `--historical-receipt`.
Both must be PASS for this unchanged candidate. The historical suite must finish
all six tests with zero skips. Inputs are checked before and after running;
aggregate re-reads the real historical snapshot (HEAD/index/WIP/files/configs/
model) and rejects changed or unavailable evidence. Exit 2/status BLOCKED means
acceptance remains open. These local receipts are reviewable evidence, not
cryptographic approval signatures; independent review seals them and the source.

Clean CI without original history may pass portable tests, while historical and
release aggregate remain BLOCKED/NOT RUN, explicitly reported by the workflow.
Full Flutter runner acceptance remains open if SDK permissions block it; direct
Dart assertions are separate evidence. Remote CI, native builds, Core merge,
model calibration and store acceptance remain separate obligations.
