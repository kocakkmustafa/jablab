"""Offline research-only CMU ASF/AMC angle embedding. No product provider.

No downloader, executable imports or shared-Core pipeline writes. Data stays
outside the app. Raw angles are used directly: no unverified FK/body33 mapping.
"""
from __future__ import annotations
import argparse,hashlib,json,math,os,time
from dataclasses import dataclass
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw

class MocapError(ValueError): pass

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def finite(tokens):
    try: values=[float(v) for v in tokens]
    except ValueError as exc: raise MocapError('Non-numeric channel') from exc
    if not all(math.isfinite(v) for v in values):raise MocapError('Non-finite channel')
    return values

@dataclass(frozen=True)
class Skeleton:
    dofs: dict
    directions: dict
    lengths: dict
    parents: dict
    length_unit: float
    root_order: tuple
    @property
    def meters_per_unit(self): return .0254/self.length_unit

def parse_asf(text: str) -> Skeleton:
    section='';bones={};parents={};units={};root={};current=None
    for raw in text.splitlines():
        line=raw.split('#',1)[0].strip()
        if not line:continue
        if line.startswith(':'):section=line[1:];continue
        fields=line.split();key=fields[0]
        if section=='units':units[key]=fields[1:]
        elif section=='root':root[key]=fields[1:]
        elif section=='bonedata':
            if key=='begin':
                if current is not None:raise MocapError('Nested bone')
                current={}
            elif key=='end':
                if current is None:raise MocapError('Bone end without begin')
                required={'name','direction','length','axis'}
                if not required.issubset(current):raise MocapError('Incomplete bone')
                name=current['name'][0]
                if name in bones or name=='root':raise MocapError('Duplicate bone')
                bones[name]=current;current=None
            elif current is not None and key in ('name','direction','length','axis','dof'):
                if key in current:raise MocapError('Duplicate bone field')
                current[key]=fields[1:]
        elif section=='hierarchy' and key not in ('begin','end'):
            for child in fields[1:]:
                if child in parents:raise MocapError('Multiple parents')
                parents[child]=key
    if current is not None or units.get('angle')!=['deg']:raise MocapError('Unsupported ASF angle unit')
    scale=finite(units.get('length',[]))
    if len(scale)!=1 or scale[0]<=0:raise MocapError('Invalid length unit')
    order=tuple(root.get('order',[]))
    if order!=('TX','TY','TZ','RX','RY','RZ') or root.get('axis')!=['XYZ']:raise MocapError('Unsupported root convention')
    if finite(root.get('position',[]))!=[0,0,0] or finite(root.get('orientation',[]))!=[0,0,0]:raise MocapError('Unsupported root offset')
    dofs={'root':order};directions={};lengths={}
    for name,bone in bones.items():
        axis=bone['axis'];direction=np.array(finite(bone['direction']));length=finite(bone['length'])
        if len(axis)!=4 or axis[3]!='XYZ' or len(finite(axis[:3]))!=3:raise MocapError('Unsupported bone axis')
        if direction.shape!=(3,) or abs(np.linalg.norm(direction)-1)>1e-4 or len(length)!=1 or length[0]<=0:raise MocapError('Invalid bone geometry')
        dof=tuple(bone.get('dof',[]))
        if len(set(dof))!=len(dof) or not set(dof).issubset({'rx','ry','rz'}):raise MocapError('Unsupported DOF')
        dofs[name]=dof;directions[name]=direction;lengths[name]=length[0]
        if name not in parents:raise MocapError('Unparented bone')
        seen={name};parent=parents[name]
        while parent!='root':
            if parent in seen or parent not in bones or parent not in parents:raise MocapError('Invalid hierarchy')
            seen.add(parent);parent=parents[parent]
    if set(parents)!=set(bones):raise MocapError('Unknown hierarchy child')
    return Skeleton(dofs,directions,lengths,parents,scale[0],order)

def parse_amc(text: str, skeleton: Skeleton):
    headers={line.strip() for line in text.splitlines() if line.strip().startswith(':')}
    if ':DEGREES' not in headers or ':FULLY-SPECIFIED' not in headers or ':RADIANS' in headers:raise MocapError('Unsupported AMC mode')
    expected={n:len(d) for n,d in skeleton.dofs.items() if d}
    frames=[];numbers=[];frame=None
    def finish():
        if frame is not None:
            if set(frame)!=set(expected):raise MocapError('Incomplete AMC frame')
            frames.append(frame)
    for raw in text.splitlines():
        line=raw.strip()
        if not line or line[0] in '#:':continue
        fields=line.split()
        if len(fields)==1 and fields[0].isdigit():
            finish();number=int(fields[0])
            if number!=len(numbers)+1:raise MocapError('Non-contiguous frame clock')
            numbers.append(number);frame={};continue
        if frame is None:raise MocapError('Channel before frame')
        name=fields[0]
        if name not in expected or name in frame or len(fields)-1!=expected[name]:raise MocapError('Unexpected/duplicate/wrong-width channel')
        frame[name]=finite(fields[1:])
    finish()
    if not frames:raise MocapError('No frames')
    arrays={name:np.asarray([f[name] for f in frames],dtype=np.float64) for name in expected}
    return np.asarray(numbers),arrays

