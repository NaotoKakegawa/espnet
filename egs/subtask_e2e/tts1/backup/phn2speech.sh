#!/bin/bash

# Copyright 2018 Nagoya University (Tomoki Hayashi)
# [stage 6] 2019 Okayama University (Katsuki Inoue)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

# translate purpose
purpose=$1  # eval or joke
if [ $# -ne 1 ]; then↲
  echo "Error: argument num invalid"↲
  exit 1↲
fi↲
# general configuration
backend=pytorch
stage=0
stop_stage=0
ngpu=1       # number of gpus ("0" uses cpu, otherwise use gpu)
nj=1        # number of parallel jobs
#nj=32        # number of parallel jobs
dumpdir=dump # directory to dump full features
verbose=1    # verbose option (if set > 0, get more log)
N=0          # number of minibatches to be used (mainly for debugging). "0" uses all minibatches.
seed=1       # random seed number
resume=""    # the snapshot path to resume (if set empty, no effect)

# feature extraction related
fs=22050      # sampling frequency
fmax=7600     # maximum frequency
fmin=80       # minimum frequency
n_mels=80     # number of mel basis
n_fft=1024    # number of fft points
n_shift=256   # number of shift points
win_length="" # window length

# char or phn
# In the case of phn, input transcription is convered to phoneem using https://github.com/Kyubyong/g2p.
trans_type="phn"

# config files
train_config=conf/train_pytorch_tacotron2.yaml # you can select from conf or conf/tuning.
                                               # now we support tacotron2, transformer, and fastspeech
                                               # see more info in the header of each config.
decode_config=conf/decode.yaml

# knowledge distillation related
teacher_model_path=""
teacher_decode_config=conf/decode_for_knowledge_dist.yaml
do_filtering=false     # whether to do filtering using focus rate
focus_rate_thres=0.65  # for phn taco2 around 0.65, phn transformer around 0.9
                       # if you want to do filtering please carefully check this threshold

# decoding related
model=model.loss.best
n_average=1 # if > 0, the model averaged with n_average ckpts will be used instead of model.loss.best
griffin_lim_iters=64  # the number of iterations of Griffin-Lim

# objective evaluation related
asr_model="librispeech.transformer.ngpu4"
eval_tts_model=true                            # true: evaluate tts model, false: evaluate ground truth
wer=true                                       # true: evaluate CER & WER, false: evaluate only CER

# root directory of db
db_root=downloads

# exp tag
tag="" # tag for managing experiments.

. utils/parse_options.sh || exit 1;

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

train_set="${trans_type}_train_no_dev"
dev_set="${trans_type}_dev"
eval_set="${trans_type}_eval"
free_input_set="${trans_type}_free_input"
joke_input_set="${trans_type}_joke_input"
mkdir -p data/${free_input_set}
mkdir -p data/${joke_input_set}

feat_tr_dir=${dumpdir}/${train_set}; mkdir -p ${feat_tr_dir}
feat_dt_dir=${dumpdir}/${dev_set}; mkdir -p ${feat_dt_dir}
feat_ev_dir=${dumpdir}/${eval_set}; mkdir -p ${feat_ev_dir}
feat_free_input_dir=${dumpdir}/${free_input_set}; mkdir -p ${feat_free_input_dir}
feat_joke_input_dir=${dumpdir}/${joke_input_set}; mkdir -p ${feat_joke_input_dir}
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "stage 1: Text & utt2spk Prep"
    (
    cd mytool
# text
    if [ ${purpose} = "eval" ];then bash kana2phn.sh ../nmt_output/out_wo_tail_punctuation.txt FREE > ../data/${free_input_set}/text ;fi
    if [ ${purpose} = "joke" ];then bash kana2phn.sh ../nmt_output/joke/joke_nmt_out.txt JOKE > ../data/${joke_input_set}/text ;fi

# utt2spk
    if [ ${purpose} = "eval" ];then 
      echo -n "" > ../data/${free_input_set}/utt2spk
      cat ../data/${free_input_set}/text | while read line; do
        echo ${line} | sed -e 's/ .*/ LJ/g' >> ../data/${free_input_set}/utt2spk
      done
    fi

    if [ ${purpose} = "joke" ];then 
      echo -n "" > ../data/${joke_input_set}/utt2spk
      cat ../data/${joke_input_set}/text | while read line; do
        echo ${line} | sed -e 's/ .*/ LJ/g' >> ../data/${joke_input_set}/utt2spk
      done
    fi
    )

    echo "done."
fi

dict=data/lang_1${trans_type}/${train_set}_units.txt
echo "dictionary: ${dict}"
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    ### Task dependent. You have to check non-linguistic symbols used in the corpus.
    echo "stage 2: Json Data Preparation"

    # make json labels
    if [ ${purpose} = "eval" ];then 
    data2json.sh --trans_type ${trans_type} \
         data/${free_input_set} ${dict} > ${feat_free_input_dir}/data.json
    fi

    if [ ${purpose} = "joke" ];then 
    data2json.sh --trans_type ${trans_type} \
         data/${joke_input_set} ${dict} > ${feat_joke_input_dir}/data.json
    fi

    echo "done."
fi


if [ -z ${tag} ]; then
    expname=${train_set}_${backend}_$(basename ${train_config%.*})
else
    expname=${train_set}_${backend}_${tag}
fi
expdir=exp/${expname}
mkdir -p ${expdir}
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "stage 3: do nothing"
    echo "done."
fi

if [ ${n_average} -gt 0 ]; then
    model=model.last${n_average}.avg.best
fi
outdir=${expdir}/outputs_${model}_$(basename ${decode_config%.*})
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "stage 4: Decoding"
    if [ ${n_average} -gt 0 ]; then
        average_checkpoints.py --backend ${backend} \
                               --snapshots ${expdir}/results/snapshot.ep.* \
                               --out ${expdir}/results/${model} \
                               --num ${n_average}
    fi
    pids=() # initialize pids

    decode_set=""
    if [ ${purpose} = "eval" ];then ${decode_set}="free_input_set";fi
    if [ ${purpose} = "joke" ];then ${decode_set}="joke_input_set";fi

    for name in ${decode_set}; do
    (
        [ ! -e ${outdir}/${name} ] && mkdir -p ${outdir}/${name}
        cp ${dumpdir}/${name}/data.json ${outdir}/${name}
        splitjson.py --parts ${nj} ${outdir}/${name}/data.json
        # decode in parallel
        ${train_cmd} JOB=1:${nj} ${outdir}/${name}/log/decode.JOB.log \
            tts_decode.py \
                --backend ${backend} \
                --ngpu 0 \
                --verbose ${verbose} \
                --out ${outdir}/${name}/feats.JOB \
                --json ${outdir}/${name}/split${nj}utt/data.JOB.json \
                --model ${expdir}/results/${model} \
                --config ${decode_config}
        # concatenate scp files
        for n in $(seq ${nj}); do
            cat "${outdir}/${name}/feats.$n.scp" || exit 1;
        done > ${outdir}/${name}/feats.scp
    ) &
    pids+=($!) # store background pids
    done
    i=0; for pid in "${pids[@]}"; do wait ${pid} || ((i++)); done
    [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
fi

if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "stage 5: Synthesis"
    pids=() # initialize pids

    synth_set=""
    if [ ${purpose} = "eval" ];then ${decode_set}="free_input_set";fi
    if [ ${purpose} = "joke" ];then ${decode_set}="joke_input_set";fi

    for name in ${synth_set}; do
    (
        [ ! -e ${outdir}_denorm/${name} ] && mkdir -p ${outdir}_denorm/${name}
        apply-cmvn --norm-vars=true --reverse=true data/${train_set}/cmvn.ark \
            scp:${outdir}/${name}/feats.scp \
            ark,scp:${outdir}_denorm/${name}/feats.ark,${outdir}_denorm/${name}/feats.scp
        convert_fbank.sh --nj ${nj} --cmd "${train_cmd}" \
            --fs ${fs} \
            --fmax "${fmax}" \
            --fmin "${fmin}" \
            --n_fft ${n_fft} \
            --n_shift ${n_shift} \
            --win_length "${win_length}" \
            --n_mels ${n_mels} \
            --iters ${griffin_lim_iters} \
            ${outdir}_denorm/${name} \
            ${outdir}_denorm/${name}/log \
            ${outdir}_denorm/${name}/wav
    ) &
    pids+=($!) # store background pids
    done
    i=0; for pid in "${pids[@]}"; do wait ${pid} || ((i++)); done
    [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
fi



if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
    echo "stage 6: mel2wav"

    if [ ${purpose} = "eval" ];then bash mytool/mel2wav.sh phn_free_input;fi
    if [ ${purpose} = "joke" ];then bash mytool/mel2wav.sh phn_joke_input;fi

    echo "done."
fi


if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
    echo "stage 7: Objective Evaluation"
    pids=() # initialize pids
    for name in ${dev_set} ${eval_set}; do
    (
        local/ob_eval/evaluate_cer.sh --nj ${nj} \
            --do_delta false \
            --eval_tts_model ${eval_tts_model} \
            --db_root ${db_root}/LJSpeech-1.1 \
            --backend pytorch \
            --wer ${wer} \
            --api v2 \
            ${asr_model} \
            ${outdir} \
            ${name}
    ) &
    pids+=($!) # store background pids
    done
    i=0; for pid in "${pids[@]}"; do wait ${pid} || ((i++)); done
    [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
    echo "Finished."
fi
