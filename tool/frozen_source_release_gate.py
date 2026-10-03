#!/usr/bin/env python3
"""Local evidence runner. Portable PASS alone can never accept a release.

Keep receipts outside the candidate. The independently sealed candidate manifest
and its identity are required for each lane and for aggregation. No network calls.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

EXCLUDED_DIRS = {'.git', '.dart_tool', 'build', '__pycache__', 'Pods', '.symlinks'}
EXCLUDED_FILES = {'.DS_Store', '.flutter-plugins-dependencies'}
HISTORICAL_BASE = 'bc10c21e57c85a468c380a79d9fed288554100ca'
DOCS_HEAD = '3c9429fc95b65caf72e30847e709bd53606ac940'
MODEL = 'assets/models/pose_landmarker_full.v1.task'
MODEL_HASH = '5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1'

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def need(condition, message):
    if not condition:
        raise ValueError(message)

def source_rows(root):
    rows = []
    for folder, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_DIRS)
        need(all(not (Path(folder) / d).is_symlink() for d in dirs), 'Candidate source directory link')
        for name in sorted(files):
            p = Path(folder) / name
            rel = p.relative_to(root).as_posix()
            if name in EXCLUDED_FILES or (rel.startswith('assets/models/') and name.endswith('.task')):
                continue
            need(not p.is_symlink(), 'Candidate source link: ' + rel)
            rows.append([rel, sha(p)])
    return sorted(rows)

def candidate_identity(root, manifest, expected):
    rows = json.loads(manifest.read_text())
    need(isinstance(rows, list) and all(isinstance(r, list) and len(r) == 2 for r in rows), 'Bad manifest')
    need(rows == sorted(rows) and len({r[0] for r in rows}) == len(rows), 'Manifest must be sorted and unique')
    identity = hashlib.sha256(json.dumps(rows, sort_keys=True).encode()).hexdigest()
    need(identity == expected, 'Wrong sealed candidate identity')
    need(source_rows(root) == rows, 'Candidate files changed, missing or extra')
    return identity

def git(canonical, *args):
    result = subprocess.run(['git', '-C', str(canonical), *args], capture_output=True,
                            env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})
    need(result.returncode == 0, 'Historical Git inspection failed: ' + result.stderr.decode(errors='replace'))
    return result.stdout.decode().strip()

def historical_snapshot(workspace):
    need(workspace is not None, 'Historical evidence unavailable: JABLAB_HISTORY_WORKSPACE is unset')
    workspace = Path(workspace).resolve()
    canonical = workspace / 'ventures/jablab/app'
    preview = workspace / 'scratch/2026-10-01-release-week-dispatch/lanes/jablab/core-adoption-v4'
    receipt = preview / 'SELECTION-RECEIPT.json'
    need(sha(receipt) == '9b346343e939bab2d45037b8103a575e91565d8866198826e8b52b088b7e4af9', 'Historical receipt changed')
    selection = json.loads(receipt.read_text())
    head = git(canonical, 'rev-parse', 'HEAD')
    need(head in {HISTORICAL_BASE, DOCS_HEAD}, 'Unknown canonical HEAD')
    if head == DOCS_HEAD:
        need(git(canonical, 'rev-parse', 'HEAD^') == HISTORICAL_BASE, 'Wrong docs parent')
        need(set(git(canonical, 'diff', '--name-only', HISTORICAL_BASE, head).splitlines()) == {'AGENTS.md', 'CLAUDE.md'}, 'Changed product blobs')
    for rel, expected in selection['canonicalPinnedFiles'].items():
        need(sha(canonical / rel) == expected, 'Canonical pinned WIP changed: ' + rel)
    for rel in ['test/core_adoption_contract_test.dart', 'test/dependency_pin_test.dart']:
        need(sha(preview / 'app' / rel) == selection['appFiles'][rel]['sha256'], 'Original production guard changed: ' + rel)
    ignored = subprocess.run(['git', '-C', str(canonical), 'check-ignore', '--quiet', MODEL])
    tracked = subprocess.run(['git', '-C', str(canonical), 'ls-files', '--error-unmatch', MODEL], capture_output=True)
    need(ignored.returncode == 0 and tracked.returncode == 1, 'Historical model ignore/index boundary changed')
    model = preview / 'app' / MODEL
    need(model.stat().st_size == 9398198 and sha(model) == MODEL_HASH, 'Real historical model changed/missing')
    # Fingerprint real source and config inputs, plus all index/WIP status. An
    # aggregate re-read refuses a receipt if any inspected input changed since run.
    files = [receipt, model, preview / 'package-uri-probe.dart']
    files += [canonical / rel for rel in selection['canonicalPinnedFiles']]
    files += [preview / 'app' / rel for rel in ['test/core_adoption_contract_test.dart', 'test/dependency_pin_test.dart']]
    files += [preview / 'app' / rel for rel in ['pubspec.lock', '.dart_tool/package_config.json', 'packages/jablab_engine/pubspec.lock', 'packages/jablab_engine/.dart_tool/package_config.json']]
    core = workspace / 'scratch/2026-10-01-release-week-dispatch/lanes/motion_core'
    files += [core / name for name in ['MOTION-CORE-FINAL-v4-source.manifest.json', 'MOTION-CORE-FINAL-v4.patch', 'MOTION-CORE-FINAL-v4-source.tar.gz']]
    manifest = json.loads((core / 'MOTION-CORE-FINAL-v4-source.manifest.json').read_text())
    selected = preview / 'core'
    members = sorted(selected.rglob('*'))
    need(all(not p.is_symlink() for p in members), 'Historical source contains links')
    actual = {p.relative_to(selected).as_posix() for p in members if p.is_file()}
    need(actual == {row['path'] for row in manifest['allFiles']}, 'Historical source inventory changed')
    files += [selected / row['path'] for row in manifest['allFiles']]
    state = {'workspace': str(workspace), 'head': head,
             'index': git(canonical, 'ls-files', '--stage'),
             'wip': git(canonical, 'status', '--porcelain=v1', '--untracked-files=all'),
             'files': [[str(p), sha(p)] for p in sorted(files)]}
    return hashlib.sha256(json.dumps(state, sort_keys=True).encode()).hexdigest()

def validate_portable_report(report, identity):
    expected = {'schema': 1, 'checker': 'jablab-frozen-source-v1',
                'candidate_identity': identity, 'status': 'PASS',
                'fixture_files': 7, 'source_files': 329,
                'vm_graphs': ['app', 'engine'], 'negative_cases': 4}
    need(report == expected, 'Portable checker did not prove all expected checks for this candidate')
    return report

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('lane', choices=['portable', 'historical', 'aggregate'])
    parser.add_argument('--manifest', required=True, type=Path)
    parser.add_argument('--candidate-identity', required=True)
    parser.add_argument('--portable-receipt', type=Path)
    parser.add_argument('--historical-receipt', type=Path)
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--flutter', default='flutter')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = {'schema': 1, 'lane': args.lane, 'candidate_identity': args.candidate_identity, 'status': 'BLOCKED'}
    try:
        identity = candidate_identity(root, args.manifest, args.candidate_identity)
        if args.lane == 'aggregate':
            for lane, path in [('portable', args.portable_receipt), ('historical', args.historical_receipt)]:
                need(path is not None and path.is_file(), lane + ' receipt unavailable')
                receipt = json.loads(path.read_text())
                need(receipt.get('schema') == 1 and receipt.get('lane') == lane and receipt.get('status') == 'PASS' and
                     receipt.get('candidate_identity') == identity, lane + ' receipt missing, stale or mismatched')
                if lane == 'portable':
                    validate_portable_report(receipt.get('checker_report'), identity)
                if lane == 'historical':
                    need(receipt.get('historical_snapshot') == historical_snapshot(os.environ.get('JABLAB_HISTORY_WORKSPACE')),
                         'Historical evidence stale since validation')
        else:
            free = os.statvfs(root)
            need(free.f_bavail * free.f_frsize >= 8 * 2**30, 'Disk below 8 GiB floor')
            snapshot = historical_snapshot(os.environ.get('JABLAB_HISTORY_WORKSPACE')) if args.lane == 'historical' else None
            command = ([args.dart, '--packages=.dart_tool/package_config.json', 'tool/check_frozen_source_fixture.dart', identity]
                       if args.lane == 'portable' else
                       [args.flutter, 'test', '--no-pub', '--reporter', 'json', 'tool/historical_source_selection_test.dart'])
            result = subprocess.run(command, cwd=root, capture_output=True)
            output['command'] = command
            output['exit_code'] = result.returncode
            output['log_sha256'] = hashlib.sha256(result.stdout + result.stderr).hexdigest()
            sys.stderr.buffer.write(result.stdout + result.stderr)
            need(result.returncode == 0, args.lane + ' execution failed; acceptance not established')
            if args.lane == 'portable':
                try:
                    report = json.loads(result.stdout)
                except (ValueError, UnicodeDecodeError):
                    raise ValueError('Portable checker did not produce a completion report')
                output['checker_report'] = validate_portable_report(report, identity)
            if args.lane == 'historical':
                events = [json.loads(line) for line in result.stdout.decode().splitlines() if line.startswith('{')]
                done = [event for event in events if event.get('type') == 'done']
                tests = [event for event in events if event.get('type') == 'testDone' and not event.get('hidden', False)]
                need(done and done[-1].get('success') is True and len(tests) == 6 and
                     all(event.get('result') == 'success' and event.get('skipped') is False for event in tests),
                     'Historical suite must complete all six tests without skips')
                need(snapshot == historical_snapshot(os.environ.get('JABLAB_HISTORY_WORKSPACE')), 'Historical input changed during run')
                output['historical_snapshot'] = snapshot
            need(candidate_identity(root, args.manifest, identity) == identity, 'Candidate changed during run')
        output['status'] = 'PASS'
    except (ValueError, OSError, KeyError, TypeError, json.JSONDecodeError) as error:
        output['reason'] = str(error)
    print(json.dumps(output, sort_keys=True))
    return 0 if output['status'] == 'PASS' else 2

if __name__ == '__main__':
    sys.exit(main())
