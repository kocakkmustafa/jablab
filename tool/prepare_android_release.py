"""Regenerate Android release glue using the installed Flutter tool, without a build.

Run after offline pub get and release --config-only --no-pub, immediately before
direct offline Gradle. Do not call pub afterwards: it writes non-release glue.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

ADAPTER = r'''import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';

Future<void> main(List<String> args) async {
  Cache.flutterRoot = args[0];
  await runInContext(() async {
    final project = FlutterProject.fromDirectory(globals.fs.directory(args[1]));
    await injectPlugins(project, releaseMode: true, androidPlatform: true);
  }, overrides: {TemplateRenderer: () => const MustacheTemplateRenderer()});
}
'''
REGISTRANT = 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate_registrant(metadata, java):
    plugins = metadata['plugins']['android']
    if any(type(p.get('dev_dependency')) is not bool for p in plugins):
        raise ValueError('Plugin dev_dependency metadata must be explicit')
    expected = {p['name'] for p in plugins if p.get('native_build', True) and not p['dev_dependency']}
    rows = re.findall(r'Error registering plugin ([\w]+), ([\w.]+)"', java)
    actual = {name for name, _ in rows}
    if actual != expected or len(rows) != len(actual):
        raise ValueError('Release registrant mismatch: unexpected=' + ','.join(sorted(actual-expected))
                         + '; missing=' + ','.join(sorted(expected-actual)))
    return {'production_plugins': sorted(actual), 'count': len(actual),
            'excluded_dev_plugins': sorted(p['name'] for p in plugins if p['dev_dependency']),
            'classes': dict(rows)}


def prepare(repo, flutter_root, evidence):
    repo, flutter_root, evidence = map(lambda p: Path(p).resolve(), (repo, flutter_root, evidence))
    if evidence.exists():
        raise FileExistsError('Use a new evidence folder; original glue is preserved')
    version = json.loads((flutter_root/'bin/cache/flutter.version.json').read_text())
    if version['frameworkVersion'] != '3.47.5':
        raise ValueError('Revalidate Flutter internal generator adapter for this SDK version')
    package_config = flutter_root/'packages/flutter_tools/.dart_tool/package_config.json'
    dart = flutter_root/'bin/cache/dart-sdk/bin/dart'
    if not package_config.is_file() or not dart.is_file():
        raise FileNotFoundError('Installed Flutter tool dependencies required; no download attempted')
    registry = repo/REGISTRANT
    original = registry.read_text()
    if 'Generated file. Do not edit.' not in original:
        raise ValueError('Unexpected registry ownership; preserve and review manually')
    evidence.mkdir(parents=True)
    shutil.copyfile(registry, evidence/'registrant-before.java')
    adapter = evidence/'flutter_release_generator.dart'
    adapter.write_text(ADAPTER)
    pinned = ['pubspec.yaml', 'pubspec.lock', '.dart_tool/package_config.json', '.flutter-plugins-dependencies']
    before = {p: digest(repo/p) for p in pinned}
    command = ['/usr/bin/sandbox-exec', '-p', '(version 1) (allow default) (deny network*)',
               str(dart), '--packages='+str(package_config), str(adapter), str(flutter_root), str(repo)]
    env = dict(os.environ, CI='true', FLUTTER_SUPPRESS_ANALYTICS='true')
    run = subprocess.run(command, cwd=repo, env=env, capture_output=True, text=True, timeout=90)
    (evidence/'generator.log').write_text(run.stdout + run.stderr)
    if run.returncode:
        raise RuntimeError('Official generator failed; inspect preserved generator.log')
    if before != {p: digest(repo/p) for p in pinned}:
        raise RuntimeError('Generator changed dependency inputs; stop before any native build')
    receipt = validate_registrant(json.loads((repo/'.flutter-plugins-dependencies').read_text()), registry.read_text())
    receipt.update(sdk=version['frameworkVersion'], command=command, exit_code=run.returncode,
                   before_sha256=digest(evidence/'registrant-before.java'), after_sha256=digest(registry),
                   dependency_inputs_unchanged=before, native_build_started=False,
                   network='denied per process', generated_by='official injectPlugins(releaseMode:true,androidPlatform:true)')
    (evidence/'RESULT.json').write_text(json.dumps(receipt, indent=2)+'\n')
    return receipt


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--flutter-root', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    receipt = prepare(args.repo, args.flutter_root, args.evidence)
    print(json.dumps({key: receipt[key] for key in ['count','production_plugins','excluded_dev_plugins','native_build_started']}))
