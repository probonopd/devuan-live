#!/bin/bash
# Validation script for Devuan Live ISO configuration
# This script validates that the configuration is correct without building the full ISO

set -e

echo "==================================="
echo "Devuan Live ISO Configuration Validator"
echo "==================================="

ERRORS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

echo ""
echo "Checking configuration files..."

# Check if config files exist
if [ -f config/bootstrap ]; then
    pass "config/bootstrap exists"
else
    fail "config/bootstrap missing"
fi

if [ -f config/common ]; then
    pass "config/common exists"
else
    fail "config/common missing"
fi

if [ -f config/chroot ]; then
    pass "config/chroot exists"
else
    fail "config/chroot missing"
fi

if [ -f config/binary ]; then
    pass "config/binary exists"
else
    fail "config/binary missing"
fi

echo ""
echo "Checking package lists..."

if [ -f config/package-lists/desktop.list.chroot ]; then
    pass "Desktop package list exists"
    PKGS=$(grep -v "^#" config/package-lists/desktop.list.chroot | grep -v "^$" | wc -l)
    echo "  Found $PKGS packages in desktop list"
else
    fail "Desktop package list missing"
fi

if [ -f config/package-lists/hardware.list.chroot ]; then
    pass "Hardware package list exists"
else
    fail "Hardware package list missing"
fi

echo ""
echo "Checking bootloader configuration..."

# Check if boot=live is in boot parameters (required for live-boot)
if grep -q 'LB_BOOTAPPEND_LIVE=.*boot=live' config/binary; then
    pass "Boot parameters include 'boot=live'"
else
    fail "Boot parameters missing 'boot=live' (required for live-boot)"
fi

echo ""
echo "Checking distribution settings..."

# Check if distribution is set to daedalus
if grep -q "LB_DISTRIBUTION=\"daedalus\"" config/bootstrap; then
    pass "Distribution set to daedalus"
else
    fail "Distribution not set to daedalus"
fi

# Check if mirrors point to Devuan
if grep -q "pkgmaster.devuan.org" config/bootstrap; then
    pass "Using Devuan mirrors"
else
    fail "Not using Devuan mirrors"
fi

echo ""
echo "Checking live-build availability..."

if command -v lb > /dev/null 2>&1; then
    pass "live-build is installed"
    LB_VERSION=$(lb --version 2>&1 | head -n 1 || echo "unknown")
    echo "  Version: $LB_VERSION"
else
    fail "live-build is not installed"
fi

if command -v debootstrap > /dev/null 2>&1; then
    pass "debootstrap is installed"
else
    fail "debootstrap is not installed"
fi

echo ""
echo "Checking debootstrap scripts..."

if [ -f /usr/share/debootstrap/scripts/daedalus ] || [ -L /usr/share/debootstrap/scripts/daedalus ]; then
    pass "Daedalus debootstrap script exists"
else
    fail "Daedalus debootstrap script missing (run: sudo ln -sf sid /usr/share/debootstrap/scripts/daedalus)"
fi

echo ""
echo "Testing lb config..."

# Try to run lb config
if lb config > /tmp/lb_config_test.log 2>&1; then
    pass "lb config runs successfully"
else
    fail "lb config failed"
    echo "  See /tmp/lb_config_test.log for details"
fi

echo ""
echo "==================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo "The configuration is ready to build."
    echo ""
    echo "To build the ISO, run: sudo ./build.sh"
    exit 0
else
    echo -e "${RED}Found $ERRORS error(s)${NC}"
    echo "Please fix the errors above before building."
    exit 1
fi
