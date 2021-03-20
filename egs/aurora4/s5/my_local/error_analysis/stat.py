import re
import argparse
from collections import defaultdict


def stat(exp_dir, lm_type):
    counter = defaultdict(lambda: defaultdict(lambda: 0))
    
    for test_set in ["A", "B", "C", "D"]:
        decode_dir = f"{exp_dir}/decode_{lm_type}_{test_set}"    
        with open(f"{decode_dir}/scoring/wer_details/ops") as file:
            for line in file:
                ops, ref, hyp, count = re.sub(" +", " ", line.strip()).split()
                count = int(count)
                if ops == "substitution":
                    counter[ops][f"{ref}-{hyp}"] += count
                elif ops == "deletion":
                    counter[ops][ref] += count
                elif ops == "insertion":
                    counter[ops][hyp] += count
    return counter


def print_top_k(counter, k):
    for ops, word2count in counter.items():
        word2count = sorted(word2count.items(), key=lambda x: -x[1])
        tot = sum([count for word, count in word2count])
        print(f"[{ops}] - {tot}")
        for word, count in word2count[:k]:
            print(f"{count}: {word}")
        print("===============")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(epilog="python my_local/error_analysis/stat.py exp/chain/train_from_scratch/TDNN_1A/FSFAE3/DEFAULT/SPECAUG/tdnn_1a_feam_mtlae_fbank-mfcc-context_noise-stats/e50_fdae0.04_fdspae0.04_stats-900.1.1.900_il0.01_fl0.001 tgpr_5k")
    parser.add_argument("exp_dir", help="experiment directory")
    parser.add_argument("lm_type", default="tgpr_5k", nargs="?", help="language model type")
    parser.add_argument("--k", default=5, type=int, help="print top k")
    args = parser.parse_args()

    counter = stat(args.exp_dir, args.lm_type)
    print_top_k(counter, args.k)