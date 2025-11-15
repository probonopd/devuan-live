#!/bin/bash
# Build script for Devuan Live ISO
# This script sets up the environment and builds the ISO

set -e

echo "==================================="
echo "Devuan Live ISO Builder"
echo "==================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo ""
echo "Step 1: Installing dependencies..."
apt-get update
apt-get install -y live-build debootstrap wget

echo ""
echo "Step 2: Setting up Devuan debootstrap script..."
# Create symlink for excalibur to use sid script
if [ ! -e /usr/share/debootstrap/scripts/excalibur ]; then
    ln -sf sid /usr/share/debootstrap/scripts/excalibur
    echo "  Created symlink for excalibur script"
fi

echo ""
echo "Step 3: Installing Devuan keyring..."
cd /tmp
if [ ! -f /usr/share/keyrings/devuan-archive-keyring.gpg ]; then
    wget -q http://pkgmaster.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2023.10.07_all.deb || \
    wget -q http://deb.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2023.10.07_all.deb || \
    echo "  Warning: Could not download devuan-keyring, build may fail during bootstrap"
    
    if [ -f devuan-keyring_2023.10.07_all.deb ]; then
        dpkg -i devuan-keyring_2023.10.07_all.deb || apt-get install -y -f
        echo "  Devuan keyring installed"
    fi
else
    echo "  Devuan keyring already installed"
fi

# Return to project directory
cd -

echo ""
echo "Step 4: Configuring live-build..."
lb config

echo ""
echo "Step 5: Building ISO (this may take a long time)..."
echo "  Note: The build process will download packages and may take 30-60 minutes"
echo ""
lb build

echo ""
echo "==================================="
echo "Build complete!"
echo "==================================="

# Find and display the ISO file
ISO_FILE=$(ls *.iso 2>/dev/null | head -n 1)
if [ -n "$ISO_FILE" ]; then
    echo "ISO created: $ISO_FILE"
    ls -lh "$ISO_FILE"
else
    echo "Warning: No ISO file found. Build may have failed."
    exit 1
fi
