#!/usr/bin/env bash

SCRIPT_DIR="$HOME/.useful_stuff"
BLACKLIST_FILE="$SCRIPT_DIR/black.list"

FILES=$(find "$SCRIPT_DIR" -maxdepth 1 -type f -printf "%f\n")

if [ -f "$BLACKLIST_FILE" ]; then
    SELECTED=$(echo "$FILES" | grep -v -F -xf "$BLACKLIST_FILE" | fuzzel --dmenu)
else
    SELECTED=$(echo "$FILES" | fuzzel --dmenu)
fi

if [ -n "$SELECTED" ]; then
    if [ -f "$SCRIPT_DIR/$SELECTED" ]; then
        wezterm -e $SCRIPT_DIR/$SELECTED
    fi
fi
