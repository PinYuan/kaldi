#!/usr/bin/env bash

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

dev_sets="dev_0330a"
tree_dir="exp/chain/tree_a_sp"

# model to decode
argu_desc="e20_f0.04_il0.01_fl0.001"
dir="exp/chain/train_from_scratch/TDNN_1A/FSFAE3/DEFAULT/tdnn_1a_feam_baseline_mfcc_v1/${argu_desc}"
iters="30 35 40 45 final"

chunk_width=140,100,160
frames_per_chunk=$(echo $chunk_width | cut -d, -f1)


for data in ${dev_sets}; do
    for iter in ${iters}; do
        (
        data_affix=$(echo $data | sed s/dev_//)
        nspk=$(wc -l <data/${data}_hires/spk2utt)
        # for lmtype in tgpr_5k; do
        #     steps/nnet3/decode.sh \
        #     --acwt 1.0 --post-decode-acwt 10.0 \
        #     --extra-left-context 0 --extra-right-context 0 \
        #     --extra-left-context-initial 0 \
        #     --extra-right-context-final 0 \
        #     --frames-per-chunk $frames_per_chunk \
        #     --iter $iter \
        #     --nj $nspk --cmd "$decode_cmd"  --num-threads 4 \
        #     --online-ivector-dir exp/nnet3/ivectors_${data}_hires \
        #     $tree_dir/graph_${lmtype} data/${data}_hires ${dir}/decode_${iter}_${lmtype}_${data_affix} || exit 1
        # done

        wer=$(cat $dir/decode_${iter}_tgpr_5k_${data_affix}/wer* | utils/best_wer.sh | awk '{print $2}')
        printf "iter %s % 10s\n" $iter $wer

        ) || touch $dir/.error #&
    done
done