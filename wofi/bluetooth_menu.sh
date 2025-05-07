#!/bin/bash

# Function to get Bluetooth status
get_status() {
  bluetoothctl show | grep "Powered: yes" >/dev/null && echo "Turn Bluetooth OFF" || echo "Turn Bluetooth ON"
}

# Function to list paired devices
list_paired_devices() {
  bluetoothctl devices Paired | awk '{$1=""; $2=""; print "Connect to" $0}' | sed 's/^Connect to //'
}

# Show main menu
OPTIONS="$(get_status)
Scan for Devices
$(list_paired_devices)"

CHOICE=$(echo "$OPTIONS" | wofi --dmenu --prompt "Bluetooth Menu")

case "$CHOICE" in
"Turn Bluetooth ON")
  bluetoothctl power on
  notify-send "Bluetooth turned ON"
  ;;

"Turn Bluetooth OFF")
  bluetoothctl power off
  notify-send "Bluetooth turned OFF"
  ;;

"Scan for Devices")
  # Ensure Bluetooth is on
  bluetoothctl power on

  # Start scanning and capture output
  notify-send "Scanning for Bluetooth devices..."
  bluetoothctl --timeout 10 scan on >/tmp/bt_scan_output 2>&1

  # Parse discovered devices from scan output
  DEVICES=$(cat /tmp/bt_scan_output | grep "Device " | awk '{print $3 " " $4 " " $5 " " $6 " " $7}' | sort | uniq)

  # Combine with paired devices
  PAIRED=$(list_paired_devices)
  if [ -n "$PAIRED" ]; then
    DEVICES="$DEVICES\n$PAIRED"
  fi

  # Clean up
  rm /tmp/bt_scan_output

  if [ -z "$DEVICES" ]; then
    notify-send "No Bluetooth devices found."
    exit 1
  fi

  # Display discovered and paired devices in Wofi
  SELECTED=$(echo -e "$DEVICES" | wofi --dmenu --prompt "Select Device to Connect")

  if [ -n "$SELECTED" ]; then
    # Extract MAC address (first field of the selected line)
    DEVICE_MAC=$(echo "$SELECTED" | awk '{print $1}')
    DEVICE_NAME=$(echo "$SELECTED" | awk '{$1=""; print $0}' | sed 's/^ //')

    if [ -n "$DEVICE_MAC" ]; then
      # Check if device is already paired
      if ! bluetoothctl devices Paired | grep -q "$DEVICE_MAC"; then
        notify-send "Pairing with $DEVICE_NAME..."
        bluetoothctl pair "$DEVICE_MAC"
        bluetoothctl trust "$DEVICE_MAC"
      fi

      notify-send "Connecting to $DEVICE_NAME..."
      bluetoothctl connect "$DEVICE_MAC"
      if [ $? -eq 0 ]; then
        notify-send "Connected to $DEVICE_NAME"
      else
        notify-send "Failed to connect to $DEVICE_NAME"
      fi
    fi
  fi
  ;;

"Connect to"*)
  DEVICE_NAME="${CHOICE#Connect to }"
  DEVICE_MAC=$(bluetoothctl devices Paired | grep "$DEVICE_NAME" | awk '{print $2}')
  if [ -n "$DEVICE_MAC" ]; then
    notify-send "Connecting to $DEVICE_NAME..."
    bluetoothctl connect "$DEVICE_MAC"
    if [ $? -eq 0 ]; then
      notify-send "Connected to $DEVICE_NAME"
    else
      notify-send "Failed to connect to $DEVICE_NAME"
    fi
  else
    notify-send "Device $DEVICE_NAME not found."
  fi
  ;;
esac
