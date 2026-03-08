#!/bin/bash

# Configuration
PI_HOST="192.168.50.41"
PI_USER="daniel"
SOURCE_DIR="/home/daniel/programming/ballie/ballie/"
DEST_DIR="/home/daniel/programming/ballie"
SERVICE_NAME="ballie_camera.service"
PICO_FIRMWARE_DIR="/home/daniel/programming/ballie/pico-shim-firmware"
PICO_SERIAL="/dev/ttyACM0"

# Arguments
MODE="foreground"
INSTALL_DEPS=false

# Check for dependencies_check flag in any argument
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
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S systemctl stop $SERVICE_NAME 2>/dev/null || true; echo '24602460' | sudo -S systemctl disable $SERVICE_NAME 2>/dev/null || true; echo '24602460' | sudo -S rm /etc/systemd/system/$SERVICE_NAME 2>/dev/null || true"
}

# 1. Handle "background off" (Stop, Remove, Exit)
if [ "$MODE" == "background_off" ]; then
    stop_service
    echo "Background service removed."
    exit 0
fi

# Fix remote permissions (ownership) to ensure rsync can modify/delete files
echo "Fixing remote permissions..."
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S chown -R $PI_USER:$PI_USER $DEST_DIR"

# 2. Sync Files to Pi Zero
# NOTE: Pico firmware is already flashed and managed via UART, not USB.
echo ""
echo "Syncing from $SOURCE_DIR to $PI_USER@$PI_HOST:$DEST_DIR"
sshpass -p '2460' rsync -av --delete --exclude '__pycache__/' --exclude '.git/' --exclude 'external_repos/' --exclude '*.uf2' "$SOURCE_DIR" "$PI_USER@$PI_HOST:$DEST_DIR"

echo "Syncing from $PICO_FIRMWARE_DIR to $PI_USER@$PI_HOST:$DEST_DIR/pico-shim-firmware"
sshpass -p '2460' rsync -av --delete --exclude '__pycache__/' --exclude '.git/' --exclude '*.uf2' "$PICO_FIRMWARE_DIR/" "$PI_USER@$PI_HOST:$DEST_DIR/pico-shim-firmware"

# 4. Handle "background on" (Install Service, Start, Exit)
if [ "$MODE" == "background_on" ]; then
    echo "Setting up $SERVICE_NAME on remote..."
    
    cat > ballie_camera.service <<EOF
[Unit]
Description=Ballie Camera Feed
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
    sshpass -p '2460' scp ballie_camera.service "$PI_USER@$PI_HOST:$DEST_DIR/$SERVICE_NAME"
    
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S mv $DEST_DIR/$SERVICE_NAME /etc/systemd/system/$SERVICE_NAME && echo '24602460' | sudo -S chown root:root /etc/systemd/system/$SERVICE_NAME && echo '24602460' | sudo -S systemctl daemon-reload && echo '24602460' | sudo -S systemctl enable $SERVICE_NAME && echo '24602460' | sudo -S systemctl restart $SERVICE_NAME"
    
    rm ballie_camera.service
    
    echo "$SERVICE_NAME started and enabled on boot."
    exit 0
fi

# 3. Handle "foreground" — Run camera + motor control together
stop_service

if [ "$INSTALL_DEPS" = true ]; then
    echo "Installing dependencies on remote..."
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "chmod +x $DEST_DIR/install_dependencies.sh && echo '24602460' | sudo -S $DEST_DIR/install_dependencies.sh && echo '24602460' | sudo -S apt-get install -y ffmpeg"
else
    echo "Skipping dependency check (run with 'dependencies_check' to enable)."
fi

# Kill any stale processes holding the Pico serial port
echo ""
echo "Cleaning up stale serial processes..."
pkill -9 -f "mpremote connect /dev/ttyACM0" 2>/dev/null
pkill -9 -f "python3.*ttyACM0" 2>/dev/null
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S killall -9 python python3 2>/dev/null" || true
sleep 1

# Start camera on Pi Zero in the background
echo "Starting camera_feed.py on Pi Zero (background)..."
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S python3 $DEST_DIR/camera_feed.py" &
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
    echo 24602460 | sudo -S chmod a+rw "$PICO_SERIAL" 2>/dev/null

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
    sshpass -p '2460' ssh -t -t "$PI_USER@$PI_HOST" "
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
