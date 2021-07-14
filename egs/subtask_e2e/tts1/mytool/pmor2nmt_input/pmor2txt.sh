#!/bin/bash
# usage: bash this [input]
# description: *.pmor -> text

set -eu

input=$1
if [ $# -ne 1 ]; then
  echo "Error: argument num invalid"
  exit 1
fi
cd `dirname $0`

python pmor2txt.py convert \
    --input=${input}
