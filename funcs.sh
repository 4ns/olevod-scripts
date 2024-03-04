
download_to() {
	local N=${3:-1}

    if ! command -v yt-dlp &> /dev/null; then
        ffmpeg -hide_banner -loglevel info -i "$1" -c copy $2 < /dev/null;
    else
        # yt-dlp -r 1M -N $N --retry-sleep 10 -o "$2" --use-postprocessor FFmpegCopyStream --ppa CopyStream:"-c:v libx264 -c:a aac -f mp4" "$1"
        yt-dlp -r 1M -N $N --retry-sleep 10 -o "$2" "$1"
    fi
}

get_url_root() {
    echo "$1" | grep -oP "https?://[.0-9a-z]+"
}

olevod_check_url() {
    local url="$1"
    local id
    local sid
    local nid
    if [[ $url == *"olevod.com"* ]]; then
        # https://www.olevod.com/index.php/vod/detail/id/11111.html
        # https://www.olevod.com/index.php/vod/play/id/11111/sid/1/nid/1.html
        id=$(echo "$url" | grep -oP '(?<=/id/)[^./]+')
        sid=$(echo "$url" | grep -oP '(?<=/sid/)[^./]+')
        nid=$(echo "$url" | grep -oP '(?<=/nid/)[^./]+')
        if [[ -z $sid ]]; then
            echo "https://www.olevod.com/index.php/vod/play/id/$id/sid/1/nid/1.html"
        else
            echo "$url"
        fi
    elif [[ $url == *"olevod.app"* ]]; then
        # https://www.olevod.app/playlist_list=/123ABC.html
        # https://www.olevod.app/watch_v=123ABC-1-1.html
        id=$(echo "$url" | grep -oP '(?<=/playlist_list=/)[^.]+')
        if [[ -z $id ]]; then
            echo "$url"
        else
            echo "https://www.olevod.app/watch_v=$id-1-1.html"
        fi
    elif [[ $url == *"olevod.one"* ]]; then
        # https://www.olevod.one/vod/201011111
        # https://www.olevod.one/vod/201011111/play/ep1
        # https://www.olevod.one/_olevod_lazy/201011111-ep1'
        id=$(echo "$url" | grep -oP '(?<=vod/)[^/]+')
        nid=$(echo "$url" | grep -oP "(?<=/play/ep)[^/]+")
        if [[ -z $nid ]]; then
            echo "https://www.olevod.one/vod/$id/play/ep1"
        else
            echo "$url"
        fi
    else
        echo -e "\033[0;31mInvalid URL.\033[0m" >&2
        exit 1
    fi
}
