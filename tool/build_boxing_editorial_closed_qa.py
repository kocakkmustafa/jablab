"""Strict app-owned original editorial source QA. No SDK or network.

Historical v2k inputs remain immutable. This proof grants no media, rights,
physical technique or release acceptance. --write is create-only/idempotent;
--check only reads and compares every generated output byte.
"""

import argparse
import copy
import hashlib
import json
from pathlib import Path

COURSE_BEFORE = '0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f'
COURSE_AFTER = '56773912d8917e3403fb1b2fe3755cf564b10e57e4ed35f24c1df6640b2594dd'
BASE_MANIFEST = 'd887683c9a9b9bdb8d4ab7c51cdc5a5b4b4de6a918079e4cfd9cf543e9751e60'
BASE_CATALOG = '791bfea8e1479307794bcf8799cf703a7a840bcd3058c1a0d7fdf065d32d8594'
BASE_PROOF = 'dec615e14881b86b7676e1157f63b8bf6269026d856e59f2ee3a65d7f97e512a'
BASE_FIXTURE = 'da806a35f838e8dbe6e770b0d8168bd99214f62eee5833dcfd584ee9cc035241'
DELTA_SHA = 'f9bab1d2087a286c7ca471d8be81da9ea615e567b6c875f3c9eabea0c5e371ac'
BASE_SUBSET_SHA = 'a2775e75c51ff1bdf1111b1130ce06fb1964b698ff2991b4975456c76bc2f318'
REFERENCE_BINDINGS_SHA = 'dbb3b922a5b8aa3c3795b2afeaff91f751d22614a7c9a62a4a86b93449d98757'


def require(value, message):
    if not value:
        raise ValueError(message)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()


