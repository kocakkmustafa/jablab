"""Offline exact-source catalog and bundle validation. No network or SDK required."""
from pathlib import Path
import argparse, hashlib, json, re
ROOT = Path(__file__).resolve().parents[2]
LOCALES = ['tr','en','es-419','pt-BR','de','fr','ja','ar']

def key(en, tr):
    return 's_' + hashlib.sha256((en+'\0'+tr).encode()).hexdigest()

def lex(s):
    tokens=[]; i=0
    while i<len(s):
        if s[i].isspace(): i+=1; continue
        if s.startswith('//',i):
            j=s.find('\n',i); i=len(s) if j<0 else j; continue
        if s.startswith('/*',i):
            depth=1;i+=2
            while i<len(s) and depth:
                if s.startswith('/*',i): depth+=1;i+=2
                elif s.startswith('*/',i): depth-=1;i+=2
                else:i+=1
            continue
        raw=s[i:i+1] in ('r','R') and s[i+1:i+2] in ('"',"'")
        q=i+1 if raw else i
        if s[q:q+1] in ('"',"'"):
            start=i; d=s[q:q+3] if s[q:q+3] in ('"""',"'''") else s[q]; j=q+len(d)
            while j<len(s):
                if not raw and s[j]=='\\':j+=2;continue
                # Dart interpolation is retained verbatim for manual migration.
                if not raw and s.startswith('${',j):
                    b=1;j+=2
                    while j<len(s) and b:
                        if s[j]=='{':b+=1
                        elif s[j]=='}':b-=1
                        elif s[j] in ('"',"'"):
                            quote=s[j];j+=1
                            while j<len(s) and s[j]!=quote:
                                j+=2 if s[j]=='\\' else 1
                        j+=1
                    continue
                if s.startswith(d,j):break
                j+=1
            tokens.append(('str',s[start:j+len(d)],start));i=j+len(d);continue
        m=re.match(r'[A-Za-z_$][A-Za-z_0-9$]*',s[i:])
        if m:
            v=m.group();tokens.append(('id',v,i));i+=len(v)
        else:tokens.append(('p',s[i],i));i+=1
    return tokens

def decode(tokens):
    if not tokens or any(t[0]!='str' for t in tokens):return None
    out=''
    for _,s,_ in tokens:
        raw=s[0] in 'rR';s=s[1:] if raw else s
        d=s[:3] if s[:3] in ('"""',"'''") else s[0];v=s[len(d):-len(d)]
        if not raw:
            if re.search(r'(?<!\\)\$',v):return None
            def esc(m):
                v=m[1]
                if v.startswith('u{'):return chr(int(v[2:-1],16))
                if v.startswith('u'):return chr(int(v[1:],16))
                if v.startswith('x'):return chr(int(v[1:],16))
                return {'n':'\n','r':'\r','t':'\t','b':'\b','f':'\f','v':'\v'}.get(v,v)
            v=re.sub(r'\\(u\{[0-9a-fA-F]+\}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|.)',esc,v)
        out+=v
    return out

def variants(tokens):
    """Enumerate source-matched literal branches; never evaluate Dart code."""
    while len(tokens)>1 and tokens[0][1]=='(' and tokens[-1][1]==')':
        depth=0;outer=True
        for i,t in enumerate(tokens):
            if t[1]=='(':depth+=1
            elif t[1]==')':depth-=1
            if depth==0 and i<len(tokens)-1:outer=False;break
        if not outer:break
        tokens=tokens[1:-1]
    literal=decode(tokens)
    if literal is not None:return [((),literal)]
    if tokens and tokens[0][1]=='switch':
        brace=next((i for i,t in enumerate(tokens) if t[1]=='{'),None)
        if brace is not None and tokens[-1][1]=='}':
            result=[]
            for branch in arguments(tokens,brace,len(tokens)-1):
                arrow=next((i for i in range(len(branch)-1) if branch[i][1]=='=' and branch[i+1][1]=='>'),None)
                if arrow is None:return []
                route=''.join(t[1] for t in branch[:arrow])
                values=variants(branch[arrow+2:])
                if not values:return []
                result += [(((route,True),)+rest,text) for rest,text in values]
            return result

    depth=0;question=None;nested=0
    for i,t in enumerate(tokens):
        v=t[1]
        if v in ('(','{','['):depth+=1
        elif v in (')','}',']'):depth-=1
        elif depth==0 and v=='?':
            if question is None:question=i
            else:nested+=1
        elif depth==0 and v==':' and question is not None:
            if nested:nested-=1;continue
            condition=''.join(x[1] for x in tokens[:question])
            yes=variants(tokens[question+1:i]);no=variants(tokens[i+1:])
            if yes and no:
                return [(((condition,True),)+route,value) for route,value in yes]+[(((condition,False),)+route,value) for route,value in no]
            return []
    return []

