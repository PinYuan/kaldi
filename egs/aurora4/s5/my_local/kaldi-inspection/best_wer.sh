#!/bin/bash
# Reference from https://github.com/kaldi-asr/kaldi/blob/master/egs/wsj/s5/steps/scoring/score_kaldi_wer.sh

. ./cmd.sh
. ./path.sh

word_ins_penalty=0.0
min_lmwt=7
max_lmwt=17
stats=true

symtab=data/lang_test_tgpr_5k/words.txt
dir=exp/chain/train_from_scratch/TDNN_1A/FSFAE3/AM_SPECAUG/tdnn_1a_feam_specaug_mfcc_v1/e50_f0.2_il0.01_fl0.001/decode_tgpr_5k_D
  
for lmwt in $(seq $min_lmwt $max_lmwt); do
    # adding /dev/null to the command list below forces grep to output the filename
    grep WER $dir/wer_${lmwt} /dev/null
done | utils/best_wer.sh  >& $dir/scoring/best_wer || exit 1

cat "$dir/scoring/best_wer"
best_wer_file=$(awk -F'/' '{print $NF}' $dir/scoring/best_wer)
best_wip=0 # $(echo $best_wer_file | awk -F_ '{print $NF}')
best_lmwt=$(echo $best_wer_file | awk -F_ '{N=NF; print $N}')

if [ -z "$best_lmwt" ]; then
echo "$0: we could not get the details of the best WER from the file $dir/wer_*.  Probably something went wrong."
exit 1;
fi

if $stats; then
    mkdir -p $dir/scoring/wer_details
    echo $best_lmwt > $dir/scoring/wer_details/lmwt # record best language model weight
    echo $best_wip > $dir/scoring/wer_details/wip # record best word insertion penalty

    # Transform tra to txt
    hyp_filtering_cmd="cat"
    cat $dir/scoring/$best_lmwt.tra | \
        utils/int2sym.pl -f 2- $symtab > $dir/scoring/$best_lmwt.txt || exit 1;

    # Align text (C/I/S)
    run.pl $dir/scoring/log/stats1.log \
        cat $dir/scoring/$best_lmwt.txt \| \
        align-text --special-symbol="'***'" ark:$dir/scoring/test_filt.txt ark:- ark,t:- \|  \
        utils/scoring/wer_per_utt_details.pl --special-symbol "'***'" \| tee $dir/scoring/wer_details/per_utt || exit 1;
fi