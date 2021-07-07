#!/bin/bash

# local/chain/tuning/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/run_cnn_tdnn_1a.sh --nj 96 \
#     --stage 13 \
#     --train-set train_worn_simu_u400k_cleaned \
#     --test-sets "dev_gss eval_gss" \
#     --gmm tri3_cleaned --nnet3-affix _train_worn_simu_u400k_cleaned_rvb

# local/decode.sh --stage 3 \
#     --enhancement gss \
#     --train_set "train_worn_simu_u400k" \
#     --dir "exp/chain_train_worn_simu_u400k_cleaned_rvb/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/cnn_tdnn_1a_sp/e8_il1.5e-4_fl1.5e-5"

# local/chain/tuning/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/run_cnn_tdnn_1a_feam_mtlae_fbank-mfcc-context_noise-stats.sh --nj 96 \
#     --stage 13 \
#     --train-set train_worn_simu_u400k_cleaned \
#     --test-sets "dev_gss eval_gss" \
#     --gmm tri3_cleaned --nnet3-affix _train_worn_simu_u400k_cleaned_rvb --train-stage -2 \
# && local/decode.sh --stage 3 \
#     --enhancement gss \
#     --train_set "train_worn_simu_u400k" \
#     --dir "exp/chain_train_worn_simu_u400k_cleaned_rvb/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/feam_mtlae_fbank-mfcc-context_noise-stats/e10_fdae4e-2_fdspae4e-2_stats-900.1.1.900_il1.5e-4_fl1.5e-5"

local/chain/tuning/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/run_cnn_tdnn_1a_feam_mtlae_fbank-mfcc-t_noise-t_copy.sh --nj 96 \
    --stage 13 \
    --train-set train_worn_simu_u400k_cleaned \
    --test-sets "dev_gss eval_gss" \
    --gmm tri3_cleaned --nnet3-affix _train_worn_simu_u400k_cleaned_rvb \
&& local/decode.sh --stage 3 \
    --enhancement gss \
    --train_set "train_worn_simu_u400k" \
    --dir "exp/chain_train_worn_simu_u400k_cleaned_rvb/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/feam_mtlae_fbank-mfcc-t_noise-t/e8_fdae4e-2_fdspae4e-2_il1.5e-4_fl1.5e-5_new"

# local/decode.sh --stage 3 \
#     --enhancement gss \
#     --train_set "train_worn_simu_u400k" \
#     --dir "exp/chain_train_worn_simu_u400k_cleaned_rvb/train_from_scratch/CNN_TDNN_1A/FSFAE3/DEFAULT/SPECAUG/feam_mtlae_fbank-mfcc-t_noise-t/e10_fdae4e-2_fdspae4e-2_il1.5e-4_fl1.5e-5_new"
