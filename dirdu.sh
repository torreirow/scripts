#!/bin/bash
checkDir=$1
if [[ -z ${checkDir} ]]; then  checkDir=.; fi
dirs=($(find . -maxdepth 1 -type d -not -name "."))
for dir in ${dirs[@]}; do
    if ! mountpoint -q ${dir}; then
        du -xsm ${dir}
    fi
done | sort -n
