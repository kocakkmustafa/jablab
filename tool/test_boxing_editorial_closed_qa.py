"""Proposed strict source-QA tests. Definitions only; UNRUN in the report packet."""

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

APP = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    'boxing_editorial_subject', APP / 'tool/build_boxing_editorial_closed_qa.py'
)
SUBJECT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SUBJECT)


class EditorialClosedQaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original_reader = SUBJECT.local_reader(APP)
        cls.inputs = {}

        def record(name):
            raw = cls.original_reader(name)
            cls.inputs[name] = raw
            return raw

        cls.expected, cls.diagnostics = SUBJECT.build_bundle(record)

    def reader(self, edits=None):
        inputs = dict(self.inputs)
        inputs.update(edits or {})
        return inputs.__getitem__

    def test_current_exact_bundle_and_closed_policy(self):
        outputs, diagnostics = SUBJECT.build_bundle(self.reader())
        self.assertEqual(outputs, self.expected)
        self.assertEqual(len(outputs), 8)
        self.assertEqual(diagnostics['changedCueCount'], 7)
        self.assertEqual(diagnostics['unchangedCueCount'], 285)
        self.assertEqual(diagnostics['regeneratedSourcePins'], 292)
        proof = json.loads(outputs['tool/boxing_editorial_source/source_proof.v1.json'])
        for name in ['releaseEligible', 'visible', 'mediaBytesAccepted',
                     'nativePlaybackAccepted', 'rightsAccepted',
                     'physicalTechniqueAccepted', 'approvedProductionTrustRoot']:
            self.assertIs(proof[name], False, name)
        self.assertEqual(proof['generatedMedia'], 0)
        self.assertEqual(proof['qualifiedMedia'], 0)
        self.assertEqual(proof['progressEffect'], 0)

    def test_proof_hashes_actual_delta_and_baseline_bytes(self):
        proof = json.loads(self.expected['tool/boxing_editorial_source/source_proof.v1.json'])
        for name, path in [
            ('deltaSha256', 'tool/boxing_editorial_source/editorial_delta.v1.json'),
            ('baselineSubsetSha256', 'tool/boxing_editorial_source/baseline_v2k_jablab.v1.json'),
            ('producerSha256', 'tool/build_boxing_editorial_closed_qa.py'),
        ]:
            self.assertEqual(proof[name], SUBJECT.sha(self.inputs[path]))

    def test_one_byte_delta_text_mutant_keeps_six_rows_but_is_rejected(self):
        path = 'tool/boxing_editorial_source/editorial_delta.v1.json'
        original = self.inputs[path]
        mutant = original.replace(b'Stop the practice immediately', b'Ttop the practice immediately', 1)
        self.assertNotEqual(original, mutant)
        self.assertEqual(len(original), len(mutant))
        self.assertEqual(sum(left != right for left, right in zip(original, mutant)), 1)
        self.assertEqual(len(json.loads(mutant)['changes']), 6)
        with self.assertRaisesRegex(ValueError, 'byte hash drift'):
            SUBJECT.build_bundle(self.reader({path: mutant}))

    def test_one_byte_baseline_policy_mutant_keeps_39_292_but_is_rejected(self):
        path = 'tool/boxing_editorial_source/baseline_v2k_jablab.v1.json'
        original = self.inputs[path]
        mutant = original.replace(b'PENDING_VIEWED_ASSET_REVIEW', b'QENDING_VIEWED_ASSET_REVIEW', 1)
        self.assertNotEqual(original, mutant)
        self.assertEqual(len(original), len(mutant))
        self.assertEqual(sum(left != right for left, right in zip(original, mutant)), 1)
        rows = json.loads(mutant)['lessonRecords']
        self.assertEqual(len(rows), 39)
        self.assertEqual(sum(len(row['scenes']) for row in rows), 292)
        with self.assertRaisesRegex(ValueError, 'byte hash drift'):
            SUBJECT.build_bundle(self.reader({path: mutant}))

    def test_wrong_before_after_duplicate_unknown_and_seventh_delta_rejected(self):
        path = 'tool/boxing_editorial_source/editorial_delta.v1.json'
        original = json.loads(self.inputs[path])
        for variation in ['before', 'after', 'duplicate', 'unknown', 'seventh']:
            with self.subTest(variation=variation):
                mutant = copy.deepcopy(original)
                rows = mutant['changes']
                if variation in ['before', 'after']:
                    rows[0][variation]['en'] += ' changed'
                elif variation == 'duplicate':
                    rows[1] = copy.deepcopy(rows[0])
                elif variation == 'unknown':
                    rows[0]['json_pointer'] = '/modules/0/unknown'
                else:
                    rows.append(copy.deepcopy(rows[0]))
                with self.assertRaises(ValueError):
                    SUBJECT.build_bundle(self.reader({path: SUBJECT.pretty(mutant)}))

    def test_old_course_and_changed_actual_evidence_rejected(self):
        for path in ['assets/content/solo_boxing_course.v1.json',
                     'tool/boxing_editorial_source/evidence/MYBOXINGCOACH-JAB.json']:
            with self.subTest(path=path), self.assertRaises(ValueError):
                SUBJECT.build_bundle(self.reader({path: self.inputs[path] + b' '}))

    def test_actual_output_tamper_and_producer_change_do_not_reuse_old_pins(self):
        actual = dict(self.expected)
        key = 'tool/boxing_editorial_source/production_manifest.v1.json'
        tampered = json.loads(actual[key])
        tampered['releaseEligible'] = True
        actual[key] = SUBJECT.canonical(tampered)
        with self.assertRaises(ValueError):
            SUBJECT.check_output_reader(actual.__getitem__, self.expected)
        producer_path = 'tool/build_boxing_editorial_closed_qa.py'
        changed, _ = SUBJECT.build_bundle(self.reader({producer_path: self.inputs[producer_path] + b'\n# changed producer\n'}))
        self.assertNotEqual(changed, self.expected)
        with self.assertRaises(ValueError):
            SUBJECT.check_output_reader(self.expected.__getitem__, changed)

    def test_strict_json_rejects_duplicates_nonfinite_and_wrong_root(self):
        for raw in [b'{"kind":1,"kind":2}', b'{"n":NaN}', b'[]']:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                SUBJECT.json_object(raw)

    def test_create_only_preflights_all_targets_before_any_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'existing.json').write_bytes(b'old')
            with self.assertRaises(ValueError):
                SUBJECT.write_create_only(root, {'new.json': b'new', 'existing.json': b'changed'})
            self.assertFalse((root / 'new.json').exists())
            self.assertEqual((root / 'existing.json').read_bytes(), b'old')


if __name__ == '__main__':
    unittest.main()
