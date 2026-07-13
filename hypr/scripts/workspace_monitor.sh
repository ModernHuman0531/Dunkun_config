#!/usr/bin/env bash

while read -r line; do

    if hyprctl monitors | grep -q "Monitor HDMI-A-1"; then

        hyprctl dispatch moveworkspacetomonitor 1 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 2 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 3 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 4 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 5 HDMI-A-1

    else

        hyprctl dispatch moveworkspacetomonitor 1 eDP-1
        hyprctl dispatch moveworkspacetomonitor 2 eDP-1
        hyprctl dispatch moveworkspacetomonitor 3 eDP-1
        hyprctl dispatch moveworkspacetomonitor 4 eDP-1
        hyprctl dispatch moveworkspacetomonitor 5 eDP-1

    fi

done
