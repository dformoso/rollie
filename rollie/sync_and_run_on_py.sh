#!/bin/bash

# Load user configuration — copy sync_config.sh.example to sync_config.sh first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/sync_config.sh" ]; then
    echo "Error: sync_config.sh not found. Copy sync_config.sh.example to sync_config.sh and fill in your values."
    exit 1
fi
source "$SCRIPT_DIR/sync_config.sh"

SERVICE_NAME="rollie_camera.service"
PICO_SERIAL="/dev/ttyACM0"

# Arguments
MODE="foreground"
INSTALL_DEPS=false

# Check for flags in arguments
for arg in "$@"
do
    if [ "$arg" == "dependencies_check" ]; then
        INSTALL_DEPS=true
    fi
done

if [ "$1" == "background" ]; then
    if [ "$2" == "on" ]; then
        MODE="background_on"
    elif [ "$2" == "off" ]; then
        MODE="background_off"
    else
        echo "Usage: ./sync_and_run_on_py.sh [background on|off] [dependencies_check]"
        exit 1
    fi
fi

# Function to stop/remove service
stop_service() {
    echo "Stopping and disabling $SERVICE_NAME on remote..."
    sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "echo "$PI_SUDO_PASS" | sudo -S systemctl stop $SERVICE_NAME 2>/dev/null || true; echo "$PI_SUDO_PASS" | sudo -S systemctl disable $SERVICE_NAME 2>/dev/null || true; echo "$PI_SUDO_PASS" | sudo -S rm /etc/systemd/system/$SERVICE_NAME 2>/dev/null || true"
}

# 1. Handle "background off" (Stop, Remove, Exit)
if [ "$MODE" == "background_off" ]; then
    stop_service
    echo "Background service removed."
    exit 0
fi

# Fix remote permissions (ownership) to ensure rsync can modify/delete files
echo "Fixing remote permissions..."
sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "echo "$PI_SUDO_PASS" | sudo -S chown -R $PI_USER:$PI_USER $DEST_DIR"

# 2. Sync Files to Pi Zero
echo ""
echo "Syncing from $SOURCE_DIR to $PI_USER@$PI_HOST:$DEST_DIR"

# Always include .uf2 in case the factory flash prompt is triggered later
sshpass -p "$PI_SSH_PASS" rsync -av --delete --exclude '__pycache__/' --exclude '.git/' --exclude 'external_repos/' "$SOURCE_DIR" "$PI_USER@$PI_HOST:$DEST_DIR"
echo "Syncing from $PICO_FIRMWARE_DIR to $PI_USER@$PI_HOST:$DEST_DIR/pico-shim-firmware"
sshpass -p "$PI_SSH_PASS" rsync -av --delete --exclude '__pycache__/' --exclude '.git/' "$PICO_FIRMWARE_DIR/" "$PI_USER@$PI_HOST:$DEST_DIR/pico-shim-firmware"

# 4. Handle "background on" (Install Service, Start, Exit)
if [ "$MODE" == "background_on" ]; then
    echo "Setting up $SERVICE_NAME on remote..."
    
    cat > rollie_camera.service <<EOF
[Unit]
Description=Rollie Camera Feed
After=network.target

[Service]
Type=simple
User=$PI_USER
WorkingDirectory=$DEST_DIR
ExecStart=/usr/bin/python3 $DEST_DIR/camera_feed.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    echo "Copying service file to remote..."
    sshpass -p "$PI_SSH_PASS" scp rollie_camera.service "$PI_USER@$PI_HOST:$DEST_DIR/$SERVICE_NAME"
    
    sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "echo "$PI_SUDO_PASS" | sudo -S mv $DEST_DIR/$SERVICE_NAME /etc/systemd/system/$SERVICE_NAME && echo "$PI_SUDO_PASS" | sudo -S chown root:root /etc/systemd/system/$SERVICE_NAME && echo "$PI_SUDO_PASS" | sudo -S systemctl daemon-reload && echo "$PI_SUDO_PASS" | sudo -S systemctl enable $SERVICE_NAME && echo "$PI_SUDO_PASS" | sudo -S systemctl restart $SERVICE_NAME"
    
    rm rollie_camera.service
    
    echo "$SERVICE_NAME started and enabled on boot."
    exit 0
fi

# 3. Handle "foreground" — Run camera + motor control together
stop_service

if [ "$INSTALL_DEPS" = true ]; then
    echo "Installing dependencies on remote..."
    sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "chmod +x $DEST_DIR/install_dependencies.sh && echo "$PI_SUDO_PASS" | sudo -S $DEST_DIR/install_dependencies.sh && echo "$PI_SUDO_PASS" | sudo -S apt-get install -y ffmpeg"
else
    echo "Skipping dependency check (run with 'dependencies_check' to enable)."
fi

