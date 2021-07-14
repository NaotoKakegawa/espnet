#!/bin/bash

# Copyright 2019 Kyoto University (Hirofumi Inaguma)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

# general configuration
backend=pytorch # chainer or pytorch
stage=-1        # start from -1 if you need to start from data download
stop_stage=-1
ngpu=1          # number of gpus ("0" uses cpu, otherwise use gpu)
debugmode=1
dumpdir=dump    # directory to dump full features
N=0             # number of minibatches to be used (mainly for debugging). "0" uses all minibatches.
verbose=0       # verbose option
resume=         # Resume the training from snapshot
seed=1          # seed to generate random number

train_config=conf/train.yaml
decode_config=conf/decode.yaml

# decoding parameter
trans_model=model.acc.best # set a model to be used for decoding: 'model.acc.best' or 'model.loss.best'

# model average realted (only for transformer)
n_average=5                  # the number of NMT models to be averaged
use_valbest_average=true     # if true, the validation `n_average`-best NMT models will be averaged.
                             # if false, the last `n_average` NMT models will be averaged.

# preprocessing related
src_case=lc.rm
tgt_case=lc
# tc: truecase
# lc: lowercase
# lc.rm: lowercase with punctuation removal

# bpemode (unigram or bpe)
nbpe=106
bpemode=bpe
# NOTE: nbpe=88 means character-level NMT (lc.rm)
# NOTE: nbpe=106 means character-level NMT (lc)
# NOTE: nbpe=134 means character-level NMT (tc)

# Set this to somewhere where you want to put your data, or where
# someone else has already put it.  You'll want to change this
# if you're not on the CLSP grid.
st_ted=/export/b08/inaguma/IWSLT
# st_ted=/n/rd11/corpora_8/iwslt18

# exp tag
tag="" # tag for managing experiments.

. utils/parse_options.sh || exit 1;

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

train_set=train_nodevtest.de
train_set_prefix=train_nodevtest
train_dev=train_dev.de
trans_set="test.de dev2010.de tst2010.de tst2013.de tst2014.de tst2015.de"

if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    echo "stage -1: Data Download"
    for part in train dev2010 tst2010 tst2013 tst2014 tst2015; do
        local/download_and_untar.sh ${st_ted} ${part}
    done
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    ### Task dependent. You have to make data the following preparation part by yourself.
    ### But you can utilize Kaldi recipes in most cases
    echo "stage 0: Data Preparation"
    local/data_prep_train.sh ${st_ted}

    # data cleaning
    ### local/forced_align.sh ${st_ted} data/train
    cp -rf data/train data/train.tmp
    reduce_data_dir.sh data/train.tmp data/local/downloads/reclist data/train
    for lang in en de; do
        utils/filter_scp.pl data/train/utt2spk <data/train.tmp/text.tc.${lang} >data/train/text.tc.${lang}
        utils/filter_scp.pl data/train/utt2spk <data/train.tmp/text.lc.${lang} >data/train/text.lc.${lang}
        utils/filter_scp.pl data/train/utt2spk <data/train.tmp/text.lc.rm.${lang} >data/train/text.lc.rm.${lang}
    done
    rm -rf data/train.tmp

    for part in dev2010 tst2010 tst2013 tst2014 tst2015; do
        local/data_prep_eval.sh ${st_ted} ${part}
    done
fi

