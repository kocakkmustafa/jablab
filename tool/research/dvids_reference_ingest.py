"""Local research reference ingestion, never training or production admission.

Uses the consumer-pinned canonical Core VIDEO extractor without modifying it.
Requires actual ffprobe PTS to agree with its index/fps clock; fails on VFR.
"""
from __future__ import annotations
import argparse,hashlib,json,math,subprocess,sys,time
from fractions import Fraction
from pathlib import Path

class ReferenceError(ValueError):pass

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def write(path,value):Path(path).write_text(json.dumps(value,ensure_ascii=False,allow_nan=False,separators=(',',':'))+'\n')

def validate_timing(probe,tolerance=1e-5):
    streams=[s for s in probe['streams'] if s['codec_type']=='video']
    if len(streams)!=1:raise ReferenceError('One video stream required')
    stream=streams[0];fps=float(Fraction(stream['avg_frame_rate']))
    if not math.isfinite(fps) or fps<=0:raise ReferenceError('Invalid FPS')
    rotation=[float(x['rotation']) for x in stream.get('side_data_list',[]) if 'rotation' in x]
    if any(v%360!=0 for v in rotation):raise ReferenceError('Rotated input requires separate explicit adapter')
    frames=[f for f in probe['frames'] if f.get('media_type','video')=='video']
    if not frames:raise ReferenceError('No frame timestamps')
    pts=[float(f['best_effort_timestamp_time']) for f in frames]
    if not all(math.isfinite(x) for x in pts):raise ReferenceError('Non-finite timestamps')
    if any(b<=a for a,b in zip(pts,pts[1:])):raise ReferenceError('Non-monotonic PTS')
    residual=max(abs((t-pts[0])-i/fps) for i,t in enumerate(pts))
    if residual>tolerance:raise ReferenceError('VFR/gap incompatible with canonical index/fps extractor')
    return {'fps':fps,'pts_s':pts,'first_pts_s':pts[0],'last_pts_s':pts[-1],'frames':frames,'count':len(pts),'width':int(stream['width']),'height':int(stream['height']),'time_base':stream['time_base'],'max_index_clock_residual_s':residual,'constant_frame_timing':True,'rotation_deg':0}

def normalize_frame(frame,width,height,visibility=.5,presence=.5,minimum_scale=1e-6):
    if not frame.get('detected'):return {'status':'missing_pose','xy':None,'joint_observable':[False]*33}
    lm=frame.get('lm')
    if not isinstance(lm,list) or len(lm)!=33 or any(len(p)!=5 or not all(math.isfinite(v) for v in p) for p in lm):raise ReferenceError('Invalid body33 envelope')
    if any(not 0<=p[3]<=1 or not 0<=p[4]<=1 for p in lm):raise ReferenceError('Invalid confidence range')
    if width<=0 or height<=0:raise ReferenceError('Invalid image dimensions')
    observable=[p[3]>=visibility and p[4]>=presence and 0<=p[0]<=1 and 0<=p[1]<=1 for p in lm]
    if not all(observable[i] for i in [11,12,23,24]):return {'status':'torso_unobservable','xy':None,'joint_observable':observable}
    aspect=width/height;xy=[[p[0]*aspect,p[1]] for p in lm]
    hip=[(xy[23][a]+xy[24][a])/2 for a in range(2)];shoulder=[(xy[11][a]+xy[12][a])/2 for a in range(2)]
    scale=math.dist(hip,shoulder)
    if scale<minimum_scale:return {'status':'collapsed_torso','xy':None,'joint_observable':observable}
    return {'status':'normalized','xy':[[(p[a]-hip[a])/scale for a in range(2)] if observable[i] else None for i,p in enumerate(xy)],'joint_observable':observable,'hip_image_xy_aspect_corrected':hip,'torso_image_scale':scale}

def path_segments(records,joint,max_gap_s):
    segments=[];current=[]
    for frame in records:
        norm=frame['normalized'];xy=norm['xy'];point=xy[joint] if xy else None
        if frame['scene_neighborhood_uncertain'] or point is None:
            if current:segments.append(current);current=[]
            continue
        if current and not 0<frame['source_pts_s']-current[-1]['source_pts_s']<=max_gap_s:
            segments.append(current);current=[]
        current.append({'frame_index':frame['frame_index'],'source_pts_s':frame['source_pts_s'],'xy':point})
    if current:segments.append(current)
    return segments

