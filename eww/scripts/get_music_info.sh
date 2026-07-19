#!/bin/zsh
 
# ------------------------------------
# Universal MPRIS Music Script
#
# Support:
# ncspot
# Firefox Youtube
# Any MPRIS media player
# -------------------------------------
 
# 沒有封面時使用的本地預設圖，請自行換成你想要的路徑
FALLBACK_COVER="$HOME/.config/eww/images/no-cover.png"
 
# GTK CSS 的 background-image: url() 只吃得懂本地檔案路徑，
# 不支援直接抓 http(s) 遠端圖片，所以遠端封面都要先下載到這裡
COVER_CACHE_DIR="$HOME/.cache/eww-music"
COVER_CACHE_FILE="$COVER_CACHE_DIR/cover.jpg"
COVER_URL_CACHE="$COVER_CACHE_DIR/cover_url.txt"
mkdir -p "$COVER_CACHE_DIR"
 
# -------Find active media player --------------
get_player() {
    # Find "Playing" media first
    for player in $(playerctl -l 2>/dev/null); do
        STATUS=$(playerctl -p "$player" status 2>/dev/null)
 
        if [ "$STATUS" = "Playing" ]; then
            echo "$player"
            return
        fi
    done
 
    # If no playing, find Paused
    for player in $(playerctl -l 2>/dev/null); do
        STATUS=$(playerctl -p "$player" status 2>/dev/null)
 
        if [ "$STATUS" = "Paused" ]; then
            echo "$player"
            return
        fi
    done
}
PLAYER=$(get_player)
 
   # No playing
if [ -z "$PLAYER" ]; then
    case "$1" in
        --status)
            echo "Stopped"
            ;;
        --cover)
            # 沒播放時，如果 eww 仍要顯示東西，給 fallback 圖也比空字串安全
            echo "$FALLBACK_COVER"
            ;;
        --position)
            # progress widget 的 :value 一定要吃到數字，
            # 空字串會直接讓 eww 拋出 parse error 崩潰，這裡一定要給 "0"
            echo "0"
            ;;
        --length-s)
            echo "0"
            ;;
        --position-s)
            echo "0"
            ;;
        --formatted-position)
            echo "0:00"
            ;;
        --np)
            echo "No Music Playing"
            ;;
        --title|--song|--artist|--album|--player)
            # 這些欄位給空字串沒關係，label 顯示空白不會出錯
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
    exit 0
fi
 
# ----------Basic info for media ----------------
 
get_status(){
    playerctl \
    -p "$PLAYER" \
    status 2>/dev/null
}
 
get_title(){
    playerctl \
    -p "$PLAYER" \
    metadata xesam:title 2>/dev/null
}
 
get_artist(){
    playerctl \
    -p "$PLAYER" \
    metadata xesam:artist 2>/dev/null
}
 
get_album(){
    playerctl \
    -p "$PLAYER" \
    metadata xesam:album 2>/dev/null
}
 
