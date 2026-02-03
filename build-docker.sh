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
echo "Step 4: Cleaning any previous build..."
lb clean --purge || true

echo ""
echo "Step 5: Configuring live-build..."
lb config

echo ""
echo "Step 6: Building ISO..."
echo "  This may take 30-60 minutes..."

# Set environment variable to help debootstrap find xz-compressed files
export DEBOOTSTRAP_CHECKSUM_FIELD=SHA256
lb build

echo ""
echo "Step 7: Renaming ISO with date..."
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
