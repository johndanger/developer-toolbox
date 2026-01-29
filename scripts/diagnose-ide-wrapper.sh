#!/usr/bin/env bash
# Diagnostic script to check IDE wrapper and extension installation status

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     IDE Wrapper & Extension Installation Diagnostics      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_ok() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check for installed IDEs
IDES=("code" "windsurf" "cursor")

echo "═══════════════════════════════════════════════════════════"
echo "1. Checking for installed IDEs"
echo "═══════════════════════════════════════════════════════════"
echo ""

FOUND_IDES=()
for ide in "${IDES[@]}"; do
    print_check "Looking for $ide..."
    if command -v "$ide" >/dev/null 2>&1; then
        IDE_PATH=$(which "$ide")
        print_ok "$ide found at: $IDE_PATH"
        FOUND_IDES+=("$ide")
    else
        print_warning "$ide not found"
    fi
done

echo ""

if [ ${#FOUND_IDES[@]} -eq 0 ]; then
    print_error "No IDEs found! Install VS Code, Windsurf, or Cursor first."
    exit 1
fi

# Check wrapper status for each IDE
echo "═══════════════════════════════════════════════════════════"
echo "2. Checking wrapper status"
echo "═══════════════════════════════════════════════════════════"
echo ""

for ide in "${FOUND_IDES[@]}"; do
    echo "--- $ide ---"
    IDE_PATH=$(which "$ide")

    # Check if it's a symlink
    if [ -L "$IDE_PATH" ]; then
        TARGET=$(readlink "$IDE_PATH")
        if [[ "$TARGET" == *"wrapped"* ]]; then
            print_ok "Binary is wrapped (symlink to: $TARGET)"
        else
            print_warning "Binary is a symlink but not to wrapper: $TARGET"
        fi
    else
        print_warning "Binary is not a symlink (not wrapped)"
    fi

    # Check for .real binary
    REAL_PATHS=("${IDE_PATH}.real" "/usr/bin/${ide}.real" "/usr/local/bin/${ide}.real")
    FOUND_REAL=false
    for real_path in "${REAL_PATHS[@]}"; do
        if [ -f "$real_path" ]; then
            print_ok "Real binary found at: $real_path"
            FOUND_REAL=true
            break
        fi
    done

    if [ "$FOUND_REAL" = false ]; then
        print_error "Real binary (.real) not found!"
    fi

    # Check for wrapper script
    WRAPPER_PATH="/usr/local/bin/${ide}-wrapped"
    if [ -f "$WRAPPER_PATH" ]; then
        print_ok "Wrapper script exists at: $WRAPPER_PATH"
        if [ -x "$WRAPPER_PATH" ]; then
            print_ok "Wrapper script is executable"
        else
            print_error "Wrapper script is NOT executable!"
        fi
    else
        print_error "Wrapper script not found at: $WRAPPER_PATH"
    fi

    echo ""
done

# Check for extension setup script
echo "═══════════════════════════════════════════════════════════"
echo "3. Checking extension setup script"
echo "═══════════════════════════════════════════════════════════"
echo ""

SETUP_SCRIPT="/usr/local/bin/setup-ide-extensions"
if [ -f "$SETUP_SCRIPT" ]; then
    print_ok "Extension setup script exists: $SETUP_SCRIPT"
    if [ -x "$SETUP_SCRIPT" ]; then
        print_ok "Extension setup script is executable"
    else
        print_error "Extension setup script is NOT executable!"
    fi
else
    print_error "Extension setup script not found: $SETUP_SCRIPT"
fi

echo ""

# Check environment variables
echo "═══════════════════════════════════════════════════════════"
echo "4. Checking environment variables"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ -n "$DISABLE_IDE_AUTO_EXTENSIONS" ]; then
    if [ "$DISABLE_IDE_AUTO_EXTENSIONS" = "1" ] || [ "$DISABLE_IDE_AUTO_EXTENSIONS" = "true" ]; then
        print_warning "DISABLE_IDE_AUTO_EXTENSIONS is set to: $DISABLE_IDE_AUTO_EXTENSIONS"
        print_warning "Automatic extension installation is DISABLED"
    else
        print_ok "DISABLE_IDE_AUTO_EXTENSIONS is set but not to 1 or true: $DISABLE_IDE_AUTO_EXTENSIONS"
    fi
else
    print_ok "DISABLE_IDE_AUTO_EXTENSIONS is not set (auto-install enabled)"
fi

echo ""

# Check wrapper execution logs
echo "═══════════════════════════════════════════════════════════"
echo "5. Checking wrapper execution logs"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ -f "/tmp/ide-wrapper-trace.log" ]; then
    print_ok "Wrapper trace log found"
    echo ""
    echo "Recent wrapper executions:"
    echo "─────────────────────────────────────────────────────────"
    tail -10 /tmp/ide-wrapper-trace.log 2>/dev/null | sed 's/^/  /'
    echo "─────────────────────────────────────────────────────────"
