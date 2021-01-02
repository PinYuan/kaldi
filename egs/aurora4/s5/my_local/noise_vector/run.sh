#!/bin/bash

. ./cmd.sh
. ./path.sh

stage=1

train_sets="si84_multi_sp"
test_sets="A B C D"
model_affix="_multi"
silence_weight=0.00001
conf_threshold=1.0


if [ $stage -le 0 ]; then
    # Decode with GMM-HMM, generate lattices
    echo "Generating lattices, stage 1"

    for datadir in $train_sets $test_sets; do
        if [[ "A B C D" =~ ${datadir} ]]; then
            datadir_prefix="test"
        else
            datadir_prefix="train"
        fi

        echo ">    Processing ${datadir_prefix}_${datadir}..."

        nspk=$(wc -l <data/${datadir_prefix}_${datadir}/spk2utt)
        utils/mkgraph.sh data/lang_test_tgpr \
            exp/tri3b${model_affix} exp/tri3b${model_affix}/graph_tgpr || exit 1;
        steps/decode_fmllr.sh --nj $nspk --cmd "$decode_cmd" \
            exp/tri3b${model_affix}/graph_tgpr data/${datadir_prefix}_${datadir} exp/tri3b${model_affix}/decode_tgpr_${datadir} || exit 1;
    done
fi


if [ $stage -le 1 ]; then
    echo "Generating vad weights file"
    for datadir in $train_sets $test_sets; do
        if [[ "A B C D" =~ ${datadir} ]]; then
            datadir_prefix="test"
        else
            datadir_prefix="train"
        fi

        echo ">    Processing ${datadir_prefix}_${datadir}..."
        
        decode_dir=exp/tri3b${model_affix}/decode_tgpr_${datadir}

        vad_weights=${decode_dir}/weights_${conf_threshold}.gz
        my_local/noise_vector/extract_vad_weights.sh --silence-weight $silence_weight \
            --conf-threshold $conf_threshold \
            --cmd "$decode_cmd" ${iter:+--iter $iter} \
            data/${datadir_prefix}_${datadir} data/lang_test_tgpr \
            ${decode_dir} $vad_weights
    done
fi


if [ $stage -le 2 ]; then
    echo "Computing noise vector -> my_data/noise_vector/..."
    python3 my_local/noise_vector/gen_noise_vector.py --weights-conf-threshold ${conf_threshold} # 'flm' or 'sad', default is 'sad'
fi