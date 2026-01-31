#!/bin/bash
# Browser Integration Test Script for Distrobox Developer Toolbox
# This script tests whether URL opening works correctly from within the container

set -e

echo "==================================================================="
echo "Browser Integration Test for Distrobox Developer Toolbox"
echo "==================================================================="
echo

# Check if we're in a container
if [ -f /run/.containerenv ]; then
    echo "✓ Running inside container"
else
    echo "⚠ Warning: Not running inside a container"
fi

echo

# Check available tools
echo "Checking available host integration tools:"
echo

tools_found=0

if command -v distrobox-host-exec >/dev/null 2>&1; then
    echo "✓ distrobox-host-exec: Available"
    tools_found=$((tools_found + 1))
else
    echo "✗ distrobox-host-exec: Not found"
fi

if command -v host-spawn >/dev/null 2>&1; then
    echo "✓ host-spawn: Available"
    tools_found=$((tools_found + 1))
else
    echo "✗ host-spawn: Not found"
fi

if command -v flatpak-spawn >/dev/null 2>&1; then
    echo "✓ flatpak-spawn: Available"
    tools_found=$((tools_found + 1))
else
    echo "✗ flatpak-spawn: Not found"
fi

if [ -x /run/host/usr/bin/xdg-open ]; then
    echo "✓ Host xdg-open: Available at /run/host/usr/bin/xdg-open"
    tools_found=$((tools_found + 1))
else
    echo "✗ Host xdg-open: Not found at /run/host/usr/bin/xdg-open"
fi

echo

# Check custom xdg-open wrapper
if [ -x /usr/local/bin/xdg-open-host ]; then
    echo "✓ Custom xdg-open-host wrapper: Available"
else
    echo "✗ Custom xdg-open-host wrapper: Not found"
    echo "  Run the build script to install browser integration"
    exit 1
fi

if [ -L /usr/bin/xdg-open ] && readlink /usr/bin/xdg-open | grep -q xdg-open-host; then
    echo "✓ System xdg-open: Properly redirected to host wrapper"
else
    echo "⚠ System xdg-open: Not redirected (may still work)"
fi

echo

# Check environment variables
if [ -n "$BROWSER" ]; then
    echo "✓ BROWSER environment variable: $BROWSER"
else
    echo "⚠ BROWSER environment variable: Not set"
fi

echo

# Test the integration
if [ $tools_found -eq 0 ]; then
    echo "✗ No host integration tools found!"
    echo "  This container may not be properly set up for host integration."
    echo "  Make sure you're using distrobox and the container was built correctly."
    exit 1
fi

echo "Testing browser integration..."
echo

# Create a test URL
TEST_URL="https://example.com"

echo "Attempting to open test URL: $TEST_URL"
echo "This should open in your host browser."
echo

read -p "Press Enter to test opening the URL, or Ctrl+C to cancel: "

echo
echo "Running: xdg-open $TEST_URL"
echo

# Clear previous debug log
> /tmp/xdg-open-debug.log 2>/dev/null || true

# Try to open the URL
if xdg-open "$TEST_URL"; then
    echo
    echo "✓ Command executed successfully!"
    echo "  Check if the URL opened in your host browser."
else
    echo
    echo "✗ Command failed!"
fi

echo
echo "Debug log:"
if [ -f /tmp/xdg-open-debug.log ]; then
    cat /tmp/xdg-open-debug.log
else
    echo "  No debug log found"
fi

echo
echo "==================================================================="
echo "Test completed!"
echo
echo "If the URL opened in your host browser, the integration is working."
echo "If not, check the debug output above for troubleshooting information."
echo
echo "Common issues:"
echo "  - Make sure you're running this inside a distrobox container"
echo "  - Ensure the container was created with proper host integration"
echo "  - Check that a browser is installed and set as default on the host"
echo "==================================================================="