def pair_variants(en,tr):
    a=dict(variants(en));b=dict(variants(tr))
    return [(a[k],b[k]) for k in a if k in b] if a.keys()==b.keys() else []

def groups(t):
    stack=[];out=[]
    for i,x in enumerate(t):
        if x[1] in ('(','{','['):stack.append(i)
        elif x[1] in (')','}',']') and stack:
            start=stack.pop();out.append((start,i))
    return out

def arguments(t,start,end):
    args=[];begin=start+1;depth=0
    for i in range(start+1,end):
        v=t[i][1]
        if v in ('(','{','['):depth+=1
        elif v in (')','}',']'):depth-=1
        elif v==',' and depth==0:args.append(t[begin:i]);begin=i+1
    if begin<end:args.append(t[begin:end])
    return args

def refresh():
    path=ROOT/'l10n/source_catalog.json';data=json.loads(path.read_text());entries={x['id']:x for x in data['entries']}
    # Rebuild UI contexts, retaining authored content order and stable IDs.
    for e in entries.values():e['contexts']=[x for x in e['contexts'] if not x['path'].startswith('lib/')]
    def add(en,tr,p,pos):
        if en is None or tr is None:return
        ident=key(en,tr)
        if ident not in entries:entries[ident]={'id':ident,'en':en,'tr':tr,'placeholders':re.findall(r'\{(\w+)\}',en),'plural_arg':None,'contexts':[],'kind':'UI'}
        ctx={'path':str(p.relative_to(ROOT)),'line':p.read_text().count('\n',0,pos)+1}
        if ctx not in entries[ident]['contexts']:entries[ident]['contexts'].append(ctx)
        return entries[ident]
    unresolved=[]
    for p in sorted((ROOT/'lib').rglob('*.dart')):
        s=p.read_text();t=lex(s)
        for begin,end in groups(t):
            args=arguments(t,begin,end);named={a[0][1]:a[2:] for a in args if len(a)>2 and a[0][0]=='id' and a[1][1]==':'}
            if 'en' in named and 'tr' in named:
                pairs=pair_variants(named['en'],named['tr'])
                for en,tr in pairs:
                    e=add(en,tr,p,t[begin][2])
                    if 'pluralArg' in named:e['plural_arg']=decode(named['pluralArg'])
                if not pairs:unresolved.append({'path':str(p.relative_to(ROOT)),'line':s.count('\n',0,t[begin][2])+1,'type':'dynamic-pair'})
            if begin:
                name=t[begin-1][1]
                pair=[]
                if name=='StudyText' and len(args)==2:pair=args
                elif name=='text' and p.name=='technique_capability_panel.dart' and t[begin-2][1]!='.' and len(args)==2:pair=args
                elif name in ('_label','_text') and len(args)>=3 and args[0] and args[0][0][1]=='context':pair=args[1:3]
                # Authored (section-id, Copy, English-label, Turkish-label) rows.
                elif p.name=='taikyoku_shodan_course_page.dart' and len(args)==4 and decode(args[0]) in {'start','feet','hands','finish','next','limit'} and decode(args[2]) is not None and decode(args[3]) is not None:pair=args[2:4]
                if pair:
                    pairs=pair_variants(*pair)
                    for en,tr in pairs:add(en,tr,p,t[begin][2])
                    if not pairs:unresolved.append({'path':str(p.relative_to(ROOT)),'line':s.count('\n',0,t[begin][2])+1,'type':'dynamic-positional'})
        # English-keyed presentation maps only, not identifiers or source hashes.
        map_names={'cueCopies','_boxingMeasured','_boxingNotMeasured','_componentLabelsTr','_tempoBandsTr','_materialReasonsTr'}
        for begin,end in groups(t):
            if t[begin][1]!='{':continue
            prefix=s[max(0,t[begin][2]-100):t[begin][2]]
            if not any(re.search(r'\b'+n+r'\b',prefix) for n in map_names):continue
            for a in arguments(t,begin,end):
                split=next((i for i,x in enumerate(a) if x[1]==':'),None)
                if split is not None:add(decode(a[:split]),decode(a[split+1:]),p,a[0][2])
    def read_map(filename,name):
        p=ROOT/filename;s=p.read_text();t=lex(s)
        for start,end in groups(t):
            if t[start][1]!='{' or not re.search(r'\b'+name+r'\s*=.*$',s[max(0,t[start][2]-160):t[start][2]],re.S):continue
            result={}
            for branch in arguments(t,start,end):
                colon=next((i for i,x in enumerate(branch) if x[1]==':'),None)
                if colon is None:continue
                k=decode(branch[:colon]);v=branch[colon+1:]
                if k is None:continue
                if v and v[0][1]=='(':
                    result[k]={a[0][1]:decode(a[2:]) for a in arguments(v,0,len(v)-1) if len(a)>2 and a[1][1]==':'}
                else:result[k]=decode(v)
            return result
        return {}
    library=json.loads((ROOT/'assets/content/library.json').read_text())
    add(library['productName'],'JabLab — Tek başına dövüş antrenmanı',ROOT/'lib/app/select_page.dart',0)
    titles=read_map('lib/app/catalog_locale.dart','_turkishTitles')
    blurbs=read_map('lib/app/catalog_locale.dart','_turkishBlurbs')
    teaches=read_map('lib/app/teach_locale.dart','_teachCopies')
    for discipline in library['disciplines']:
        for field,translated in [('displayName',titles),('blurb',blurbs)]:
            if isinstance(translated.get(discipline['id']),str):add(discipline[field],translated[discipline['id']],ROOT/'lib/app/catalog_locale.dart',0)
        for course in discipline['courses']:
            for lesson in course['lessons']:
                translated=teaches.get(lesson['id']);source=lesson.get('teach')
                if translated and isinstance(source,str) and hashlib.sha256(source.encode()).hexdigest()==translated['sourceSha256']:
                    add(source,translated['tr'],ROOT/'lib/app/teach_locale.dart',0)
    exclusions=read_map('lib/app/why_not_locale.dart','_exclusions')
    for title,value in exclusions.items():
        add(title,value['trTitle'],ROOT/'lib/app/why_not_locale.dart',0)
        add(value['enReason'],value['trReason'],ROOT/'lib/app/why_not_locale.dart',0)
    # Paired switch/getter outputs used by variable-valued UI adapters.
    def expression(filename,name):
        text=(ROOT/filename).read_text();t=lex(text)
        for i,x in enumerate(t):
            if x[1]!=name:continue
            arrow=next((j for j in range(i+1,min(i+25,len(t)-1)) if t[j][1]=='=' and t[j+1][1]=='>'),None)
            if arrow is None or t[arrow+2][1]!='switch':continue
            end=next((j for j in range(arrow+2,len(t)) if t[j][1]==';'),None)
            if end:return t[arrow+2:end]
        return []
    for filename,en,tr in [('lib/app/content_failure_screen.dart','_headline','_headlineTr'),('lib/app/content_failure_screen.dart','_body','_bodyTr'),('lib/app/session_screen.dart','_failureSentenceEn','_failureSentenceTr')]:
        for english,turkish in pair_variants(expression(filename,en),expression(filename,tr)):
            add(english,turkish,ROOT/filename,0)
    p=ROOT/'lib/app/why_not_locale.dart';t=lex(p.read_text());constants={}
    for i,x in enumerate(t):
        if x[1] in ('_englishIntro','_turkishIntro') and i+1<len(t) and t[i+1][1]=='=':
            end=next(j for j in range(i+2,len(t)) if t[j][1]==';');constants[x[1]]=decode(t[i+2:end])
    if len(constants)==2:add(constants['_englishIntro'],constants['_turkishIntro'],p,0)
    data['entries']=list(entries.values())
    data['limits']=['Exact source pair overlay; canonical content bytes are unchanged.','Translation source is not native-speaker, clinical, legal or rendered UI acceptance.']
    singulars={'{count} courses':'{count} course','{count} lessons':'{count} lesson','{count} rounds':'{count} round','{count} intervals':'{count} interval','{count} things are deliberately not in this app.':'{count} thing is deliberately not in this app.'}
    for e in data['entries']:
        e['placeholder_types']={name:('num' if name in {'count','n','minutes','hours','position','total','stopped'} or (name.startswith('value') and (e['en'].startswith('Lesson {') or any(term in e['en'] for term in ['written reviews reported','written targets','written review','self-reported complete','/24','/16','/20',' min','recorded','Written lesson ']))) else 'String') for name in e['placeholders']}
        if e['plural_arg']:
            e['forms']={'en':{'one':singulars.get(e['en'],e['en'].replace('{count} lessons here have','{count} lesson here has')),'other':e['en']},'tr':{'other':e['tr']}}
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'l10n/unresolved_ui.json').write_text(json.dumps(unresolved,ensure_ascii=False,indent=2)+'\n')
    return data

