#!/usr/bin/env bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. ./path.sh

stage=0
train_set=multi # Set this to 'clean' or 'multi'
test_sets="dev test"
train=true   # set to false to disable the training-related scripts
             # note: you probably only want to set --train false if you
             # are using at least --stage 1.
decode=false  # set to false to disable the decoding-related scripts.

. utils/parse_options.sh

ntimit=/mnt/HDD/dataset/NTIMIT

if [ $stage -le 0 ]; then
  echo ============================================================================
  echo "                Data & Lexicon & Language Preparation                     "
  echo ============================================================================
  local/ntimit_data_prep.sh $ntimit

  local/ntimit_prepare_dict.sh
  utils/prepare_lang.sh --sil-prob 0.0 --position-dependent-phones false --num-sil-states 3 \
    data/local/dict "sil" data/local/lang_tmp data/lang

  local/ntimit_format_data.sh
fi

if [ $stage -le 1 ]; then
  echo ============================================================================
  echo "         MFCC Feature Extration & CMVN for Training and Test set          "
  echo ============================================================================
 
  mfccdir=mfcc

  for x in train dev test; do 
   steps/make_mfcc.sh --nj 20 data/$x exp/make_mfcc/$x $mfccdir || exit 1;
   steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
  done
fi

if [ $stage -le 2 ]; then
  echo ============================================================================
  echo "                     MonoPhone Training & Decoding                        "
  echo ============================================================================

  if $train; then
    steps/train_mono.sh --boost-silence 1.25 --nj 20 --cmd "$train_cmd" \
      data/train data/lang exp/mono || exit 1;
  fi

  if $decode; then
    utils/mkgraph.sh data/lang_test_bg exp/mono exp/mono/graph
    for testdir in $test_sets; do
      steps/decode.sh --nj 8 --cmd "$decode_cmd" \
        exp/mono/graph data/${testdir} exp/mono/decode_${testdir}
    done 
  fi
fi

if [ $stage -le 3 ]; then
  echo ============================================================================
  echo "           tri1 : Deltas + Delta-Deltas Training & Decoding               "
  echo ============================================================================
  
  if $train; then
    steps/align_si.sh --boost-silence 1.25 --nj 20 --cmd "$train_cmd" \
       data/train data/lang exp/mono exp/mono_ali || exit 1;
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;
  fi

  if $decode; then
    utils/mkgraph.sh data/lang_test_bg exp/tri1 exp/tri1/graph
    for testdir in $test_sets; do
      steps/decode.sh --nj 8 --cmd "$decode_cmd" \
        exp/tri1/graph data/${testdir} exp/tri1/decode_${testdir}
    done 
  fi
fi

if [ $stage -le 4 ]; then
  echo ============================================================================
  echo "                 tri2a : LDA + MLLT Training & Decoding                  "
  echo ============================================================================

  if $train; then 
    steps/align_si.sh --nj 20 --cmd "$train_cmd" \
      data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

    steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 \
      data/train data/lang exp/tri1_ali exp/tri2a || exit 1;

    steps/align_si.sh --nj 20 --cmd "$train_cmd" \
      data/train data/lang exp/tri2a exp/tri2a_ali || exit 1;
    
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
       --splice-opts "--left-context=3 --right-context=3" \
       2500 15000 data/train data/lang exp/tri2a_ali exp/tri2b || exit 1;
  fi
  
  if $decode; then
    for testdir in $test_sets; do
      utils/mkgraph.sh data/lang_test_bg exp/tri2b exp/tri2b/graph || exit 1;
      steps/decode.sh --nj 8 --cmd "$decode_cmd" \
        exp/tri2b/graph data/${testdir} exp/tri2b/decode_${testdir} || exit 1;
    done
  fi
fi

if [ $stage -le 5 ]; then
  echo ============================================================================
  echo "                 tri3 : LDA + MLLT + SAT Training & Decoding                  "
  echo ============================================================================
  if $train; then
    steps/align_si.sh --nj 20 --cmd "$train_cmd" --use-graphs true \
      data/train data/lang exp/tri2b exp/tri2b_ali  || exit 1;
    
    steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
      data/train data/lang exp/tri2b_ali exp/tri3 || exit 1;
  fi

  if $decode; then
    for testdir in $test_sets; do
      nspk=$(wc -l <data/${testdir}/spk2utt)
      utils/mkgraph.sh data/lang_test_bg exp/tri3 exp/tri3/graph || exit 1;
      steps/decode_fmllr.sh --nj $nspk --cmd "$decode_cmd" \
        exp/tri3/graph data/${testdir} exp/tri3/decode_${testdir} || exit 1;
    done
  fi
fi

exit 0;

# Chain training
if [ $stage -le 6 ]; then
  # Caution: this part needs a GPU.
  local/chain/run_tdnn.sh 
fi

exit 0;

