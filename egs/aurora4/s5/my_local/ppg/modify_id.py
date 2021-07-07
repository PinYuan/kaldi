def modify_uid(kind):
    ppg_dir = f"exp/nnet3/ppg/train_si84_clean_sp_hires/{kind}"
    with open(f"{ppg_dir}/output.scp") as file_r, \
        open(f"{ppg_dir}/target.scp", "w") as file_w:
        for line in file_r:
            uid, path = line.strip().split(" ", 1)
            uid = uid[:-1] + "1"
            file_w.write(f"{uid} {path}\n")


def main():
    kind = "tdnnf4.noop"
    modify_uid(kind)


if __name__ == "__main__":
    main()