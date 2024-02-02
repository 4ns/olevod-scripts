
download_to() {
    if ! command -v yt-dlp &> /dev/null; then
        ffmpeg -hide_banner -loglevel info -i "$1" -c copy $2 < /dev/null;
    else
        yt-dlp -N 1 -o "$2" "$1"
    fi
}

