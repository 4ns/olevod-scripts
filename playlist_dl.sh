#!/bin/bash
source ./funcs.sh

if [ -z "$1" ]; then
    echo -e "\033[0;31mNo playlist supplied.\033[0m" >&2
    echo "Usage: $0 playlist [output dir]" >&2
    exit 1
fi

urls=$1
output=${2:-output}
output=${output%/}

#  while IFS='|' read -r nid m3u8 next
#  do
#     echo "$nid"
#     echo "$m3u8"
#     echo "$next"
#     #  ffmpeg_to "$m3u8" $output/$nid.mp4
#  done <$urls

while IFS= read -r line; do
    IFS="|" read -a videoarr <<< $line
    # echo "${videoarr[@]}"
    echo "${videoarr[0]} ${videoarr[1]}"
    download_to "${videoarr[1]}" "$output/${videoarr[0]}.mp4"
done < "$urls"

