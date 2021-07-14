#!/bin/bash
# usage: bash this [input_path]

set -eu

input_path=$1
if [ $# -ne 1 ]; then
  echo "Error: argument num invalid"
  exit 1
fi
#cd `dirname $0`

cat ${input_path} | sort | while read -r filename;do
  echo $(soxi -D ${filename})","
done
