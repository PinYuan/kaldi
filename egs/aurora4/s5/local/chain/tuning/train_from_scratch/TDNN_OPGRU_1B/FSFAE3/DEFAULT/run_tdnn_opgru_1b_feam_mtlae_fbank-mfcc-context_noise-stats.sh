#!/usr/bin/env bash
# Copyright 2018 Xiaohui Zhang
#           2017 University of Chinese Academy of Sciences (UCAS) Gaofeng Cheng
# Apache 2.0

# This is similar with tdnn_opgru_1a but with correct num_leaves (7k rather than 11k),
# aligments from lattices when building the tree, and better l2-regularization as opgru-1a
# from fisher-swbd.

# ./local/chain/compare_wer_general.sh tdnn_opgru_1a_sp tdnn_opgru_1b_sp
# System            tdnn_opgru_1a_sp  tdnn_opgru_1b_sp
# WER on eval2000(tg)        11.6      11.4
# WER on eval2000(fg)        11.5      11.2
# WER on rt03(tg)            11.5      11.1
# WER on rt03(fg)            11.2      10.8
# Final train prob         -0.088     -0.091
# Final valid prob         -0.088     -0.091
# Final train prob (xent)  -1.048     -0.990
# Final valid prob (xent)  -1.0253    -0.091
# Num-parameters          37364848    34976320


# ./steps/info/chain_dir_info.pl exp/${multi}/chain/tdnn_opgru_1b_sp
# exp/${multi}/chain/tdnn_opgru_1b_sp: num-iters=2621 nj=3..16 num-params=35.0M dim=40+100->6176 combine=-0.098->-0.096 (over 4)
# xent:train/valid[1744,2620,final]=(-1.49,-0.991,-0.990/-1.51,-1.01,-1.01) 
# logprob:train/valid[1744,2620,final]=(-0.118,-0.091,-0.091/-0.117,-0.093,-0.091)

# online results
# Eval2000
# %WER 14.3 | 2628 21594 | 87.8 8.9 3.3 2.1 14.3 49.8 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_eval2000_fsh_sw1_tg/score_7_0.0/eval2000_hires.ctm.callhm.filt.sys
# %WER 11.4 | 4459 42989 | 90.2 7.2 2.7 1.6 11.4 46.3 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_eval2000_fsh_sw1_tg/score_8_0.5/eval2000_hires.ctm.filt.sys
# %WER 8.4 | 1831 21395 | 92.7 5.3 2.0 1.1 8.4 41.8 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_eval2000_fsh_sw1_tg/score_10_0.0/eval2000_hires.ctm.swbd.filt.sys
# %WER 14.2 | 2628 21594 | 88.0 8.8 3.3 2.2 14.2 49.4 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_eval2000_fsh_sw1_fg/score_7_0.0/eval2000_hires.ctm.callhm.filt.sys
# %WER 11.4 | 4459 42989 | 90.3 7.1 2.6 1.7 11.4 45.9 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_eval2000_fsh_sw1_fg/score_8_0.0/eval2000_hires.ctm.filt.sys
# %WER 8.2 | 1831 21395 | 92.9 5.1 2.0 1.1 8.2 41.3 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_eval2000_fsh_sw1_fg/score_11_0.0/eval2000_hires.ctm.swbd.filt.sys

# RT03
# %WER 9.0 | 3970 36721 | 92.0 5.5 2.4 1.1 9.0 37.9 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_rt03_fsh_sw1_tg/score_7_0.0/rt03_hires.ctm.fsh.filt.sys
# %WER 11.2 | 8420 76157 | 90.0 6.8 3.2 1.2 11.2 41.1 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_rt03_fsh_sw1_tg/score_8_0.0/rt03_hires.ctm.filt.sys
# %WER 13.2 | 4450 39436 | 88.1 7.5 4.4 1.3 13.2 44.1 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_rt03_fsh_sw1_tg/score_10_0.0/rt03_hires.ctm.swbd.filt.sys
# %WER 8.7 | 3970 36721 | 92.3 5.1 2.6 1.0 8.7 37.8 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_rt03_fsh_sw1_fg/score_8_0.0/rt03_hires.ctm.fsh.filt.sys
# %WER 10.9 | 8420 76157 | 90.3 6.5 3.1 1.2 10.9 40.6 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_rt03_fsh_sw1_fg/score_8_0.0/rt03_hires.ctm.filt.sys
# %WER 12.9 | 4450 39436 | 88.5 7.9 3.6 1.4 12.9 43.1 | exp/${multi}/chain/tdnn_opgru_1b_sp_online/decode_rt03_fsh_sw1_fg/score_8_0.0/rt03_hires.ctm.swbd.filt.sys

