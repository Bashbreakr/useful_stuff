#!/usr/bin/env bash

MIN_THRESHOLD=8

# Get the current brightness percentage
current=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')

# Calculate the new value and apply it safely
new_val=$((current - 8))
if [ "$new_val" -lt "$MIN_THRESHOLD" ]; then
    brightnessctl set "${MIN_THRESHOLD}%"
else
    brightnessctl set 8%-
fi
