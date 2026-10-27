"""Offline store submission draft export and build-input preflight.

Never builds, signs, logs config values, contacts providers or publishes forms.
"""
import argparse,base64,hashlib,json,plistlib,re,subprocess,urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path
from prepare_store_assets import export_assets

LIMITS={'name':30,'subtitle':30,'promotionalText':170,'keywords':100}
EXPECTED_TYPES={'EmailAddress','Name','UserID','OtherDiagnosticData','CoarseLocation','OtherDataTypes'}

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def validate_public_config(path):
    data=json.loads(Path(path).read_text())
    required={'MOTION_SUPABASE_URL','MOTION_SUPABASE_PUBLISHABLE_KEY'}
    if not isinstance(data,dict) or set(data)!=required:raise ValueError('Config must contain exactly the two public Motion keys')
    url=data['MOTION_SUPABASE_URL'];key=data['MOTION_SUPABASE_PUBLISHABLE_KEY']
    if not isinstance(url,str) or not isinstance(key,str):raise ValueError('Public config fields must be strings')
    u=urllib.parse.urlsplit(url)
    if u.scheme!='https' or not u.hostname or u.username or u.password or u.query or u.fragment:raise ValueError('HTTPS project URL required')
    if key.startswith('sb_secret_'):raise ValueError('Secret key forbidden in a client config')
    if key.startswith('sb_publishable_'):
        if len(key)<20:raise ValueError('Malformed publishable key')
    else:
        try:
            parts=key.split('.');payload=json.loads(base64.urlsafe_b64decode(parts[1]+'='*(-len(parts[1])%4)))
            if len(parts)!=3 or payload.get('role')!='anon':raise ValueError('Only legacy anon role permitted')
        except (IndexError,ValueError,TypeError) as e:raise ValueError('Publishable or legacy anon client key required') from e
    # Syntax/role guard only. No signature, live project or account verification.
    return {'path':str(Path(path).resolve()),'sha256':sha(path),'fields':sorted(required),'syntax':'PASS','live_account_verified':False}

def public_listing(data):
    result={key:data[key] for key in ['appStore','description','supportUrl','privacyPolicyUrl']}
    result['playStore']={'shortDescription':data['playStore']['shortDescription']}
    if set(result['appStore'])!=set(LIMITS):raise ValueError('Unexpected App Store fields')
    for name,limit in LIMITS.items():
        value=result['appStore'][name]
        if not isinstance(value,str):raise ValueError('App Store text limit: '+name)
        length=len(value.encode('utf-8')) if name=='keywords' else len(value)
        if not 0<length<=limit:raise ValueError('App Store text limit: '+name)
    if not 0<len(result['playStore']['shortDescription'])<=80 or not 0<len(result['description'])<=4000:raise ValueError('Play/description text limit')
    for name in ['supportUrl','privacyPolicyUrl']:
        if urllib.parse.urlsplit(result[name]).scheme!='https':raise ValueError('HTTPS listing URL required')
    return result

def privacy_rows(path):
    data=plistlib.loads(Path(path).read_bytes())
    if data['NSPrivacyTracking'] or data['NSPrivacyTrackingDomains']:raise ValueError('Tracking policy changed')
    rows=data['NSPrivacyCollectedDataTypes'];types=set()
    for row in rows:
        key=row['NSPrivacyCollectedDataType'].removeprefix('NSPrivacyCollectedDataType');types.add(key)
        if not row['NSPrivacyCollectedDataTypeLinked'] or row['NSPrivacyCollectedDataTypeTracking'] or row['NSPrivacyCollectedDataTypePurposes']!=['NSPrivacyCollectedDataTypePurposeAppFunctionality']:raise ValueError('Privacy purpose/linkage changed')
    if types!=EXPECTED_TYPES or len(rows)!=6:raise ValueError('Unexpected privacy categories')
    return rows

def native_identity(repo):
    repo=Path(repo);android='{http://schemas.android.com/apk/res/android}'
    manifest=ET.fromstring((repo/'android/app/src/main/AndroidManifest.xml').read_text())
    application=manifest.find('application')
    if application is None or application.get(android+'label')!='JabLab':raise ValueError('Android display name mismatch')
    permissions={p.get(android+'name') for p in manifest.findall('uses-permission')}
    if permissions!={'android.permission.INTERNET','android.permission.CAMERA'}:raise ValueError('Unexpected Android source permissions')
    callbacks=[d for d in manifest.findall('.//data') if d.get(android+'scheme')=='com.yulalab.jablab']
    if len(callbacks)!=1 or callbacks[0].get(android+'host')!='auth' or callbacks[0].get(android+'path')!='/callback':raise ValueError('Exact account callback missing')
    info=plistlib.loads((repo/'ios/Runner/Info.plist').read_bytes())
    if info.get('CFBundleDisplayName')!='JabLab' or 'NSMicrophoneUsageDescription' in info:raise ValueError('iOS display/permission mismatch')
    families=set(re.findall(r'TARGETED_DEVICE_FAMILY = ([^;]+);',(repo/'ios/Runner.xcodeproj/project.pbxproj').read_text()))
    if families!={'1'}:raise ValueError('Device families changed; revisit screenshot requirements')
    return {'displayName':'JabLab','callback':'com.yulalab.jablab://auth/callback','androidSourcePermissions':sorted(permissions),'deviceFamily':'iPhone only','mergedBinaryPermissionsVerified':False}