feat_tr_dir=${dumpdir}/${train_set}; mkdir -p ${feat_tr_dir}
feat_dt_dir=${dumpdir}/${train_dev}; mkdir -p ${feat_dt_dir}
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    ### Task dependent. You have to design training and dev sets by yourself.
    ### But you can utilize Kaldi recipes in most cases
    echo "stage 1: Feature Generation"

    # make a dev set
    utils/subset_data_dir.sh --speakers data/train 2000 data/dev
    utils/subset_data_dir.sh --spk-list <(utils/filter_scp.pl --exclude data/dev/spk2utt data/train/spk2utt) data/train data/train_nodev
    for lang in en de; do
        utils/filter_scp.pl data/train_nodev/utt2spk <data/train/text.tc.${lang} >data/train_nodev/text.tc.${lang}
        utils/filter_scp.pl data/train_nodev/utt2spk <data/train/text.lc.${lang} >data/train_nodev/text.lc.${lang}
        utils/filter_scp.pl data/train_nodev/utt2spk <data/train/text.lc.rm.${lang} >data/train_nodev/text.lc.rm.${lang}
        utils/filter_scp.pl data/dev/utt2spk <data/train/text.tc.${lang} >data/dev/text.tc.${lang}
        utils/filter_scp.pl data/dev/utt2spk <data/train/text.lc.${lang} >data/dev/text.lc.${lang}
        utils/filter_scp.pl data/dev/utt2spk <data/train/text.lc.rm.${lang} >data/dev/text.lc.rm.${lang}
    done

    # make a speaker-disjoint test set
    utils/subset_data_dir.sh --speakers data/train_nodev 2000 data/test
    utils/subset_data_dir.sh --spk-list <(utils/filter_scp.pl --exclude data/test/spk2utt data/train_nodev/spk2utt) data/train_nodev data/train_nodevtest
    for lang in en de; do
        utils/filter_scp.pl data/train_nodevtest/utt2spk <data/train_nodev/text.tc.${lang} >data/train_nodevtest/text.tc.${lang}
        utils/filter_scp.pl data/train_nodevtest/utt2spk <data/train_nodev/text.lc.${lang} >data/train_nodevtest/text.lc.${lang}
        utils/filter_scp.pl data/train_nodevtest/utt2spk <data/train_nodev/text.lc.rm.${lang} >data/train_nodevtest/text.lc.rm.${lang}
        utils/filter_scp.pl data/test/utt2spk <data/train_nodev/text.tc.${lang} >data/test/text.tc.${lang}
        utils/filter_scp.pl data/test/utt2spk <data/train_nodev/text.lc.${lang} >data/test/text.lc.${lang}
        utils/filter_scp.pl data/test/utt2spk <data/train_nodev/text.lc.rm.${lang} >data/test/text.lc.rm.${lang}
    done

    # Divide into source and target languages
    for x in ${train_set_prefix} dev test dev2010 tst2010 tst2013 tst2014 tst2015; do
        local/divide_lang.sh ${x}
    done

    cp -rf data/dev.en data/train_dev.en
    cp -rf data/dev.de data/train_dev.de

    for x in ${train_set_prefix} train_dev; do
        # remove utt having more than 3000 frames
        # remove utt having more than 400 characters
        for lang in en de; do
            remove_longshortdata.sh --no_feat true --maxchars 400 data/${x}.${lang} data/${x}.${lang}.tmp
        done

        # Match the number of utterances between source and target languages
        # extract commocn lines
        cut -f 1 -d " " data/${x}.en.tmp/text > data/${x}.de.tmp/reclist1
        cut -f 1 -d " " data/${x}.de.tmp/text > data/${x}.de.tmp/reclist2
        comm -12 data/${x}.de.tmp/reclist1 data/${x}.de.tmp/reclist2 > data/${x}.de.tmp/reclist

        for lang in en de; do
            reduce_data_dir.sh data/${x}.${lang}.tmp data/${x}.de.tmp/reclist data/${x}.${lang}
            utils/fix_data_dir.sh --utt_extra_files "text.tc text.lc text.lc.rm" data/${x}.${lang}
        done
        rm -rf data/${x}.*.tmp
    done
fi

