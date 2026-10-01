#!/usr/bin/env python3
"""Pin JabLab-only v2k source membership for closed, metadata-only app QA."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


APP = Path(__file__).resolve().parents[1]
WORKSPACE = Path(__file__).resolve().parents[4]
UPSTREAM = WORKSPACE / "ops/tools/motion_courses/contracts/v2k/source_pins_v1/source-pins.json"
FIXTURE = APP / "test/fixtures/jablab_v2k_source_pins_v1.json"
DART = APP / "lib/app/lesson_media_source_pins_v2k.dart"
CATALOG_SHA = "791bfea8e1479307794bcf8799cf703a7a840bcd3058c1a0d7fdf065d32d8594"
MANIFEST_SHA = "d887683c9a9b9bdb8d4ab7c51cdc5a5b4b4de6a918079e4cfd9cf543e9751e60"
PROOF_SHA = "dec615e14881b86b7676e1157f63b8bf6269026d856e59f2ee3a65d7f97e512a"
COURSE_SHA = "0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f"
COURSE = APP / "assets/content/solo_boxing_course.v1.json"


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def encoded(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()


def source_identity(catalog: dict, lesson: dict, scene: dict, variant: dict) -> dict:
    return {
        "manifestSHA256": catalog["manifestSHA256"],
        "app": lesson["app"],
        "courseSourceSHA256": lesson["courseSourceSHA256"],
        "lessonId": lesson["lessonId"],
        "lessonCanonicalSHA256": lesson["lessonCanonicalSHA256"],
        "assetId": lesson["assetId"],
        "sceneId": scene["sceneId"],
        "variantStem": variant["stem"],
        "productionSpecSHA256": scene["productionSpecSHA256"],
        "sourceCueSHA256": scene["sourceCueSHA256"],
        "idempotencyKey": scene["idempotencyKey"],
        "productionState": scene["productionState"],
    }


def outputs(catalog_path: Path = UPSTREAM) -> dict[Path, bytes]:
    require(catalog_path.is_file() and not catalog_path.is_symlink(), "upstream catalog missing/symlink")
    raw = catalog_path.read_bytes()
    require(sha(raw) == CATALOG_SHA, "upstream catalog SHA drift")
    catalog = json.loads(raw)
    require(
        catalog["schemaVersion"] == 1
        and catalog["kind"] == "MOTION_MEDIA_V2K_SOURCE_PINS_V1"
        and catalog["manifestSHA256"] == MANIFEST_SHA
        and catalog["sourceProofSHA256"] == PROOF_SHA
        and catalog["state"] == "CLOSED_PREPRODUCTION_SOURCE_MEMBERSHIP_ONLY"
        and catalog["visible"] is False
        and catalog["releaseEligible"] is False
        and catalog["progressEffect"] == 0
        and catalog["approvedProductionTrustRoot"] is False
        and catalog["counts"]["generatedMedia"] == 0
        and catalog["counts"]["qualifiedMedia"] == 0,
        "source catalog policy drift",
    )
    require(COURSE.is_file() and not COURSE.is_symlink() and sha(COURSE.read_bytes()) == COURSE_SHA, "live JabLab course SHA drift")
    require(catalog["courseSourcePins"]["jablab"]["sha256"] == COURSE_SHA, "upstream JabLab course pin drift")
    lessons = [item for item in catalog["lessons"] if item["app"] == "jablab"]
    require(len(lessons) == len({item["lessonId"] for item in lessons}) == 39, "JabLab lesson set drift")
    pins: set[str] = set()
    scenes: set[str] = set()
    stems: set[str] = set()
    for lesson in lessons:
        require(lesson["membershipStatus"] == "SOURCE_PINNED_TEST_ONLY" and lesson["courseSourceSHA256"] == COURSE_SHA, "JabLab lesson held/drift")
        for scene in lesson["scenes"]:
            require(scene["productionState"] == "PREPRODUCTION_UNGENERATED", "JabLab scene no longer closed")
            require(scene["sceneId"] not in scenes, "duplicate scene")
            scenes.add(scene["sceneId"])
            for variant in scene["variants"]:
                require(variant["stem"] not in stems, "duplicate variant stem")
                stems.add(variant["stem"])
                identity = source_identity(catalog, lesson, scene, variant)
                calculated = sha(json.dumps(identity, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode())
                require(variant["sourcePinSHA256"] == calculated and calculated not in pins, "invalid/duplicate source pin")
                pins.add(calculated)
    require(len(scenes) == len(stems) == len(pins) == 292, "JabLab scene/variant count drift")
    fixture = {
        "schemaVersion": 1,
        "kind": "JABLAB_V2K_CLOSED_QA_SOURCE_PINS_V1",
        "sourceCatalogSHA256": CATALOG_SHA,
        "manifestSHA256": MANIFEST_SHA,
        "sourceProofSHA256": PROOF_SHA,
        "app": "jablab",
        "courseSourceSHA256": COURSE_SHA,
        "lessons": lessons,
        "visible": False,
        "releaseEligible": False,
        "progressEffect": 0,
        "mediaBytesAccepted": False,
        "nativePlaybackAccepted": False,
    }
    lines = [
        "// Generated closed QA source membership. No media, rights or release acceptance.",
        "// Source: durable v2k source_pins_v1; review before any app cutover.",
        f"const jablabV2kSourcePinCatalogSha256 = '{CATALOG_SHA}';",
        f"const jablabV2kSourcePinManifestSha256 = '{MANIFEST_SHA}';",
        f"const jablabV2kSourcePinProofSha256 = '{PROOF_SHA}';",
        "const jablabV2kClosedQaReleaseEligible = false;",
        "const jablabV2kClosedQaProgressEffect = 0;",
        "const Set<String> jablabV2kClosedQaSourcePinHashes = {",
        *(f"  '{pin}'," for pin in sorted(pins)),
        "};", "",
    ]
    return {FIXTURE: encoded(fixture), DART: "\n".join(lines).encode()}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--source-catalog", type=Path, default=UPSTREAM)
    args = parser.parse_args()
    generated = outputs(args.source_catalog)
    if args.check:
        for path, expected in generated.items():
            require(path.is_file() and not path.is_symlink() and path.read_bytes() == expected, f"generated output drift: {path}")
        print("PASS_JABLAB_V2K_CLOSED_QA_39_292")
    else:
        require(not any(path.exists() for path in generated), "generated output exists; use --check")
        for path, blob in generated.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(blob)
        print("WROTE_JABLAB_V2K_CLOSED_QA_39_292")


if __name__ == "__main__":
    main()
