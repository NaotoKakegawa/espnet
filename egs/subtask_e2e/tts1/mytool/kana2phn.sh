#!/bin/bash
# usage: bash this [input] [prefix]
# example: bash kana2phn.sh test_input.txt FREE
# description: kana + accent -> phoneme + HL 

set -eu

input=$1
prefix=$2
if [ $# -ne 2 ]; then
  echo "Error: argument num invalid"
  exit 1
fi
cd `dirname $0`

python kana2phn.py make_esp_input \
    --input=${input} \
    --prefix=${prefix}
