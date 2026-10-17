import os,unittest
from pathlib import Path
import numpy as np
from cmu_boxing_pilot import (MocapError,parse_asf,parse_amc,finite,fit_embedding,
 masked_reconstruct,angular_error,angle_features,BONES)
ASF='''\n:units\n length 0.45\n angle deg\n:root\n order TX TY TZ RX RY RZ\n axis XYZ\n position 0 0 0\n orientation 0 0 0\n:bonedata\nbegin\n name bone\n direction 1 0 0\n length 1\n axis 0 0 0 XYZ\n dof rx\nend\n:hierarchy\nbegin\n root bone\nend\n'''
AMC=':FULLY-SPECIFIED\n:DEGREES\n1\nroot 0 0 0 0 0 0\nbone 30\n2\nroot 1 0 0 0 0 0\nbone 40\n'
class SyntheticContractTests(unittest.TestCase):
 def test_asf_scale_and_declared_channels(self):
  s=parse_asf(ASF);self.assertEqual(s.dofs['bone'],('rx',));self.assertAlmostEqual(s.meters_per_unit,0.0254/0.45)
 def test_amc_retains_full_frames_and_angles(self):
  ids,data=parse_amc(AMC,parse_asf(ASF));np.testing.assert_array_equal(ids,[1,2]);np.testing.assert_array_equal(data['bone'][:,0],[30,40])
 def test_asf_rejects_hierarchy_cycle_and_unknown_parent(self):
  for edge in ['bone bone','unknown bone']:
   with self.assertRaises(MocapError):parse_asf(ASF.replace('root bone',edge))
 def test_asf_rejects_bad_geometry_units_and_dof(self):
  for old,new in [('length 1','length -1'),('direction 1 0 0','direction 0 0 0'),('angle deg','angle rad'),('dof rx','dof tx'),('axis 0 0 0 XYZ','axis 0 0 0 ZYX')]:
   with self.assertRaises(MocapError):parse_asf(ASF.replace(old,new))
 def test_missing_duplicate_unknown_and_wrong_width_channels_fail_closed(self):
  for text in [AMC.replace('bone 30\n',''),AMC.replace('bone 30','bone 30\nbone 31'),AMC.replace('bone 30','unknown 30'),AMC.replace('bone 30','bone 30 40')]:
   with self.assertRaises(MocapError):parse_amc(text,parse_asf(ASF))
 def test_frame_clock_gap_reorder_and_missing_header_fail_closed(self):
  for text in [AMC.replace('\n2\n','\n3\n'),AMC.replace('\n2\n','\n1\n'),AMC.replace(':DEGREES',':RADIANS'),AMC.replace(':DEGREES','# :DEGREES')]:
   with self.assertRaises(MocapError):parse_amc(text,parse_asf(ASF))
 def test_nonfinite_channels_not_silently_removed(self):
  for token in ['nan','inf','-inf']:
   with self.assertRaises(MocapError):parse_amc(AMC.replace('bone 30','bone '+token),parse_asf(ASF))
 def test_missing_feature_channel_is_not_zero_filled(self):
  with self.assertRaises(MocapError):angle_features({},parse_asf(ASF),4)
 def test_pca_basis_centering_uses_only_supplied_train(self):
  x=np.arange(30,dtype=float).reshape(10,3);mu,basis,_=fit_embedding(x,1)
  np.testing.assert_allclose(mu,x.mean(axis=0));np.testing.assert_allclose(basis@basis.T,[[1]])
 def test_masked_targets_never_enter_reconstruction_inputs(self):
  rng=np.random.default_rng(4);x=rng.normal(size=(80,12));mu,b,_=fit_embedding(x,3);hidden=np.array([True]*4+[False]*8)
  a=masked_reconstruct(x,mu,b,hidden,.001);changed=x.copy();changed[:,hidden]=999
  np.testing.assert_allclose(a,masked_reconstruct(changed,mu,b,hidden,.001))
 def test_circular_error_wraps_without_360degree_jump(self):
  angle=np.array([[-179.,20.]]);p=np.stack([np.sin(np.deg2rad(angle)),np.cos(np.deg2rad(angle))],axis=-1).reshape(1,4)
  np.testing.assert_allclose(angular_error(p,np.array([[179.,20.]]),[0]),[[2.]])
 def test_embedding_invalid_rank_and_nonfinite_fail(self):
  for x,rank in [(np.zeros((2,2)),2),(np.array([[np.nan,1],[2,3],[4,5]]),1)]:
   with self.assertRaises(MocapError):fit_embedding(x,rank)

@unittest.skipUnless(os.environ.get('JABLAB_CMU_ROOT'),'UNRUN: official local files not supplied')
class OfficialDataParserTests(unittest.TestCase):
 def test_both_official_records_fully_parse_without_dropping_frames(self):
  root=Path(os.environ['JABLAB_CMU_ROOT']);s=parse_asf((root/'raw/13.asf').read_text())
  for clip in ['13_17','13_18']:
   text=(root/('raw/'+clip+'.amc')).read_text();ids,ch=parse_amc(text,s)
   self.assertEqual(len(ids),sum(line.strip().isdigit() for line in text.splitlines()))
   self.assertGreater(len(ids),120);features,angles,names=angle_features(ch,s,4)
   self.assertEqual(features.shape,(len(angles),len(names)*2));self.assertTrue(np.isfinite(features).all())
   pairs=features.reshape(len(features),-1,2);np.testing.assert_allclose((pairs*pairs).sum(axis=2),1,atol=1e-12)
 def test_unreliable_channels_not_in_learned_features(self):
  self.assertTrue(all(not any(x in n for x in ['hand','wrist','finger','thumb','foot','toes']) for n in BONES))

if __name__=='__main__':unittest.main()
