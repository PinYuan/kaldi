#!/bin/bash

test_sets="A B C D"
lang_type="tgpr_5k"
exp_dir="exp/chain/train_from_scratch/TDNN_1A/FSFAE3/AM_SPECAUG/tdnn_1a_feam_specaug_mfcc_v1/e50_f0.2_il0.01_fl0.001"

for test_set in $test_sets; do
    kaldi-inspection/gen_mir_web_ana_data.sh Aurora4 data/test_${test_set}_hires/ \
    	data/lang_test_${lang_type}/ ${exp_dir}/decode_${lang_type}_${test_set}/
done
