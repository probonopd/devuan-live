#!/bin/bash
# Build script for Devuan Live ISO using official Devuan Docker container
# This bypasses host system debootstrap issues by using native Devuan environment

set -e

echo "==================================="
echo "Devuan Live ISO Builder (Docker)"
echo "==================================="

# Configuration
DEVUAN_VERSION="${DEVUAN_VERSION:-excalibur}"
DOCKER_IMAGE="devuan/devuan:${DEVUAN_VERSION}"

echo ""
echo "Using Docker image: ${DOCKER_IMAGE}"

# Check if running as root or with docker group access
if ! docker ps >/dev/null 2>&1; then
    echo "Error: Docker access required. Run with sudo or add user to docker group."
    exit 1
fi

echo ""
echo "Step 1: Pulling Devuan Docker image..."
docker pull "${DOCKER_IMAGE}"

echo ""
echo "Step 2: Starting Docker container with privileged access..."
echo "  (Privileged mode is required for debootstrap and chroot operations)"

# Run the build inside the container
# Mount the current directory so we can access the config and get the ISO out
docker run --rm --privileged \
    -v "$(pwd):/build" \
    -w /build \
    "${DOCKER_IMAGE}" \
    /bin/bash -c '
set -e

echo ""
echo "Step 3: Installing build dependencies inside container..."
apt-get update
apt-get install -y live-build debootstrap wget xz-utils

echo ""
echo "Step 4: Patching live-build to support LB_BOOTSTRAP_EXCLUDE..."
# The live-build bootstrap_debootstrap script doesn'\''t read LB_BOOTSTRAP_EXCLUDE
# We need to patch it to add usr-is-merged to the exclusion list

BOOTSTRAP_SCRIPT="/usr/lib/live/build/bootstrap_debootstrap"

if [ -f "$BOOTSTRAP_SCRIPT" ]; then
    echo "  Found bootstrap_debootstrap at $BOOTSTRAP_SCRIPT"
    
    # Create a backup
    cp "$BOOTSTRAP_SCRIPT" "${BOOTSTRAP_SCRIPT}.orig"
    
    # Find the line number where DEBOOTSTRAP_EXCLUDE is set
    LINE_NUM=$(grep -n "^DEBOOTSTRAP_EXCLUDE=\"\${DEBOOTSTRAP_EXCLUDE_OPTION:+--exclude=\${DEBOOTSTRAP_EXCLUDE_OPTION}}\"" "$BOOTSTRAP_SCRIPT" | cut -d: -f1)
    
    if [ -n "$LINE_NUM" ]; then
        echo "  Found DEBOOTSTRAP_EXCLUDE at line $LINE_NUM"
        
        # Create the patch content
        cat > /tmp/bootstrap.patch << '\''PATCH_EOF'\''
# PATCHED: Add support for LB_BOOTSTRAP_EXCLUDE from config
if [ -n "${LB_BOOTSTRAP_EXCLUDE}" ]; then
    if [ -n "${DEBOOTSTRAP_EXCLUDE_OPTION}" ]; then
        DEBOOTSTRAP_EXCLUDE_OPTION="${DEBOOTSTRAP_EXCLUDE_OPTION},${LB_BOOTSTRAP_EXCLUDE}"
    else
        DEBOOTSTRAP_EXCLUDE_OPTION="${LB_BOOTSTRAP_EXCLUDE}"
    fi
    DEBOOTSTRAP_EXCLUDE="--exclude=${DEBOOTSTRAP_EXCLUDE_OPTION}"
    echo "  Added LB_BOOTSTRAP_EXCLUDE to debootstrap: ${LB_BOOTSTRAP_EXCLUDE}"
fi
PATCH_EOF
        
        # Insert the patch after the DEBOOTSTRAP_EXCLUDE line
        head -n "$LINE_NUM" "${BOOTSTRAP_SCRIPT}.orig" > "${BOOTSTRAP_SCRIPT}.new"
        echo "" >> "${BOOTSTRAP_SCRIPT}.new"
        cat /tmp/bootstrap.patch >> "${BOOTSTRAP_SCRIPT}.new"
        tail -n +$((LINE_NUM + 1)) "${BOOTSTRAP_SCRIPT}.orig" >> "${BOOTSTRAP_SCRIPT}.new"
        
        # Replace the original file
        mv "${BOOTSTRAP_SCRIPT}.new" "$BOOTSTRAP_SCRIPT"
        chmod +x "$BOOTSTRAP_SCRIPT"
        
        echo "  Patch applied successfully!"
        echo "  Verifying patch..."
        if grep -q "PATCHED: Add support for LB_BOOTSTRAP_EXCLUDE" "$BOOTSTRAP_SCRIPT"; then
            echo "  ✓ Patch verified!"
        else
            echo "  WARNING: Could not verify patch"
        fi
    else
        echo "  ERROR: Could not find DEBOOTSTRAP_EXCLUDE line to patch"
        exit 1
    fi
else
    echo "  ERROR: bootstrap_debootstrap not found at $BOOTSTRAP_SCRIPT"
    exit 1
fi

echo ""
echo "Step 5: Cleaning any previous build..."
lb clean --purge || true

echo ""
echo "Step 6: Configuring live-build..."
lb config

echo ""
echo "Step 7: Building ISO..."
echo "  This may take 30-60 minutes depending on your internet connection..."
echo ""

# Set environment variable to help debootstrap find xz-compressed files
export DEBOOTSTRAP_CHECKSUM_FIELD=SHA256
lb build

echo ""
echo "Step 8: Renaming ISO with date..."
iso_file=$(ls *.iso 2>/dev/null | head -n 1)
if [ -n "$iso_file" ]; then
    date_str=$(date +%Y.%m.%d)
    new_name="devuan-live-${date_str}-amd64.iso"
    mv "$iso_file" "$new_name"
    echo "ISO created: $new_name"
    ls -lh "$new_name"
else
    echo "Error: No ISO file found!"
    exit 1
fi
'

# Check if ISO was created
ISO_FILE=$(ls *.iso 2>/dev/null | head -n 1)
if [ -n "$ISO_FILE" ]; then
    echo ""
    echo "==================================="
    echo "Build complete!"
    echo "==================================="
    echo "ISO: $ISO_FILE"
    ls -lh "$ISO_FILE"
else
    echo ""
    echo "Build failed - no ISO file found"
    exit 1
fi