def build_prerequisite_gates(target,pods_ready):
    gates=[]
    if target!='lib/main.dart':gates.append('FLUTTER_TARGET_REGENERATION_REQUIRED')
    if not pods_ready:gates.append('LOCKED_IOS_PODS_INSTALL_REQUIRED')
    return gates

def export_packet(repo,output,config=None):
    repo=Path(repo).resolve();output=Path(output).resolve()
    if output.exists():raise FileExistsError('Output must be new; existing evidence is preserved')
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip();tree=subprocess.check_output(['git','rev-parse','HEAD^{tree}'],cwd=repo,text=True).strip();status=subprocess.check_output(['git','status','--porcelain'],cwd=repo,text=True).strip()
    locales={locale:public_listing(json.loads((repo/'docs/store'/name).read_text())) for locale,name in [('en-US','listing.json'),('tr-TR','listing.tr-TR.json')]}
    rows=privacy_rows(repo/'ios/Runner/PrivacyInfo.xcprivacy');identity=native_identity(repo)
    version=re.search(r'^version:\s*(\S+)',(repo/'pubspec.yaml').read_text(),re.M).group(1)
    generated=repo/'ios/Flutter/Generated.xcconfig';target=None
    if generated.exists():
        m=re.search(r'^FLUTTER_TARGET=(.*)$',generated.read_text(),re.M);target=m.group(1) if m else None
    profile=repo/'docs/store/release-review.json';review=json.loads(profile.read_text())
    if review['appReview']['reviewAccount'] is not None:raise ValueError('Review credentials belong in the secure store flow, not this packet')
    # Required draft fields stay explicitly pending; absence never yields ready.
    blocked=['CURRENT_SIGNED_BINARY','REAL_ACCOUNT_ACCEPTANCE','PHYSICAL_DEVICE_ACCEPTANCE','FINAL_PRIVACY_PROVIDER_READBACK','NATIVE_SCREENSHOTS','FEATURE_GRAPHIC_OWNER_REVIEW','USER_RELEASE_DECISION']
    # A URL that is not live yet (pending_live) still blocks.
    if not review['play']['accountDeletionWebUrl'] or review['play'].get('accountDeletionWebUrlStatus')!='live':blocked.append('PLAY_ACCOUNT_DELETION_WEB_URL')
    if not config:blocked.append('APPROVED_PUBLIC_CONFIG_PATH')
    blocked.extend(build_prerequisite_gates(target,(repo/'ios/Pods/Manifest.lock').is_file()))
    config_receipt=validate_public_config(config) if config else None
    spec={'status':'LOCAL_DRAFT_PACKET_ONLY_NOT_RELEASE_ACCEPTANCE','source':{'head':head,'tree':tree,'working_tree_status':status},'identity':{'bundle':'com.yulalab.jablab','asc_id':'6794715669','source_version':version,'candidate_version':'1.0.0','candidate_build':3,'candidate_build_is_explicit_override_not_existing_package':True},'locales':locales,'nativeIdentity':identity,'applePrivacy':rows,'review':review,'public_config':config_receipt,'preflight':{'generated_flutter_target':target,'must_regenerate_with_explicit_main_and_config_before_build':True,'android_signing_file_present':(repo/'android/key.properties').is_file(),'android_key_access_tested':False,'ios_pods_lock_present':(repo/'ios/Podfile.lock').is_file(),'ios_pods_manifest_present':(repo/'ios/Pods/Manifest.lock').is_file(),'private_key_or_profile_access_tested':False,'new_build_started':False},'blocked_gates':blocked,'source_hashes':{name:sha(repo/name) for name in ['pubspec.yaml','pubspec.lock','packages/jablab_engine/pubspec.lock','ios/Runner/PrivacyInfo.xcprivacy','docs/store/listing.json','docs/store/listing.tr-TR.json','docs/store/release-review.json']},'no_remote_writes':True}
    output.mkdir(parents=True,mode=0o700)
    spec['storeAssets']=export_assets(repo,output/'assets')
    for locale,payload in locales.items():(output/(locale+'.json')).write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n')
    (output/'release-packet.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n')
    return spec

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,default=Path(__file__).resolve().parents[1]);p.add_argument('--out',type=Path);p.add_argument('--public-config',type=Path);p.add_argument('--validate-config',type=Path);a=p.parse_args()
    if a.validate_config:result=validate_public_config(a.validate_config)
    elif a.out:result=export_packet(a.repo,a.out,a.public_config)
    else:p.error('--out or --validate-config required')
    print(json.dumps(result if a.validate_config else {'status':result['status'],'source':result['source']['head'],'blocked_gates':result['blocked_gates']},ensure_ascii=False))
