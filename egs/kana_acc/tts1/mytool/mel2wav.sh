#!/bin/bash

# cd to this script path
cd $(dirname $0)

# case 1と2があるけど，espnetを訓練したのはjsutではないのでcase2．
# Case 2: If you use different datasets for Text2Mel and Mel2Wav models
mkdir -p ../output/normFeats
mkdir -p ../output/wav
pretrain_model_tag="jsut_parallel_wavegan.v1"

parallel-wavegan-normalize \
    --skip-wav-copy \
    --config ../pretrained_model/${pretrain_model_tag}/config.yml \
    --stats ../pretrained_model/${pretrain_model_tag}/stats.h5 \
    --feats-scp ../exp/phn_train_no_dev_pytorch_train_pytorch_tacotron2/outputs_*_decode_denorm/phn_eval/feats.scp \
    --dumpdir ../output/normFeats

parallel-wavegan-decode \
    --checkpoint ../pretrained_model/${pretrain_model_tag}/checkpoint-400000steps.pkl \
    --dumpdir ../output/normFeats \
    --outdir ../output/wav
