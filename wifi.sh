#!/usr/bin/env bash

set -euo pipefail

# Check if gum and nmcli are installed
command -v gum >/dev/null 2>&1 || { echo "Error: 'gum' is not installed." >&2; exit 1; }
command -v nmcli >/dev/null 2>&1 || { echo "Error: 'nmcli' is not installed." >&2; exit 1; }

# Ensure Wi-Fi is enabled
wifi_status=$(nmcli radio wifi)
if [ "$wifi_status" != "enabled" ]; then
  gum spin --spinner dot --title "Enabling Wi-Fi..." -- nmcli radio wifi on
fi

# Spin while scanning for networks
gum spin --spinner globe --title "Scanning for Wi-Fi networks..." -- nmcli device wifi rescan

# Get list of Wi-Fi networks (SSID, Signal Strength, Security)
# We filter out empty SSIDs (hidden networks)
networks=$(nmcli -f SSID,SIGNAL,SECURITY device wifi list | stdbuf -oL awk 'NR>1 && $1 != "--" {print $0}')

if [ -z "$networks" ]; then
  gum format -- "### No Wi-Fi networks found."
  exit 0
fi

# Prompt user to select a network
selected_line=$(echo "$networks" | gum choose --header "Select a Wi-Fi Network:")

if [ -z "$selected_line" ]; then
  echo "No network selected. Exiting."
  exit 0
fi

# Extract the SSID (first field / column cluster)
# Using awk to extract SSID handling trailing spaces carefully
ssid=$(echo "$selected_line" | awk '{print $1}')
security=$(echo "$selected_line" | awk '{print $NF}')

# Check if the network requires a password
if [[ "$security" == "--" || "$security" == "NONE" ]]; then
  # Open network
  gum spin --spinner dot --title "Connecting to $ssid..." -- nmcli device wifi connect "$ssid"
else
  # Secured network - prompt for password
  password=$(gum input --password --placeholder "Enter Wi-Fi Password for $ssid")

  if [ -z "$password" ]; then
    echo "Password cannot be empty. Exiting."
    exit 1
  fi

  # Attempt connection
  if gum spin --spinner dot --title "Connecting to $ssid..." -- nmcli device wifi connect "$ssid" password "$password"; then
    gum style --foreground 212 "Successfully connected to $ssid!"
  else
    gum style --foreground 196 "Failed to connect to $ssid."
    exit 1
  fi
fi
