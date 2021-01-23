import os
import pathlib
import argparse
import subprocess
import numpy as np
from pathlib import Path
from shutil import copyfile
from kaldiio import ReadHelper, WriteHelper


def dump_mfcc(uid2mfcc, output_path):
    os.makedirs(Path(output_path).parent, exist_ok=True)
    with WriteHelper(f"ark,scp:{output_path}.ark,{output_path}.scp") as writer:
        for uid in sorted(uid2mfcc.keys()):
            writer(uid, uid2mfcc[uid])


def cp_basic_files(src_dir, dest_dir):
    files = ["wav.scp", "utt2spk", "spk2utt", "utt2num_frames", "utt2dur", "text", "spk2gender", "frame_shift"]
    for file in files:
        copyfile(f"{src_dir}/{file}", f"{dest_dir}/{file}")


def prepare_clean_noisy(output_dir):
    clean_mfcc = dict() # test data would use

    for data_set in ["train_si84_multi_sp_hires",
                     "test_A_hires", "test_B_hires", "test_C_hires", "test_D_hires"]:
        clean_noisy_mfcc = dict()

        print(f"Processing {data_set}...")
        if data_set.startswith("train"):
            multi_set = data_set
            clean_set = data_set.replace("multi", "clean")
            with ReadHelper(f"scp:data/{multi_set}/feats.scp") as reader_noisy, \
                    ReadHelper(f"scp:data/{clean_set}/feats.scp") as reader_clean:
                    for (key_noisy, array_noisy), (key_clean, array_clean) in zip(reader_noisy, reader_clean):
                        clean_noisy_mfcc[key_noisy] = np.concatenate((array_clean, array_noisy), axis=1) # [#, 40]
        else:
            with ReadHelper(f"scp:data/{data_set}/feats.scp") as reader:
                for key, array in reader:
                    if key.endswith("0"):
                        clean_mfcc[key] = array
                        clean_noisy_mfcc[key] = np.concatenate((array, array), axis=1)
                    else:
                        clean_key = key[:-1] + "0"
                        clean_noisy_mfcc[key] = np.concatenate((clean_mfcc[clean_key], array), axis=1)
        
        print("Dumping to files...") 
        dump_mfcc(clean_noisy_mfcc, f"{output_dir}/{data_set}/mfcc/raw_mfcc")
        copyfile(f"{output_dir}/{data_set}/mfcc/raw_mfcc.scp", f"{output_dir}/{data_set}/feats.scp")
        cp_basic_files(f"data/{data_set}", f"{output_dir}/{data_set}")


def prepare_denoised_noisy(mdl, iter, denoised_dir, output_dir):
    for data_set in ["train_si84_multi_sp_hires",
                     "test_A_hires", "test_B_hires", "test_C_hires", "test_D_hires"]:
        if "train" in data_set: nj = 20
        else: nj = 8
    
        print(f"Computing [{data_set}] denoised MFCC...")
        p = subprocess.Popen(f"./my_local/custom_feats/compute_denoised.sh --mdl {mdl} --iter {iter} --nj {nj} " + \
                            f"--data-set {data_set} --output-dir {denoised_dir}/{data_set}", shell=True)
        p.communicate()
      
        print(f"Concatenating [{data_set}] features...")
        denoised_noisy_mfcc = dict()
        with ReadHelper(f"scp:{denoised_dir}/{data_set}/output.scp") as reader_denoised, \
             ReadHelper(f"scp:data/{data_set}/feats.scp") as reader_noisy:
            for (key_denoised, array_denoised), (key_noisy, array_noisy) in zip(reader_denoised, reader_noisy):
                denoised_noisy_mfcc[key_denoised] = np.concatenate((array_denoised, array_noisy), axis=1)
            
        print(f"Dumping [{data_set}] features...")
        dump_mfcc(denoised_noisy_mfcc, f"{output_dir}/{data_set}/mfcc/raw_mfcc")
        copyfile(f"{output_dir}/{data_set}/mfcc/raw_mfcc.scp", f"{output_dir}/{data_set}/feats.scp")

        cp_basic_files(f"data/{data_set}", f"{output_dir}/{data_set}")


