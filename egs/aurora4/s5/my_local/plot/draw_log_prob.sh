#/bin/bash

# Reference: https://github.com/kaldi-asr/kaldi/blob/master/egs/aurora4/s5/local/chain/compare_wer.sh
# Example: https://groups.google.com/g/kaldi-help/c/DrWBaWi_kkQ/m/ZiMKCQqhBAAJ

exp_dir="exp/chain/tdnn1a_sp/e10"

all_exp="tdnn1a_sp/e15 train_from_scratch/0927/e30_f0.2_il0.0005_fl0.00005 train_from_scratch/0928/e10_f0.2_il0.0005_fl0.00005"

max_iter=0
for exp_dir in ${all_exp}; do
    exp_max_iter=`ls exp/chain/${exp_dir}/log/compute_prob_train.*.log | grep -v "final" | rev | cut -d '/' -f 1 | rev | cut -d '.' -f 2 | sort -n -r | head -1`
    if (( ${exp_max_iter} > ${max_iter} )); then
        max_iter=${exp_max_iter}
    fi
done


for iter in $(seq 1 ${max_iter}); do
    result="${iter}"
    for exp_dir in ${all_exp}; do
	train_iter_log="exp/chain/${exp_dir}/log/compute_prob_train.${iter}.log"
	if [ -f ${train_iter_log} ]; then
	    train_output_prob=$(grep Overall ${train_iter_log} | grep -v xent | awk '{printf("%.4f", $8)}')
	else
	    train_output_prob=""
	fi

	valid_iter_log="exp/chain/${exp_dir}/log/compute_prob_valid.${iter}.log"
	if [ -f ${valid_iter_log} ]; then
	    valid_output_prob=$(grep Overall ${valid_iter_log} | grep -v xent | awk '{printf("%.4f", $8)}')
        else
	    valid_output_prob=""
	fi

	result="${result},${train_output_prob},${valid_output_prob}"
    done
    echo ${result}
done

