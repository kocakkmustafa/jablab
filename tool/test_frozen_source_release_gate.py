"""Regression for accidental no-op executors and incomplete portable receipts."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

import frozen_source_release_gate as gate

ROOT = Path(__file__).resolve().parents[1]

class PortableCompletionTest(unittest.TestCase):
    def test_noop_executor_and_legacy_receipt_cannot_pass(self):
        free = os.statvfs(ROOT)
        self.assertGreaterEqual(free.f_bavail * free.f_frsize, 8 * 2**30,
                                'Regression blocked by disk floor')
        rows = gate.source_rows(ROOT)
        identity = hashlib.sha256(json.dumps(rows, sort_keys=True).encode()).hexdigest()
        with tempfile.TemporaryDirectory(prefix='jablab-gate-negative-') as folder:
            manifest = Path(folder) / 'manifest.json'
            manifest.write_text(json.dumps(rows))
            command = [sys.executable, str(ROOT / 'tool/frozen_source_release_gate.py')]
            args = ['--manifest', str(manifest), '--candidate-identity', identity]
            result = subprocess.run(command + ['portable'] + args +
                                    ['--dart', shutil.which('true')], capture_output=True)
            receipt = json.loads(result.stdout)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(receipt['status'], 'BLOCKED')
            self.assertEqual(receipt['exit_code'], 0)
            self.assertIn('completion report', receipt['reason'])
            # A portable PASS receipt without completion proof is rejected before
            # even considering the historical obligation. Negative input only.
            portable = Path(folder) / 'legacy-negative-only.json'
            portable.write_text(json.dumps({'schema': 1, 'lane': 'portable',
                'status': 'PASS', 'candidate_identity': identity}))
            result = subprocess.run(command + ['aggregate'] + args +
                                    ['--portable-receipt', str(portable)], capture_output=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn('expected checks', json.loads(result.stdout)['reason'])

    def test_incomplete_and_wrong_candidate_reports_rejected(self):
        identity = '1' * 64
        report = {'schema': 1, 'checker': 'jablab-frozen-source-v1',
                  'candidate_identity': identity, 'status': 'PASS',
                  'fixture_files': 7, 'source_files': 329,
                  'vm_graphs': ['app', 'engine'], 'negative_cases': 4}
        self.assertEqual(gate.validate_portable_report(report, identity), report)
        for change in [{'candidate_identity': '0' * 64}, {'negative_cases': 0},
                       {'vm_graphs': ['app']}, {'source_files': 328}]:
            with self.subTest(change=change), self.assertRaises(ValueError):
                gate.validate_portable_report({**report, **change}, identity)

if __name__ == '__main__':
    unittest.main()