# ----------封面：Firefox 沒有 artUrl，改抓 YouTube 縮圖；遠端圖片一律下載成本地檔案 -------
get_cover(){
    local art_url remote_url track_url video_id cached_url
 
    art_url=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null)
 
    if [ -n "$art_url" ]; then
        remote_url="$art_url"
    else
        # 沒有 artUrl，嘗試從 xesam:url 判斷是否為 YouTube，抓出 video id
        track_url=$(playerctl -p "$PLAYER" metadata xesam:url 2>/dev/null)
 
        if [[ "$track_url" == *"youtube.com/watch"* || "$track_url" == *"youtu.be/"* ]]; then
            # 支援兩種格式：
            # https://www.youtube.com/watch?v=VIDEO_ID
            # https://youtu.be/VIDEO_ID
            if [[ "$track_url" == *"v="* ]]; then
                video_id=$(echo "$track_url" | sed -E 's/.*[?&]v=([A-Za-z0-9_-]{11}).*/\1/')
            else
                video_id=$(echo "$track_url" | sed -E 's#.*youtu\.be/([A-Za-z0-9_-]{11}).*#\1#')
            fi
 
            if [[ -n "$video_id" && ${#video_id} -eq 11 ]]; then
                remote_url="https://img.youtube.com/vi/${video_id}/hqdefault.jpg"
            fi
        fi
    fi
 
    # 完全抓不到任何封面來源，直接回傳本地 fallback 圖
    if [ -z "$remote_url" ]; then
        echo "$FALLBACK_COVER"
        return
    fi
 
    # 如果已經是本地檔案路徑（例如某些播放器直接給 file:// 的 artUrl），
    # GTK 可以直接吃，不用下載
    if [[ "$remote_url" == file://* ]]; then
        echo "${remote_url#file://}"
        return
    fi
 
    # 比對快取，封面沒換就不用重新下載，省流量也避免每 5 秒打一次網路請求
    cached_url=""
    [ -f "$COVER_URL_CACHE" ] && cached_url=$(cat "$COVER_URL_CACHE")
 
    if [[ "$remote_url" != "$cached_url" || ! -s "$COVER_CACHE_FILE" ]]; then
        if curl -sL --max-time 3 "$remote_url" -o "$COVER_CACHE_FILE.tmp" 2>/dev/null; then
            mv "$COVER_CACHE_FILE.tmp" "$COVER_CACHE_FILE"
            echo "$remote_url" > "$COVER_URL_CACHE"
        else
            rm -f "$COVER_CACHE_FILE.tmp"
            echo "$FALLBACK_COVER"
            return
        fi
    fi
 
    echo "$COVER_CACHE_FILE"
}

# ----------給 progress-bar 用：秒數制長度/位置，交給 eww 自己算百分比 -------
# (原本 --position 回傳的是「已經算好的百分比」，
#  這幾個是給你新排版那種 :max song_length_s :value song_position_s 的用法)
get_length_seconds(){
    local length
    length=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null)
    if [ -z "$length" ]; then
        echo "1"   # 避免 scale 的 :max 變成 0 或空字串
        return
    fi
    echo "scale=2; $length / 1000000" | bc 2>/dev/null || echo "1"
}
 
get_position_seconds(){
    local pos
    pos=$(playerctl -p "$PLAYER" position 2>/dev/null)
    if [ -z "$pos" ]; then
        echo "0"
        return
    fi
    echo "$pos"
}
 
get_formatted_position(){
    local formatted
    formatted=$(playerctl -p "$PLAYER" position -f '{{duration(position)}}' 2>/dev/null)
    if [ -z "$formatted" ]; then
        echo "0:00"
        return
    fi
    echo "$formatted"
}
 

# ----------Progress percentage -------------------
get_position(){
    local length pos percent
 
    length=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null)
 
    # 原本這裡用 exit 會把整支 script 中斷（因為 function 裡的 exit 等同全域 exit）
    # 改成 return，讓其他呼叫者（case 區塊）能繼續正常結束
    if [ -z "$length" ]; then
        echo "0"
        return
    fi
 
    pos=$(playerctl -p "$PLAYER" position 2>/dev/null)
    if [ -z "$pos" ]; then
        echo "0"
        return
    fi
 
    # Second -> ms
    pos=$(echo "$pos * 1000000" | bc)
    percent=$(echo "scale=2; ($pos / $length) * 100" | bc 2>/dev/null)
 
    if [ -z "$percent" ]; then
        echo "0"
        return
    fi
 
    echo "$percent"
}
 
get_player_name(){
    echo "$PLAYER"
}

# --------------For scroll runner: Let label and artist be in one line -------------------
# Pipeline: For music-feeder.sh -> scroll.py
# Find the Playing first, then find the Paused part logic
# Doesn't have to like playerctl --follow, just stare at one player.
get_now_playing(){
    local title artist
    title=$(get_title)
    artist=$(get_artist)

    # If title is empty, then return nothing
    if [ -z "$title" ]; then
        echo "No music playing"
        return
    fi

    if [ -n "$artist" ]; then
        echo "$title - $artist"
    else
        echo "$title"
    fi
}
# --------------Command-----------------
case "$1" in
    --status)
        get_status
        ;;
 
    --title)
        get_title
        ;;
 
    --song)
        get_title
        ;;
 
    --artist)
        get_artist
        ;;
 
    --album)
        get_album
        ;;
 
    --cover)
        get_cover
        ;;
 
    --position)
        get_position
        ;;
    --length-s)
        get_length_seconds
        ;;
    --position-s)
        get_position_seconds
        ;;
    --formatted-position)
        get_formatted_position
        ;;
 
    --player)
        get_player_name
        ;;
    
    --np)
        get_now_playing
        ;;
 
    *)
        cat <<EOF
 
Usage:
 
$0 --status
$0 --song
$0 --artist
$0 --album
$0 --cover
$0 --position
$0 --player
$0 --np
 
EOF
        ;;
 
esac