def validate(data,allow_partial=False,write=False):
    errors=[];coverage={};bundles={};source={e['id']:e for e in data['entries']}
    for ident,e in source.items():
        if ident!=key(e['en'],e['tr']):errors.append(ident+': stale ID')
        if sorted(re.findall(r'\{(\w+)\}',e['en']))!=sorted(re.findall(r'\{(\w+)\}',e['tr'])):errors.append(ident+': source placeholders')
    for locale in LOCALES:
        if locale in ('en','tr'):messages={k:e.get('forms',{}).get(locale,e[locale]) for k,e in source.items()}
        else:
            p=ROOT/f'l10n/translations/{locale}.json'
            if not p.exists():messages={}
            else:
                d=json.loads(p.read_text());messages=d['messages']
                if d.get('locale')!=locale:errors.append(locale+': tag mismatch')
        missing=set(source)-set(messages);extra=set(messages)-set(source)
        coverage[locale]={'present':len(messages),'missing':len(missing),'extra':len(extra)}
        if extra:errors.append(locale+': unknown IDs '+str(len(extra)))
        if missing and not allow_partial:errors.append(locale+': missing '+str(len(missing)))
        for ident,value in messages.items():
            if ident not in source:continue
            values=value.values() if isinstance(value,dict) else [value]
            if not values or any(not isinstance(v,str) or not v.strip() for v in values):errors.append(locale+': blank/nontext '+ident);continue
            expected=sorted(source[ident]['placeholders'])
            for v in values:
                if sorted(re.findall(r'\{(\w+)\}',v))!=expected:errors.append(locale+': placeholder mismatch '+ident)
            if isinstance(value,dict) and 'other' not in value:errors.append(locale+': plural other absent '+ident)
            if source[ident]['plural_arg']:
                required={'ar':{'zero','one','two','few','many','other'},'ja':{'other'},'tr':{'other'},'en':{'one','other'},'de':{'one','other'},'fr':{'one','many','other'},'es-419':{'one','many','other'},'pt-BR':{'one','many','other'}}[locale]
                if not isinstance(value,dict) or not required.issubset(value):errors.append(locale+': plural forms absent '+ident)

        bundles[locale]={'schemaVersion':1,'locale':locale,'complete':not bool(missing),'sourceCount':len(source),'messages':messages}
    if write and not errors:
        for locale,bundle in bundles.items():
            target=ROOT/f'assets/i18n/{locale}.json';target.parent.mkdir(exist_ok=True);target.write_text(json.dumps(bundle,ensure_ascii=False,separators=(',',':'))+'\n')
    print(json.dumps({'coverage':coverage,'errors':errors},ensure_ascii=False,indent=2))
    return not errors

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--refresh',action='store_true');parser.add_argument('--write',action='store_true');parser.add_argument('--allow-partial',action='store_true');args=parser.parse_args()
    data=refresh() if args.refresh else json.loads((ROOT/'l10n/source_catalog.json').read_text())
    raise SystemExit(0 if validate(data,args.allow_partial,args.write) else 1)
