#/bin/bash

. ./cmd.sh
. ./path.sh

# Prepare noise dir -> data/train_si84_noise_mismatch_sp_hires
python3 my_local/extract_noise/prepare_noise_dir.py

# Extract 40-D MFCC
data_dir="train_si84_noise_mismatch_sp_hires"
steps/make_mfcc.sh --nj 20 --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" data/$data_dir
steps/compute_cmvn_stats.sh data/$data_dir
utils/fix_data_dir.sh data/$data_dir