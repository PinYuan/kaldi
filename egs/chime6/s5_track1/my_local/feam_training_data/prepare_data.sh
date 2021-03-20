#!/bin/bash

. ./cmd.sh
. ./path.sh

datadir="train_worn_simu_u400k_cleaned_dae_sp"

python3 my_local/feam_training_data/mk_feam_clean_data.py

utils/utt2spk_to_spk2utt.pl data/${datadir}_hires/utt2spk > data/${datadir}_hires/spk2utt
cat data/${datadir}_hires/wav.scp | sort | uniq | sort -o data/${datadir}_hires/wav.scp

steps/make_mfcc.sh --nj 20 --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" data/${datadir}_hires || exit 1;
    steps/compute_cmvn_stats.sh data/${datadir}_hires || exit 1;
    utils/fix_data_dir.sh data/${datadir}_hires || exit 1;