#!/bin/bash
# usage: bash this [target]
# example: bash mel2wav.sh phn_joke_input

set -eu

target=$1
if [ $# -ne 1 ]; then
  echo "Error: argument num invalid"
  exit 1
fi


# 毎回これをやっとく
#source /home/abelab/n_kake/tool/re_espnet/tools/venv/bin/activate


# cd to this script parent path
cd $(dirname $0)
cd ..

# case 1と2があるけど，espnetを訓練したのはjsutではないのでcase2．
# Case 2: If you use different datasets for Text2Mel and Mel2Wav models
mkdir -p vocoder_output/${target}/normFeats
mkdir -p vocoder_output/${target}/wav
pretrain_model_tag="jsut_parallel_wavegan.v1"

. ./path.sh

parallel-wavegan-normalize \
    --skip-wav-copy \
    --config pretrained_model/${pretrain_model_tag}/config.yml \
    --stats pretrained_model/${pretrain_model_tag}/stats.h5 \
    --feats-scp exp/phn_train_no_dev_pytorch_train_pytorch_tacotron2/outputs_*_decode_denorm/${target}/feats.scp \
    --dumpdir vocoder_output/${target}/normFeats

parallel-wavegan-decode \
    --checkpoint pretrained_model/${pretrain_model_tag}/checkpoint-400000steps.pkl \
    --dumpdir vocoder_output/${target}/normFeats \
    --outdir vocoder_output/${target}/wav