def pretty(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


def json_object(raw, expected=None, label='input'):
    require(expected is None or sha(raw) == expected, label + ': byte hash drift')
    def unique(pairs):
        result = {}
        for name, value in pairs:
            require(name not in result, label + ': duplicate JSON key')
            result[name] = value
        return result
    value = json.loads(raw.decode('utf-8'), object_pairs_hook=unique, parse_constant=lambda value: (_ for _ in ()).throw(ValueError(label + ': non-finite JSON constant')))
    require(isinstance(value, dict), label + ': object required')
    return value


def exact_keys(value, keys, label):
    require(isinstance(value, dict) and set(value) == set(keys), label + ': exact keys changed')


def parent_at(value, pointer):
    require(pointer.startswith('/'), 'invalid pointer')
    parts = pointer[1:].split('/')
    for part in parts[:-1]:
        value = value[int(part)] if isinstance(value, list) else value[part]
    part = int(parts[-1]) if isinstance(value, list) else parts[-1]
    return value, part


def flatten(course):
    lessons = [lesson for module in course['modules'] for lesson in module['lessons']]
    require(len(lessons) == len({x['id'] for x in lessons}) == 39, '39 lesson identity drift')
    return {x['id']: x for x in lessons}


def cue_from_lesson(lesson, field):
    # Exact JabLab mapping independently reconstructed against all292 old cues.
    if field == 'learningObjective':
        return lesson['objective']
    if field.startswith('teachingSequence/'):
        return lesson['steps'][int(field.split('/')[1])]
    if field in {'currentPractice', 'storyboard/3/content'}:
        return lesson['practice']
    if field == 'adaptation+selfReview+stopSignal':
        return {language: ('Uyarlama: ' if language == 'tr' else 'Adaptation: ') + lesson['adaptation'][language] + ('\nÖz değerlendirme: ' if language == 'tr' else '\nSelf review: ') + '\n'.join(x[language] for x in lesson['selfChecks']) + ('\nDur: ' if language == 'tr' else '\nStop: ') + lesson['stopSignal'][language] for language in ['tr', 'en']}
    raise ValueError('unsupported source cue field: ' + field)


def production_spec(scene):
    spec = copy.deepcopy(scene)
    spec['format'].pop('filenameVariantsWithoutExtension', None)
    for name in ['productionSpecSHA256', 'idempotencyKey', 'idempotencyRule', 'generatedAssetSHA256']:
        spec.pop(name, None)
    return spec


def identity(manifest_sha, course_sha, lesson, scene, stem):
    return {'manifestSHA256': manifest_sha, 'app': 'jablab', 'courseSourceSHA256': course_sha, 'lessonId': lesson['lessonId'], 'lessonCanonicalSHA256': lesson['lessonCanonicalSHA256'], 'assetId': lesson['assetId'], 'sceneId': scene['sceneId'], 'variantStem': stem, 'productionSpecSHA256': scene['productionSpecSHA256'], 'sourceCueSHA256': scene['sourceCueSHA256'], 'idempotencyKey': scene['idempotencyKey'], 'productionState': scene['productionState']}


def build_bundle(read_bytes):
    def read_input(path, expected=None):
        return json_object(read_bytes(path), expected, path)
    current = read_input('assets/content/solo_boxing_course.v1.json', COURSE_AFTER)
    delta_path = 'tool/boxing_editorial_source/editorial_delta.v1.json'
    delta = read_input(delta_path, DELTA_SHA)
    exact_keys(delta, {'schemaVersion','kind','state','baselineCourseSha256','targetCourseSha256','changes','progressEffect','releaseEligible','mediaBytesAccepted','rightsAccepted','physicalTechniqueAccepted','qualifiedMedia','sourceWriterReceipt'}, 'editorial delta')
    require(delta['schemaVersion'] == 1 and delta['kind'] == 'JABLAB_EDITORIAL_SOURCE_DELTA_V1', 'delta kind/schema')
    require(delta['baselineCourseSha256'] == COURSE_BEFORE and delta['targetCourseSha256'] == COURSE_AFTER, 'delta course boundary')
    require(type(delta['progressEffect']) is int and type(delta['qualifiedMedia']) is int and delta['progressEffect'] == delta['qualifiedMedia'] == 0, 'delta counts')
    require(len(delta['changes']) == 6, 'exact six delta shape changed')
    exact_keys(delta['sourceWriterReceipt'], {'path','sha256'}, 'writer binding')
    writer = read_input(delta['sourceWriterReceipt']['path'], delta['sourceWriterReceipt']['sha256'])
    require([{k: x[k] for k in ['id', 'lesson_id', 'json_pointer', 'before', 'after', 'reason', 'primary_safety_support_url'] if k in x} for x in writer['changes']] == delta['changes'], 'writer six delta mismatch')
    require(all(delta[x] is False for x in ['releaseEligible', 'mediaBytesAccepted', 'rightsAccepted', 'physicalTechniqueAccepted']), 'delta may not grant media/rights/physical acceptance')
    baseline = copy.deepcopy(current)
    paths = set()
    for change in delta['changes']:
        require(set(change) in [set(['id','lesson_id','json_pointer','before','after','reason']), set(['id','lesson_id','json_pointer','before','after','reason','primary_safety_support_url'])], 'delta change exact keys')
        require(change['json_pointer'] not in paths, 'duplicate delta pointer')
        paths.add(change['json_pointer'])
        parent, key = parent_at(baseline, change['json_pointer'])
        require(parent[key] == change['after'], 'after image drift')
        require(set(change['before']) == set(change['after']) == {'tr', 'en'}, 'delta must be one EN/TR text pair')
        parent[key] = copy.deepcopy(change['before'])
    require(sha(pretty(baseline)) == COURSE_BEFORE, 'delta does not recover exact original0909bytes')
    old_lessons, new_lessons = flatten(baseline), flatten(current)
    require(list(old_lessons) == list(new_lessons), 'lesson order/identity changed')
    changed_lessons = [key for key in old_lessons if old_lessons[key] != new_lessons[key]]
    require(changed_lessons == ['boxing.footwork.diagonal', 'boxing.combinations.angle_exit', 'boxing.rounds.personal_plan'], 'three changed lesson set drift')
    subset_path = 'tool/boxing_editorial_source/baseline_v2k_jablab.v1.json'
    baseline_subset_input = read_input(subset_path, BASE_SUBSET_SHA)
    exact_keys(baseline_subset_input, {'schemaVersion','kind','sourceManifestSHA256','sourceCatalogSHA256','sourceProofSHA256','courseSourceSHA256','lessonRecords'}, 'baseline subset')
    require(baseline_subset_input['schemaVersion'] == 1 and baseline_subset_input['kind'] == 'JABLAB_IMMUTABLE_V2K_MANIFEST_SUBSET_V1', 'baseline kind/schema')
    require(baseline_subset_input['sourceManifestSHA256'] == BASE_MANIFEST and baseline_subset_input['sourceCatalogSHA256'] == BASE_CATALOG and baseline_subset_input['sourceProofSHA256'] == BASE_PROOF and baseline_subset_input['courseSourceSHA256'] == COURSE_BEFORE, 'baseline historical lineage')
    read_input('tool/boxing_editorial_source/historical_source_proof.v1.json', BASE_PROOF)
    old_fixture = read_input('test/fixtures/jablab_v2k_source_pins_v1.json', BASE_FIXTURE)
    require(old_fixture['sourceCatalogSHA256'] == BASE_CATALOG and old_fixture['manifestSHA256'] == BASE_MANIFEST and old_fixture['sourceProofSHA256'] == BASE_PROOF, 'old fixture provenance')
    historical_manifest = {'lessonRecords': baseline_subset_input['lessonRecords']}
    records = [x for x in historical_manifest['lessonRecords'] if x['app'] == 'jablab']
    old_membership = old_fixture['lessons']
    require(all(x['app'] == 'jablab' for x in old_membership), 'historical fixture app membership')
    require(len(records) == len(old_membership) == 39, 'historical lesson membership drift')
    require(sum(len(x['scenes']) for x in records) == 292, 'historical scene count drift')
    old_by_id = {x['lessonId']: x for x in old_membership}
    for record in records:
        lesson = old_lessons[record['lessonId']]
        require(record['courseSourceSHA256'] == COURSE_BEFORE and record['lessonCanonicalSHA256'] == sha(canonical(lesson)), 'historical lesson digest mismatch')
        member = old_by_id[record['lessonId']]
        require(member['lessonCanonicalSHA256'] == record['lessonCanonicalSHA256'] and member['courseSourceSHA256'] == COURSE_BEFORE, 'historical pin lesson mismatch')
        require(len(member['scenes']) == len(record['scenes']), 'historical scene membership count')
        for scene, pin_scene in zip(record['scenes'], member['scenes']):
            require(scene['sceneId'] == pin_scene['sceneId'], 'historical scene order mismatch')
            require(scene['sourceCue'] == cue_from_lesson(lesson, scene['sourceCueField']), 'historical cue differs from actual0909lesson')
            require(sha(canonical(scene['sourceCue'])) == scene['sourceCueSHA256'], 'historical cue digest mismatch')
            require(sha(canonical(production_spec(scene))) == scene['productionSpecSHA256'], 'historical spec digest mismatch')
            require(scene['productionState'] == 'PREPRODUCTION_UNGENERATED' and scene['generatedAssetSHA256'] is None, 'historical scene not closed')
            require(scene['format']['filenameVariantsWithoutExtension'] == [v['stem'] for v in pin_scene['variants']], 'historical variant stems mismatch')
            for variant in pin_scene['variants']:
                require(sha(canonical(identity(BASE_MANIFEST, COURSE_BEFORE, member, pin_scene, variant['stem']))) == variant['sourcePinSHA256'], 'historical source pin mismatch')
    references_path = 'tool/boxing_editorial_source/reference_bindings.v1.json'
    references = read_input(references_path, REFERENCE_BINDINGS_SHA)
    exact_keys(references, {'schemaVersion','kind','references','primarySafetyUrl','limits','releaseEligible','mediaBytesAccepted','rightsAccepted','physicalTechniqueAccepted'}, 'reference bindings')
    require(references['schemaVersion'] == 1 and references['kind'] == 'JABLAB_EDITORIAL_REFERENCE_BINDINGS_V1', 'reference kind/schema')
    require(all(references[name] is False for name in ['releaseEligible','mediaBytesAccepted','rightsAccepted','physicalTechniqueAccepted']), 'references grant no acceptance')
    for row in references['references']:
        relative = Path(row['path'])
        require(not relative.is_absolute() and '..' not in relative.parts, 'unsafe evidence reference')
        exact_keys(row, {'path','sha256','scope','originReportPath'}, 'reference row')
        require(sha(read_bytes(str(relative))) == row['sha256'], 'actual source receipt changed')
    baseline_subset = {'schemaVersion': 1, 'kind': 'JABLAB_IMMUTABLE_V2K_MANIFEST_SUBSET_V1', 'sourceManifestSHA256': BASE_MANIFEST, 'sourceCatalogSHA256': BASE_CATALOG, 'sourceProofSHA256': BASE_PROOF, 'courseSourceSHA256': COURSE_BEFORE, 'lessonRecords': records}
    proof = {'schemaVersion': 1, 'kind': 'JABLAB_ORIGINAL_EDITORIAL_SOURCE_PROOF_V1', 'state': 'SOURCE_TEXT_DELTA_ONLY_NOT_MEDIA_OR_PHYSICAL_ACCEPTANCE', 'historicalManifestSha256': BASE_MANIFEST, 'historicalCatalogSha256': BASE_CATALOG, 'historicalProofSha256': BASE_PROOF, 'historicalFixtureSha256': BASE_FIXTURE, 'baselineSubsetSha256': sha(read_bytes(subset_path)), 'beforeCourseSha256': COURSE_BEFORE, 'afterCourseSha256': COURSE_AFTER, 'deltaSha256': DELTA_SHA, 'deltaPairCount': 6, 'changedLessonIds': changed_lessons, 'referenceBindingsSha256': sha(read_bytes(references_path)), 'producerSha256': sha(read_bytes('tool/build_boxing_editorial_closed_qa.py')), 'progressEffect': 0, 'releaseEligible': False, 'visible': False, 'mediaBytesAccepted': False, 'nativePlaybackAccepted': False, 'rightsAccepted': False, 'physicalTechniqueAccepted': False, 'approvedProductionTrustRoot': False, 'generatedMedia': 0, 'qualifiedMedia': 0}
    proof_raw = canonical(proof)
    proof_sha = sha(proof_raw)
    new_records = copy.deepcopy(records)
    cue_changes = []
    for record in new_records:
        lesson = new_lessons[record['lessonId']]
        record['courseSourceSHA256'] = COURSE_AFTER
        record['lessonCanonicalSHA256'] = sha(canonical(lesson))
        for scene in record['scenes']:
            old_spec = scene['productionSpecSHA256']
            old_cue = scene['sourceCueSHA256']
            cue = cue_from_lesson(lesson, scene['sourceCueField'])
            scene.update(courseSourceSHA256=COURSE_AFTER, sourceLessonCanonicalSHA256=record['lessonCanonicalSHA256'], sourceCue=copy.deepcopy(cue), sourceCueSHA256=sha(canonical(cue)))
            scene['prompt']['sourceCue'] = copy.deepcopy(cue)
            scene['captions']['sourceCueSHA256'] = scene['sourceCueSHA256']
            new_spec = sha(canonical(production_spec(scene)))
            require(new_spec != old_spec, 'course hash must invalidate every production spec')
            scene['productionSpecSHA256'] = new_spec
            scene['idempotencyKey'] = 'motion-media-v1:' + new_spec
            stems = scene['format']['filenameVariantsWithoutExtension']
            require(len(stems) == 1 and stems[0].count('--' + old_spec + '--') == 1, 'unrecognized exact original filename shape')
            scene['format']['filenameVariantsWithoutExtension'] = [stems[0].replace('--' + old_spec + '--', '--' + new_spec + '--')]
            if old_cue != scene['sourceCueSHA256']:
                cue_changes.append({'sceneId': scene['sceneId'], 'sourceCueField': scene['sourceCueField'], 'beforeSha256': old_cue, 'afterSha256': scene['sourceCueSHA256']})
    require(len(cue_changes) == 7, 'expected seven changed cues')
    # A full-tree restoration check rejects every unapproved policy mutation.
    for before_record, after_record in zip(records, new_records):
        restored_record = copy.deepcopy(after_record)
        for name in ['courseSourceSHA256', 'lessonCanonicalSHA256']:
            restored_record[name] = before_record[name]
        for before_scene, after_scene in zip(before_record['scenes'], restored_record['scenes']):
            for name in ['courseSourceSHA256', 'sourceLessonCanonicalSHA256', 'sourceCueSHA256', 'sourceCue', 'productionSpecSHA256', 'idempotencyKey']:
                after_scene[name] = copy.deepcopy(before_scene[name])
            after_scene['prompt']['sourceCue'] = copy.deepcopy(before_scene['prompt']['sourceCue'])
            after_scene['captions']['sourceCueSHA256'] = before_scene['captions']['sourceCueSHA256']
            after_scene['format']['filenameVariantsWithoutExtension'] = copy.deepcopy(before_scene['format']['filenameVariantsWithoutExtension'])
            require(after_scene == before_scene, 'unapproved scene policy/source field changed')
        require(restored_record == before_record, 'unapproved lesson metadata changed')
    manifest = {'schemaVersion': 1, 'kind': 'JABLAB_EDITORIAL_CLOSED_PREPRODUCTION_MANIFEST_V1', 'sourceProofReceiptSHA256': proof_sha, 'baselineManifestSHA256': BASE_MANIFEST, 'courseSourcePins': {'jablab': {'path': 'ventures/jablab/app/assets/content/solo_boxing_course.v1.json', 'sha256': COURSE_AFTER}}, 'releaseEligible': False, 'visible': False, 'progressEffect': 0, 'mediaBytesAccepted': False, 'nativePlaybackAccepted': False, 'rightsAccepted': False, 'approvedProductionTrustRoot': False, 'counts': {'apps': 1, 'lessons': 39, 'scenes': 292, 'filenameStems': 292, 'generatedMedia': 0, 'qualifiedMedia': 0, 'educatorAccepted': 0}, 'lessonRecords': new_records}
    manifest_raw = canonical(manifest)
    manifest_sha = sha(manifest_raw)
    membership = []
    pins = set()
    for record in new_records:
        lesson = {'app': 'jablab', 'lessonId': record['lessonId'], 'assetId': record['assetId'], 'courseSourceSHA256': COURSE_AFTER, 'lessonCanonicalSHA256': record['lessonCanonicalSHA256'], 'membershipStatus': 'SOURCE_PINNED_TEST_ONLY', 'scenes': []}
        for scene in record['scenes']:
            item = {name: scene[name] for name in ['sceneId', 'productionSpecSHA256', 'sourceCueSHA256', 'idempotencyKey', 'productionState']}
            stem = scene['format']['filenameVariantsWithoutExtension'][0]
            pin = sha(canonical(identity(manifest_sha, COURSE_AFTER, lesson, item, stem)))
            require(pin not in pins, 'duplicate new source pin')
            pins.add(pin)
            item['variants'] = [{'stem': stem, 'sourcePinSHA256': pin}]
            lesson['scenes'].append(item)
        membership.append(lesson)
    require(len(pins) == 292, 'new292source pin inventory drift')
    catalog = {'schemaVersion': 1, 'kind': 'JABLAB_EDITORIAL_CLOSED_QA_SOURCE_PINS_V1', 'manifestSHA256': manifest_sha, 'sourceProofSHA256': proof_sha, 'courseSourceSHA256': COURSE_AFTER, 'state': 'CLOSED_PREPRODUCTION_SOURCE_MEMBERSHIP_ONLY', 'visible': False, 'releaseEligible': False, 'progressEffect': 0, 'approvedProductionTrustRoot': False, 'counts': {'apps': 1, 'lessons': 39, 'scenes': 292, 'variants': 292, 'heldVariants': 0, 'generatedMedia': 0, 'qualifiedMedia': 0}, 'lessons': membership}
    catalog_raw = canonical(catalog)
    catalog_sha = sha(catalog_raw)
    fixture = {'schemaVersion': 1, 'kind': 'JABLAB_EDITORIAL_CLOSED_QA_SOURCE_PINS_V1', 'sourceCatalogSHA256': catalog_sha, 'manifestSHA256': manifest_sha, 'sourceProofSHA256': proof_sha, 'app': 'jablab', 'courseSourceSHA256': COURSE_AFTER, 'lessons': membership, 'visible': False, 'releaseEligible': False, 'progressEffect': 0, 'mediaBytesAccepted': False, 'nativePlaybackAccepted': False}
    source_slice = {'schemaVersion': 1, 'kind': 'MOTION_V2L_APP_SOURCE_SLICE_V1', 'appId': 'jablab', 'sourceCatalogSHA256': catalog_sha, 'sourceManifestSHA256': manifest_sha, 'sourceProofSHA256': proof_sha, 'courseSourceSHA256': COURSE_AFTER, 'lessons': membership, 'holds': []}
    rows = []
    for lesson in membership:
        for order, scene in enumerate(lesson['scenes']):
            for variant in scene['variants']:
                rows.append([variant['sourcePinSHA256'], lesson['lessonId'], lesson['assetId'], scene['sceneId'], order, variant['stem'], lesson['lessonCanonicalSHA256'], scene['productionSpecSHA256'], scene['sourceCueSHA256'], scene['idempotencyKey'], False])
    rows.sort(key=lambda row: row[0])
    projection = {'schemaVersion': 1, 'kind': 'MOTION_V2L_APP_SOURCE_PROJECTION_V1', 'appId': 'jablab', 'sourceCatalogSHA256': catalog_sha, 'sourceManifestSHA256': manifest_sha, 'courseSourceSHA256': COURSE_AFTER, 'rows': rows}
    fixture_raw = pretty(fixture)
    slice_raw, projection_raw = canonical(source_slice), canonical(projection)
    require(len(slice_raw) <= 2 * 1024**2 and len(projection_raw) <= 2 * 1024**2, 'existing consumer size limit')
    outputs = {'tool/boxing_editorial_source/source_proof.v1.json': proof_raw, 'tool/boxing_editorial_source/production_manifest.v1.json': manifest_raw, 'tool/boxing_editorial_source/source_pins.v1.json': catalog_raw, 'test/fixtures/jablab_editorial_source_pins.v1.json': fixture_raw, 'assets/motion_content/jablab.editorial.source-slice.v1.json': slice_raw, 'assets/motion_content/jablab.editorial.source-projection.v1.json': projection_raw}
    dart = ['// App-owned original editorial delta; closed source QA only.', '// Historical v2k inputs remain immutable. This is not media/rights/physical acceptance.', f"const jablabEditorialSourcePinCatalogSha256 =\n    '{catalog_sha}';", f"const jablabEditorialSourcePinManifestSha256 =\n    '{manifest_sha}';", f"const jablabEditorialSourcePinProofSha256 =\n    '{proof_sha}';", 'const jablabEditorialClosedQaReleaseEligible = false;', 'const jablabEditorialClosedQaProgressEffect = 0;', 'const Set<String> jablabEditorialClosedQaSourcePinHashes = {', *[f"  '{pin}'," for pin in sorted(pins)], '};', '']
    outputs['lib/app/lesson_media_source_pins_editorial.dart'] = '\n'.join(dart).encode()
    selector = '''/// Current app-owned editorial source identity only; no media acceptance.
abstract final class JabLabSourceProjectionPin {
  static const appId = 'jablab';
  static const coursePath = 'assets/content/solo_boxing_course.v1.json';
  static const slicePath =\n      'assets/motion_content/jablab.editorial.source-slice.v1.json';
  static const projectionPath =\n      'assets/motion_content/jablab.editorial.source-projection.v1.json';
  static const qaFixturePath =\n      'test/fixtures/jablab_editorial_source_pins.v1.json';
'''
    for name, value in {'courseSha256': COURSE_AFTER, 'sliceSha256': sha(slice_raw), 'projectionSha256': sha(projection_raw), 'qaFixtureSha256': sha(fixture_raw), 'sourceCatalogSha256': catalog_sha, 'sourceManifestSha256': manifest_sha, 'sourceProofSha256': proof_sha, 'producerSha256': proof['producerSha256']}.items():
        selector += f"  static const {name} =\n      '{value}';\n"
    selector += '  static const lessonCount = 39;\n  static const sceneCount = 292;\n  static const variantCount = 292;\n  static const heldCount = 0;\n}\n'
    outputs['lib/app/media_source_projection_pin.dart'] = selector.encode()

    require(canonical(baseline_subset) == read_bytes(subset_path), 'sealed subset actual bytes mismatch')
    diagnostics = {'changedLessonIds': changed_lessons, 'changedCues': cue_changes, 'changedCueCount': 7, 'unchangedCueCount': 285, 'regeneratedProductionSpecs': 292, 'regeneratedIdempotencyAndFilenameStems': 292, 'regeneratedSourcePins': 292}
    return outputs, diagnostics


def local_reader(app_root):
    def read_bytes(relative):
        parts = Path(relative).parts
        require(parts and not Path(relative).is_absolute() and '..' not in parts and '\\' not in relative and '\x00' not in relative, 'unsafe input path')
        path = app_root
        for part in parts:
            path = path / part
            require(not path.is_symlink(), 'linked input path')
        require(path.is_file(), 'input is not a regular file: ' + relative)
        raw = path.read_bytes()
        require(0 < len(raw) <= 2 * 1024**2, 'input byte limit: ' + relative)
        return raw
    return read_bytes


def check_output_reader(read_bytes, outputs):
    for name, expected in outputs.items():
        require(read_bytes(name) == expected, 'generated output drift: ' + name)


def check_outputs(app_root, outputs):
    check_output_reader(local_reader(app_root), outputs)


def write_create_only(app_root, outputs):
    # Preflight every target before the first write; no existing unequal output
    # is overwritten. Root normally applies reviewed afterimages then --check.
    for name, expected in outputs.items():
        target = app_root / name
        for ancestor in [target, *target.parents]:
            if ancestor == app_root.parent:
                break
            require(not ancestor.is_symlink(), 'linked output path')
        require(not target.exists() or (target.is_file() and target.read_bytes() == expected), 'existing output differs: ' + name)
    for name, expected in outputs.items():
        target = app_root / name
        if target.exists():
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as stream:
            stream.write(expected)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--check', action='store_true')
    args = parser.parse_args()
    app_root = Path(__file__).resolve().parents[1]
    outputs, diagnostics = build_bundle(local_reader(app_root))
    if args.write:
        write_create_only(app_root, outputs)
    check_outputs(app_root, outputs)
    print(json.dumps({'state': 'PASS_CURRENT_EDITORIAL_SOURCE_ONLY_RELEASE_CLOSED', **diagnostics, 'files': {name: sha(raw) for name, raw in outputs.items()}}, sort_keys=True))


if __name__ == '__main__':
    main()
