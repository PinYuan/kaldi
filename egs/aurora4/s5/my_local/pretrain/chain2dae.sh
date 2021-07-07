#!/bin/bash
# Usage: Extract the Speech Enhancement component from chain model

. ./path.sh

input_model="exp/chain/train_from_scratch/TDNN_1A/FSFAE3/AM_SPECAUG/\
             tdnn_1a_feam_specaug_mfcc_v1/e50_f0.04_il0.01_fl0.001/final.mdl"
output_model=`dirname $input_model`/ext_dae.raw

nnet3-copy --edits="remove-output-nodes name=output;                \
                    remove-output-nodes name=output-xent;           \
                    remove-orphans remove-orphan-inputs=true;       \
                    rename-node old-name=output_ae new-name=output" \
            $input_model $output_model

