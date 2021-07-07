import os
import re
import tqdm
import argparse
import subprocess
import numpy as np
from kaldiio import ReadHelper, WriteHelper


def main(uid_key):
    output_dir = "my_data/noise_vector/sad/view"

    uid_data_dict = {"uid": uid_key, "weights": None, "wav_path": None, "wav_cmd": None, "ctm": []}
    
    for dset in ["train_si84_multi_sp"]: # , "test_A", "test_B", "test_C", "test_D"
        print(f"Processing {dset}...")

        suffix = re.sub("train_|test_", "", dset)
        decode_dir = f"exp/tri3b_multi/decode_tgpr_{suffix}"
        mfcc_dir = f"data/{dset}_hires"

        with open(f"{mfcc_dir}/wav.scp") as wav_reader:
            for line in tqdm.tqdm(wav_reader):
                uid, wav_cmd = line.strip().split(" ", 1)
                if uid == uid_key:
                    uid_data_dict["wav_path"] = f"{output_dir}/{uid}.wav"
                    uid_data_dict["wav_cmd"] = wav_cmd[:-3] + uid_data_dict["wav_path"]
                    break

        with open(f"{decode_dir}/score_10/{dset}.ctm") as ctm_reader:
            for line in ctm_reader:
                uid, channel, start, duration, word, conf = line.strip().split()
                if uid == uid_key:
                    uid_data_dict["ctm"] += [(start, duration, word, conf)]

    # raw 2 wav
    p = subprocess.Popen(uid_data_dict["wav_cmd"], shell=True)
    p.communicate()

    for item in uid_data_dict["ctm"]:
        print(item)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("uid", default="011c02101", nargs="?",
                        help="utterence id to view its ctm and convert to wav")
    args = parser.parse_args()
    
    main(uid_key=args.uid)