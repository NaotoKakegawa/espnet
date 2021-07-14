#!/bin/bash
# usage: bash this
# description: *.pmor -> nmt_input

set -eu

cd `dirname $0`

cat ../data/phn_eval/wav.scp | while read line; do
  pmor_file="../../"$(echo ${line} | \
            sed -e 's/.* //g' | \
            sed -e 's/.*FJS_/downloads\/FJS\/tmor\//g' | \
            sed -e 's/_/\//g' | \
            sed -e 's/wav$/pmor/g')
# 出力の一文字ごとにスペース挿入
  pmor2nmt_input/pmor2txt.sh ${pmor_file} | \
    awk -v FS='' '{
         for (i = 1; i <= NF; i++) {if(i == 1){printf $i}else{printf " "$i;}}print ""
     }'
done

