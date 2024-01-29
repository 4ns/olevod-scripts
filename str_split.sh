#!/bin/bash

 urls=$1
 output=$2

 ffmpeg_to() {
     ffmpeg -hide_banner -loglevel info -i "$1" -c copy $2 < /dev/null;
 }

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
    ffmpeg_to "${videoarr[1]}" "$output/${videoarr[0]}.mp4"
done < "$urls"

