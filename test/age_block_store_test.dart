import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/age_block_store.dart';

void main() {
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('jablab_age_block_');
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('a fresh device starts unblocked', () async {
    final store = AgeBlockStore(directory: () async => temp);
    await store.load();
    expect(store.blocked, isFalse);
  });

  test('a recorded block survives a restart', () async {
    final first = AgeBlockStore(directory: () async => temp);
    await first.load();
    await first.markBlocked();
    expect(first.blocked, isTrue);

    final restarted = AgeBlockStore(directory: () async => temp);
    await restarted.load();
    expect(restarted.blocked, isTrue);
  });

  test('an unreadable location starts unblocked', () async {
    final store = AgeBlockStore(
      directory: () async => throw const FileSystemException('denied'),
    );
    await store.load();
    expect(store.blocked, isFalse);
    await store.markBlocked();
    expect(store.blocked, isTrue, reason: 'in-memory block holds this run');
  });

  test('production wires the durable block into the shared account page', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('await ageBlock.load();'));
    expect(main, contains('ageBlocked: ageBlock.blocked'));
    expect(
      main,
      contains('onAgeBlocked: () => unawaited(ageBlock.markBlocked())'),
    );
    final page = File(
      'lib/app/owner_bound_account_page.dart',
    ).readAsStringSync();
    expect(page, contains('ageBlocked: widget.ageBlocked'));
    expect(page, contains('onAgeBlocked: widget.onAgeBlocked'));
  });
}
