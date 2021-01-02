import os
import re
import tqdm
import argparse
import numpy as np
from kaldiio import ReadHelper, WriteHelper


def compute_sad(weights, feats):
    speech_frame_indices = np.where(weights == 1)
    sil_frame_indices = np.where(weights == 0.00001)
    
    speech_features = feats[speech_frame_indices] # (speech frame num, 40)
    sil_features = feats[sil_frame_indices] # (speech frame num, 40)

    if speech_features.shape[0] == 0:
        mean_speech_features = np.zeros(40)
    else:
        mean_speech_features = np.mean(speech_features, axis=0) # (40)
   
    if sil_features.shape[0] == 0:
        mean_sil_features = np.zeros(40)
    else:
        mean_sil_features = np.mean(sil_features, axis=0) # (40)

    noise_vector = np.concatenate((mean_speech_features, mean_sil_features)) # (80)
    noise_vector = noise_vector[np.newaxis, :] # (1, 80)
    
    return noise_vector


def compute_flm(feats, num_frame=10):
    first_frames = feats[:num_frame]
    last_frames = feats[-num_frame:]
    noise_frames = np.concatenate((first_frames, last_frames))
    noise_vector = np.mean(noise_frames, axis=0) # (40)
    noise_vector = noise_vector[np.newaxis, :] # (1, 40)
    return noise_vector
    

def main(kind, conf_threshold):
    for dset in ["train_si84_multi_sp", "test_A", "test_B", "test_C", "test_D"]: # test_eval92
        print(f"Processing {dset}...")

        suffix = re.sub("train_|test_", "", dset)
        decode_dir = f"exp/tri3b_multi/decode_tgpr_{suffix}"
        mfcc_dir = f"data/{dset}_hires"

        uid2noise_vector = dict()
        if kind == "sad":
            with ReadHelper(f"ark: gunzip -c {decode_dir}/weights_{conf_threshold}.gz |") as weights_reader, \
                ReadHelper(f"scp:{mfcc_dir}/feats.scp") as feats_reader:
                for (uid, weights), (_, feats) in tqdm.tqdm(zip(weights_reader, feats_reader)):
                    noise_vector = compute_sad(weights, feats)
                    if "test" in dset:
                        noise_vector = np.squeeze(noise_vector, axis=0)
                    uid2noise_vector[uid] = noise_vector

        elif kind == "flm":
            with ReadHelper(f"scp:{mfcc_dir}/feats.scp") as feats_reader:
                for uid, feats in tqdm.tqdm(feats_reader):
                    noise_vector = compute_flm(feats)
                    if "test" in dset:
                        noise_vector = np.squeeze(noise_vector, axis=0)
                    uid2noise_vector[uid] = noise_vector      

        output_dir = f"/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5/my_data/noise_vector/{kind}/nvectors_{dset}_hires"
        if kind == "sad": output_dir = f"{output_dir}/conf_{conf_threshold}"
        output_name = "ivector_online" # hack
        os.makedirs(output_dir, exist_ok=True)
        with WriteHelper(f"ark,scp:{output_dir}/{output_name}.ark,{output_dir}/{output_name}.scp") as writer:
            for uid in sorted(uid2noise_vector):
                writer(str(uid), uid2noise_vector[uid])

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