dict=data/lang_1spm/${train_set}_${bpemode}${nbpe}_units_${tgt_case}.txt
nlsyms=data/lang_1spm/non_lang_syms_${tgt_case}.txt
bpemodel=data/lang_1spm/${train_set}_${bpemode}${nbpe}_${tgt_case}
echo "dictionary: ${dict}"
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    ### Task dependent. You have to check non-linguistic symbols used in the corpus.
    echo "stage 2: Dictionary and Json Data Preparation"
    mkdir -p data/lang_1spm/

    echo "make a non-linguistic symbol list for all languages"
    cut -f 2- -d' ' data/${train_set_prefix}.*/text.${tgt_case} | grep -o -P '&[^;]*;'| sort | uniq > ${nlsyms}
    cat ${nlsyms}

    echo "make a joint source and target dictionary"
    echo "<unk> 1" > ${dict} # <unk> must be 1, 0 will be used for "blank" in CTC
    offset=$(wc -l < ${dict})
    cut -f 2- -d " " data/${train_set_prefix}.*/text.${tgt_case} | grep -v -e '^\s*$' > data/lang_1spm/input.txt
    spm_train --user_defined_symbols="$(tr "\n" "," < ${nlsyms})" --input=data/lang_1spm/input.txt --vocab_size=${nbpe} --model_type=${bpemode} --model_prefix=${bpemodel} --input_sentence_size=100000000 --character_coverage=1.0
    spm_encode --model=${bpemodel}.model --output_format=piece < data/lang_1spm/input.txt | tr ' ' '\n' | sort | uniq | awk -v offset=${offset} '{print $0 " " NR+offset}' >> ${dict}
    wc -l ${dict}

    echo "make json files"
    local/data2json.sh --nj 16 --text data/${train_set}/text.${tgt_case} --bpecode ${bpemodel}.model \
        data/${train_set} ${dict} > ${feat_tr_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json
    local/data2json.sh --text data/${train_dev}/text.${tgt_case} --bpecode ${bpemodel}.model \
        data/${train_dev} ${dict} > ${feat_dt_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json
    for ttask in ${trans_set}; do
        feat_trans_dir=${dumpdir}/${ttask}; mkdir -p ${feat_trans_dir}
        if [ ${ttask} = "dev.de" ] || [ ${ttask} = "test.de" ]; then
            local/data2json.sh --text data/${ttask}/text.${tgt_case} --bpecode ${bpemodel}.model \
                data/${ttask} ${dict} > ${feat_trans_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json
        else
            local/data2json.sh --text data/${ttask}/text_noseg.${tgt_case} --bpecode ${bpemodel}.model --skip_utt2spk true \
                data/${ttask} ${dict} > ${feat_trans_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json
        fi
    done

    # update json (add source references)
    local/update_json.sh --text data/"$(echo ${train_set} | cut -f 1 -d ".")".en/text.${src_case} --bpecode ${bpemodel}.model \
        ${feat_tr_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json data/"$(echo ${train_set} | cut -f 1 -d ".")".en ${dict}
    local/update_json.sh --text data/"$(echo ${train_dev} | cut -f 1 -d ".")".en/text.${src_case} --bpecode ${bpemodel}.model \
        ${feat_dt_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json data/"$(echo ${train_dev} | cut -f 1 -d ".")".en ${dict}
    for ttask in ${trans_set}; do
        feat_dir=${dumpdir}/${ttask}
        data_dir=data/"$(echo ${ttask} | cut -f 1 -d ".")".en
        if [ ${ttask} = "dev.de" ] || [ ${ttask} = "test.de" ]; then
            local/update_json.sh --text ${data_dir}/text.${src_case} --bpecode ${bpemodel}.model --set ${ttask} \
                ${feat_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json ${data_dir} ${dict}
        else
            local/update_json.sh --text ${data_dir}/text_noseg.${src_case} --bpecode ${bpemodel}.model --set ${ttask} \
                ${feat_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json ${data_dir} ${dict}
        fi
    done
fi

# NOTE: skip stage 3: LM Preparation

if [ -z ${tag} ]; then
    expname=${train_set}_${src_case}_${tgt_case}_${backend}_$(basename ${train_config%.*})_${bpemode}${nbpe}
else
    expname=${train_set}_${src_case}_${tgt_case}_${backend}_${tag}
fi
expdir=exp/${expname}
mkdir -p ${expdir}

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "stage 4: Network Training"

    ${cuda_cmd} --gpu ${ngpu} ${expdir}/train.log \
        mt_train.py \
        --config ${train_config} \
        --ngpu ${ngpu} \
        --backend ${backend} \
        --outdir ${expdir}/results \
        --tensorboard-dir tensorboard/${expname} \
        --debugmode ${debugmode} \
        --dict ${dict} \
        --debugdir ${expdir} \
        --minibatches ${N} \
        --seed ${seed} \
        --verbose ${verbose} \
        --resume ${resume} \
        --train-json ${feat_tr_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json \
        --valid-json ${feat_dt_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json
fi

if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "stage 5: Decoding"
    if [[ $(get_yaml.py ${train_config} model-module) = *transformer* ]]; then
        # Average NMT models
        if ${use_valbest_average}; then
            trans_model=model.val${n_average}.avg.best
            opt="--log ${expdir}/results/log"
        else
            trans_model=model.last${n_average}.avg.best
            opt="--log"
        fi
        average_checkpoints.py \
            ${opt} \
            --backend ${backend} \
            --snapshots ${expdir}/results/snapshot.ep.* \
            --out ${expdir}/results/${trans_model} \
            --num ${n_average}
    fi
    nj=16

    pids=() # initialize pids
    for ttask in ${trans_set}; do
    (
        decode_dir=decode_${ttask}_$(basename ${decode_config%.*})
        feat_trans_dir=${dumpdir}/${ttask}

        # split data
        splitjson.py --parts ${nj} ${feat_trans_dir}/data_${bpemode}${nbpe}.${src_case}_${tgt_case}.json

        #### use CPU for decoding
        ngpu=0

        ${decode_cmd} JOB=1:${nj} ${expdir}/${decode_dir}/log/decode.JOB.log \
            mt_trans.py \
            --config ${decode_config} \
            --ngpu ${ngpu} \
            --backend ${backend} \
            --batchsize 0 \
            --trans-json ${feat_trans_dir}/split${nj}utt/data_${bpemode}${nbpe}.JOB.json \
            --result-label ${expdir}/${decode_dir}/data.JOB.json \
            --model ${expdir}/results/${trans_model}

        score_bleu.sh --case ${tgt_case} --bpe ${nbpe} --bpemodel ${bpemodel}.model \
            ${expdir}/${decode_dir} de ${dict}

    ) &
    pids+=($!) # store background pids
    done
    i=0; for pid in "${pids[@]}"; do wait ${pid} || ((++i)); done
    [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
    echo "Finished"
fi