# Finger/thumb are unmeasured editing channels; hands/toes can be noisy.
# Exclude all hand/wrist/finger/thumb/foot/toe channels from the learned pilot.
BONES=('lowerback','upperback','thorax','lowerneck','upperneck','head',
       'rclavicle','rhumerus','rradius','lclavicle','lhumerus','lradius',
       'rfemur','rtibia','lfemur','ltibia')

def angle_features(channels,skeleton,stride):
    if stride<1:raise MocapError('Invalid stride')
    columns=[];names=[]
    for bone in BONES:
        if bone not in channels:raise MocapError('Required research channel missing')
        for index,dof in enumerate(skeleton.dofs[bone]):
            columns.append(channels[bone][::stride,index]);names.append(f'{bone}.{dof}')
    angles=np.stack(columns,axis=1)
    radians=np.deg2rad(angles)
    return np.stack((np.sin(radians),np.cos(radians)),axis=-1).reshape(len(angles),-1),angles,names

def fit_embedding(train,rank):
    if train.ndim!=2 or not np.isfinite(train).all() or not 0<rank<min(train.shape):raise MocapError('Invalid PCA input')
    mean=train.mean(axis=0);_,singular,basis=np.linalg.svd(train-mean,full_matrices=False)
    # Deterministic sign for serialized components; fit sees train only.
    basis=basis[:rank].copy()
    for row in basis:
        if row[np.argmax(np.abs(row))]<0:row*=-1
    return mean,basis,singular

def masked_reconstruct(values,mean,basis,hidden,ridge):
    if ridge<=0:raise MocapError('Invalid ridge')
    visible=~hidden;observed=basis[:,visible]
    latent=np.linalg.solve(observed@observed.T+ridge*np.eye(len(basis)),observed@(values[:,visible]-mean[visible]).T).T
    return mean+latent@basis

def angular_error(predicted,true_angles,angle_indices):
    pairs=predicted.reshape(len(predicted),-1,2)
    angles=np.rad2deg(np.arctan2(pairs[:,:,0],pairs[:,:,1]))
    return np.abs((angles[:,angle_indices]-true_angles[:,angle_indices]+180)%360-180)

def visualize(skeleton,angles,names,predicted,output):
    """Diagnostic rest geometry + channel image, not an animated FK proof."""
    image=Image.new('RGB',(1200,760),'#111827');d=ImageDraw.Draw(image)
    d.text((24,16),'CMU 13 - parse/angle embedding diagnostics; NOT technique grading',fill='white')
    d.text((24,44),'ASF rest directions (meters); no animated forward-kinematics claim',fill='#cbd5e1')
    positions={'root':np.zeros(3)}
    def point(name):
        if name not in positions:
            positions[name]=point(skeleton.parents[name])+skeleton.directions[name]*skeleton.lengths[name]*skeleton.meters_per_unit
        return positions[name]
    for name in skeleton.parents:point(name)
    for projection,center in [((0,1),(180,300)),((2,1),(490,300))]:
        for name,parent in skeleton.parents.items():
            if any(t in name for t in ('finger','thumb','hand','wrist','toes')):continue
            a,b=positions[parent],positions[name]
            xy=lambda p:(center[0]+int(p[projection[0]]*170),center[1]-int(p[projection[1]]*170))
            d.line([xy(a),xy(b)],fill='#67e8f9',width=3)
        d.text((center[0]-90,490),'orthographic rest projection',fill='#cbd5e1')
    d.text((680,80),'13_18 raw AMC angles; rows=channels, x=nominal time',fill='white')
    normalized=np.clip((np.sin(np.deg2rad(angles)).T+1)*127.5,0,255).astype('uint8')
    rgb=np.stack([normalized,np.full_like(normalized,70),255-normalized],axis=2)
    heat=Image.fromarray(rgb).resize((480,380));image.paste(heat,(680,110))
    d.text((680,505),'Hue displays sin(angle); no punch/quality labels exist',fill='#cbd5e1')
    index=names.index('lradius.rx');pred_angles=np.rad2deg(np.arctan2(predicted.reshape(len(predicted),-1,2)[:,index,0],predicted.reshape(len(predicted),-1,2)[:,index,1]))
    d.text((24,560),'Masked lradius.rx - source (cyan), research reconstruction (orange); degrees',fill='white')
    for y,color in [(angles[:,index],'#67e8f9'),(pred_angles,'#fb923c')]:
        # Sparse visual rendering only; metric uses every diagnostic sample.
        ids=np.linspace(0,len(y)-1,min(len(y),1000)).astype(int)
        points=[(30+int(i/(len(y)-1)*1120),640-int(float(np.clip(y[i],-180,180))/180*60)) for i in ids]
        d.line(points,fill=color,width=1)
    image.save(output)

