#!/usr/bin/env python3
"""Negative controls for the frozen boxing source research lineage."""

import copy
import json
import unittest
from pathlib import Path

from generate_solo_boxing_course import validate_attribution_contract


CONTRACT = Path(__file__).with_name("boxing_source_attribution.v1.json")


class BoxingSourceProvenanceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))

    def test_reviewed_lineage_is_accepted(self) -> None:
        validate_attribution_contract(self.contract)

    def test_missing_new_source_lineage_is_rejected(self) -> None:
        broken = copy.deepcopy(self.contract)
        del broken["sourceResearch"]["rarebreed_beginner_round_structure"]
        with self.assertRaisesRegex(ValueError, "research provenance drifted"):
            validate_attribution_contract(broken)

    def test_misassigned_new_source_lineage_is_rejected(self) -> None:
        broken = copy.deepcopy(self.contract)
        broken["sourceResearch"]["marksman_independent_focus_reflection"] = ["v8"]
        with self.assertRaisesRegex(ValueError, "research provenance drifted"):
            validate_attribution_contract(broken)

    def test_missing_source_record_is_rejected(self) -> None:
        broken = copy.deepcopy(self.contract)
        broken["sources"].pop()
        with self.assertRaisesRegex(ValueError, "source roster"):
            validate_attribution_contract(broken)

    def test_new_source_binding_cannot_move_to_another_lesson(self) -> None:
        broken = copy.deepcopy(self.contract)
        broken["bindings"]["boxing.integration.two_round_rehearsal"] = [
            "marksman_independent_focus_reflection"
        ]
        with self.assertRaisesRegex(ValueError, "contract or bindings"):
            validate_attribution_contract(broken)


if __name__ == "__main__":
    unittest.main()
