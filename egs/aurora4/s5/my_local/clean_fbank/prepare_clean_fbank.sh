. ./cmd.sh
. ./path.sh

nnet3_affix=""

data_sets="train_si84_clean_sp"

for datadir in ${data_sets}; do
  utils/copy_data_dir.sh data/$datadir data/${datadir}_fbank
done

for datadir in ${data_sets}; do
  mkdir -p data/${datadir}_fbank/conf

  fbank_conf=data/${datadir}_fbank/conf/fbank_40.conf
  echo "--num-mel-bins=40" > $fbank_conf
 
  steps/make_fbank.sh --fbank-config "$fbank_conf" --nj 20 \
    --cmd "run.pl" data/${datadir}_fbank || exit 1;
  steps/compute_cmvn_stats.sh data/${datadir}_fbank || exit 1;
  
  utils/fix_data_dir.sh data/${datadir}_fbank

  cat data/${datadir}_fbank/feats.scp | sed "s/0 /1 /g" > data/${datadir}_fbank/feats.target.scp
done