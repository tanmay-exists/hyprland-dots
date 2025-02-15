#!/bin/bash

# Function to cleanup on exit
cleanup() {
  if [ -n "$con_name" ]; then
    nmcli connection delete "$con_name" 2>/dev/null
  fi
}

# Set timeout for connection attempts (in seconds)
TIMEOUT=15

# Scan for available WiFi networks
networks=$(nmcli -t -f SSID dev wifi | grep -v "^$" | sort | uniq)

# Show WiFi network list in Wofi
selected_network=$(echo -e "$networks" | wofi --dmenu -p "Select WiFi Network")

# If user selected a network
if [ -n "$selected_network" ]; then
  # Check if the network requires a password
  security_info=$(nmcli -t -f SSID,SECURITY dev wifi | grep "^$selected_network" | cut -d ':' -f2)

  if [[ -z "$security_info" || "$security_info" == "--" ]]; then
    # Connect to an open network (no password needed)
    timeout $TIMEOUT nmcli device wifi connect "$selected_network"
  else
    # Ask for WiFi password using Wofi
    password=$(echo "" | wofi --dmenu -p "Enter WiFi Password" --password)

    if [ -n "$password" ]; then
      # Create a temporary connection profile
      con_name="wifi_$selected_network"

      # Delete any existing connection with the same name
      nmcli connection delete "$con_name" 2>/dev/null

      # Try direct connection first
      if timeout $TIMEOUT nmcli device wifi connect "$selected_network" password "$password"; then
        notify-send "WiFi Connection" "Successfully connected to $selected_network"
        exit 0
      fi

      # If direct connection fails, try with a connection profile
      nmcli connection add \
        type wifi \
        con-name "$con_name" \
        ifname wlo1 \
        ssid "$selected_network" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$password"

      # Attempt to activate with timeout
      if timeout $TIMEOUT nmcli connection up "$con_name"; then
        notify-send "WiFi Connection" "Successfully connected to $selected_network"
      else
        notify-send "WiFi Connection" "Failed to connect to $selected_network"
        cleanup
      fi
    else
      notify-send "WiFi Connection" "No password entered. Connection aborted."
    fi
  fi
fi

# Cleanup any leftover connection profiles
cleanup
