#!/bin/bash
#
# Param 1: start URL
# Param 2: playlist filename or output folder for downloading
# Param 3: download videos immediately
source ./funcs.sh

if [ -z "$1" ]; then
	echo -e "\033[0;31mNo start URL supplied.\033[0m" >&2
    echo "Usage: $0 URL playlist_or_folder [immediately_download]"
	exit 1
fi

next=$(olevod_check_url $1)
target=$2
download=$3
if [ -z "$3" ]; then
	# save to playlist
	target=${2:-playlist}

	if [ -e "$target" ] && [ ! -f "$target" ]; then
		echo -e "\033[0;31mError: $target exists and is not a file.\033[0m" >&2
		exit 1
	fi
else
	target=${2:-output}
	target=${target%/}
	if [ ! -e "$target" ]; then
		mkdir -p "$target"
	elif [ -e "$target" ] && [ ! -d "$target" ]; then
		echo -e "\033[0;31mError: $target exists and is not a folder.\033[0m" >&2
		exit 1
	fi
fi

root_url=$(get_url_root $next)
last_url=$root_url

extract_from() {
    TMPHTML=tmp.html
    TMPJSON=tmp.json
    local id
    local nid
    local m3u8

    if [[ $url == *"olevod.one"* ]]; then
        id=$(echo "$url" | grep -oP '(?<=vod/)[^/]+')
        nid=$(echo "$url" | grep -oP "(?<=/play/ep)[^/]+")
        local apiurl="https://www.olevod.one/_olevod_lazy/$id-ep$nid"

        curl --fail-with-body "$apiurl" -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Accept-Language: ja-JP,ja;q=0.9,zh-CN;q=0.8,zh;q=0.7,en-US;q=0.6,en;q=0.5' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Host: www.olevod.one' -H 'Referer: $last_url' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/' -H 'sec-ch-ua: "Chromium";v="114", "Google Chrome";v="114", ";Not A Brand";v="99"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -c olevod.cookies -o $TMPJSON

        if [ $? -ne 0 ]; then
            echo -e "\033[0;31mdata failed on ep: $nid.\033[0m" >&2
            exit 1
        fi

        m3u8=$(jq -r '.video_plays[] | select(.src_site | test("sd.*")) | .play_data' $TMPJSON)
        local nnid=$((nid + 1))
        next="https://www.olevod.one/vod/$id/play/ep$nnid"

    else
        curl "$url" -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'Accept-Language: ja-JP,ja;q=0.9,zh-CN;q=0.8,zh;q=0.7,en-US;q=0.6,en;q=0.5' -H 'Cache-Control: max-age=0'  -H 'Connection: keep-alive' -H 'DNT: 1' -H "Referer: $last_url" -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36' -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Google Chrome";v="114"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -c olevod.cookies -o $TMPHTML

        grep -oP 'player_aaaa=\K[^<]+' $TMPHTML > $TMPJSON

        m3u8=$(jq -r .url $TMPJSON)
        nid=$(jq -r .nid $TMPJSON)
        next=$(jq -r .link_next $TMPJSON)
    fi


    if [[ ! -z $m3u8 ]]; then
		if [ -z "$download" ]; then
			# save to playlist
        	echo "$nid|$m3u8|$next" | tee -a $target

		else
			# download video
			echo "download_to $m3u8 $target/$nid.mp4"
			download_to "$m3u8" "$target/$nid.mp4" 2
		fi
    else
	    echo -e "\033[0;31mError! m3u8 URL not found.\033[0m" >&2
        exit 1
    fi
}


while [[ ! -z $next ]]; do
    last_url=$url
    if [[ $next == https:* ]]; then
        url="$next"
    else
        url="$root_url$next"
    fi

    extract_from

    interval=$(( RANDOM % 10 + 10 ))
    echo "sleep $interval"
    sleep $interval
done
