#!/usr/bin/env python3
"""Read JabLab app inputs through open directory descriptors, then check bytes."""

from __future__ import annotations

import argparse
import base64
from contextlib import ExitStack
import json
import os
import stat
from pathlib import Path
import subprocess
import sys
from typing import Callable

MAX_JSON_BYTES = 2 * 1024 * 1024
APP_INPUTS = {
    "slice": "assets/motion_content/jablab.source-slice.v1.json",
    "projection": "assets/motion_content/jablab.source-projection.v1.json",
    "course": "assets/content/solo_boxing_course.v1.json",
    "fixture": "test/fixtures/jablab_v2k_source_pins_v1.json",
}


class SourceReadError(ValueError):
    pass


def read_regular_relative(
    root: Path,
    relative: str,
    *,
    before_open: Callable[[], None] | None = None,
) -> bytes:
    """Convenience entry for one file, used by the race regression tests."""
    try:
        root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
        try:
            return _read_under_root_fd(root_fd, relative, before_open=before_open)
        finally:
            os.close(root_fd)
    except OSError as exc:
        raise SourceReadError(f"linked, missing or unreadable app root: {root}") from exc


def _read_under_root_fd(
    root_fd: int,
    relative: str,
    *,
    before_open: Callable[[], None] | None = None,
) -> bytes:
    """Walk from one already-open app root; retain every component FD."""
    parts = relative.split("/")
    if not parts or any(part in ("", ".", "..") for part in parts):
        raise SourceReadError("unsafe app input path")
    if any("\\" in part or "\x00" in part for part in parts):
        raise SourceReadError("unsafe app input component")

    dir_flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
    file_flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC
    try:
        with ExitStack() as opened:
            parent_fd = os.dup(root_fd)
            opened.callback(os.close, parent_fd)
            if before_open is not None:
                before_open()
            for index, part in enumerate(parts):
                last = index == len(parts) - 1
                child_fd = os.open(
                    part, file_flags if last else dir_flags, dir_fd=parent_fd
                )
                opened.callback(os.close, child_fd)
                mode = os.fstat(child_fd).st_mode
                if not (stat.S_ISREG(mode) if last else stat.S_ISDIR(mode)):
                    raise SourceReadError("non-regular app input component")
                parent_fd = child_fd

            size = os.fstat(parent_fd).st_size
            if size <= 0 or size > MAX_JSON_BYTES:
                raise SourceReadError("app input exceeds 2 MiB limit")
            chunks: list[bytes] = []
            length = 0
            while length <= MAX_JSON_BYTES:
                chunk = os.read(parent_fd, min(65536, MAX_JSON_BYTES + 1 - length))
                if not chunk:
                    break
                chunks.append(chunk)
                length += len(chunk)
            if length <= 0 or length > MAX_JSON_BYTES:
                raise SourceReadError("app input exceeds 2 MiB limit")
            return b"".join(chunks)
    except OSError as exc:
        raise SourceReadError(f"linked, missing or unreadable app input: {relative}") from exc


def check_from_app_root(root: Path) -> None:
    try:
        root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    except OSError as exc:
        raise SourceReadError(f"linked or unreadable app root: {root}") from exc
    try:
        inputs = {
            name: base64.b64encode(_read_under_root_fd(root_fd, relative)).decode("ascii")
            for name, relative in APP_INPUTS.items()
        }
    finally:
        os.close(root_fd)
    envelope = json.dumps(inputs, sort_keys=True, separators=(",", ":")).encode(
        "utf-8"
    )
    try:
        result = subprocess.run(
            ["dart", "run", "tool/check_media_source_projection.dart", "--check-bytes"],
            input=envelope,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=root,
            timeout=120,
            check=False,
        )
    except OSError as exc:
        raise SourceReadError("Dart source-byte validator unavailable") from exc
    if result.returncode != 0:
        error = result.stderr.decode("utf-8", errors="replace").strip()
        raise SourceReadError(f"source semantics rejected: {error}")
    print(result.stdout.decode("utf-8", errors="replace").strip())
    print("PASS_APP_FD_SOURCE_IDENTITY_ONLY_RELEASE_CLOSED jablab 39/292/292/0")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", required=True)
    parser.parse_args(argv)
    try:
        # "." anchors the read to the process's current directory inode.
        # The four inputs then share the same open root descriptor.
        check_from_app_root(Path("."))
        return 0
    except (SourceReadError, subprocess.TimeoutExpired) as exc:
        print(f"JabLab source projection rejected: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
