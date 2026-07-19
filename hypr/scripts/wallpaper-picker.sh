#!/usr/bin/env zsh

# ---------------------------------------------------------
# Use rofi to select wallpaper and use hyprpaper to use it
# ---------------------------------------------------------

WALLPAPER_DIR="$HOME/wallpapers"
RASI_THEME="$HOME/.config/rofi/config-wallpaper.rasi"


# Check hyprpaper daemon is running or not
if ! pgrep -x hyprpaper > /dev/null; then
    notify-send "Wallpaper Picker" "hyprpaper is not working, please activate hyprpaper daemon first"
    exit 1
fi

# Take the first monitor
MONITOR=("${(@f)$(hyprctl monitors -j | jq -r '.[].name')}")



# Create "show_text\0icon\x1fGraph_path" format for rofu to read.
get_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
        | sort | while read -r img; do
            name=$(basename "$img")
            printf '%s\0icon\x1f%s\n' "$name" "$img"
    done
}

# Called rofi and load the rofi theme
selected=$(get_wallpapers | rofi -dmenu -show-icons -p "Wallpaper" -theme "$RASI_THEME")

# User press ESC to exit
[ -z "$selected" ] && exit 0

full_path="$WALLPAPER_DIR/$selected"

# Check if file exist or not
if [ ! -f "$full_path" ]; then
    notify-send "Wallpaper selector can't find the $full_path file."
    exit 1
fi

# Apply the same wallpaper to every connected monitor
for mon in "${MONITOR[@]}"; do
    hyprctl hyprpaper wallpaper "$mon,$full_path,cover"
done
notify-send "Wallpaper already changed to $(basename "$full_path")"
