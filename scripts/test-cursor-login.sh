#!/bin/bash
# Test script to simulate Cursor login URL opening
# This demonstrates the browser integration feature

set -e

echo "==================================================================="
echo "Cursor Login Browser Integration Test"
echo "==================================================================="
echo
echo "This script simulates what happens when Cursor tries to open"
echo "a login URL. It should open in your host browser."
echo

# Check if we're in the right environment
if [ ! -f /run/.containerenv ]; then
    echo "⚠ Warning: This script is designed to run inside a distrobox container"
    echo "   You may want to run it from inside the devtoolbox container:"
    echo "   distrobox enter devtoolbox -- test-cursor-login"
    echo
fi

# Simulate Cursor's login URL
CURSOR_LOGIN_URL="https://www.cursor.com/settings"
GITHUB_AUTH_URL="https://github.com/login/oauth/authorize?client_id=example&scope=user:email"

echo "Testing Cursor-like URL opening scenarios:"
echo

# Test 1: Settings page
echo "1. Testing Cursor settings page URL..."
echo "   URL: $CURSOR_LOGIN_URL"
read -p "   Press Enter to open this URL: "
echo "   Running: xdg-open '$CURSOR_LOGIN_URL'"
if xdg-open "$CURSOR_LOGIN_URL"; then
    echo "   ✓ Command executed"
else
    echo "   ✗ Command failed"
fi
echo

# Test 2: GitHub OAuth (common for Cursor login)
echo "2. Testing GitHub OAuth URL (common for IDE authentication)..."
echo "   URL: $GITHUB_AUTH_URL"
read -p "   Press Enter to open this URL: "
echo "   Running: xdg-open '$GITHUB_AUTH_URL'"
if xdg-open "$GITHUB_AUTH_URL"; then
    echo "   ✓ Command executed"
else
    echo "   ✗ Command failed"
fi
echo

# Test 3: Using BROWSER environment variable
echo "3. Testing BROWSER environment variable method..."
if [ -n "$BROWSER" ]; then
    echo "   BROWSER is set to: $BROWSER"
    read -p "   Press Enter to test BROWSER variable: "
    echo "   Running: \$BROWSER '$CURSOR_LOGIN_URL'"
    if $BROWSER "$CURSOR_LOGIN_URL"; then
        echo "   ✓ BROWSER command executed"
    else
        echo "   ✗ BROWSER command failed"
    fi
else
    echo "   ⚠ BROWSER environment variable is not set"
fi
echo

# Show debug information
echo "Debug Information:"
echo "=================="
echo "Container info:"
if [ -f /run/.containerenv ]; then
    echo "  ✓ Running in container"
    echo "  Container ID: $(cat /proc/self/cgroup | head -1 | sed 's/.*\///' | cut -c1-12 2>/dev/null || echo 'unknown')"
else
    echo "  ✗ Not in container"
fi
echo

echo "Available host integration tools:"
for tool in distrobox-host-exec host-spawn flatpak-spawn; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool"
    fi
done
echo

echo "xdg-open configuration:"
if [ -L /usr/bin/xdg-open ]; then
    echo "  System xdg-open: $(readlink /usr/bin/xdg-open)"
else
    echo "  System xdg-open: $(which xdg-open 2>/dev/null || echo 'not found')"
fi

if [ -x /usr/local/bin/xdg-open-host ]; then
    echo "  Custom wrapper: /usr/local/bin/xdg-open-host (available)"
else
    echo "  Custom wrapper: /usr/local/bin/xdg-open-host (missing)"
fi
echo

echo "Recent debug log:"
if [ -f /tmp/xdg-open-debug.log ]; then
    echo "  Last 5 entries from /tmp/xdg-open-debug.log:"
    tail -5 /tmp/xdg-open-debug.log | sed 's/^/    /'
else
    echo "  No debug log found"
fi
echo

echo "==================================================================="
echo "Test Summary:"
echo ""
echo "If URLs opened successfully in your HOST browser (not in container),"
echo "then the browser integration is working correctly for Cursor and"
echo "other IDEs."
echo ""
echo "What this means for Cursor:"
echo "  • Login links will open in your host browser automatically"
echo "  • GitHub/OAuth authentication will work seamlessly"
echo "  • External documentation links will open on the host"
echo "  • No need to install browsers inside the container"
echo ""
echo "If URLs didn't open automatically, check the debug information above"
echo "and ensure you're running inside a properly configured distrobox."
echo "==================================================================="
