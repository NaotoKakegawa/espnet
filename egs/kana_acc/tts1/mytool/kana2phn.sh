#!/bin/bash
# usage: bash this [input]
# example: bash kana2phn.sh test_input.txt
# description: kana + accent -> phoneme + HL 

set -eu

input=$1
if [ $# -ne 1 ]; then
  echo "Error: argument num invalid"
  exit 1
fi
cd `dirname $0`

python kana2phn.py convert \
    --input=${input}
