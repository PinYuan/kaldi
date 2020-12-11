#!/bin/bash

kaldi_inspection_dir="/mnt/HDD2/user_pinyuanc/kaldi-inspection"

exp_dir="/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5/exp/chain/train_from_scratch/TDNN_1A/FSFAE3/AM_SPECAUG/tdnn_1a_feam_specaug_mfcc_v1/e50_f0.2_il0.01_fl0.001"
lang_type="tgpr_5k"

test_sets="A B C D"
for test_set in ${test_sets}; do
    ln -s ${exp_dir}/decode_${lang_type}_${test_set}/ ${kaldi_inspection_dir}/kaldi/decodes/
done