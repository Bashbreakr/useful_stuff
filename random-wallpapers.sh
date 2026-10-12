#!/usr/bin/env bash

WALLDIR="$HOME/.wallpapers"

# Ensure hyprpaper is running
if ! pgrep -x hyprpaper >/dev/null; then
    echo "Starting hyprpaper..."
    hyprpaper &
    sleep 2
fi

# Collect wallpapers
mapfile -t WALLPAPERS < <(find "$WALLDIR" -type f)

# Exit if none found
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLDIR"
    exit 1
fi

# Preload wallpapers
for img in "${WALLPAPERS[@]}"; do
    hyprctl hyprpaper preload "$img"
done

# Get monitor names
mapfile -t MONITORS < <(hyprctl monitors | awk '/Monitor/ {print $2}')

# Assign random wallpaper to each monitor
for mon in "${MONITORS[@]}"; do
    random_wall="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"

    echo "Setting $random_wall on $mon"

    hyprctl hyprpaper wallpaper "$mon,$random_wall"
done

