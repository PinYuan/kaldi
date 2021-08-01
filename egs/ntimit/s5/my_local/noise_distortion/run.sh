#/bin/bash

. ./cmd.sh
. ./path.sh

# Prepare noise dir -> data/train_noise_mismatch_sp_hires
python3 my_local/noise_distortion/prepare_noise_dir.py

# Extract 40-D MFCC
train_dirs="train_noise_mismatch_sp_hires"
test_dirs="dev_noise_mismatch_hires
           test_noise_mismatch_hires"
# data_dirs="${train_dirs} ${test_dirs}"
data_dirs="${train_dirs}"

for data_dir in $data_dirs; do
    steps/make_mfcc.sh --nj 20 --mfcc-config conf/mfcc_hires.conf \
        --cmd "$train_cmd" data/$data_dir
    steps/compute_cmvn_stats.sh data/$data_dir
    utils/fix_data_dir.sh data/$data_dir
done