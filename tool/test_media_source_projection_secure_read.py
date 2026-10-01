from __future__ import annotations

import os
import base64
from contextlib import redirect_stdout
import io
import json
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from check_media_source_projection import (
    APP_INPUTS,
    MAX_JSON_BYTES,
    SourceReadError,
    check_from_app_root,
    read_regular_relative,
)


class SecureReadTests(unittest.TestCase):
    def setUp(self) -> None:
        self.sandbox = tempfile.TemporaryDirectory()
        self.addCleanup(self.sandbox.cleanup)
        base = Path(self.sandbox.name)
        self.root = base / "app"
        self.outside = base / "outside"
        (self.root / "assets" / "motion_content").mkdir(parents=True)
        (self.outside / "motion_content").mkdir(parents=True)
        self.relative = "assets/motion_content/jablab.source-slice.v1.json"
        self.payload = b'{"same":"verified bytes"}'
        (self.root / self.relative).write_bytes(self.payload)
        (self.outside / "motion_content" / "jablab.source-slice.v1.json").write_bytes(
            self.payload
        )

    def test_same_byte_outside_parent_swap_is_rejected(self) -> None:
        def swap_after_check() -> None:
            os.rename(self.root / "assets", self.root / "assets-original")
            os.symlink(self.outside, self.root / "assets")

        with self.assertRaises(SourceReadError):
            read_regular_relative(
                self.root, self.relative, before_open=swap_after_check
            )

    def test_normal_regular_file_reads_exact_bytes(self) -> None:
        self.assertEqual(
            read_regular_relative(self.root, self.relative), self.payload
        )

    def test_existing_symlink_parent_is_rejected(self) -> None:
        os.rename(self.root / "assets", self.root / "assets-original")
        os.symlink(self.outside, self.root / "assets")
        with self.assertRaises(SourceReadError):
            read_regular_relative(self.root, self.relative)

    def test_existing_symlink_file_is_rejected(self) -> None:
        (self.root / self.relative).unlink()
        os.symlink(
            self.outside / "motion_content" / "jablab.source-slice.v1.json",
            self.root / self.relative,
        )
        with self.assertRaises(SourceReadError):
            read_regular_relative(self.root, self.relative)

    def test_root_symlink_is_rejected(self) -> None:
        alias = self.root.parent / "app-alias"
        os.symlink(self.root, alias)
        with self.assertRaises(SourceReadError):
            read_regular_relative(alias, self.relative)

    def test_oversized_file_is_rejected(self) -> None:
        (self.root / self.relative).write_bytes(b"x" * (MAX_JSON_BYTES + 1))
        with self.assertRaises(SourceReadError):
            read_regular_relative(self.root, self.relative)

    def test_parent_escape_is_rejected(self) -> None:
        with self.assertRaises(SourceReadError):
            read_regular_relative(self.root, "../outside/motion_content/jablab.source-slice.v1.json")

    def _write_all_app_inputs(self) -> dict[str, bytes]:
        expected = {}
        for name, relative in APP_INPUTS.items():
            payload = f"{name}-source-bytes".encode("ascii")
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(payload)
            expected[name] = payload
        return expected

    def test_wrapper_passes_only_four_opened_byte_inputs_to_dart(self) -> None:
        expected = self._write_all_app_inputs()
        accepted = subprocess.CompletedProcess(
            args=[], returncode=0, stdout=b"PASS_PINNED_SOURCE_BYTES\n", stderr=b""
        )
        with mock.patch(
            "check_media_source_projection.subprocess.run", return_value=accepted
        ) as run, redirect_stdout(io.StringIO()):
            check_from_app_root(self.root)
        call = run.call_args
        self.assertEqual(call.args[0][-1], "--check-bytes")
        self.assertEqual(call.kwargs["cwd"], self.root)
        envelope = json.loads(call.kwargs["input"])
        self.assertEqual(envelope.keys(), expected.keys())
        for name, value in expected.items():
            self.assertEqual(base64.b64decode(envelope[name]), value)

    def test_dart_semantic_rejection_closes_wrapper(self) -> None:
        self._write_all_app_inputs()
        rejected = subprocess.CompletedProcess(
            args=[], returncode=1, stdout=b"", stderr=b"semantic mismatch"
        )
        with mock.patch(
            "check_media_source_projection.subprocess.run", return_value=rejected
        ):
            with self.assertRaises(SourceReadError):
                check_from_app_root(self.root)


if __name__ == "__main__":
    unittest.main()
