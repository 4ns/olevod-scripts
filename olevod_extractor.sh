#!/bin/bash
#
# param1: starter url

next=$1
target=$2
root_url='https://www.olevod.com'
last_url=$root_url

extract_from() {
    TMPHTML=tmp.html
    TMPJSON=tmp.json

    curl "$url" -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'Accept-Language: ja-JP,ja;q=0.9,zh-CN;q=0.8,zh;q=0.7,en-US;q=0.6,en;q=0.5' -H 'Cache-Control: max-age=0'  -H 'Connection: keep-alive' -H 'DNT: 1' -H "Referer: $last_url" -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36' -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Google Chrome";v="114"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -c olevod.cookies -o $TMPHTML

    grep -oP 'player_aaaa=\K[^<]+' $TMPHTML > $TMPJSON

    m3u8=$(jq -r .url $TMPJSON)
    nid=$(jq -r .nid $TMPJSON)
    next=$(jq -r .link_next $TMPJSON)

    
    if [[ ! -z $m3u8 ]]; then
        echo "$nid|$m3u8|$next" | tee -a $target
    else
        echo "error"
        exit 1
    fi
}

ffmpeg_to() {
    ffmpeg -hide_banner -i "$1" -c copy $2
}

while [[ ! -z $next ]]; do
    last_url=$url
    if [[ $next == https:* ]]; then
        url="$next"
    else
        url="$root_url$next"
    fi

    extract_from

    #interval=$((RANDOM % 20 + 30))
    interval=$((RANDOM % 10 + 5))
    echo "sleep $interval";
    sleep $interval
done
