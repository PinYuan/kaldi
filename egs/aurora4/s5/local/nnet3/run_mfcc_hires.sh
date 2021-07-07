#!/usr/bin/env bash

set -e -o pipefail

# This script is called from scripts like local/nnet3/run_tdnn.sh and
# local/chain/run_tdnn.sh (and may eventually be called by more scripts).  It
# contains the common feature preparation and iVector-related parts of the
# script.  See those scripts for examples of usage.

stage=0
nj=30
data_set="chien_denoised_eval92" 
data_set="chien_denoised_si84_multi_sp_vp"

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh


if [ $stage -le 5 ]; then
  echo "$0: creating high-resolution MFCC features"

  for datadir in ${data_set}; do
    utils/copy_data_dir.sh data/$datadir data/${datadir}_hires
  done

  for datadir in ${data_set}; do
    steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
      --cmd "$train_cmd" data/${datadir}_hires
    steps/compute_cmvn_stats.sh data/${datadir}_hires
    utils/fix_data_dir.sh data/${datadir}_hires
  done

fi

exit 0;
