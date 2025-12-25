#!/bin/bash

# Configuration
PI_HOST="192.168.50.41"
PI_USER="daniel"
SOURCE_DIR="/home/daniel/programming/ballie/ballie/"
DEST_DIR="/home/daniel/programming/ballie"

# Sync with deletion
echo "Syncing from $SOURCE_DIR to $PI_USER@$PI_HOST:$DEST_DIR"
sshpass -p '2460' rsync -av --delete --exclude '__pycache__/' "$SOURCE_DIR" "$PI_USER@$PI_HOST:$DEST_DIR"

# Run remote script
echo "Running camera_feed.py on remote..."
sshpass -p '2460' ssh -t "$PI_USER@$PI_HOST" "sudo python3 $DEST_DIR/camera_feed.py"
