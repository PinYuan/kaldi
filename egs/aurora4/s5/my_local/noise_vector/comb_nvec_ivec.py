import os
import tqdm
import argparse
import numpy as np
from kaldiio import ReadHelper, WriteHelper


def get_ivec(dataset):
    ivec_dir = f"exp/nnet3/ivectors_{dataset}"
    uid2ivec = dict()
    with ReadHelper(f"scp:{ivec_dir}/ivector_online.scp") as feats_reader:
        for uid, feats in tqdm.tqdm(feats_reader):
            uid2ivec[uid] = feats
    return uid2ivec


def get_nvec(dataset, kind, conf_threshold):
    nvec_dir = f"my_data/noise_vector/{kind}/nvectors_{dataset}/" + \
                (f"conf_{conf_threshold}" if kind == "sad" else "")
    uid2nvec = dict()
    with ReadHelper(f"scp:{nvec_dir}/ivector_online.scp") as feats_reader:
        for uid, feats in tqdm.tqdm(feats_reader):
            uid2nvec[uid] = feats
    return uid2nvec


def main(kind, conf_threshold):
    for dset in ["train_si84_multi_sp", "test_A", "test_B", "test_C", "test_D"]: # dev_0330a
        print(f"Processing {dset}...")
        uid2ivec = get_ivec(f"{dset}_hires")
        uid2nvec = get_nvec(f"{dset}_hires", kind, conf_threshold)

        output_dir = f"/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5/my_data/ni_vector/{kind}/nivectors_{dset}_hires"
        if kind == "sad": output_dir = f"{output_dir}/conf_{conf_threshold}"
        output_name = "ivector_online" # hack
        os.makedirs(output_dir, exist_ok=True)

        with WriteHelper(f"ark,scp:{output_dir}/{output_name}.ark,{output_dir}/{output_name}.scp") as writer:
            for uid in sorted(uid2ivec):
                if dset == "train_si84_multi_sp":
                    uid2nvec[uid] = np.squeeze(uid2nvec[uid], axis=0)
                    uid2nvec[uid] = np.repeat(uid2nvec[uid][np.newaxis, :], uid2ivec[uid].shape[0], axis=0)
                    nivec = np.concatenate((uid2ivec[uid], uid2nvec[uid]), axis=1)
                elif "test" in dset:
                    uid2ivec[uid] = uid2ivec[uid][0]
                    nivec = np.concatenate((uid2ivec[uid], uid2nvec[uid]), axis=0)
                writer(str(uid), nivec)

        if dset == "train_si84_multi_sp":
            with open(f"{output_dir}/ivector_period", "w") as file:
                file.write("-1") # for compatible


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", default="sad", nargs="?",
                        help="speech activity detection (sad) or mean of first and last 10 frames (flm)")
    parser.add_argument("--weights-conf-threshold", default="1.0",
                        help="vad weight's confidence threshold")
    
    args = parser.parse_args()
    
    main(kind=args.kind, conf_threshold=args.weights_conf_threshold)