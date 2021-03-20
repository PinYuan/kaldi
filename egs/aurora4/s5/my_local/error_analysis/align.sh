#!/bin/bash

. ./path.sh
cmd=run.pl

lm_type="tgpr_5k"
exp_dir="exp/chain/train_from_scratch/TDNN_1A/FSFAE3/DEFAULT/SPECAUG/tdnn_1a_feam_mtlae_fbank-mfcc-context_noise-stats/e50_fdae0.04_fdspae0.04_stats-900.1.1.900_il0.01_fl0.001"

graph="exp/chain/tree_a_sp/graph_${lm_type}"

for test_set in "A" "B" "C" "D"; do
    data="data/test_${test_set}_hires"
    decode_dir="${exp_dir}/decode_${lm_type}_${test_set}"
    
    # minimum wer
    lmwt_wer=`grep -r '%WER' ${decode_dir}/wer_* | rev | cut -f 2 -d '/' | rev | sed -E 's/%WER|:|\[ [0-9]+//g' | awk 'BEGIN{min=100; lmwt=0;} $2 < min {lmwt=$1; min=$2;} END{print lmwt, min;}' | sed 's/wer_//g'`
    best_lmwt=`echo $lmwt_wer | cut -d ' ' -f 1`
    wer=`echo $lmwt_wer | cut -d ' ' -f 2`

    mkdir -p $decode_dir/scoring/wer_details
    
    # record best language model weight
    echo $best_lmwt > $decode_dir/scoring/wer_details/lmwt

    # tra 2 txt
    cat $decode_dir/scoring/$best_lmwt.tra | utils/int2sym.pl -f 2- $graph/words.txt | sed s:\<UNK\>::g > $decode_dir/scoring/$best_lmwt.txt

    # per_utt, per_spk
    $cmd $decode_dir/scoring/log/stats1.log \
        cat $decode_dir/scoring/$best_lmwt.txt \| \
        align-text --special-symbol="'***'" ark:$decode_dir/scoring/test_filt.txt ark:- ark,t:- \|  \
        utils/scoring/wer_per_utt_details.pl --special-symbol "'***'" \| tee $decode_dir/scoring/wer_details/per_utt \|\
        utils/scoring/wer_per_spk_details.pl $data/utt2spk \> $decode_dir/scoring/wer_details/per_spk || exit 1;

    # ops
    $cmd $decode_dir/scoring/log/stats2.log \
        cat $decode_dir/scoring/wer_details/per_utt \| \
        utils/scoring/wer_ops_details.pl --special-symbol "'***'" \| \
        sort -b -i -k 1,1 -k 4,4rn -k 2,2 -k 3,3 \> $decode_dir/scoring/wer_details/ops || exit 1;

    $cmd $decode_dir/scoring/log/wer_bootci.log \
        compute-wer-bootci --mode=present \
        ark:$decode_dir/scoring/test_filt.txt ark:$decode_dir/scoring/$best_lmwt.txt \
        '>' $decode_dir/scoring/wer_details/wer_bootci || exit 1;

    rm $decode_dir/scoring/$best_lmwt.txt
done