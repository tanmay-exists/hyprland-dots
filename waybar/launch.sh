#!/bin/bash

# Kill any existing Waybar instances
pkill waybar

# Wait a moment to ensure the process is fully terminated
sleep 0.5

# Start a new Waybar instance
waybar &