else
    print_warning "No wrapper trace log found at /tmp/ide-wrapper-trace.log"
    print_warning "This means the wrapper hasn't been executed yet, or logging failed"
fi

echo ""

MARKER_COUNT=$(ls /tmp/ide-wrapper-executed-*.tmp 2>/dev/null | wc -l)
if [ "$MARKER_COUNT" -gt 0 ]; then
    print_ok "Found $MARKER_COUNT wrapper execution marker(s)"
else
    print_warning "No wrapper execution markers found"
fi

echo ""

# Check extension installation logs
echo "═══════════════════════════════════════════════════════════"
echo "6. Checking extension installation logs"
echo "═══════════════════════════════════════════════════════════"
echo ""

LOG_FILES=$(ls -t /tmp/ide-extension-setup-*.log 2>/dev/null || true)
if [ -n "$LOG_FILES" ]; then
    LOG_COUNT=$(echo "$LOG_FILES" | wc -l)
    print_ok "Found $LOG_COUNT extension installation log file(s)"
    echo ""
    echo "Most recent logs:"
    echo "─────────────────────────────────────────────────────────"
    ls -lht /tmp/ide-extension-setup-*.log 2>/dev/null | head -5 | sed 's/^/  /'
    echo "─────────────────────────────────────────────────────────"
    echo ""
    LATEST_LOG=$(ls -t /tmp/ide-extension-setup-*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        echo "Content of latest log ($LATEST_LOG):"
        echo "─────────────────────────────────────────────────────────"
        tail -20 "$LATEST_LOG" | sed 's/^/  /'
        echo "─────────────────────────────────────────────────────────"
    fi
else
    print_warning "No extension installation logs found"
    print_warning "Extensions may not have been installed yet"
fi

echo ""

# Check installed extensions
echo "═══════════════════════════════════════════════════════════"
echo "7. Checking installed extensions"
echo "═══════════════════════════════════════════════════════════"
echo ""

EXPECTED_EXTENSIONS=(
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-azuretools.vscode-docker"
    "DankLinux.dms-theme"
)

for ide in "${FOUND_IDES[@]}"; do
    echo "--- $ide extensions ---"

    if command -v "$ide" >/dev/null 2>&1; then
        INSTALLED_EXTS=$("$ide" --list-extensions 2>/dev/null || echo "")

        if [ -n "$INSTALLED_EXTS" ]; then
            for ext in "${EXPECTED_EXTENSIONS[@]}"; do
                if echo "$INSTALLED_EXTS" | grep -q "^${ext}$"; then
                    print_ok "$ext"
                else
                    print_warning "$ext (missing)"
                fi
            done
        else
            print_warning "Could not retrieve extension list (IDE may need to run first)"
        fi
    fi
    echo ""
done

# Check for running background processes
echo "═══════════════════════════════════════════════════════════"
echo "8. Checking for running background processes"
echo "═══════════════════════════════════════════════════════════"
echo ""

if pgrep -f "setup-ide-extensions" >/dev/null 2>&1; then
    print_ok "setup-ide-extensions process is currently running"
    ps aux | grep -i "setup-ide-extensions" | grep -v grep | sed 's/^/  /'
else
    print_warning "No setup-ide-extensions process currently running"
fi

echo ""

# Summary and recommendations
echo "═══════════════════════════════════════════════════════════"
echo "9. Summary and Recommendations"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ -f "/tmp/ide-wrapper-trace.log" ]; then
    print_ok "Wrappers appear to be working (trace log exists)"
else
    print_error "Wrappers may not be executing"
    echo "  → Try launching an IDE and check if /tmp/ide-wrapper-trace.log is created"
    echo ""
fi

if [ -n "$LOG_FILES" ]; then
    print_ok "Extension installation has run at least once"
    echo "  → Check the log content above to see if extensions installed successfully"
else
    print_warning "Extension installation may not have run yet"
    echo "  → Launch an IDE and wait ~15 seconds"
    echo "  → Or run manually: setup-ide-extensions"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Quick Actions:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Test wrapper manually:"
echo "   $ /usr/local/bin/code-wrapped --version"
echo ""
echo "2. Run extension setup manually:"
echo "   $ setup-ide-extensions"
echo ""
echo "3. Watch logs in real-time:"
echo "   $ tail -f /tmp/ide-wrapper-trace.log"
echo "   $ tail -f /tmp/ide-extension-setup-*.log"
echo ""
echo "4. Launch IDE and monitor:"
echo "   $ code &"
echo "   $ sleep 15 && cat /tmp/ide-extension-setup-code-*.log"
echo ""
echo "For more detailed debugging, see:"
echo "  developer-toolbox/docs/IDE_EXTENSION_DEBUG.md"
echo ""
