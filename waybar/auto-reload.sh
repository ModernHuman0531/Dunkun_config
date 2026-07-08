while inotifywait -e close_write ~/Dunkun_config/waybar; do killall -SIGUSR2 waybar; done