def probe_video(path):
    r=subprocess.run(['ffprobe','-v','error','-show_streams','-show_format','-show_frames','-of','json',str(path)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=45)
    if r.returncode:raise ReferenceError('ffprobe failed: '+r.stderr.decode(errors='replace')[-800:])
    return json.loads(r.stdout)

def run(root):
    start=time.monotonic();config=json.loads((root/'runconfig.json').read_text());plan=json.loads((root/'source-plan.json').read_text());ledger=json.loads((root/'download-ledger.json').read_text())
    assert sum(row['bytes'] for row in ledger)<20_000_000 and len(plan['rows'])==3
    extractor_path=Path(config['extractor']);model=Path(config['model'])
    assert sha(extractor_path)==config['extractor_sha256'] and sha(model)==config['model_sha256']
    # Imports are inside the shared CPU lease held by the caller. Borrow only
    # existing runtime, suppressing bytecode/cache writes outside this task.
    sys.path.insert(0,config['runtime']);sys.path.insert(0,str(extractor_path.parent))
    import numpy as np
    import cv2
    import mediapipe as mp
    import extract_landmarks as extractor
    from PIL import Image,ImageDraw
    import matplotlib;matplotlib.use('Agg');import matplotlib.pyplot as plt
    out=root/'out';out.mkdir(exist_ok=True);summaries=[];fig,axes=plt.subplots(1,3,figsize=(12,4));contacts=Image.new('RGB',(3*380,3*260),'#111827');draw=ImageDraw.Draw(contacts)
    for clip_index,row in enumerate(plan['rows']):
        media=root/row['local'];receipt=next(x for x in ledger if x['local']==row['local'])
        assert media.stat().st_size==row['expected_bytes'] and sha(media)==receipt['sha256']
        source_probe=probe_video(media);write(out/(row['id']+'.ffprobe.json'),source_probe)
        clock=validate_timing(source_probe,config['source_cfr_tolerance_s']);assert clock['count']<=config['maximum_frames_per_clip']
        # Decode a lightweight continuity signal from every original frame.
        cap=cv2.VideoCapture(str(media));tiny=[];sample_indices=[0,clock['count']//2,clock['count']-1];sample_images={};i=0
        while True:
            ok,bgr=cap.read()
            if not ok:break
            tiny.append(cv2.resize(cv2.cvtColor(bgr,cv2.COLOR_BGR2GRAY),(32,32)).astype(np.float32)/255)
            if i in sample_indices:sample_images[i]=Image.fromarray(cv2.cvtColor(bgr,cv2.COLOR_BGR2RGB))
            i+=1
        cap.release();assert len(tiny)==clock['count']
        deltas=[0.]+[float(np.abs(b-a).mean()) for a,b in zip(tiny,tiny[1:])];cuts=[i for i,d in enumerate(deltas) if d>config['scene_delta_threshold']]
        uncertain={j for i in cuts for j in range(max(0,i-config['scene_neighborhood_frames']),min(clock['count'],i+config['scene_neighborhood_frames']+1))}
        frames,fps,host_ms,resolution=extractor._run_video(media,model,min_confidence=config['landmark_min_confidence'],crop=None)
        assert len(frames)==clock['count'] and resolution==f"{clock['width']}x{clock['height']}"
        records=[];timestamp_difference=[]
        for i,(frame,pts) in enumerate(zip(frames,clock['pts_s'])):
            difference=abs(frame['t']-(pts-clock['first_pts_s'])*1000);timestamp_difference.append(difference)
            if difference>config['max_source_model_timestamp_delta_ms']:raise ReferenceError('Serialized extractor clock disagrees with source PTS')
            norm=normalize_frame(frame,clock['width'],clock['height'],config['visibility'],config['presence'],config['minimum_normalized_torso_size'])
            if i in uncertain:norm={**norm,'status':'scene_change_uncertain','xy':None}
            records.append({'frame_index':i,'source_pts_s':pts,'source_best_effort_timestamp':clock['frames'][i].get('best_effort_timestamp'),'source_best_effort_timestamp_time':clock['frames'][i]['best_effort_timestamp_time'],'extractor_serialized_t_ms':frame['t'],'detected':frame['detected'],'lm':frame.get('lm'),'world_model_prediction_not_ground_truth':frame.get('world'),'normalized':norm,'scene_delta_diagnostic':deltas[i],'scene_neighborhood_uncertain':i in uncertain})
        paths={name:path_segments(records,joint,1.5/clock['fps']) for name,joint in [('left_wrist',15),('right_wrist',16),('left_elbow',13),('right_elbow',14)]}
        sequence={'schema':'jablab.research.source-timed-body33-reference.v1','publisher_label':row['publisher_label'],'sports_boxing_label_mapping':None,'source_page':row['page'],'source_sha256':receipt['sha256'],'source_bytes':receipt['bytes'],'publisher':'Bruce Hardcastle / U.S. Marine Corps Training and Education Command','date_taken':'2020-06-19','publisher_rights_mark':'PUBLIC DOMAIN subject to DVIDS restrictions','non_endorsement':'The appearance of U.S. Department of War (DoW) visual information does not imply or constitute DoW endorsement.','partition':'reference_extraction_only','person_session_independence':'unknown;all3same conservative group,no identity recognition','model_id':config['model_id'],'model_sha256':config['model_sha256'],'canonical_extractor_sha256':config['extractor_sha256'],'source_time_base':clock['time_base'],'normalization':'Hip-centered,torso-scaled aspect-corrected imageXY;no mirror/side correction;observable joints only','visibility_thresholds':{'visibility':config['visibility'],'presence':config['presence']},'source_timing_preserved':True,'source_index_clock_max_residual_s':clock['max_index_clock_residual_s'],'max_serialized_extractor_vs_pts_ms':max(timestamp_difference),'inference_timestamp_note':'Canonical VIDEO usesfloor(index*1000/OpenCVfps);serializedt_ms rounded2 decimals. ActualsourcePTS retained separately. No sensor/native timing accuracy claimed.','scene_changes':{'method':'32x32gray meanabsolute adjacentdifference>0.20','candidates':cuts,'not_semantic_boundary_or_guarantee':True},'frames':records,'paths':paths,'quality_labels':None,'expert_or_independent_accuracy_accepted':False,'production_activation':False}
        seqpath=out/(row['id']+'.reference.json');write(seqpath,sequence)
        observable=np.array([r['normalized']['joint_observable'] for r in records],dtype=float)
        summary={'id':row['id'],'publisher_label':row['publisher_label'],'source_sha256':receipt['sha256'],'source_bytes':receipt['bytes'],'frames':len(frames),'fps':clock['fps'],'resolution':resolution,'first_pts_s':clock['first_pts_s'],'last_pts_s':clock['last_pts_s'],'pts_monotonic':True,'source_clock_max_residual_s':clock['max_index_clock_residual_s'],'detected_frames':sum(r['detected'] for r in records),'normalized_frames':sum(r['normalized']['status']=='normalized' and not r['scene_neighborhood_uncertain'] for r in records),'visibility_coverage_all_frames':{str(j):float(observable[:,j].mean()) for j in [11,12,13,14,15,16,23,24,25,26,27,28]},'low_visibility_or_out_of_frame_not_blur_label':True,'scene_change_candidates':cuts,'scene_delta_max':max(deltas),'host_inference_ms_per_frame':host_ms,'reference_sha256':sha(seqpath),'path_segment_counts':{name:len(v) for name,v in paths.items()}}
        summaries.append(summary);print(json.dumps(summary),flush=True)
        ax=axes[clip_index]
        for side,color in [('left_wrist','#2563eb'),('right_wrist','#ea580c')]:
            first=True
            for segment in paths[side]:
                points=np.array([x['xy'] for x in segment]);ax.plot(points[:,0],points[:,1],color=color,label=side if first else None,linewidth=1);first=False
        ax.set_title(row['publisher_label']);ax.set_xlabel('imageXY / torso');ax.invert_yaxis();ax.set_aspect('equal',adjustable='datalim');ax.legend(fontsize=6)
        for column,index in enumerate(sample_indices):
            im=sample_images[index];im.thumbnail((370,225));contacts.paste(im,(column*380,clip_index*260+25));draw.text((column*380+5,clip_index*260+5),row['publisher_label']+f" frame{index} PTS{clock['pts_s'][index]:.3f}s",fill='white')
    fig.suptitle('Local reference trajectories - model predictions, not technique quality');fig.tight_layout();fig.savefig(out/'wrist-paths.png',dpi=130);plt.close(fig);contacts.save(out/'source-view-contact.png')
    result={'status':'LOCAL_REFERENCE_INGESTION_COMPLETE_NOT_TRAINED_OR_ACCEPTED','clips':summaries,'runtime':{'python':sys.version,'mediapipe':mp.__version__,'cv2':cv2.__version__,'numpy':np.__version__,'runtime_borrowed_read_only':config['runtime']},'model_sha256':config['model_sha256'],'canonical_extractor_sha256':config['extractor_sha256'],'extractor_core_pin':config['core_pin'],'runconfig_sha256':sha(root/'runconfig.json'),'script_sha256':sha(Path(__file__)),'elapsed_s':time.monotonic()-start,'no_training_or_independent_split':True,'publisher_labels_preserved':True,'production_enabled':False,'identity_recognition':False,'core_files_written':False}
    write(out/'ingestion-result.json',result);return result

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',required=True,type=Path);a=p.parse_args();print(json.dumps(run(a.root),indent=2))
