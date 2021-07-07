import re
import glob
import argparse
import numpy as np
from pathlib import Path
import matplotlib.pyplot as plt
from collections import defaultdict


egs_dir = "/mnt/HDD2/user_pinyuanc/mod-kaldi/kaldi-slam/egs/aurora4/s5"
pt_dir = "exp/chain/pretrain/TDNN_1A/FSFAE3/DEFAULT/feam_tdnn_mfcc-mfcc-context_fixed/e20_f0.04_il0.01_fl0.001_pl0"
ptjt_dir = "exp/chain/pretrain/TDNN_1A/FSFAE3/DEFAULT/feam_tdnn_mfcc-mfcc-context_fixed/e20_f0.04_il0.01_fl0.001_pl0.01"
jt_dir = "exp/chain/train_from_scratch/TDNN_1A/FSFAE3/DEFAULT/tdnn_1a_feam_tdnn_mfcc-mfcc-context/e20_f0.04_il0.01_fl0.001"

# taskinfo = {"pt": (pt_dir, "k-"), "ptjt": (ptjt_dir, "k--"), "jt": (jt_dir, "k:")}
taskinfo = {"jt": (jt_dir, "b"), "pt": (pt_dir, "r"), "ptjt": (ptjt_dir, "g")}
abbr2full = {"jt": "Joint training", "pt": "Pre-training", "ptjt": "Pre-training + Joint training"}


def get_obj(file_path):
    output, output_ae = 0, 0
    with open(file_path) as file:
        for line in file:
            if re.search("Overall average objective function for 'output'", line):
                match = re.search("is ([0-9\.\-]+) over", line)
                output = float(match.group(1))
            elif re.search("Overall average objective function for 'output_ae'", line):
                match = re.search("is ([0-9\.\-]+) over", line)
                output_ae = float(match.group(1))       
    return output, output_ae


def plot(loss):
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)
    fig.subplots_adjust(hspace=0.05)  # adjust space between axes

    # plot the same data on both axes
    for task in taskinfo:
        _loss = loss[task]
        ax1.plot(_loss, taskinfo[task][1], label=abbr2full[task])
        ax2.plot(_loss, taskinfo[task][1], label=abbr2full[task])

    # zoom-in / limit the view to different portions of the data
    ax1.set_ylim([-130, -100]) # most of the data
    ax2.set_ylim([-210, -190]) # outliers only

    # hide the spines between ax and ax2
    ax1.spines["bottom"].set_visible(False)
    ax2.spines["top"].set_visible(False)
    ax1.xaxis.tick_top()
    ax1.tick_params(labeltop=False)  # don't put tick labels at the top
    ax2.xaxis.tick_bottom()

    # set ticks
    ax1.set_yticks([i for i in range(-130, -100+10, 10)])
    ax2.set_yticks([i for i in range(-210, -190+5, 5)])

    ax2.set_xlabel("Iteration", fontsize=14)
    # ax2.set_ylabel("Objective function")
    fig.text(0.0, 0.5, "Objective function", va="center", rotation="vertical", fontsize=14)
    
    # cut-out slanted lines
    d = .5  # proportion of vertical to horizontal extent of the slanted line
    kwargs = dict(marker=[(-1, -d), (1, d)], markersize=12,
                  linestyle="none", color="k", mec="k", mew=1, clip_on=False)
    ax1.plot([0, 1], [0, 0], transform=ax1.transAxes, **kwargs)
    ax2.plot([0, 1], [1, 1], transform=ax2.transAxes, **kwargs)

    ax1.grid()
    ax2.grid()
    plt.legend()
    plt.tight_layout()

    plt.savefig("my_local/plot/effect-of-pt-jt.png")


def main(args):
    loss = dict()

    for task in taskinfo.keys():
        exp_dir = taskinfo[task][0]

        avg_output = defaultdict(lambda: [])
        avg_output_ae = defaultdict(lambda: [])

        for file_path in sorted(glob.glob(f"{egs_dir}/{exp_dir}/log/train.*.log")):
            file_stem = Path(file_path).stem
            _, iteration, job = file_stem.split(".")
            output, output_ae = get_obj(file_path)
            avg_output[int(iteration)] += [output]
            avg_output_ae[int(iteration)] += [output_ae]

        for iteration in sorted(avg_output.keys()):
            num_job = len(avg_output[iteration])
            avg_output[iteration] = sum(avg_output[iteration]) / num_job
            avg_output_ae[iteration] = sum(avg_output_ae[iteration]) / num_job
            if args.print:
                print(f"{iteration},{avg_output[iteration]:.7f},{avg_output_ae[iteration]:.3f}")
            
        avg_output_ae = sorted(list(avg_output_ae.items()), key=lambda x: x[0])
        avg_output_ae = np.array([obj for iteration, obj in avg_output_ae])
        loss[task] = avg_output_ae

    if args.plot:
        plot(loss)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--print", action="store_true")
    parser.add_argument("--plot", action="store_true")
    args = parser.parse_args()

    main(args)
