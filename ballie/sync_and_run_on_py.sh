#!/bin/bash

# Configuration
PI_HOST="192.168.50.41"
PI_USER="daniel"
SOURCE_DIR="/home/daniel/programming/ballie/ballie/"
DEST_DIR="/home/daniel/programming/ballie"
SERVICE_NAME="ballie_camera.service"

# Arguments
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
# Files created by root (via sudo run previously) might block rsync
echo "Fixing remote permissions..."
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S chown -R $PI_USER:$PI_USER $DEST_DIR"

# 2. Sync Files (Required for both foreground and background_on)
echo "Syncing from $SOURCE_DIR to $PI_USER@$PI_HOST:$DEST_DIR"
sshpass -p '2460' rsync -av --delete --exclude '__pycache__/' "$SOURCE_DIR" "$PI_USER@$PI_HOST:$DEST_DIR"

# 3. Handle "background on" (Install Service, Start, Exit)
if [ "$MODE" == "background_on" ]; then
    echo "Setting up $SERVICE_NAME on remote..."
    
    # Create service file locally first to avoid escaping issues
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

    # Copy service file to remote, then move to auto restart location
    echo "Copying service file to remote..."
    sshpass -p '2460' scp ballie_camera.service "$PI_USER@$PI_HOST:$DEST_DIR/$SERVICE_NAME"
    
    # Move to systemd folder, reload, enable, restart
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S mv $DEST_DIR/$SERVICE_NAME /etc/systemd/system/$SERVICE_NAME && echo '24602460' | sudo -S chown root:root /etc/systemd/system/$SERVICE_NAME && echo '24602460' | sudo -S systemctl daemon-reload && echo '24602460' | sudo -S systemctl enable $SERVICE_NAME && echo '24602460' | sudo -S systemctl restart $SERVICE_NAME"
    
    # Cleanup local file
    rm ballie_camera.service
    
    echo "$SERVICE_NAME started and enabled on boot."
    exit 0
fi

# 4. Handle "foreground" (Stop service if running, Run interactively)
# We stop the service to avoid hardware conflicts with the camera
stop_service

# Install Dependencies (Optional check could go here, but keeping it simple/fast for now, assuming setup is largely done 
# because previous script did it every time. Let's keep doing it or maybe skip for speed? 
# The user didn't explicitly ask to remove dep installation, but let's include it for consistency with old script, 
# or maybe move it to a separate setup script. The old script ran it every time in status=on or default.
# I will keep the dependency installation for robustness but make it part of the run sequence.)

if [ "$INSTALL_DEPS" = true ]; then
    echo "Installing dependencies on remote..."
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "chmod +x $DEST_DIR/install_dependencies.sh && echo '24602460' | sudo -S $DEST_DIR/install_dependencies.sh && echo '24602460' | sudo -S apt-get install -y ffmpeg"
else
    echo "Skipping dependency check (run with 'dependencies_check' to enable)."
fi

echo "Running camera_feed.py on remote (Foreground)..."
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S python3 $DEST_DIR/camera_feed.py"
