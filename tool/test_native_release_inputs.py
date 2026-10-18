import unittest
from prepare_android_release import validate_registrant


class NativeReleaseInputTests(unittest.TestCase):
    def setUp(self):
        self.metadata = {'plugins': {'android': [
            {'name': 'production_plugin', 'native_build': True, 'dev_dependency': False},
            {'name': 'integration_test', 'native_build': True, 'dev_dependency': True},
            {'name': 'dart_only', 'native_build': False, 'dev_dependency': False},
        ]}}
        self.release = 'Log.e(TAG, "Error registering plugin production_plugin, example.Production", e);'

    def test_release_retains_native_production_and_excludes_dev_and_dart_only(self):
        receipt = validate_registrant(self.metadata, self.release)
        self.assertEqual(receipt['production_plugins'], ['production_plugin'])
        self.assertEqual(receipt['excluded_dev_plugins'], ['integration_test'])

    def test_pub_generated_dev_plugin_leak_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'unexpected=integration_test'):
            validate_registrant(self.metadata, self.release + '\n"Error registering plugin integration_test, example.Test"')

    def test_missing_production_registration_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'missing=production_plugin'):
            validate_registrant(self.metadata, '')


if __name__ == '__main__':
    unittest.main()
