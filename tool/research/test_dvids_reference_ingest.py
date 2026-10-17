import unittest,copy,math
from dvids_reference_ingest import ReferenceError,validate_timing,normalize_frame,path_segments

def probe(times=('0.100000','0.133333','0.166667')):
 return {'streams':[{'codec_type':'video','avg_frame_rate':'30/1','width':640,'height':480,'time_base':'1/30000'}],'frames':[{'media_type':'video','best_effort_timestamp_time':v} for v in times]}
def frame():
 lm=[[.5,.5,0.,1.,1.] for _ in range(33)]
 for j,p in [(11,[.4,.2]),(12,[.6,.2]),(23,[.4,.6]),(24,[.6,.6])]:lm[j][:2]=p
 return {'detected':True,'lm':lm}
def record(t,point=True,cut=False):return {'frame_index':0,'source_pts_s':t,'scene_neighborhood_uncertain':cut,'normalized':{'xy':[[0.,0.] for _ in range(33)] if point else None}}
class IngestionContractTests(unittest.TestCase):
 def test_original_pts_origin_and_clock_preserved(self):
  result=validate_timing(probe());self.assertEqual(result['first_pts_s'],.1);self.assertEqual(result['count'],3);self.assertLess(result['max_index_clock_residual_s'],1e-6)
 def test_vfr_and_gaps_never_silently_resampled(self):
  for values in [('0','0.033333','0.08'),('0','0.066667','0.10')]:
   with self.assertRaises(ReferenceError):validate_timing(probe(values))
 def test_nonmonotonic_nonfinite_missing_pts_rejected(self):
  for values in [('0','0','0.03'),('0','.033','nan'),('.1','.0','.2')]:
   with self.assertRaises(ReferenceError):validate_timing(probe(values))
 def test_rotation_does_not_silently_change_coordinate_basis(self):
  p=probe();p['streams'][0]['side_data_list']=[{'rotation':90}]
  with self.assertRaises(ReferenceError):validate_timing(p)
 def test_normalization_is_aspect_corrected_hip_centered(self):
  f=frame();r=normalize_frame(f,640,480);self.assertEqual(r['status'],'normalized');self.assertAlmostEqual(r['xy'][11][0],-1/3);self.assertAlmostEqual(r['xy'][11][1],-1)
 def test_translation_and_uniform_scaling_preserve_normalized_shape(self):
  f=frame();g=copy.deepcopy(f)
  for p in g['lm']:p[0]=.1+p[0]*.5;p[1]=.1+p[1]*.5
  a=normalize_frame(f,640,480)['xy'];b=normalize_frame(g,640,480)['xy']
  for x,y in zip(a,b):
   for p,q in zip(x,y):self.assertAlmostEqual(p,q)
 def test_missing_and_low_confidence_torso_keep_abstention(self):
  self.assertEqual(normalize_frame({'detected':False},640,480)['status'],'missing_pose')
  f=frame();f['lm'][11][3]=.4;r=normalize_frame(f,640,480);self.assertEqual(r['status'],'torso_unobservable');self.assertIsNone(r['xy'])
 def test_occluded_or_outside_wrist_is_null_not_zero_filled(self):
  for field,value in [(0,1.1),(3,.1),(4,.1)]:
   f=frame();f['lm'][15][field]=value;r=normalize_frame(f,640,480);self.assertIsNone(r['xy'][15]);self.assertFalse(r['joint_observable'][15])
 def test_invalid_landmark_payload_and_confidence_rejected(self):
  for kind in ['shape','nan','confidence']:
   f=frame()
   if kind=='shape':f['lm'].pop()
   elif kind=='nan':f['lm'][15][0]=math.nan
   else:f['lm'][15][3]=1.1
   with self.assertRaises(ReferenceError):normalize_frame(f,640,480)
 def test_path_breaks_at_missing_pose_cut_and_time_gap(self):
  r=[record(0),record(.03),record(.06,False),record(.09),record(.12,cut=True),record(.15),record(.5)]
  self.assertEqual([len(s) for s in path_segments(r,15,.05)],[2,1,1,1])
 def test_path_never_links_clock_rewind(self):
  self.assertEqual([len(s) for s in path_segments([record(.1),record(.0)],15,.05)],[1,1])
if __name__=='__main__':unittest.main()
