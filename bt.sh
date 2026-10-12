#!/usr/bin/env bash

set -euo pipefail

# Check dependencies
command -v gum >/dev/null 2>&1 || { echo "Error: 'gum' is not installed." >&2; exit 1; }
command -v bluetoothctl >/dev/null 2>&1 || { echo "Error: 'bluetoothctl' is not installed." >&2; exit 1; }

# Function to ensure Bluetooth controller is powered on
ensure_power_on() {
  local power_state
  power_state=$(bluetoothctl show | awk '/Powered:/ {print $2}')
  if [ "$power_state" != "yes" ]; then
    gum style --foreground 212 "Bluetooth is currently off. Powering on..."
    bluetoothctl power on > /dev/null
    sleep 1
  fi
}

# Connect to a previously paired device
connect_paired() {
  ensure_power_on

  # Fetch paired devices: MAC address + Alias/Name
  local paired_list
  paired_list=$(bluetoothctl devices Paired | awk '{MAC=$2; $1=$2=""; print $0 " (" MAC ")"}')

  if [ -z "$paired_list" ]; then
    gum style --foreground 214 "No paired devices found."
    return
  fi

  local selected
  selected=$(echo "$paired_list" | gum choose --header "Select a paired device to connect:")

  if [ -n "$selected" ]; then
    # Extract MAC address from parenthesis
    local mac
    mac=$(echo "$selected" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')

    gum spin --spinner dot --title "Connecting to $selected..." -- bluetoothctl connect "$mac"
    gum style --foreground 82 "Connected successfully!"
  fi
}

# Scan, Pair, Trust, and Connect to a new device
pair_new() {
  ensure_power_on

  gum style --foreground 212 "Scanning for Bluetooth devices (5 seconds)..."
  
  # Start discovery in background, wait 5 sec, then stop
  bluetoothctl --timeout 5 scan on > /dev/null 2>&1 || true

  # Fetch discovered devices
  local device_list
  device_list=$(bluetoothctl devices | awk '{MAC=$2; $1=$2=""; print $0 " (" MAC ")"}')

  if [ -z "$device_list" ]; then
    gum style --foreground 196 "No Bluetooth devices discovered."
    return
  fi

  local selected
  selected=$(echo "$device_list" | gum choose --header "Select a device to pair:")

  if [ -n "$selected" ]; then
    local mac
    mac=$(echo "$selected" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')

    gum spin --spinner dot --title "Pairing with $selected..." -- bluetoothctl pair "$mac"
    bluetoothctl trust "$mac" > /dev/null
    
    gum spin --spinner dot --title "Connecting..." -- bluetoothctl connect "$mac"
    gum style --foreground 82 "Paired and connected successfully!"
  fi
}

# Disconnect an active device
disconnect_device() {
  # Get list of currently connected devices
  local connected_list
  connected_list=$(bluetoothctl devices Connected | awk '{MAC=$2; $1=$2=""; print $0 " (" MAC ")"}')

  if [ -z "$connected_list" ]; then
    gum style --foreground 214 "No devices are currently connected."
    return
  fi

  local selected
  selected=$(echo "$connected_list" | gum choose --header "Select a device to disconnect:")

  if [ -n "$selected" ]; then
    local mac
    mac=$(echo "$selected" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')

    gum spin --spinner dot --title "Disconnecting $selected..." -- bluetoothctl disconnect "$mac"
    gum style --foreground 212 "Disconnected."
  fi
}

# Toggle Bluetooth power state
toggle_power() {
  local current_state
  current_state=$(bluetoothctl show | awk '/Powered:/ {print $2}')

  if [ "$current_state" == "yes" ]; then
    bluetoothctl power off > /dev/null
    gum style --foreground 196 "Bluetooth powered OFF."
  else
    bluetoothctl power on > /dev/null
    gum style --foreground 82 "Bluetooth powered ON."
  fi
}

# --- Main Interactive Menu ---
main() {
  while true; do
    echo ""
    local action
    action=$(gum choose \
      "Connect Paired Device" \
      "Scan & Pair New Device" \
      "Disconnect Device" \
      "Toggle Bluetooth Power" \
      "Exit")

    case "$action" in
      "Connect Paired Device")  connect_paired ;;
      "Scan & Pair New Device") pair_new ;;
      "Disconnect Device")      disconnect_device ;;
      "Toggle Bluetooth Power") toggle_power ;;
      "Exit"|"")                echo "Goodbye!"; exit 0 ;;
    esac
  done
}

main
