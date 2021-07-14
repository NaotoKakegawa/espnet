#!/bin/bash
# usage: bash this [plane_text]
# example: bash mytool/e2e_synth.sh ../plane_text/joke.txt

set -eu

plane_text=$1
if [ $# -ne 1 ]; then
  echo "Error: argument num invalid"
  exit 1
fi
cd `dirname $0`

# plane_text -> [NMT] -> kana + prosody
#(
#echo "NMT translating..."
#model=tf_1head5x5
#epoch=40
#
#mkdir -p translate/${model}/ep${epoch}
#python ~/tool/OpenNMT-py/translate.py \
#         -max_length 1700 \
#         -model ~/tool/OpenNMT-py/exp/${model}/${model}_model_step_50310.pt \
#         -src ${plane_text} \
#         -output ../nmt_output/joke/joke_nmt_out.txt \
#         -gpu 0
#
#echo "done."
#)

# synth
(
  cd ..
  bash phn2speech.sh joke
)
