#!/bin/bash

local/chain/tuning/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/run_cnn_tdnn_1a.sh --nj 96 \
    --stage 13 \
    --train-set train_worn_simu_u400k_cleaned \
    --test-sets "dev_gss eval_gss" \
    --gmm tri3_cleaned --nnet3-affix _train_worn_simu_u400k_cleaned_rvb

local/decode.sh --stage 3 \
    --enhancement gss \
    --train_set "train_worn_simu_u400k" \
    --dir "exp/chain_train_worn_simu_u400k_cleaned_rvb/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/cnn_tdnn_1a_sp/e8_il1.5e-4_fl1.5e-5"