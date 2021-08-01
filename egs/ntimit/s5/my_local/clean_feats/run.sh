#!/bin/bash

stage=0
nj=30
target_set="train"

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

timit_egs="/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/timit/s5"
ntimit_egs="/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/ntimit/s5"

if [ $stage -le 0 ]; then
    cd ${timit_egs}

    echo "$0: preparing directory for speed-perturbed data"
    utils/data/perturb_data_dir_speed_3way.sh data/${target_set} data/${target_set}_sp

    echo "$0: creating high-resolution MFCC features"
    mfccdir=data/${train_set}_sp_hires/data
    utils/copy_data_dir.sh data/${target_set}_sp data/${target_set}_sp_hires
    utils/data/perturb_data_dir_volume.sh data/${target_set}_sp_hires
    steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
      --cmd "$train_cmd" data/${target_set}_sp_hires
    steps/compute_cmvn_stats.sh data/${target_set}_sp_hires
    utils/fix_data_dir.sh data/${target_set}_sp_hires
fi

if [ $stage -le 1 ]; then
    cd ${ntimit_egs}

    python my_local/clean_feats/prepare_feats_scp.py
fi

