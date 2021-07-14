#!/bin/bash
# usage: bash this [input_dir]

set -eu

input_dir=$1
if [ $# -ne 1 ]; then
  echo "Error: argument num invalid"
  exit 1
fi
#cd `dirname $0`

find ${input_dir} -follow -name "*.wav" | sort | while read -r filename;do
  echo $(soxi -D ${filename})","
done
