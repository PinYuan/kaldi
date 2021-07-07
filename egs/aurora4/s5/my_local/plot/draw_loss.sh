#!/bin/bash

egs_dir="/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5"
exp_dir="exp/chain/pretrain/TDNN_1A/FSFAE3/DEFAULT/feam_tdnn_mfcc-mfcc-context_fixed/e20_f0.04_il0.01_fl0.001_pl0"
exp_dir="exp/chain/pretrain/TDNN_1A/FSFAE3/DEFAULT/feam_tdnn_mfcc-mfcc-context_fixed/e20_f0.04_il0.01_fl0.001_pl0.01"
exp_dir="exp/chain/train_from_scratch/TDNN_1A/FSFAE3/DEFAULT/tdnn_1a_feam_tdnn_mfcc-mfcc-context/e20_f0.04_il0.01_fl0.001"
# exp_dir="exp/chain/seperate/tdnn_1a_feam_baseline/e100_f1_il0.05_fl0.05"
# exp_dir="exp/chain/seperate/tdnn_1a_feam_specaug_v1/e300_f1_il0.01_fl0.01"
# exp_dir="exp/chain/tdnn1a_sp"

basic_iter_field=2
custom_iter_field=5 #4,6,5

if [[ ${exp_dir} == *"tdnn1a_sp"* ]]; then
    iter_field=${basic_iter_field}
else
    iter_field=${custom_iter_field}
fi

for filename in $(ls ${egs_dir}/${exp_dir}/log/train.*.1.log | sort -n -t . -k ${iter_field}); do
    iteration=`echo $filename | rev | cut -d '/' -f 1 | rev | cut -d '.' -f 2`
    output=0
    output=$(grep "Overall average objective function for 'output'" $filename | cut -d ' ' -f 10 | head -1)
    output_ae=0
    output_ae=$(grep "Overall average objective function for 'output_ae'" $filename | cut -d ' ' -f 10 | head -1)
    echo "$iteration,$output,$output_ae"
done
