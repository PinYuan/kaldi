import os
import re
import tqdm

train_dir = "data/train_worn_simu_u400k_cleaned_sp_hires"
dest_dir = "data/train_worn_simu_u400k_cleaned_dae_sp_hires"

os.makedirs(dest_dir, exist_ok=True)

# segments
uid2info = dict()
uid2rid = dict()
with open(f"{train_dir}/segments", "r") as file:
    for line in file:
        uid, rid, start, end = line.strip().split()
        uid2info[uid] = (start, end)
        uid2rid[uid] = rid

# wav.scp
rid2cmd = dict()
with open(f"{train_dir}/wav.scp", "r") as file:
    for line in file:
        rid, cmd = line.strip().split(" ", 1)
        rid2cmd[rid] = cmd
        
# utt2spk
utt2spk = dict()
with open(f"{train_dir}/utt2spk", "r") as file:
    for line in file:
        uid, fake_spkid = line.strip().split()
        real_spkid = re.search("P[0-9]{2}", fake_spkid).group()
        utt2spk[uid] = (real_spkid, fake_spkid)

# wav.scp (rid cmd)
#       rid採用原先的，但是cmd將reverb, noise等移除掉，僅保留速度與音量資訊，並且將音檔換成頭帶式麥克風
# segments (uid rid start end)
#       沒有變動
# utt2spk (uid spkid)
#       沒有變動

rid_set = set()
cmd_fmt = "sox /mnt/HDD/dataset/CHiME-6/audio/train/{0}.wav -t wav - remix {1} | sox -t wav - -t wav - speed {2} | sox --vol {3} -t wav - -t wav - |"

with open(f"{dest_dir}/wav.scp", "w") as wavscp_file, \
    open(f"{dest_dir}/segments", "w") as segments_file, \
    open(f"{dest_dir}/utt2spk", "w") as utt2spk_file:
    for uid in tqdm.tqdm(sorted(uid2rid.keys())):
        rid = uid2rid[uid]
        old_cmd = rid2cmd[rid]

        # worn wav
        sid = re.search("S[0-9]{2}", rid).group()
        spkid = utt2spk[uid][0]
        worn_wav = f"{sid}_{spkid}"

        # channel (default use L channel)
        channel = "2" if rid.split(".")[-1] == "R" else "1"

        # speed
        speed = rid.split("-")[0].replace("sp", "") if re.search("sp", rid) else 1

        # volume
        volume = re.search("--vol ([0-9\.]+)", old_cmd).group(1)

        cmd = cmd_fmt.format(worn_wav, channel, speed, volume)
        if rid not in rid_set:
            wavscp_file.write(f"{rid} {cmd}\n")
            rid_set.add(rid)

        start, end = uid2info[uid]
        segments_file.write(f"{uid} {rid} {start} {end}\n")

        utt2spk_file.write(f"{uid} {utt2spk[uid][1]}\n")
      