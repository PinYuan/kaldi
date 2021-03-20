import os
import tqdm
import argparse
import subprocess
from shutil import copyfile


def dump_files(src_dir, out_dir, data):
    with open(f"{out_dir}/wav.scp", "w") as file:
        for key in sorted(data):
            file.write(f"{key} {data[key]}\n")
    copyfile(f"data/{src_dir}/utt2spk", f"{out_dir}/utt2spk")
    copyfile(f"data/{src_dir}/spk2utt", f"{out_dir}/spk2utt")
    copyfile(f"data/{src_dir}/segments", f"{out_dir}/segments")


def prepare_train(kind):
    data_dir = f"data/train_worn_simu_u400k_cleaned_{kind}_sp_hires"
    os.makedirs(f"{data_dir}/wav", exist_ok=True)
    os.makedirs(f"{data_dir}/log", exist_ok=True)

    clean_set = "train_worn_simu_u400k_cleaned_dae_sp_hires"
    multi_set = "train_worn_simu_u400k_cleaned_sp_hires"

    data = dict()

    with open(f"data/{multi_set}/wav.scp") as multi_file, open(f"data/{clean_set}/wav.scp") as clean_file,\
        open(f"data/train_worn_simu_u400k_cleaned_{kind}_sp_hires/log/mix_wav.log", "w") as log_file:
        for multi_line, clean_line in tqdm.tqdm(zip(multi_file, clean_file)):
            multi_key, multi_cmd = multi_line.strip().split(" ", 1)
            clean_key, clean_cmd = clean_line.strip().split(" ", 1)
            multi_cmd = multi_cmd[:-3] # [:-2]
            clean_cmd = clean_cmd[:-2]

            # create physical multi wav
            multi_wav_path = f"{data_dir}/wav/multi/{multi_key}.wav"
            if not os.path.exists(multi_wav_path):
                cmd = f"{multi_cmd} {multi_wav_path}"
                p = subprocess.Popen(cmd, shell=True)
                p.communicate()
            
            # compute the difference between 2 wav files and output a new wav
            noise_wav_path = f"{data_dir}/wav/{multi_key}.wav"
            if not os.path.exists(noise_wav_path):
                cmd = f"sox -m -v 1 '{multi_wav_path}' -v -1 '|{clean_cmd}' {noise_wav_path}"
                p = subprocess.Popen(cmd, shell=True)
                p.communicate()
            data[multi_key] = noise_wav_path

            log_file.write(f"{multi_key} {noise_wav_path}\n")

    # Dump wav.scp, utt2spk, spk2utt
    dump_files(multi_set, data_dir, data)


def main(kind):
    prepare_train(kind)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", default="noise_mismatch", nargs="?",
                        help="'noise_mismatch' might contain channel distortion, "\
                             "'pure_noise' only extract added noise (TODO)")
    args = parser.parse_args()

    main(kind=args.kind)