#!/bin/bash

exp_dir="exp/chain/ppg/tdnn_1a_clean/e10_il0.01_fl0.001"
add_config="my_local/ppg/add.config"
node="tdnnf4.noop"

. ./path.sh

# 1. add "output-mine" after which node i want
echo "output-node name=output-mine input=${node}" > ${add_config}
nnet3-init ${exp_dir}/final.mdl ${add_config} ${exp_dir}/final.raw

# 2. remove old output and rename output-mine to output
nnet3-copy --edits='remove-output-nodes name=output;remove-output-nodes name=output.affine;rename-node old-name=output-mine new-name=output;' \
    ${exp_dir}/final.raw ${exp_dir}/tmp.raw
mv ${exp_dir}/tmp.raw ${exp_dir}/final.raw

# x. create text version
nnet3-copy --binary=false ${exp_dir}/final.raw ${exp_dir}/text.raw

# 3. compute_output
dataset="train_si84_clean_sp_hires"
steps/nnet3/compute_output.sh --nj 20 \
    --online-ivector-dir exp/nnet3/ivectors_${dataset} \
    data/${dataset} ${exp_dir} exp/nnet3/ppg/${dataset}/${node}
