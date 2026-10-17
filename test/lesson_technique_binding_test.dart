import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/content_repository.dart';
import 'package:jablab_engine/jablab_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = ContentRepository();
  late Library library;
  late RuleSet rules;
  setUpAll(() async {
    final content = await repository.load();
    library = content.library;
    rules = content.boxing;
  });

  test(
    'jab, cross and combination lessons bind only their declared techniques',
    () {
      expect(
        repository.liveTechniqueIdsFor(
          library,
          rules,
          'boxing.foundations.jab',
        ),
        {'jab'},
      );
      expect(
        repository.liveTechniqueIdsFor(
          library,
          rules,
          'boxing.foundations.cross',
        ),
        {'cross'},
      );
      expect(
        repository.liveTechniqueIdsFor(
          library,
          rules,
          'boxing.foundations.one_two',
        ),
        {'jab', 'cross'},
      );
    },
  );
  test(
    'stance/setup/footwork do not acquire punch counters by camera availability',
    () {
      for (final id in [
        'boxing.foundations.camera',
        'boxing.foundations.stance',
        'boxing.footwork.moving',
      ]) {
        expect(repository.usesCamera(library, id), isTrue);
        expect(repository.liveTechniqueIdsFor(library, rules, id), isEmpty);
      }
    },
  );
  test('unknown lesson cannot silently use the full boxing ruleset', () {
    expect(
      () => repository.liveTechniqueIdsFor(library, rules, 'kb-12'),
      throwsStateError,
    );
  });
  test('lesson selection is immutable for a session', () {
    final ids = repository.liveTechniqueIdsFor(
      library,
      rules,
      'boxing.foundations.jab',
    );
    expect(() => ids.add('cross'), throwsUnsupportedError);
  });
}