set -e

# configs for 'chain'
stage=12
nj=30
train_stage=-10
get_egs_stage=-10
speed_perturb=true
multi=multi_a
gmm=tri3b_multi
decode_iter=
decode_dir_affix=
rescore=false # whether to rescore lattices
dropout_schedule='0,0@0.20,0.2@0.50,0'

# training options
num_of_epoch=4
chunk_width=150
chunk_left_context=40
chunk_right_context=0
xent_regularize=0.025
self_repair_scale=0.00001
label_delay=5

frame_weight_dae=0.04
frame_weight_dspae=0.04
initial_effective_lrate=0.001
final_effective_lrate=0.0001
argu_desc="e${num_of_epoch}_fdae${frame_weight_dae}_fdspae${frame_weight_dspae}_stats-900.1.1.900_il${initial_effective_lrate}_fl${final_effective_lrate}"


# decode options
extra_left_context=50
extra_right_context=0
frames_per_chunk=

remove_egs=true
common_egs_dir=

affix=
nnet3_affix= 
# End configuration section.
echo "$0 $@"  # Print the command line for logging

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

# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet3 setup, and you can skip them by setting "--stage 8" if you have already
# run those things.
train_set=train_si84_multi
target_set=train_si84_clean
test_sets="test_A test_B test_C test_D"
ali_dir=exp/${gmm}_ali_${train_set}_sp
lat_dir=exp/chain${nnet3_affix}/${gmm}_${train_set}_sp_lats
dir=exp/chain${nnet3_affix}/train_from_scratch/TDNN_OPGRU_1B/FSFAE3/DEFAULT/feam_mtlae_fbank-mfcc-context_noise-stats/${argu_desc}
train_data_dir=data/${train_set}_sp_hires
train_ivector_dir=exp/nnet3${nnet3_affix}/ivectors_${train_set}_sp_hires
tree_dir=exp/chain${nnet3_affix}/tree_a_sp
lang=data/lang_chain

target_scp_dae=data/${target_set}_sp_hires/feats.target.scp
target_scp_dspae=data/train_si84_noise_mismatch_sp_hires/feats.scp

# if we are using the speed-perturbed data we need to generate
# alignments for it.
local/nnet3/run_ivector_common.sh \
  --stage $stage --nj $nj \
  --train-set $train_set --gmm $gmm \
  --num-threads-ubm $num_threads_ubm \
  --nnet3-affix "$nnet3_affix"

if [ $stage -le 9 ]; then
  # Get the alignments as lattices (gives the LF-MMI training more freedom).
  # use the same num-jobs as the alignments
  nj=$(cat $build_tree_ali_dir/num_jobs) || exit 1;
  steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" \
    --generate-ali-from-lats true data/$train_set  \
    data/lang_${multi}_${gmm} exp/${multi}/$gmm exp/${multi}/${gmm}_lats_nodup$suffix
  rm exp/${multi}/${gmm}_lats_nodup$suffix/fsts.*.gz # save space
fi

if [ $stage -le 10 ]; then
  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  rm -rf $lang
  cp -r data/lang_${multi}_${gmm} $lang
  silphonelist=$(cat $lang/phones/silence.csl) || exit 1;
  nonsilphonelist=$(cat $lang/phones/nonsilence.csl) || exit 1;
  # Use our special topology... note that later on may have to tune this
  # topology.
  steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang/topo
fi

if [ $stage -le 11 ]; then
  # Build a tree using our new topology.
  steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
      --context-opts "--context-width=2 --central-position=1" \
      --cmd "$train_cmd" 7000 data/$train_set $lang exp/${multi}/${gmm}_lats_nodup$suffix $treedir
fi

