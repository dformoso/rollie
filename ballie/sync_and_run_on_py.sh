#!/bin/bash

# Configuration
PI_HOST="192.168.50.41"
PI_USER="daniel"
SOURCE_DIR="/home/daniel/programming/ballie/ballie/"
DEST_DIR="/home/daniel/programming/ballie"

# Sync with deletion
echo "Syncing from $SOURCE_DIR to $PI_USER@$PI_HOST:$DEST_DIR"
sshpass -p '2460' rsync -av --delete --exclude '__pycache__/' "$SOURCE_DIR" "$PI_USER@$PI_HOST:$DEST_DIR"

# Handle "status" argument
MODE="foreground"
if [ "$1" == "status" ]; then
    if [ "$2" == "on" ]; then
        MODE="background"
    elif [ "$2" == "off" ]; then
        MODE="kill"
    else
        echo "Usage: ./sync_and_run_on_py.sh [status on|off]"
        exit 1
    fi
fi

if [ "$MODE" == "kill" ]; then
    echo "Stopping remote camera_feed.py..."
    # Sending SIGINT (2) first to allow graceful cleanup, then kill if needed
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S pkill -2 -f camera_feed.py || echo 'Not running'"
    exit 0
fi

# Install Dependencies (Only if not just killing)
echo "Installing dependencies on remote..."
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "chmod +x $DEST_DIR/install_dependencies.sh && echo '24602460' | sudo -S $DEST_DIR/install_dependencies.sh && echo '24602460' | sudo -S apt-get install -y ffmpeg"

if [ "$MODE" == "background" ]; then
    echo "Starting camera_feed.py in BACKGROUND..."
    # Kill old instance first
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S pkill -f camera_feed.py || true"
    # Run invalidating SIGHUP and redirecting output
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S nohup python3 $DEST_DIR/camera_feed.py > $DEST_DIR/camera.log 2>&1 &"
    echo "Deployed to background. Logs at $DEST_DIR/camera.log"
    exit 0
else
    # Foreground
    echo "Running camera_feed.py on remote (Foreground)..."
    sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "echo '24602460' | sudo -S python3 $DEST_DIR/camera_feed.py"
fi
