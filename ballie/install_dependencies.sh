#!/bin/bash

echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y python3-psutil python3-smbus i2c-tools python3-pil python3-numpy sshpass

echo "Installing Python dependencies (if needed)..."
# We use --break-system-packages if running on newer RaspiOS (Bookworm+) outside a venv, 
# though apt packages above are preferred and safer.
# This loop handles pip packages that might not be in apt or are newer.
if [ -f "requirements.txt" ]; then
    # Check if we are in a virtual environment or need to force install
    if python3 -c "import sys; print(sys.prefix != sys.base_prefix)" | grep -q "True"; then
        pip3 install -r requirements.txt
    else
        # Try installing via apt again for specific libraries if pip fails or is blocked
        echo "Skipping pip install to avoid breaking system packages. Relying on apt."
        # If user really needs pip packages:
        # pip3 install -r requirements.txt --break-system-packages
    fi
fi

echo "Dependencies installed."
