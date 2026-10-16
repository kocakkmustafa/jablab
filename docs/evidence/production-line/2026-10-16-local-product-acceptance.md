# JabLab local product acceptance — 2026-10-16

This is bounded software acceptance. Simulator/native integration, physical
teaching, camera/model accuracy, IAP and store release remain separate gates.

## Source and evidence identity

- Canonical repository: `ventures/jablab/app`, clean starting `main` at
  `c68fed03f48e5d7a476bc6d27bd99bb931a7d5e6`, tree
  `7376560296c6a4ba339386b03b1ffa65ad7cbff3`.
- Every acceptance row below applies to that production source. This change
  adds tests and this report; production files, shared packages, dependency
  pins, signing inputs, icons and store artwork are unchanged.
- The local manifest covers 98 runtime/content/package inputs; its file SHA-256
  is `d33ff67f1388933d30aedb680d6a85fa2319fc282bb771c6f43aba6ef631ee78`.
  It is a source subset identity, not a binary or physical-device receipt.
- Raw logs, the manifest, independent review and final publication receipt live
  under workspace `scratch/2026-10-16-jablab-night-acceptance/`. Log hashes are
  recorded in its `acceptance.json`.
- Flutter `3.47.5` / Dart `3.13.4`; local runs use cached dependencies and no
  simulator. The pose asset matches pinned SHA-256
  `5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1`.

## Bounded acceptance matrix

| User outcome | Evidence | Status and remaining boundary |
|---|---|---|
| Written course can open with the camera off | `test/written_courses_camera_off_test.dart`: 10 TR/EN first-lesson walks across all five areas; permission/native-camera calls and legacy camera-session guard calls stay zero | PASS, host widget flow with real bundled content; production account startup and native permission behavior are unrun |
| Boxing reading, practice and self-report stay distinct; saved progress reopens and account data stays isolated | `solo_boxing_course_page_test`, `solo_boxing_progress_test`, `account_bridge_test`, owner/route lifetime tests in the app suite | PASS in the 848-test local app suite; native path-provider integration still requires a simulator slot |
| Timed rounds, early stop, untimed practice and session summaries retain their own meanings | `session_rounds_test`, `fitness_ship_audit_test`, `session_store_test`, summary/clock/progress tests in the app suite | PASS in the 848-test local app suite; no real exercise or physical duration measurement |
| Detection setup failure and unreadable observations cannot become success | `live_jab_path_test`, camera ownership/transport/retirement tests, `live_honesty_bucket_test`, `live_celiski_test`, `skeleton_confidence_test` | PASS in the 848-test local app suite; injected transport/synthetic poses do not validate native interruption, actual occlusion or camera accuracy |
| Known synthetic event controls remain bounded | Engine: 127 PASS / 12 named external-reference NO_CALL; seven controls produce zero false-positive and zero missed/extra positive events | PASS for offline logic: guard + three downward swings produce no event; three straight-jab controls each produce one jab. Synthetic issue codes still occur and are not physical coaching acceptance |
| Bundled content and source projection retain byte identity | Integrity manifest check, generator `--check`, FD/source projection `39/292/292/0`, 17 Python contract tests | PASS for source/byte contracts; media redistribution, demonstration and teaching validity remain open |
| Static types and lint are clean | Full baseline `flutter analyze --no-pub`, plus analysis of the final new test | PASS; source analysis is not native execution |

The full app suite passed 848 tests with zero skips (exit 0, 15m32s). It started
before the new camera-off test was added; the additional 10 tests passed in a
separate run. These results are reported separately, without counting the new
tests twice. Two existing Yang16 lifetime drag hit-test warnings are retained
in the raw log and are not treated as physical usability evidence.

## Five areas, with their actual content

| Area | Existing course content | Separate added-on written recall |
|---|---|---|
| Boxing | 39 solo lessons / 8 modules | 2 prompts |
| Tai Chi | 14 foundation lessons + 18 Yang16 written nodes (16 movements + 2 boundaries) | 2 prompts |
| Kickboxing | 16 written lessons | 2 prompts |
| Karate | 16 foundation lessons + 10 Taikyoku written lessons / 20 movement contracts | 2 prompts |
| Muay Thai | 16 written lessons | 2 prompts |

These are JabLab's five areas within the portfolio-wide 25-area target. The
legacy eight-discipline catalogue is not eight accepted courses. Written nodes,
recall prompts and saved self-report do not certify a complete physical course.
No new lessons, exercise prescriptions, health or safety claims were authored.
Qualified instruction, personal suitability, demonstrations and feedback remain
necessary boundaries; this run closes none of the five full physical courses.

## Corrected test defect and independent review

The release gate's negative regression previously scanned the developer checkout
and stopped at the ignored `android/key.properties` signing symlink before it
could test a no-op executor or an incomplete PASS receipt. The regression now
copies the unchanged CLI into a small temporary candidate it owns. Both false
success cases still return BLOCKED. A separate synthetic link case preserves
the production gate's link rejection. The actual signing link was not read,
removed or changed; the production gate itself was not changed.

The original Python run had one error; the corrected combined contracts pass
17/17. Independent review found no blocking issue for diff SHA-256
`9a4090349d87129549e41be6de08c53a3072c5f9c6a0f9c548d233b65470ef8e`.
The final camera-off test was independently reviewed at SHA-256
`38dcb6a2f000a05e723572d9a119ced2d80c82582be4eb8eb0653c30c62ffd6c`.
Its initial fixture timing/teardown attempts were interrupted and retained as
diagnostics, not product failures. The final 10/10 run completed in 12 seconds.
TR/EN are supplied locales here; translation correctness has separate course
tests. Widget teardown is not a filesystem-drain acceptance claim.

## Reused build evidence and remaining actions

The existing [CI run 38771791519](https://github.com/kocakkmustafa/jablab/actions/runs/38771791519)
is SUCCESS for the exact baseline SHA above: portable analyze/tests, Android
release code-path build and unsigned iOS release build. These builds were not
repeated locally. They do not prove signed distribution or native runtime use.
The repo was read back as PUBLIC and the workflow uses standard
`ubuntu-latest`/`macos-latest` hosted runners. The applicable
[GitHub billing rule](https://docs.github.com/en/actions/concepts/billing-and-usage)
permits those public standard runs without a new paid-run authorization.

1. Simulator integration is **PENDING RESOURCE OWNERSHIP**, not denied: LifeOS
   has priority. No simulator was claimed, launched, controlled or shut down.
   After an exclusive slot is assigned, run `integration_test/solo_course_test.dart`
   for native save/reopen/account isolation. Production-main boot needs the
   existing valid account build configuration; no credential is requested or
   stored by this change.
2. J-007 blur versus occlusion, J-011 sustained FPS/thermal behavior, actual
   pose/model accuracy and physical teaching remain OPEN. The physical liveness
   probe intentionally rejects simulators; do not run it as simulator evidence.
3. Historical-source release aggregation remains BLOCKED/unrun. A portable
   negative-control PASS cannot satisfy historical evidence obligations.
4. Real account/provider/IAP, signing/distribution and store readback remain
   UNRUN. Store uploads are deferred by the user's first-three-groups rule.

No shared-core edit, new installation, new credential/access, budget increase,
production spend, store upload, icon adoption or unrelated cleanup occurred.
Only this task's interrupted host-test processes and four owned temporary test
directories were stopped/removed; their cleanup receipt is retained.
