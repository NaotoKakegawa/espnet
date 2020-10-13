#!/bin/bash

# cd to this script path
cd $(dirname $0)

# make wav from raw
find_dir="../downloads"
out_dir="../downloads/wavs"
mkdir -p ${out_dir}

find ${find_dir} -follow -name "*.raw" | sort | while read -r filename;do
    echo ${filename}
    out_name=$(echo ${filename} | \
    sed -e "s/\.\.\/downloads\///g" | \
    sed -e "s/raw22_SV56\.comp\///g" | \
    sed -e "s/\//_/g" | \
    sed -e "s/\.[^\.]*$//g")
    sox -r 22000 -b 16 -c 1 -e signed-integer ${filename} ${out_dir}"/"${out_name}".wav"
done
echo "finished making wav"
