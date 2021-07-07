import re
import tqdm
import matplotlib.pyplot as plt
from kaldiio import ReadHelper, WriteHelper


def main():
    output_dir = "my_data/noise_vector/sad/view"

    
    for dset in ["train_si84_multi_sp", "test_A", "test_B", "test_C", "test_D"]:
        print(f"Processing {dset}...")
        
        suffix = re.sub("train_|test_", "", dset)
        decode_dir = f"exp/tri3b_multi/decode_tgpr_{suffix}"
        mfcc_dir = f"data/{dset}_hires"

        # confidence
        conf_list = []
        
        with open(f"{decode_dir}/score_10/{dset}.ctm") as ctm_reader:
            for line in ctm_reader:
                uid, channel, start, duration, word, conf = line.strip().split()
                conf_list += [float(conf)]
        
        plt.hist(conf_list, alpha=0.5)
        plt.savefig(f"{output_dir}/{dset}.conf.png")
        plt.clf()

        # weights
        # weights_list = []
        
        # with ReadHelper(f"ark: gunzip -c {decode_dir}/weights_1.0.gz |") as weights_reader:
        #     for uid, weights in tqdm.tqdm(weights_reader):
        #         weights_list += weights.tolist()

        # plt.hist(weights_list, alpha=0.5)
        # plt.savefig(f"{output_dir}/{dset}.weights.png")
        # plt.clf()


if __name__ == "__main__":
   main()