if [ $stage -le 12 ]; then
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
  learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)
  gru_opts="dropout-per-frame=true dropout-proportion=0.0 "

  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=100 name=ivector
  input dim=40 name=input
  
  # Denoise Autoencoder + deSpeech Autoencoder
  relu-renorm-layer name=tdnn1 dim=1024

  relu-renorm-layer name=tdnn2-dae dim=256 input=tdnn1
  relu-renorm-layer name=tdnn2-shared dim=768 input=tdnn1
  relu-renorm-layer name=tdnn2-dspae dim=256 input=tdnn1

  relu-renorm-layer name=tdnn3-dae dim=512 input=Append(tdnn2-dae, tdnn2-shared)
  relu-renorm-layer name=tdnn3-shared dim=512 input=Append(tdnn2-dae, tdnn2-shared, tdnn2-dspae)
  relu-renorm-layer name=tdnn3-dspae dim=512 input=Append(tdnn2-shared, tdnn2-dspae)

  relu-renorm-layer name=tdnn4-dae dim=768 input=Append(tdnn3-dae, tdnn3-shared)
  relu-renorm-layer name=tdnn4-shared dim=256 input=Append(tdnn3-dae, tdnn3-shared, tdnn3-dspae)
  relu-renorm-layer name=tdnn4-dspae dim=768 input=Append(tdnn3-shared, tdnn3-dspae)

  relu-renorm-layer name=tdnn5-dae dim=1024 input=Append(tdnn4-dae, tdnn4-shared)
  relu-renorm-layer name=tdnn5-dspae dim=1024 input=Append(tdnn4-shared, tdnn4-dspae)

  affine-layer name=prefinal-dae dim=40 input=tdnn5-dae
  affine-layer name=prefinal-dspae dim=40 input=tdnn5-dspae

  output name=output-dae objective-type=quadratic input=prefinal-dae
  output name=output-dspae objective-type=quadratic input=prefinal-dspae
  
  # AM
  no-op-component name=context-acous input=Append(input@-2, input@-1, input@0, input@1, input@2)
  no-op-component name=context-dae input=Append(prefinal-dae@-1, prefinal-dae@0, prefinal-dae@1)
  stats-layer name=stats-dspae config=mean+stddev(-900:1:1:900) input=prefinal-dspae
  affine-layer name=lda input=Append(dae-context, stats-dspae, context-acous, ReplaceIndex(ivector, t, 0))
  
  # the first splicing is moved before the lda layer, so no splicing here
  relu-batchnorm-layer name=tdnn1-am dim=1024
  relu-batchnorm-layer name=tdnn2-am input=Append(-1,0,1) dim=1024
  relu-batchnorm-layer name=tdnn3-am input=Append(-1,0,1) dim=1024
  
  # check steps/libs/nnet3/xconfig/lstm.py for the other options and defaults
  norm-opgru-layer name=opgru1 cell-dim=1024 recurrent-projection-dim=256 non-recurrent-projection-dim=256 delay=-3 $gru_opts
  relu-batchnorm-layer name=tdnn4-am input=Append(-3,0,3) dim=1024
  relu-batchnorm-layer name=tdnn5-am input=Append(-3,0,3) dim=1024
  norm-opgru-layer name=opgru2 cell-dim=1024 recurrent-projection-dim=256 non-recurrent-projection-dim=256 delay=-3 $gru_opts
  relu-batchnorm-layer name=tdnn6-am input=Append(-3,0,3) dim=1024
  relu-batchnorm-layer name=tdnn7-am input=Append(-3,0,3) dim=1024
  norm-opgru-layer name=opgru3 cell-dim=1024 recurrent-projection-dim=256 non-recurrent-projection-dim=256 delay=-3 $gru_opts
  
  output-layer name=output input=opgru3 output-delay=$label_delay include-log-softmax=false dim=$num_targets max-change=1.5
  output-layer name=output-xent input=opgru3 output-delay=$label_delay dim=$num_targets learning-rate-factor=$learning_rate_factor max-change=1.5
EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi

