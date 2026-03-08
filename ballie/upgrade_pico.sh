#!/bin/bash
PICO_FIRMWARE_SRC="/home/daniel/programming/ballie/pico-shim-firmware"

echo "==============================================================="
echo "PICO 2 W USB FLASH SCRIPT"
echo "==============================================================="
echo "This script flashes the necessary firmware to the Pico via USB."
echo "Make sure the Pico is connected to the Pi Zero (or this machine)."
echo ""

# Identify where we are running (local or remote)
if [ -e "/dev/ttyACM0" ]; then
    echo "Pico found at /dev/ttyACM0. Starting flash..."
    python3 "$PICO_FIRMWARE_SRC/deploy_to_pico.py" "$PICO_FIRMWARE_SRC"
else
    echo "Pico not found at /dev/ttyACM0."
    echo "If you are on the dev machine, make sure the Pico is plugged in."
    echo "If you want to flash remotely on the Pi Zero, run this via sync_and_run_on_py.sh."
    exit 1
fi

echo "==============================================================="
echo "FLASH COMPLETE!"
echo "Pico is now running the latest firmware with Direct Drive support."
echo "==============================================================="
