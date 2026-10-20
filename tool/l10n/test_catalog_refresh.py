"""Source-pair replacement must not leave a required dead translation key."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    'catalog_refresh_subject', Path(__file__).with_name('catalog.py'))
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)


class RefreshContracts(unittest.TestCase):
    def test_changed_ui_pair_retires_old_key_and_preserves_content(self):
        with tempfile.TemporaryDirectory(prefix='jablab-refresh-') as directory:
            root = Path(directory)
            app = root / 'lib/app'
            app.mkdir(parents=True)
            for filename in ['catalog_locale.dart', 'teach_locale.dart',
                             'content_failure_screen.dart', 'session_screen.dart',
                             'why_not_locale.dart', 'tai_chi_course_page.dart',
                             'select_page.dart']:
                (app / filename).write_text('')
            (app / 'example.dart').write_text(
                "void example() { text(context, en: 'New source', tr: 'Yeni kaynak'); }")
            (root / 'assets/content').mkdir(parents=True)
            (root / 'assets/content/library.json').write_text(
                json.dumps({'productName': 'JabLab', 'disciplines': []}))
            (root / 'l10n').mkdir()
            old_id = catalog.key('Old source', 'Eski kaynak')
            content_id = catalog.key('Lesson', 'Ders')
            entries = [
                {'id': old_id, 'en': 'Old source', 'tr': 'Eski kaynak',
                 'kind': 'UI', 'contexts': [{'path': 'lib/app/example.dart'}],
                 'placeholders': [], 'plural_arg': None},
                {'id': content_id, 'en': 'Lesson', 'tr': 'Ders',
                 'kind': 'CONTENT', 'contexts': [{'path': 'assets/content/course.json'}],
                 'placeholders': [], 'plural_arg': None},
            ]
            (root / 'l10n/source_catalog.json').write_text(
                json.dumps({'entries': entries}))
            original_root = catalog.ROOT
            try:
                catalog.ROOT = root
                refreshed = catalog.refresh()
            finally:
                catalog.ROOT = original_root
            by_id = {entry['id']: entry for entry in refreshed['entries']}
            self.assertNotIn(old_id, by_id)
            self.assertIn(catalog.key('New source', 'Yeni kaynak'), by_id)
            self.assertEqual(by_id[content_id]['contexts'],
                             [{'path': 'assets/content/course.json'}])


if __name__ == '__main__':
    unittest.main(verbosity=2)