if [ $stage -le 13 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
     /export/b0{3,7,9,8}/$USER/kaldi-data/egs/multi-en-$(date +'%m_%d_%H_%M')/s5/$dir/egs/storage $dir/egs/storage
  fi

  steps/nnet3/chain/train_mtlae.py --stage $train_stage \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.00005 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.num-chunk-per-minibatch 64 \
    --trainer.frames-per-iter 1200000 \
    --trainer.max-param-change 2.0 \
    --trainer.num-epochs $num_of_epoch \
    --trainer.optimization.shrink-value 0.99 \
    --trainer.optimization.num-jobs-initial 3 \
    --trainer.optimization.num-jobs-final 16 \
    --trainer.optimization.initial-effective-lrate $initial_effective_lrate \
    --trainer.optimization.final-effective-lrate $final_effective_lrate \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.optimization.momentum 0.0 \
    --trainer.deriv-truncate-margin 8 \
    --egs.stage $get_egs_stage \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width $chunk_width \
    --egs.chunk-left-context $chunk_left_context \
    --egs.chunk-right-context $chunk_right_context \
    --egs.chunk-left-context-initial 0 \
    --egs.chunk-right-context-final 0 \
    --egs.frame-weight-dae=$frame_weight_dae \
    --egs.frame-weight-dspae=$frame_weight_dspae \
    --egs.dir "$common_egs_dir" \
    --cleanup.remove-egs $remove_egs \
    --use-gpu=wait \
    --feat-dir=$train_data_dir \
    --tree-dir=$tree_dir \
    --lat-dir=$lat_dir \
    --target_scp_dae=$target_scp_dae \
    --target_scp_dspae=$target_scp_dspae \
    --dir $dir  || exit 1;
fi

# if [ $stage -le 14 ]; then
#   # Note: it might appear that this $lang directory is mismatched, and it is as
#   # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
#   # the lang directory.
#   utils/mkgraph.sh --self-loop-scale 1.0 data/lang_${multi}_${gmm}_fsh_sw1_tg $dir $dir/graph_fsh_sw1_tg
# fi

if [ $stage -le 15 ]; then
  rm $dir/.error 2>/dev/null || true
  [ -z $extra_left_context ] && extra_left_context=$chunk_left_context;
  [ -z $extra_right_context ] && extra_right_context=$chunk_right_context;
  [ -z $frames_per_chunk ] && frames_per_chunk=$chunk_width;
  if [ ! -z $decode_iter ]; then
    iter_opts=" --iter $decode_iter "
  fi

  for data in $test_sets; do
      (
        data_affix=$(echo $data | sed s/test_//)
        nspk=$(wc -l <data/${data}_hires/spk2utt)
        for lmtype in tgpr_5k bg; do
            steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
                --nj $nspk --cmd "$decode_cmd" $iter_opts \
                --extra-left-context $extra_left_context  \
                --extra-right-context $extra_right_context  \
                --extra-left-context-initial 0 \
                --extra-right-context-final 0 \
                --frames-per-chunk "$frames_per_chunk" \
                --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${data}_hires \
                $tree_dir/graph_${lmtype} data/${data}_hires ${dir}/decode_${lmtype}_${data_affix} || exit 1
        done
      if $rescore; then
        steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
          data/lang_${multi}_${gmm}_fsh_sw1_{tg,fg} data/${decode_set}_hires \
          $dir/decode_${decode_set}${decode_dir_affix:+_$decode_dir_affix}_fsh_sw1_{tg,fg} || exit 1;
      fi
      ) || touch $dir/.error &
  done
  wait
  if [ -f $dir/.error ]; then
    echo "$0: something went wrong in decoding"
    exit 1
  fi
fi

test_online_decoding=false
lang=data/lang_${multi}_${gmm}_fsh_sw1_tg
if $test_online_decoding && [ $stage -le 16 ]; then
  # note: if the features change (e.g. you add pitch features), you will have to
  # change the options of the following command line.
  steps/online/nnet3/prepare_online_decoding.sh \
       --mfcc-config conf/mfcc_hires.conf \
       $lang exp/${multi}/nnet3/extractor $dir ${dir}_online

  rm $dir/.error 2>/dev/null || true
  for decode_set in rt03 eval2000; do
    (
      # note: we just give it "$decode_set" as it only uses the wav.scp, the
      # feature type does not matter.

      steps/online/nnet3/decode.sh --nj 50 --cmd "$decode_cmd" $iter_opts \
          --acwt 1.0 --post-decode-acwt 10.0 \
         $graph_dir data/${decode_set}_hires \
         ${dir}_online/decode_${decode_set}${decode_iter:+_$decode_iter}_${decode_suff} || exit 1;
      if $rescore; then
        steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
          data/lang_${multi}_${gmm}_fsh_sw1_{tg,fg} data/${decode_set}_hires \
          ${dir}_online/decode_${decode_set}${decode_dir_affix:+_$decode_dir_affix}_fsh_sw1_{tg,fg} || exit 1;
      fi
    ) || touch $dir/.error &
  done
  wait
  if [ -f $dir/.error ]; then
    echo "$0: something went wrong in online decoding"
    exit 1
  fi
fi

exit 0;