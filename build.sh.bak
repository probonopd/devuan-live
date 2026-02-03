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
    wget -q http://pkgmaster.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2025.08.09_all.deb || \
    wget -q http://deb.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2025.08.09_all.deb || \
    echo "  Warning: Could not download devuan-keyring, build may fail during bootstrap"
    
    if [ -f devuan-keyring_2025.08.09_all.deb ]; then
        dpkg -i devuan-keyring_2025.08.09_all.deb || apt-get install -y -f
        echo "  Devuan keyring installed"
    fi
else
    echo "  Devuan keyring already installed"
fi

# Return to project directory
cd -

echo ""
echo "Step 4: Patching debootstrap for merged /usr..."
# Create a patch that will be sourced by debootstrap
cat > /tmp/merged-usr-patch.sh << 'EOFPATCH'
# Patch to create merged /usr layout for Devuan Excalibur
# This is needed because usr-is-merged package doesn't exist in Devuan repos

# Save original setup_proc function
if ! declare -f setup_proc_orig >/dev/null 2>&1; then
    eval "$(declare -f setup_proc | sed '1s/setup_proc/setup_proc_orig/')"
fi

setup_proc() {
    # Call original setup_proc first
    setup_proc_orig
    
    # Now create merged /usr if needed
    if [ -d "$TARGET/bin" ] && [ ! -L "$TARGET/bin" ]; then
        info "DEVUAN: Creating merged /usr layout..."
        
        for dir in bin sbin lib; do
            # Ensure /usr directory exists
            mkdir -p "$TARGET/usr/$dir"
            
            # If root directory exists and is not a symlink
            if [ -d "$TARGET/$dir" ] && [ ! -L "$TARGET/$dir" ]; then
                # Move contents to /usr
                if [ "$(ls -A "$TARGET/$dir" 2>/dev/null)" ]; then
                    cp -a "$TARGET/$dir"/* "$TARGET/usr/$dir/" 2>/dev/null || true
                fi
                # Remove old directory
                rm -rf "$TARGET/$dir"
                # Create symlink
                ln -s "usr/$dir" "$TARGET/$dir"
                info "  Created symlink: /$dir -> /usr/$dir"
            fi
        done
        
        # Handle lib64 for amd64
        if [ -d "$TARGET/lib64" ] && [ ! -L "$TARGET/lib64" ]; then
            mkdir -p "$TARGET/usr/lib64"
            if [ "$(ls -A "$TARGET/lib64" 2>/dev/null)" ]; then
                cp -a "$TARGET/lib64"/* "$TARGET/usr/lib64/" 2>/dev/null || true
            fi
            rm -rf "$TARGET/lib64"
            ln -s "usr/lib64" "$TARGET/lib64"
            info "  Created symlink: /lib64 -> /usr/lib64"
        fi
    fi
}
EOFPATCH

# Inject the patch into debootstrap's functions file
if ! grep -q "merged-usr-patch" /usr/share/debootstrap/functions; then
    cat /tmp/merged-usr-patch.sh >> /usr/share/debootstrap/functions
    echo "  Debootstrap patched for merged /usr"
else
    echo "  Debootstrap already patched"
fi

echo ""
echo "Step 5: Configuring live-build..."
lb config

echo ""
echo "Step 6: Building ISO (this may take a long time)..."
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
