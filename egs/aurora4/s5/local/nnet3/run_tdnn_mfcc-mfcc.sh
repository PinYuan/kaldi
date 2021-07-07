#!/usr/bin/env bash

# Modified from egs/aspire/s5/local/nnet3/run_autoencoder.sh
# renorm to batchnorm

# this is an example to show a "tdnn" system in raw nnet configuration
# i.e. without a transition model
# It uses corrupted (reverberation + noise) speech as input and clean speech 
# as output.

. ./cmd.sh

stage=0
nj=20
affix=
train_stage=-10
common_egs_dir=
egs_opts=
num_data_reps=10

# Training data
train_set=train_si84_multi_sp_hires
target_set=train_si84_clean_sp_hires

# Training options
srand=0
remove_egs=true
num_of_epoch=10
initial_effective_lrate=0.001
final_effective_lrate=0.0001

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

argu_desc="e${num_of_epoch}_il${initial_effective_lrate}_fl${final_effective_lrate}"
dir=exp/nnet3/denoising_autoencoder/tdnn_mfcc-mfcc/${argu_desc}

pinyuanc_dir="/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5"
train_data_dir=${pinyuanc_dir}/data/${train_set}
targets_scp=${pinyuanc_dir}/data/${target_set}/feats.target.scp

mkdir -p $dir

if [ $stage -le 9 ]; then
  echo "$0: creating neural net configs";
  num_targets=`feat-to-dim scp:$targets_scp - 2>/dev/null` || exit 1
  feat_dim=`feat-to-dim scp:$train_data_dir/feats.scp - 2>/dev/null` || exit 1

  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=$feat_dim name=input
  relu-renorm-layer name=tdnn1 dim=1024 input=Append(-2,-1,0,1,2)
  relu-renorm-layer name=tdnn2 dim=1024 input=Append(-1,2)
  relu-renorm-layer name=tdnn3 dim=1024 input=Append(-3,3)
  relu-renorm-layer name=tdnn4 dim=1024 input=Append(-7,2)
  affine-layer name=prefinal-ae dim=40
  output name=output objective-type=quadratic input=prefinal-ae
EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi

if [ $stage -le 10 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
     /export/b0{3,4,5,6}/$USER/kaldi-data/egs/aspire-$(date +'%m_%d_%H_%M')/s5/$dir/egs/storage $dir/egs/storage
  fi

  steps/nnet3/train_raw_dnn.py --stage=$train_stage \
    --cmd="$decode_cmd" \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --trainer.num-epochs $num_of_epoch \
    --trainer.optimization.num-jobs-initial 2 \
    --trainer.optimization.num-jobs-final 2 \
    --trainer.optimization.initial-effective-lrate $initial_effective_lrate \
    --trainer.optimization.final-effective-lrate $final_effective_lrate \
    --trainer.optimization.minibatch-size 512 \
    --egs.dir "$common_egs_dir" --egs.opts "$egs_opts" \
    --cleanup.remove-egs $remove_egs \
    --cleanup.preserve-model-interval 50 \
    --nj=$nj \
    --use-gpu=wait \
    --use-dense-targets=true \
    --feat-dir=$train_data_dir \
    --targets-scp=$targets_scp \
    --dir=$dir || exit 1;
fi
