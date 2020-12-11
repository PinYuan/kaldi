#!/bin/bash

# Begin configuration section.
cur_wd="/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5"

mdl="/mnt/HDD2/user_pinyuanc/kaldi/egs/aurora4/s5/exp/nnet3/denoising_autoencoder/baseline/e10_il0.001_fl0.0001"
iter=final
nj=8
data_set=test_A_hires
output_dir="$cur_wd/my_data/denoised/test_A_hires"
# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh 

data=$cur_wd/data/$data_set 
steps/nnet3/compute_output.sh --nj $nj --use-gpu false --iter $iter $data $mdl $output_dir