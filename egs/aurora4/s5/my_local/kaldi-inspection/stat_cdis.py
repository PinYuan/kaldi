
exp_dir = "/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5/exp/chain/train_from_scratch/TDNN_1A/FSFAE3/AM_SPECAUG/tdnn_1a_feam_specaug_mfcc_v1/e50_f0.2_il0.01_fl0.001"
lang_type = "tgpr_5k"

test_sets = ["A", "B", "C", "D"]

for test_set in test_sets:
    results = {"Chr": 0, "Sent": 0,  "C": 0, "D": 0, "I": 0, "S": 0}
    with open(f"{exp_dir}/decode_{lang_type}_{test_set}/scoring/wer_details/per_utt") as file:
        for line in file:
            uid, _type, rest = line.strip().split(" ", 2)
            rest_seq = rest.split(" ")
            rest_seq = [i for i in rest_seq if i not in ["", "***"]]
            
            if _type == "op":
                for tag in rest_seq:
                    results[tag] += 1
            elif _type == "ref":
                results["Chr"] += len(rest_seq)
                results["Sent"] += 1

    print(f"For test set {test_set}: ", results)
    # break