#!/bin/bash

. ./cmd.sh
. ./path.sh

utils=`pwd`/utils
clean_dir="data/train_si84_clean_sp"
ihmdata_dir="data/train_si84_multi_ihmdata_sp"

mkdir -p ${ihmdata_dir}

sed -e "s/0 /1 /g" ${clean_dir}/utt2spk > ${ihmdata_dir}/utt2spk
sed -e "s/0 /1 /g" ${clean_dir}/wav.scp > ${ihmdata_dir}/wav.scp
sed -e "s/0 /1 /g" ${clean_dir}/text > ${ihmdata_dir}/text
cp ${clean_dir}/spk2gender ${ihmdata_dir}/spk2gender
cat ${ihmdata_dir}/utt2spk | $utils/utt2spk_to_spk2utt.pl > ${ihmdata_dir}/spk2utt

steps/make_mfcc.sh --nj 20 --cmd "$train_cmd" ${ihmdata_dir}
steps/compute_cmvn_stats.sh ${ihmdata_dir}
utils/fix_data_dir.sh ${ihmdata_dir}