# Factory setup routine (Always Prompt)
    echo "Checking for Pico flash override..."
    sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "
        echo ''
        echo '==============================================================='
        echo 'FACTORY PICO SETUP / RECOVERY'
        echo '==============================================================='
        echo 'Do you want to flash the MicroPython UF2 firmware?'
        echo 'Hold the BOOTSEL button and plug in the Pico (or reset it while holding BOOTSEL).'
        read -t 5 -p 'Type y and press ENTER to flash (skipping in 5 seconds...): ' response
        echo ''
        if [[ \"\$response\" =~ ^[Yy]$ ]]; then
            echo 'Looking for RPI-RP2 drive (/dev/sda1)...'
            sleep 2
            if [ -b /dev/sda1 ]; then
                echo "$PI_SUDO_PASS" | sudo -S mkdir -p /mnt/pico
                echo "$PI_SUDO_PASS" | sudo -S mount /dev/sda1 /mnt/pico
                echo 'Flashing pimoroni-pico2-micropython.uf2...'
                echo "$PI_SUDO_PASS" | sudo -S cp $DEST_DIR/pico-shim-firmware/pimoroni-pico2-micropython.uf2 /mnt/pico/
                echo "$PI_SUDO_PASS" | sudo -S sync
                echo 'UF2 flashed. Pico should reboot as /dev/ttyACM0.'
                sleep 5
            else
                echo 'ERROR: /dev/sda1 not found. Ensure Pico is in BOOTSEL mode.'
            fi
        else
            echo 'Skipping UF2 flashing.'
        fi
        
        echo 'Waiting for Pico to appear as /dev/ttyACM0...'
        for i in {1..10}; do
            if [ -e /dev/ttyACM0 ]; then
                echo 'Pico found! Deploying python scripts...'
                python3 $DEST_DIR/pico-shim-firmware/deploy_to_pico.py $DEST_DIR/pico-shim-firmware
                break
            fi
            sleep 1
        done
    "

# Kill any stale processes holding the Pico serial port
echo ""
echo "Cleaning up stale serial processes..."
pkill -9 -f "mpremote connect /dev/ttyACM0" 2>/dev/null
pkill -9 -f "python3.*ttyACM0" 2>/dev/null
sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "echo "$PI_SUDO_PASS" | sudo -S killall -9 python python3 2>/dev/null" || true
sleep 1

# Start camera on Pi Zero in the background
echo "Starting camera_feed.py on Pi Zero (background)..."
sshpass -p "$PI_SSH_PASS" ssh -t "$PI_USER@$PI_HOST" "echo "$PI_SUDO_PASS" | sudo -S python3 $DEST_DIR/camera_feed.py" &
CAMERA_PID=$!

# Cleanup function — kills camera SSH + restores terminal
cleanup() {
    echo ""
    echo "[CLEANUP] Stopping all processes..."
    kill $CAMERA_PID 2>/dev/null
    wait $CAMERA_PID 2>/dev/null
    echo "[CLEANUP] Done."
    exit 0
}
trap cleanup INT TERM

# Launch keyboard motor control
if [ -e "$PICO_SERIAL" ]; then
    echo "Pico found locally. Starting keyboard control (USB)..."
    echo "$PI_SUDO_PASS" | sudo -S chmod a+rw "$PICO_SERIAL" 2>/dev/null

    # Reset Pico locally
    echo "Resetting Pico..."
    python3 -c "import serial, time
try:
    s = serial.Serial('$PICO_SERIAL', 9600, timeout=0.5)
    s.write(bytes([3, 3]))
    time.sleep(0.3)
    s.write(bytes([4]))
    time.sleep(0.5)
    s.close()
    print('Pico reset OK')
except Exception as e:
    print('Reset failed:', e)" 2>/dev/null
    sleep 1

    python3 "$PICO_FIRMWARE_DIR/keyboard_control.py"
else
    echo "Pico not found locally at $PICO_SERIAL."
    # Run complete keyboard logic remotely over SSH
    sshpass -p "$PI_SSH_PASS" ssh -t -t "$PI_USER@$PI_HOST" "
        PICO_DEV='/dev/serial0'
        echo \"[REMOTE] Connecting to Pico via \$PICO_DEV (UART0)...\"
        
        # Reset Pico via UART
        python3 -c \"import serial, time
try:
    s = serial.Serial('\$PICO_DEV', 9600, timeout=0.5)
    s.write(bytes([3, 3]))
    time.sleep(0.3)
    s.write(bytes([4]))
    time.sleep(0.5)
    s.close()
    print('[REMOTE] Pico reset OK on \$PICO_DEV')
except Exception as e:
    print('[REMOTE] Reset failed on \$PICO_DEV:', e)\" 2>/dev/null
        
        # Run keyboard controller (enforce serial mode)
        python3 $DEST_DIR/pico-shim-firmware/keyboard_control.py serial
    "

fi

# When keyboard control exits, cleanup camera too
cleanup
