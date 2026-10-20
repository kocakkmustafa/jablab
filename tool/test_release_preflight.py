import base64,copy,fcntl,json,os,plistlib,subprocess,sys,tempfile,unittest
from pathlib import Path
from prepare_store_packet import validate_public_config,public_listing,privacy_rows,export_packet,native_identity,build_prerequisite_gates,EXPECTED_TYPES
from with_native_lease import run
from prepare_store_assets import approved_sources
from unittest.mock import patch
class ReleasePreparationTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(prefix='jablab-release-test-');self.addCleanup(self.temp.cleanup);self.root=Path(self.temp.name)
 def config(self,key='sb_publishable_SYNTHETIC_ONLY_NOT_REAL'):
  p=self.root/'config.json';p.write_text(json.dumps({'MOTION_SUPABASE_URL':'https://synthetic.invalid','MOTION_SUPABASE_PUBLISHABLE_KEY':key}));return p
 def listing(self):return {'appStore':{'name':'JabLab','subtitle':'Solo practice','promotionalText':'Bundled text lessons','keywords':'solo,boxing'},'playStore':{'shortDescription':'Text lessons','$private':'DO_NOT_EXPORT'},'description':'Manual practice record','supportUrl':'https://example.invalid/support','privacyPolicyUrl':'https://example.invalid/privacy','$history':'DO_NOT_EXPORT','cameraPermissionRationale':{'ios':'not a store field'}}
 def test_config_receipt_excludes_all_values(self):
  r=validate_public_config(self.config());encoded=json.dumps(r);self.assertNotIn('synthetic.invalid',encoded);self.assertNotIn('sb_publishable_',encoded);self.assertFalse(r['live_account_verified'])
 def test_secret_and_service_role_keys_fail_without_echo(self):
  for key in ['sb_secret_SYNTHETIC_DO_NOT_USE','x.'+base64.urlsafe_b64encode(b'{"role":"service_role"}').decode()+'.x']:
   with self.assertRaises(ValueError) as e:validate_public_config(self.config(key))
   self.assertNotIn(key,str(e.exception))
 def test_https_credentials_query_and_extra_fields_rejected(self):
  p=self.config()
  for url in ['http://synthetic.invalid','https://user:password@synthetic.invalid','https://synthetic.invalid?secret=x']:
   d=json.loads(p.read_text());d['MOTION_SUPABASE_URL']=url;p.write_text(json.dumps(d))
   with self.assertRaises(ValueError):validate_public_config(p)
  p=self.config();d=json.loads(p.read_text());d['SERVICE_ROLE_KEY']='NEVER_EXPORT';p.write_text(json.dumps(d))
  with self.assertRaises(ValueError):validate_public_config(p)
 def test_legacy_anon_role_is_syntax_only_not_account_acceptance(self):
  key='x.'+base64.urlsafe_b64encode(b'{"role":"anon"}').decode()+'.x';self.assertFalse(validate_public_config(self.config(key))['live_account_verified'])
 def test_store_export_is_explicit_allowlist(self):
  r=public_listing(self.listing());s=json.dumps(r);self.assertNotIn('DO_NOT_EXPORT',s);self.assertNotIn('cameraPermissionRationale',r);self.assertEqual(set(r['playStore']),{'shortDescription'})
 def test_keywords_accept_exactly_100_utf8_bytes(self):
  for keywords in ['x'*100,'影'*32+',jab','م'*48+',jab']:
   with self.subTest(keywords=keywords):
    self.assertEqual(len(keywords.encode('utf-8')),100)
    data=self.listing();data['appStore']['keywords']=keywords
    self.assertEqual(public_listing(data)['appStore']['keywords'],keywords)
 def test_keywords_reject_101_utf8_bytes(self):
  for keywords in ['x'*101,'影'*32+',jaba','م'*48+',jaba']:
   with self.subTest(keywords=keywords):
    self.assertEqual(len(keywords.encode('utf-8')),101)
    data=self.listing();data['appStore']['keywords']=keywords
    with self.assertRaisesRegex(ValueError,'App Store text limit: keywords'):public_listing(data)
 def test_overlong_store_text_and_insecure_policy_url_rejected(self):
  for field,value in [('description','x'*4001),('privacyPolicyUrl','http://example.invalid/privacy')]:
   d=self.listing();d[field]=value
   with self.assertRaises(ValueError):public_listing(d)
  d=self.listing();d['appStore']['name']='x'*31
  with self.assertRaises(ValueError):public_listing(d)
 def test_privacy_exact_six_linked_functionality_types(self):
  d={'NSPrivacyTracking':False,'NSPrivacyTrackingDomains':[],'NSPrivacyCollectedDataTypes':[{'NSPrivacyCollectedDataType':'NSPrivacyCollectedDataType'+name,'NSPrivacyCollectedDataTypeLinked':True,'NSPrivacyCollectedDataTypeTracking':False,'NSPrivacyCollectedDataTypePurposes':['NSPrivacyCollectedDataTypePurposeAppFunctionality']} for name in sorted(EXPECTED_TYPES)]};p=self.root/'privacy.plist';p.write_bytes(plistlib.dumps(d));self.assertEqual(len(privacy_rows(p)),6)
  for mutated in [dict(d,NSPrivacyTracking=True),dict(d,NSPrivacyCollectedDataTypes=d['NSPrivacyCollectedDataTypes'][:-1])]:
   p.write_bytes(plistlib.dumps(mutated))
   with self.assertRaises(ValueError):privacy_rows(p)
 def native_fixture(self):
  (self.root/'android/app/src/main').mkdir(parents=True);(self.root/'ios/Runner').mkdir(parents=True);(self.root/'ios/Runner.xcodeproj').mkdir(parents=True)
  (self.root/'android/app/src/main/AndroidManifest.xml').write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><uses-permission android:name="android.permission.INTERNET"/><uses-permission android:name="android.permission.CAMERA"/><application android:label="JabLab"><activity><intent-filter><data android:scheme="com.yulalab.jablab" android:host="auth" android:path="/callback"/></intent-filter></activity></application></manifest>')
  (self.root/'ios/Runner/Info.plist').write_bytes(plistlib.dumps({'CFBundleDisplayName':'JabLab'}));(self.root/'ios/Runner.xcodeproj/project.pbxproj').write_text('TARGETED_DEVICE_FAMILY = 1;')
 def test_native_identity_and_exact_source_permissions(self):
  self.native_fixture();r=native_identity(self.root);self.assertEqual(r['deviceFamily'],'iPhone only');self.assertFalse(r['mergedBinaryPermissionsVerified'])
  p=self.root/'android/app/src/main/AndroidManifest.xml';p.write_text(p.read_text().replace('android:label="JabLab"','android:label="wrong"'))
  with self.assertRaises(ValueError):native_identity(self.root)
 def test_permission_callback_and_device_family_changes_fail_closed(self):
  self.native_fixture();p=self.root/'android/app/src/main/AndroidManifest.xml';original=p.read_text()
  for altered in [original.replace('/callback','/other'),original.replace('</manifest>','<uses-permission android:name="android.permission.RECORD_AUDIO"/></manifest>')]:
   p.write_text(altered)
   with self.assertRaises(ValueError):native_identity(self.root)
  p.write_text(original);(self.root/'ios/Runner.xcodeproj/project.pbxproj').write_text('TARGETED_DEVICE_FAMILY = "1,2";')
  with self.assertRaises(ValueError):native_identity(self.root)
 def test_listener_and_missing_pods_are_explicit_build_prerequisites(self):
  self.assertEqual(build_prerequisite_gates('/tmp/test_listener.dart',False),['FLUTTER_TARGET_REGENERATION_REQUIRED','LOCKED_IOS_PODS_INSTALL_REQUIRED'])
  self.assertEqual(build_prerequisite_gates('lib/main.dart',True),[])
 def test_changed_icon_hash_rejected_without_writing_any_asset(self):
  with patch('prepare_store_assets.digest',return_value='SYNTHETIC_CHANGED_SHA'):
   with self.assertRaisesRegex(ValueError,'Approved icon source hash mismatch'):approved_sources(self.root)
 def test_existing_output_never_overwritten(self):
  with self.assertRaises(FileExistsError):export_packet(self.root,self.root)
 def test_lease_contention_starts_no_child(self):
  lock=self.root/'lock';lock.touch();marker=self.root/'marker'
  with lock.open('rb') as f:
   fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)
   r=run(lock,[sys.executable,'-c','from pathlib import Path;Path("'+str(marker)+'").touch()'])
   self.assertEqual(r,75);self.assertFalse(marker.exists())
 def test_child_exit_propagates_and_lease_releases(self):
  lock=self.root/'lock';lock.touch();self.assertEqual(run(lock,[sys.executable,'-c','raise SystemExit(7)']),7)
  with lock.open('rb') as f:fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB);fcntl.flock(f,fcntl.LOCK_UN)
 def test_missing_lock_does_not_create_new_mutex(self):
  lock=self.root/'absent'
  with self.assertRaises(FileNotFoundError):run(lock,[sys.executable,'-c','pass'])
  self.assertFalse(lock.exists())
if __name__=='__main__':unittest.main()
