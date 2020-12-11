import os
import argparse


def stat_duration(data_dir):
    utt2dur_filename = f"{data_dir}/utt2dur"
    if os.path.exists(utt2dur_filename):
        duration = 0
        with open(utt2dur_filename, "r") as file:
            for line in file:
                uid, dur = line.strip().split(" ", 1)
                duration += float(dur)
        print("Duration (sec):", duration)
        print("Duration (hr):", duration/3600)


def stat_speaker(data_dir):
    spk2utt_filename = f"{data_dir}/spk2utt"
    if os.path.exists(spk2utt_filename):
        number = 0
        with open(spk2utt_filename, "r") as file:
            for line in file:
                number += 1
        print("Speaker number:", number)


def stat_utt(data_dir):
    wavscp_filename = f"{data_dir}/wav.scp"
    if os.path.exists(wavscp_filename):
        number = 0
        with open(wavscp_filename, "r") as file:
            for line in file:
                number += 1
        print("Utterance number:", number)


def stat_gender(data_dir):
    spk2gender_filename = f"{data_dir}/spk2gender"
    if os.path.exists(spk2gender_filename):
        male, female = 0, 0
        with open(spk2gender_filename, "r") as file:
            for line in file:
                spk, gender = line.strip().split(" ", 1)
                if gender == "m": male += 1
                elif gender == "f": female += 1
        print("Male number:", male)
        print("Female number:", female)


def main(data_dir):
    print(f"Stating {data_dir}...")
    stat_duration(data_dir)
    stat_speaker(data_dir)
    stat_utt(data_dir)
    stat_gender(data_dir)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("data_dir", default="data/train_si84_clean", nargs="?")
    args = parser.parse_args()

    main(args.data_dir)