def run(root:Path,config:dict):
    start=time.monotonic();raw=root/'raw';out=root/'out';out.mkdir(exist_ok=True)
    for name,expected in config['source_sha256'].items():
        if digest(raw/name)!=expected:raise MocapError('Source hash mismatch')
    skeleton=parse_asf((raw/'13.asf').read_text())
    frame_info={};arrays={}
    for motion in ['13_17','13_18']:
        ids,channels=parse_amc((raw/(motion+'.amc')).read_text(),skeleton)
        arrays[motion]=angle_features(channels,skeleton,config['stride'])
        frame_info[motion]={'frames':len(ids),'nominal_hz':config['nominal_hz'],'last_nominal_time_s':(len(ids)-1)/config['nominal_hz'],'retained_samples':len(arrays[motion][0]),'root_xyz_m_range':np.ptp(channels['root'][:,:3]*skeleton.meters_per_unit,axis=0).tolist()}
    train,_,names=arrays['13_17'];diagnostic,true_angles,names2=arrays['13_18'];assert names==names2
    mean,basis,singular=fit_embedding(train,config['latent_rank'])
    # Freeze artifact before diagnostic scoring. No hyperparameter selection on13_18.
    model=out/'research-angle-embedding.npz'
    np.savez_compressed(model,mean=mean,basis=basis,feature_names=np.asarray(names),research_only=np.asarray(True))
    model_hash=digest(model)
    masked=[i for i,name in enumerate(names) if name.split('.')[0] in config['masked_bones']]
    hidden=np.repeat(np.isin(np.arange(len(names)),masked),2)
    prediction=masked_reconstruct(diagnostic,mean,basis,hidden,config['ridge'])
    baseline=np.broadcast_to(mean,diagnostic.shape)
    error=angular_error(prediction,true_angles,masked);base_error=angular_error(baseline,true_angles,masked)
    feature_error=float(np.mean((prediction[:,hidden]-diagnostic[:,hidden])**2))
    np.savez_compressed(out/'diagnostic-arrays.npz',source_angles=true_angles,masked_prediction=prediction,feature_names=np.asarray(names),masked_indices=np.asarray(masked))
    visualize(skeleton,true_angles,names,prediction,out/'diagnostics.png')
    if digest(model)!=model_hash:raise MocapError('Frozen model changed')
    result={'status':'RESEARCH_ANGLE_EMBEDDING_PILOT_ONLY','frames':frame_info,'channels':len(names),'feature_dimensions':train.shape[1],'latent_dimensions':len(basis),'train_motion':'13_17','diagnostic_motion':'13_18','person_independent_holdout':False,'subject_id_is_unique_person_identity':False,'source_session_independence_known':False,'train_only_centering_and_basis':True,'hyperparameters_selected_on_diagnostic':False,'masked_bones':config['masked_bones'],'masked_angle_channels':len(masked),'diagnostic_samples':len(diagnostic),'masked_angle_mae_deg':float(error.mean()),'mean_pose_baseline_mae_deg':float(base_error.mean()),'masked_feature_mse':feature_error,'train_explained_variance_fraction':float((singular[:len(basis)]**2).sum()/(singular**2).sum()),'model_sha256':model_hash,'model_bytes':model.stat().st_size,'compute_seconds':time.monotonic()-start,'meter_scale':skeleton.meters_per_unit,'runtime_provider_or_calibration_updated':False,'punch_or_technique_accuracy_accepted':False,'input_schema':'cmu.asf-amc.local-euler.sin-cos.v1','incompatible_with_production':'body33.image.v1 / image2d.aspectCorrected; no RGB MediaPipe parity','visualization':'Rest geometry and angle diagnostics only; animated FK/physical correctness not verified','versions':{'numpy':np.__version__},'reproducibility':{'script_sha256':digest(Path(__file__)),'config_sha256':digest(root/'runconfig.json')}}
    (out/'metrics.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,required=True);a=p.parse_args()
    config=json.loads((a.root/'runconfig.json').read_text());print(json.dumps(run(a.root,config),indent=2))
