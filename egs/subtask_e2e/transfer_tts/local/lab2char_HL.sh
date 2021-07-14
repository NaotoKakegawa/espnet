#!/bin/bash

# cd to this script path
cd $(dirname $0)

# make char and HL from lab
find_dir="../downloads"
find ${find_dir} -follow -name "*.lab" | sort | uniq | while read -r filename;do
    out_name=$(echo ${filename} | \
    sed -e "s/\.\.\/downloads\///g" | \
    sed -e "s/full\.time\///g" | \
    sed -e "s/\//_/g" | \
    sed -e "s/\.[^\.]*$//g")

    echo -n ${out_name}" "
    csh ../mytool/lab2binacc.qst.fb.4dur.sh ${filename}
    echo ""
done
