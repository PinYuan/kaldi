import random
import argparse
from collections import defaultdict


def main(args):
    random.seed(0)

    dir = args.aurora4_list_dir

    for i in range(0, 14):
        index = f"{i+1:02}"

        spkid2utt = defaultdict(lambda: [])
        with open(f"{dir}/devtest{index}_1206_16k.list") as src_file:
            for line in src_file:
                wav_path = line.strip()
                wav_name = wav_path.split("/")[-1]
                spkid = wav_name[:3]
                spkid2utt[spkid] += [wav_name]

        prefix = "/".join(line.split("/")[:2])
        
        with open(f"{dir}/devtest{index}_0330a_16k.list", "w") as dst_file:
            for spkid in sorted(spkid2utt):
                sample_utt_list = random.sample(spkid2utt[spkid], 33)
                for utt in sorted(sample_utt_list):
                    dst_file.write(f"{prefix}/{spkid}_16k/{utt}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("aurora4_list_dir", default="/mnt/HDD/dataset/Aurora4/4A/lists", nargs="?",
                        help="where is Aurora4/4a/lists")
    args = parser.parse_args()

    main(args)
