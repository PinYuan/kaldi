timit_egs = "/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/timit/s5"

with open(f"{timit_egs}/data/train_sp_hires/feats.scp") as file_clean, \
        open(f"data/train_sp_hires/feats.target.scp", "w") as file_target:
    for line in file_clean:
        uid, feats_scp = line.strip().split(" ", 1)
        uid = uid.lower()
        file_target.write(f"{uid} {feats_scp}\n")