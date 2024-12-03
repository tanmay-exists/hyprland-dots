#!/bin/bash

# Extract wallpaper path from the preload line in hyprpaper.conf
WALLPAPER=$(grep "^preload =" ~/.config/hypr/hyprpaper.conf | awk -F "= " '{print $2}' | xargs)

# Check if the wallpaper file exists
if [ -f "$WALLPAPER" ]; then
    # Apply pywal colors
    wal -i "$WALLPAPER"

    # Short delay to ensure wal finishes applying colors
    sleep 1

    # Source the pywal color sequences to update terminal colors
    [ -f "${HOME}/.cache/wal/sequences" ] && source "${HOME}/.cache/wal/sequences"
else
    echo "Wallpaper file not found: $WALLPAPER"
fi