def prepare_noise_noisy(output_dir):
    for data_set in ["train_si84_multi_sp_hires",
                     "test_A_hires", "test_B_hires", "test_C_hires", "test_D_hires"]:
        noise_noisy_mfcc = dict()

        print(f"Processing {data_set}...")

        multi_set = data_set
        if data_set.startswith("train"):
            noise_set = "train_si84_noise_mismatch_sp_hires"
        else:
            noise_set = data_set.replace("_hires", "_noise_mismatch_hires")
        
        with ReadHelper(f"scp:data/{noise_set}/feats.scp") as reader_noise, \
                ReadHelper(f"scp:data/{multi_set}/feats.scp") as reader_noisy:
                for (key_noise, array_noise), (key_noisy, array_noisy) in zip(reader_noise, reader_noisy):
                    noise_noisy_mfcc[key_noisy] = np.concatenate((array_noise, array_noisy), axis=1) # [#, 40]
        
        print("Dumping to files...") 
        dump_mfcc(noise_noisy_mfcc, f"{output_dir}/{data_set}/mfcc/raw_mfcc")
        copyfile(f"{output_dir}/{data_set}/mfcc/raw_mfcc.scp", f"{output_dir}/{data_set}/feats.scp")
        cp_basic_files(f"data/{data_set}", f"{output_dir}/{data_set}")


def prepare_clean_noise_noisy(output_dir):
    clean_mfcc = dict() # test data would use

    for data_set in ["train_si84_multi_sp_hires",
                     "test_A_hires", "test_B_hires", "test_C_hires", "test_D_hires"]:
        clean_noise_noisy_mfcc = dict()

        print(f"Processing {data_set}...")

        multi_set = data_set
        if data_set.startswith("train"):
            clean_set = data_set.replace("multi", "clean")
            noise_set = "train_si84_noise_mismatch_sp_hires"

            with ReadHelper(f"scp:data/{clean_set}/feats.scp") as reader_clean, \
                    ReadHelper(f"scp:data/{noise_set}/feats.scp") as reader_noise, \
                    ReadHelper(f"scp:data/{multi_set}/feats.scp") as reader_noisy:
                for (key_clean, array_clean), (key_noise, array_noise), (key_noisy, array_noisy) in zip(reader_clean, reader_noise, reader_noisy):
                    clean_noise_noisy_mfcc[key_noisy] = np.concatenate((array_clean, array_noise, array_noisy), axis=1) # [#, 40]
    
        else:
            noise_set = data_set.replace("_hires", "_noise_mismatch_hires")
        
            with ReadHelper(f"scp:data/{noise_set}/feats.scp") as reader_noise, \
                    ReadHelper(f"scp:data/{multi_set}/feats.scp") as reader_noisy:
                    for (key_noise, array_noise), (key_noisy, array_noisy) in zip(reader_noise, reader_noisy):
                        if key_noisy.endswith("0"):
                            clean_mfcc[key_noisy] = array_noisy
                            array_clean = array_noisy
                        else:
                            clean_key = key_noisy[:-1] + "0"
                            array_clean = clean_mfcc[clean_key]
                        clean_noise_noisy_mfcc[key_noisy] = np.concatenate((array_clean, array_noise, array_noisy), axis=1) # [#, 40]
  
        print("Dumping to files...") 
        dump_mfcc(clean_noise_noisy_mfcc, f"{output_dir}/{data_set}/mfcc/raw_mfcc")
        copyfile(f"{output_dir}/{data_set}/mfcc/raw_mfcc.scp", f"{output_dir}/{data_set}/feats.scp")
        cp_basic_files(f"data/{data_set}", f"{output_dir}/{data_set}")


def main(args, output_dir):
    if args.kind == "clean_noisy":
        prepare_clean_noisy(output_dir)
    elif args.kind == "denoised_noisy":
        assert args.denoised_mdl
        prepare_denoised_noisy(args.denoised_mdl, args.denoised_mdl_iter, args.denoised_dir, output_dir)
    elif args.kind == "noise_noisy":
        prepare_noise_noisy(output_dir)
    elif args.kind == "clean_noise_noisy":
        prepare_clean_noise_noisy(output_dir)
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("kind",
                        help="'clean_noisy' is 40-D clean and 40-D noisy MFCC; "\
                             "'denoised_noisy' is 40-D denoised and 40-D noisy MFCC; "\
                             "'noise_noisy' is 40-D noise and 40-D noisy MFCC; "\
                             "'clean_noise_noisy' is 40-D clean, 40-D noise abd 40-D noisy")
    parser.add_argument("output_dir", default="my_data", type=Path, nargs="?")

    # MDL: /mnt/HDD2/user_pinyuanc/kaldi/egs/aurora4/s5/exp/nnet3/denoising_autoencoder/baseline/e10_il0.001_fl0.0001
    parser.add_argument("--denoised-mdl", type=Path)
    parser.add_argument("--denoised-mdl-iter", default="final", type=str)
    parser.add_argument("--denoised-dir", default="my_data/denoised", type=Path, nargs="?")

    args = parser.parse_args()

    cwd = pathlib.Path().absolute()
    output_dir = f"{cwd}/{args.output_dir}/{args.kind}"

    main(args, output_dir)