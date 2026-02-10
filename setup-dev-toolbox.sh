#!/usr/bin/env bash

# MangosteenOS Developer Toolbox Setup
# Handles build, create, and export in one command

set -e  # Exit on error

# Configuration
CONTAINER_NAME="devtoolbox"
IMAGE_NAME="localhost/devtoolbox"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    figlet -w 999 -f "Soft" "MangosteenOS" 2>/dev/null || echo "MangosteenOS - Developer Toolbox Setup"
    echo
    echo "Developer Toolbox Setup"
    echo
    echo "Usage: $0 [OPTIONS] [IDE1,IDE2,...] [LSP:server1,server2,...]"
    echo
    echo "Available IDEs:"
    echo "  zed         - Zed editor"
    echo "  vscode      - Visual Studio Code"
    echo "  windsurf    - Windsurf editor"
    echo "  cursor      - Cursor editor"
    echo "  jetbrains   - JetBrains Toolbox"
    echo "  neovim      - Neovim"
    echo "  helix       - Helix"
    echo "  emacs       - Emacs"
    echo "  all         - All IDEs (default)"
    echo
    echo "Language Servers (for neovim/helix):"
    echo "  typescript  - TypeScript/JavaScript"
    echo "  python      - Python (pyright)"
    echo "  rust        - Rust (rust-analyzer)"
    echo "  go          - Go (gopls)"
    echo "  clang       - C/C++ (clangd)"
    echo "  lua         - Lua"
    echo "  bash        - Bash"
    echo "  html        - HTML"
    echo "  css         - CSS"
    echo "  json        - JSON"
    echo "  yaml        - YAML"
    echo "  docker      - Dockerfile"
    echo "  markdown    - Markdown"
    echo "  all         - All language servers"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force recreation of existing container"
    echo "  -n, --no-export Skip application export step"
    echo "  -v, --verbose  Verbose output"
    echo "  -d, --debug    Enable debug mode with detailed diagnostics"
    echo "  -i, --interactive Interactive IDE selection menu"
    echo "  --mount-containers  Mount host Docker/Podman sockets (may interfere with export)"
    echo
    echo "Examples:"
    echo "  $0                                  # Interactive menu (if no IDEs specified)"
    echo "  $0 -i                               # Force interactive menu"
    echo "  $0 zed                              # Install Zed only"
    echo "  $0 neovim LSP:typescript,python     # Install Neovim with TypeScript and Python LSP"
    echo "  $0 helix LSP:rust,clang             # Install Helix with Rust and C/C++ LSP"
    echo "  $0 vscode,cursor                    # Install VS Code and Cursor"
    echo "  $0 jetbrains,zed,cursor             # Install multiple IDEs"
    echo "  $0 --force all                      # Reinstall everything"
    echo "  $0 --no-export zed                  # Build and create only, skip export"
    echo "  $0 --debug cursor                   # Debug mode with diagnostics"
    echo
    echo "What this script does:"
    echo "  1. Builds container with selected IDEs"
    echo "  2. Creates distrobox container"
    echo "  3. Exports applications to host system"
    echo
    echo "Browser Integration:"
    echo "  --test-browser     Test browser integration after setup"
    echo "  --fix-browser      Fix browser integration issues"
}

# Interactive IDE selection using gum (preferred) or whiptail (fallback)
interactive_ide_selection() {
    log_info "Starting developer toolbox setup..."
    echo

    # Check which tool is available
    if command -v gum &>/dev/null; then
        interactive_gum_selection
    elif command -v whiptail &>/dev/null; then
        interactive_whiptail_selection
    elif command -v dialog &>/dev/null; then
        interactive_dialog_selection
    else
        log_error "No interactive menu tool found (gum, whiptail, or dialog)"
        echo
        log_error "NOTE: This should NOT happen on MangosteenOS, as the required"
        log_error "dependencies are included with the OS install. If you are seeing"
        log_error "this on MangosteenOS, please open an issue."
        echo
        log_info "On other systems, please install one of the following:"
        log_info "  • gum:      brew install gum  (or)  dnf install gum"
        log_info "  • whiptail: dnf install newt"
        log_info "  • dialog:   dnf install dialog"
        echo
        log_info "Alternatively, specify IDEs directly: $0 zed,cursor"
        exit 1
    fi
}

# Interactive selection using gum
interactive_gum_selection() {
    log_info "Using gum for interactive selection"
    echo
    echo "Select IDEs to install (Space to select, Enter to confirm):"
    echo

    local selected_ide_guis=$(gum choose --no-limit \
        --header="Select one or more IDEs:" \
        --selected="zed" \
        "zed" \
        "vscode" \
        "windsurf" \
        "cursor" \
        "jetbrains" \
        "all")

    local selected_ide_clis=$(gum choose --no-limit \
        --header="Select one or more CLI IDEs:" \
        --selected="neovim" \
        "neovim" \
        "emacs" \
        "helix" \
        "all")

    # Check if at least one category has selections
    if [ -z "$selected_ide_guis" ] && [ -z "$selected_ide_clis" ]; then
        log_error "No IDEs selected. Exiting."
        exit 1
    fi

    # Convert newline-separated output to comma-separated
    if [ -n "$selected_ide_guis" ]; then
        GUI_IDES=$(echo "$selected_ide_guis" | tr '\n' ',' | sed 's/,$//')
        log_success "Selected GUI IDEs: $GUI_IDES"
    else
        log_warning "No GUI IDEs selected."
        GUI_IDES=""
    fi

    if [ -n "$selected_ide_clis" ]; then
        CLI_IDES=$(echo "$selected_ide_clis" | tr '\n' ',' | sed 's/,$//')
        log_success "Selected CLI IDEs: $CLI_IDES"
    else
        log_warning "No CLI IDEs selected."
        CLI_IDES=""
    fi

    # Check if neovim or helix was selected for LSP prompt
    if echo "$CLI_IDES" | grep -qE "(neovim|helix)"; then
        echo
        echo "Language Server Selection for Neovim/Helix:"
        echo
        local selected_lsp=$(gum choose --no-limit \
            --header="Select language servers to install (optional):" \
            "typescript" \
            "python" \
            "rust" \
            "go" \
            "clang" \
            "lua" \
            "bash" \
            "html" \
            "css" \
            "json" \
            "yaml" \
            "docker" \
            "markdown" \
            "all")

        if [ -n "$selected_lsp" ]; then
            LSP_SERVERS=$(echo "$selected_lsp" | tr '\n' ',' | sed 's/,$//')
            log_success "Selected language servers: $LSP_SERVERS"
        else
            log_info "No language servers selected"
            LSP_SERVERS=""
        fi
    fi

    # Combine GUI and CLI IDE selections
    if [ -n "$GUI_IDES" ] && [ -n "$CLI_IDES" ]; then
        IDES="${GUI_IDES},${CLI_IDES}"
    elif [ -n "$GUI_IDES" ]; then
        IDES="$GUI_IDES"
    elif [ -n "$CLI_IDES" ]; then
        IDES="$CLI_IDES"
    fi

    echo
}

# Test browser integration
test_browser_integration() {
    log_info "Testing browser integration..."

    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' not found"
        return 1
    fi

    echo "Testing xdg-open functionality in container..."
    distrobox enter "$CONTAINER_NAME" -- bash -c '
        echo "=== Browser Integration Test ==="
        echo "1. Testing xdg-open wrapper..."
        if command -v xdg-open >/dev/null 2>&1; then
            echo "✅ xdg-open found at: $(which xdg-open)"
        else
            echo "❌ xdg-open not found"
            exit 1
        fi

        echo "2. Testing distrobox-host-exec..."
        if command -v distrobox-host-exec >/dev/null 2>&1; then
            echo "✅ distrobox-host-exec available"
            echo "   Testing host command execution..."
            if distrobox-host-exec echo "Host command test successful" 2>/dev/null; then
                echo "✅ Host command execution works"
            else
                echo "❌ Host command execution failed"
            fi
        else
            echo "❌ distrobox-host-exec not available"
        fi

        echo "3. Testing browser environment..."
        echo "   BROWSER=$BROWSER"
        echo "   XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"

        echo "4. Testing URL opening (this should open GitHub in your host browser)..."
        echo "   If a browser opens, the integration is working!"
        xdg-open "https://github.com" &
        sleep 2

        echo "=== Test Complete ==="
        echo "Check above for any errors and verify browser opened on host"
    '
}

# Fix browser integration issues
fix_browser_integration() {
    log_info "Fixing browser integration..."

    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' not found"
        return 1
    fi

    log_info "Recreating xdg-open wrapper with enhanced compatibility..."
    distrobox enter "$CONTAINER_NAME" -- bash -c '
        # Backup existing xdg-open
        if [ -f /usr/bin/xdg-open ] && [ ! -f /usr/bin/xdg-open.orig ]; then
            sudo cp /usr/bin/xdg-open /usr/bin/xdg-open.orig
        fi

        # Create enhanced xdg-open wrapper
        sudo tee /usr/local/bin/xdg-open-host > /dev/null << "WRAPPER_EOF"
#!/bin/bash
# Enhanced xdg-open wrapper for distrobox
LOG_FILE="/tmp/xdg-open-$(date +%Y%m%d).log"
echo "$(date): xdg-open called with: $*" >> "$LOG_FILE"

# Try distrobox-host-exec first (most reliable)
if command -v distrobox-host-exec >/dev/null 2>&1; then
    echo "$(date): Trying distrobox-host-exec" >> "$LOG_FILE"
    if timeout 10 distrobox-host-exec xdg-open "$@" 2>>"$LOG_FILE"; then
        echo "$(date): Success via distrobox-host-exec" >> "$LOG_FILE"
        exit 0
    fi
fi

# Try host-spawn if available
if command -v host-spawn >/dev/null 2>&1; then
    echo "$(date): Trying host-spawn" >> "$LOG_FILE"
    if timeout 10 host-spawn xdg-open "$@" 2>>"$LOG_FILE"; then
        echo "$(date): Success via host-spawn" >> "$LOG_FILE"
        exit 0
    fi
fi

# Fallback: show URL to user
echo "========================================="
echo "⚠️  Browser integration issue detected"
echo "========================================="
echo "Please copy this URL to your browser:"
echo "$1"
echo "========================================="

# Try clipboard
if command -v wl-copy >/dev/null 2>&1; then
    echo "$1" | wl-copy && echo "✅ Copied to clipboard"
fi

echo "$(date): All methods failed, showed to user" >> "$LOG_FILE"
exit 0
WRAPPER_EOF

        sudo chmod +x /usr/local/bin/xdg-open-host

        # Replace system xdg-open
        sudo ln -sf /usr/local/bin/xdg-open-host /usr/bin/xdg-open
        sudo ln -sf /usr/local/bin/xdg-open-host /usr/local/bin/xdg-open

        # Set environment variables
        echo "export BROWSER=/usr/local/bin/xdg-open-host" | sudo tee -a /etc/environment

        echo "Browser integration fix applied!"
    '

    log_success "Browser integration fix completed"
    log_info "Test with: distrobox enter $CONTAINER_NAME -- xdg-open https://github.com"
}

# Debug function to diagnose export issues
debug_container_state() {
    if [ -n "$DEBUG" ]; then
        echo
        log_info "=== DEBUG: Container State Diagnostics ==="

        log_info "Container list:"
        distrobox list || true

        log_info "Container accessibility test:"
        if distrobox enter "$CONTAINER_NAME" -- echo "Container accessible" 2>/dev/null; then
            log_success "Container is accessible"
        else
            log_error "Cannot access container"
        fi

        log_info "Available applications in container:"
        distrobox enter "$CONTAINER_NAME" -- ls -la /usr/bin/ | grep -E "(zed|code|cursor|jetbrains)" || true
        distrobox enter "$CONTAINER_NAME" -- ls -la /usr/local/bin/ | grep -E "(zed|code|cursor|jetbrains)" || true

        log_info "Desktop entries in container:"
        distrobox enter "$CONTAINER_NAME" -- ls -la /usr/share/applications/ | grep -E "(zed|code|cursor|jetbrains)" || true

        echo "=== END DEBUG ==="
        echo
    fi
}

# Build container
build_container() {
    local ides="$1"
    local lsp="$2"

    log_info "Building container with IDEs: $ides"
    if [ -n "$lsp" ]; then
        log_info "Language servers: $lsp"
    fi

    if [ -n "$VERBOSE" ]; then
        if [ -n "$lsp" ]; then
            podman build . --build-arg IDE="$ides" --build-arg LSP="$lsp" -t "$IMAGE_NAME"
        else
            podman build . --build-arg IDE="$ides" -t "$IMAGE_NAME"
        fi
    else
        if [ -n "$lsp" ]; then
            podman build . --build-arg IDE="$ides" --build-arg LSP="$lsp" -t "$IMAGE_NAME" --quiet
        else
            podman build . --build-arg IDE="$ides" -t "$IMAGE_NAME" --quiet
        fi
    fi

    if [ $? -eq 0 ]; then
        log_success "Container built successfully"
    else
        log_error "Container build failed"
        exit 1
    fi
}

# Create distrobox container
create_distrobox() {
    log_info "Creating distrobox container..."

    # Check if container already exists
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        if [ -n "$FORCE" ]; then
            log_warning "Container exists, removing due to --force flag"
            distrobox rm "$CONTAINER_NAME" --force
        else
            log_warning "Container '$CONTAINER_NAME' already exists"
            echo -n "Do you want to recreate it? (y/N): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                log_info "Removing existing container"
                distrobox rm "$CONTAINER_NAME" --force
            else
                log_info "Keeping existing container"
                return 0
            fi
        fi
    fi

    log_info "Creating new distrobox container"
    
    # Start building the distrobox command
    # Use array to properly handle arguments with spaces
    DISTROBOX_ARGS=(
        "create"
        "-n" "$CONTAINER_NAME"
        "-i" "$IMAGE_NAME"
        "--volume" "/home/linuxbrew/.linuxbrew:/home/linuxbrew/.linuxbrew"
    )
    
    # Add Docker/Podman socket mounts only if explicitly requested
    # Note: Socket mounting may interfere with distrobox export, so it's opt-in
    if [ -n "$MOUNT_CONTAINERS" ]; then
        # Add Docker socket mount if available
        if [ -e /var/run/docker.sock ]; then
            log_info "Mounting Docker socket for host Docker access"
            DISTROBOX_ARGS+=("--volume" "/var/run/docker.sock:/var/run/docker.sock")
        fi
        
        # Add Podman socket mount if available
        # Check multiple common locations for Podman socket
        PODMAN_SOCKET=""
        PODMAN_SOCKET_SOURCE=""
        
        # Check system-wide socket first
        if [ -e /run/podman/podman.sock ]; then
            # If it's a symlink, resolve it
            if [ -L /run/podman/podman.sock ]; then
                REAL_SOCKET=$(readlink -f /run/podman/podman.sock 2>/dev/null || readlink /run/podman/podman.sock 2>/dev/null)
                if [ -n "$REAL_SOCKET" ] && [ -e "$REAL_SOCKET" ]; then
                    PODMAN_SOCKET_SOURCE="$REAL_SOCKET"
                    PODMAN_SOCKET="/run/podman/podman.sock"
                else
                    # Symlink exists but target doesn't, use the symlink itself
                    PODMAN_SOCKET_SOURCE="/run/podman/podman.sock"
                    PODMAN_SOCKET="/run/podman/podman.sock"
                fi
            else
                # Regular file or socket
                PODMAN_SOCKET_SOURCE="/run/podman/podman.sock"
                PODMAN_SOCKET="/run/podman/podman.sock"
            fi
        fi
        
        # Check user-specific socket location if system-wide not found
        if [ -z "$PODMAN_SOCKET" ] && [ -e /run/user/$(id -u)/podman/podman.sock ]; then
            PODMAN_SOCKET_SOURCE="/run/user/$(id -u)/podman/podman.sock"
            PODMAN_SOCKET="/run/podman/podman.sock"
        fi
        
        # Mount Podman socket if found
        if [ -n "$PODMAN_SOCKET" ] && [ -n "$PODMAN_SOCKET_SOURCE" ]; then
            log_info "Mounting Podman socket for host Podman access: $PODMAN_SOCKET_SOURCE -> $PODMAN_SOCKET"
            DISTROBOX_ARGS+=("--volume" "$PODMAN_SOCKET_SOURCE:$PODMAN_SOCKET")
        else
            log_info "Podman socket not found (checked /run/podman/podman.sock and /run/user/$(id -u)/podman/podman.sock)"
        fi
    else
        log_info "Skipping Docker/Podman socket mounts (use --mount-containers to enable)"
    fi
    
    # Add standard flags
    DISTROBOX_ARGS+=(
        "--additional-flags" "--hostname $CONTAINER_NAME"
        "--additional-flags" "--userns=keep-id"
        "--additional-flags" "--security-opt=label=disable"
        "--additional-flags" "--device=/dev/dri"
        "--yes"
    )
    
    # Execute distrobox create
    if distrobox "${DISTROBOX_ARGS[@]}"; then
        log_success "Distrobox container created successfully"
        
        # Configure hostname resolution only if container sockets are mounted
        if [ -n "$MOUNT_CONTAINERS" ]; then
            log_info "Configuring host access hostnames..."
            distrobox enter "$CONTAINER_NAME" -- bash -c '
                # Get host IP from gateway (fallback to common Docker gateway)
                HOST_IP=$(ip route | grep default | awk "{print \$3}" | head -n1 2>/dev/null || echo "172.17.0.1")
                
                # Add hostname entries if they don't exist (non-destructive)
                if [ -n "$HOST_IP" ] && [ "$HOST_IP" != "" ]; then
                    if ! grep -q "host.docker.internal" /etc/hosts 2>/dev/null; then
                        echo "$HOST_IP host.docker.internal" | sudo tee -a /etc/hosts > /dev/null 2>&1 || true
                    fi
                    
                    if ! grep -q "host.containers.internal" /etc/hosts 2>/dev/null; then
                        echo "$HOST_IP host.containers.internal" | sudo tee -a /etc/hosts > /dev/null 2>&1 || true
                    fi
                fi
            ' 2>/dev/null || log_info "Hostname configuration skipped (optional feature)"
        fi
        
    else
        log_error "Failed to create distrobox container"
        exit 1
    fi
}

# Export applications
export_applications() {
    local ides="$1"

    if [ -n "$NO_EXPORT" ]; then
        log_info "Skipping application export (--no-export flag)"
        return 0
    fi

    log_info "Exporting applications to host system..."

    # Verify container is running and accessible
    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' not found"
        log_info "Available containers:"
        distrobox list
        return 1
    fi

    # Wait a moment for container to be ready
    log_info "Waiting for container to be ready..."
    sleep 3

    local export_result=0

    case "$ides" in
        "all")
            if ! export_all_available; then
                log_error "Failed to export all applications"
                export_result=1
            fi
            ;;
        *)
            if [[ "$ides" == *","* ]]; then
                if ! export_multiple_ides "$ides"; then
                    log_error "Failed to export some applications"
                    export_result=1
                fi
            else
                if ! export_single_ide "$ides"; then
                    log_error "Failed to export application: $ides"
                    export_result=1
                fi
            fi
            ;;
    esac

    if [ $export_result -eq 0 ]; then
        log_success "Application export completed successfully"
    else
        log_warning "Application export completed with some failures"
        log_info "Check above for specific error details"
    fi

    return $export_result
}

# Export all available IDEs
export_all_available() {
    log_info "Detecting and exporting all installed IDEs..."

    local exported_count=0
    local failed_count=0

    # Check each IDE and export if available
    if distrobox enter "$CONTAINER_NAME" -- which zed >/dev/null 2>&1; then
        log_info "Exporting Zed..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app zed; then
            ((exported_count++))
            log_success "Zed exported successfully"
        else
            log_error "Failed to export Zed"
            ((failed_count++))
        fi
    else
        log_info "Zed not installed, skipping"
    fi

    if distrobox enter "$CONTAINER_NAME" -- which code >/dev/null 2>&1; then
        log_info "Exporting VS Code..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app code; then
            ((exported_count++))
            log_success "VS Code exported successfully"
        else
            log_error "Failed to export VS Code"
            ((failed_count++))
        fi
    else
        log_info "VS Code not installed, skipping"
    fi

    if distrobox enter "$CONTAINER_NAME" -- which cursor >/dev/null 2>&1; then
        log_info "Exporting Cursor..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app cursor; then
            ((exported_count++))
            log_success "Cursor exported successfully"
        else
            log_error "Failed to export Cursor"
            ((failed_count++))
        fi
    else
        log_info "Cursor not installed, skipping"
    fi

    if distrobox enter "$CONTAINER_NAME" -- which windsurf >/dev/null 2>&1; then
        log_info "Exporting Windsurf..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app windsurf; then
            ((exported_count++))
            log_success "Windsurf exported successfully"
        else
            log_error "Failed to export Windsurf"
            ((failed_count++))
        fi
    else
        log_info "Windsurf not installed, skipping"
    fi

    if distrobox enter "$CONTAINER_NAME" -- which jetbrains-toolbox >/dev/null 2>&1; then
        log_info "Exporting JetBrains Toolbox..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app jetbrains-toolbox; then
            ((exported_count++))
            log_success "JetBrains Toolbox exported successfully"
        else
            log_error "Failed to export JetBrains Toolbox"
            ((failed_count++))
        fi
    else
        log_info "JetBrains Toolbox not installed, skipping"
    fi

    # Check and export CLI IDEs
    if distrobox enter "$CONTAINER_NAME" -- which nvim >/dev/null 2>&1; then
        log_info "Exporting Neovim..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/nvim --export-path ~/.local/bin; then
            ((exported_count++))
            log_success "Neovim exported successfully"
        else
            log_error "Failed to export Neovim"
            ((failed_count++))
        fi
    else
        log_info "Neovim not installed, skipping"
    fi

    if distrobox enter "$CONTAINER_NAME" -- which emacs >/dev/null 2>&1; then
        log_info "Exporting Emacs..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/emacs --export-path ~/.local/bin; then
            ((exported_count++))
            log_success "Emacs exported successfully"
        else
            log_error "Failed to export Emacs"
            ((failed_count++))
        fi
    else
        log_info "Emacs not installed, skipping"
    fi

    if distrobox enter "$CONTAINER_NAME" -- which helix >/dev/null 2>&1 || distrobox enter "$CONTAINER_NAME" -- which hx >/dev/null 2>&1; then
        log_info "Exporting Helix..."
        if distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/hx --export-path ~/.local/bin; then
            ((exported_count++))
            log_success "Helix exported successfully"
        else
            log_error "Failed to export Helix"
            ((failed_count++))
        fi
    else
        log_info "Helix not installed, skipping"
    fi

    log_success "Exported $exported_count IDE(s)"
    if [ $failed_count -gt 0 ]; then
        log_warning "$failed_count export(s) failed"
        return 1
    fi
    return 0
}

# Export multiple IDEs
export_multiple_ides() {
    local ides="$1"

    log_info "Exporting multiple IDEs: $ides"

    IFS=',' read -ra IDE_ARRAY <<< "$ides"
    local exported_count=0
    local failed_exports=()

    for ide in "${IDE_ARRAY[@]}"; do
        ide=$(echo "$ide" | xargs)  # Trim whitespace
        if [ -n "$ide" ]; then
            log_info "Attempting to export: $ide"
            if export_single_ide "$ide"; then
                ((exported_count++))
                log_success "Successfully exported: $ide"
            else
                log_warning "Failed to export: $ide"
                failed_exports+=("$ide")
            fi
        fi
    done

    if [ ${#failed_exports[@]} -gt 0 ]; then
        log_warning "Some exports failed: ${failed_exports[*]}"
        log_info "Successfully exported: $exported_count IDE(s)"

        # Debug mode: show more details about failures
        if [ -n "$DEBUG" ]; then
            log_info "=== DEBUG: Export failure details ==="
            for failed_ide in "${failed_exports[@]}"; do
                log_info "Checking failed IDE: $failed_ide"
                case "${failed_ide,,}" in
                    "zed")
                        distrobox enter "$CONTAINER_NAME" -- which zed || log_error "zed command not found"
                        ;;
                    "vscode"|"code")
                        distrobox enter "$CONTAINER_NAME" -- which code || log_error "code command not found"
                        ;;
                    "cursor")
                        distrobox enter "$CONTAINER_NAME" -- which cursor || log_error "cursor command not found"
                        ;;
                    "windsurf")
                        distrobox enter "$CONTAINER_NAME" -- which windsurf || log_error "windsurf command not found"
                        ;;
                    "jetbrains"|"toolbox")
                        distrobox enter "$CONTAINER_NAME" -- which jetbrains-toolbox || log_error "jetbrains-toolbox command not found"
                        ;;
                    "neovim"|"nvim")
                        distrobox enter "$CONTAINER_NAME" -- which nvim || log_error "nvim command not found"
                        ;;
                    "emacs")
                        distrobox enter "$CONTAINER_NAME" -- which emacs || log_error "emacs command not found"
                        ;;
                    "helix"|"hx")
                        distrobox enter "$CONTAINER_NAME" -- which hx || log_error "hx command not found"
                        ;;
                esac
            done
            log_info "=== END DEBUG ==="
        fi

        return 0  # Don't fail the entire installation for export failures
    else
        log_success "Exported all $exported_count IDE(s) successfully"
    fi
}

# Export single IDE
export_single_ide() {
    local ide="$1"

    case "${ide,,}" in
        "zed")
            if distrobox enter "$CONTAINER_NAME" -- which zed >/dev/null 2>&1; then
                log_info "Exporting Zed..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app zed; then
                    return 0
                else
                    log_error "Failed to export Zed application"
                    return 1
                fi
            else
                log_warning "Zed not found in container, skipping export"
                return 1
            fi
            ;;
        "vscode"|"code")
            if distrobox enter "$CONTAINER_NAME" -- which code >/dev/null 2>&1; then
                log_info "Exporting VS Code..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app code; then
                    return 0
                else
                    log_error "Failed to export VS Code application"
                    return 1
                fi
            else
                log_warning "VS Code not found in container, skipping export"
                return 1
            fi
            ;;
        "cursor")
            if distrobox enter "$CONTAINER_NAME" -- which cursor >/dev/null 2>&1; then
                log_info "Exporting Cursor..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app cursor; then
                    return 0
                else
                    log_error "Failed to export Cursor application"
                    return 1
                fi
            else
                log_warning "Cursor not found in container, skipping export"
                return 1
            fi
            ;;
        "windsurf")
            if distrobox enter "$CONTAINER_NAME" -- which windsurf >/dev/null 2>&1; then
                log_info "Exporting Windsurf..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app windsurf; then
                    return 0
                else
                    log_error "Failed to export Windsurf application"
                    return 1
                fi
            else
                log_warning "Windsurf not found in container, skipping export"
                return 1
            fi
        ;;
        "jetbrains"|"toolbox")
            if distrobox enter "$CONTAINER_NAME" -- which jetbrains-toolbox >/dev/null 2>&1; then
                log_info "Exporting JetBrains Toolbox..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --app jetbrains-toolbox; then
                    return 0
                else
                    log_error "Failed to export JetBrains Toolbox application"
                    return 1
                fi
            else
                log_warning "JetBrains Toolbox not found in container, skipping export"
                return 1
            fi
            ;;
        "neovim"|"nvim")
            if distrobox enter "$CONTAINER_NAME" -- which nvim >/dev/null 2>&1; then
                log_info "Exporting Neovim..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/nvim --export-path ~/.local/bin; then
                    return 0
                else
                    log_error "Failed to export Neovim binary"
                    return 1
                fi
            else
                log_warning "Neovim not found in container, skipping export"
                return 1
            fi
            ;;
        "emacs")
            if distrobox enter "$CONTAINER_NAME" -- which emacs >/dev/null 2>&1; then
                log_info "Exporting Emacs..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/emacs --export-path ~/.local/bin; then
                    return 0
                else
                    log_error "Failed to export Emacs binary"
                    return 1
                fi
            else
                log_warning "Emacs not found in container, skipping export"
                return 1
            fi
            ;;
        "helix"|"hx")
            if distrobox enter "$CONTAINER_NAME" -- which hx >/dev/null 2>&1; then
                log_info "Exporting Helix..."
                if distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/hx --export-path ~/.local/bin; then
                    return 0
                else
                    log_error "Failed to export Helix binary"
                    return 1
                fi
            else
                log_warning "Helix not found in container, skipping export"
                return 1
            fi
            ;;
        *)
            log_error "Unknown IDE: $ide"
            return 1
            ;;
    esac
}

# Show completion message
show_completion() {
    local ides="$1"

    echo
    figlet -w 999 -f "Soft" "MangosteenOS" 2>/dev/null || echo "MangosteenOS"
    echo "════════════════════════════════════════════════════════════════"
    log_success "IDE Installation Complete!"
    echo "════════════════════════════════════════════════════════════════"
    echo
    echo "📦 Installed IDEs: $ides"
    echo "🔧 Container: $CONTAINER_NAME"
    echo "🖼️  Image: $IMAGE_NAME"
    echo
    echo "🚀 Your IDEs are now available:"
    echo "   • From Applications menu (GUI)"
    echo "   • From command line (terminal)"
    echo "   • Integrated with your host system"
    echo
    echo "💡 Useful commands:"
    echo "   distrobox enter $CONTAINER_NAME    # Enter container"
    echo "   distrobox list                     # List containers"
    echo "   podman images                      # List images"
    echo
    echo "🔄 To reinstall or update:"
    echo "   $0 --force $ides"
    echo
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo
        log_error "Installation failed with exit code: $exit_code"
        echo
        echo "💡 Troubleshooting tips:"
        echo "   • Run with --verbose for more details: $0 --verbose $IDES"
        echo "   • Check container status: distrobox list"
        echo "   • Check container logs: podman logs \$(podman ps -a -q --filter ancestor=$IMAGE_NAME)"
        echo "   • Try --force to recreate everything: $0 --force $IDES"
        echo "   • For JetBrains issues: ./troubleshoot-jetbrains.sh"
        echo "   • Manual export: distrobox enter $CONTAINER_NAME -- distrobox-export --app [app_name]"
    fi
}

trap cleanup EXIT

# Parse command line arguments
IDES=""
LSP_SERVERS=""
FORCE=""
NO_EXPORT=""
VERBOSE=""
DEBUG=""
INTERACTIVE=""
MOUNT_CONTAINERS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -f|--force)
            FORCE="1"
            shift
            ;;
        -n|--no-export)
            NO_EXPORT="1"
            shift
            ;;
        -v|--verbose)
            VERBOSE="1"
            shift
            ;;
        -d|--debug)
            DEBUG="1"
            VERBOSE="1"  # Debug mode implies verbose
            shift
            ;;
        -i|--interactive)
            INTERACTIVE="1"
            shift
            ;;
        --test-browser)
            test_browser_integration
            exit 0
            ;;
        --fix-browser)
            fix_browser_integration
            exit 0
            ;;
        LSP:*|lsp:*)
            LSP_SERVERS="${1#LSP:}"
            LSP_SERVERS="${LSP_SERVERS#lsp:}"
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            echo
            show_usage
            exit 1
            ;;
        *)
            IDES="$1"
            shift
            ;;
    esac
done

# If no IDEs specified and not explicitly non-interactive, use interactive mode
if [ -z "$IDES" ] || [ -n "$INTERACTIVE" ]; then
    interactive_ide_selection
fi

# Default to "all" if still no IDEs specified (shouldn't happen with interactive mode)
if [ -z "$IDES" ]; then
    IDES="all"
fi

# Main execution
main() {
    figlet -w 999 -f "Soft" "MangosteenOS" 2>/dev/null || echo "MangosteenOS"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "Developer Toolbox Setup"
    echo "═══════════════════════════════════════════════════════════════════"
    echo

    # Change to script directory
    cd "$SCRIPT_DIR" || {
        log_error "Could not change to script directory: $SCRIPT_DIR"
        exit 1
    }

    # Check if we have the necessary files
    if [ ! -f "scripts/build.sh" ] || [ ! -f "Containerfile" ]; then
        log_error "Required files not found. Make sure you're in the developer-toolbox directory."
        exit 1
    fi

    log_info "Installing IDEs: $IDES"
    if [ -n "$LSP_SERVERS" ]; then
        log_info "Language servers: $LSP_SERVERS"
    fi
    if [ -n "$FORCE" ]; then
        log_info "Force mode enabled - will recreate existing containers"
    fi
    if [ -n "$NO_EXPORT" ]; then
        log_info "Export disabled - will build and create container only"
    fi
    if [ -n "$VERBOSE" ]; then
        log_info "Verbose mode enabled"
    fi
    if [ -n "$DEBUG" ]; then
        log_info "Debug mode enabled - detailed diagnostics will be shown"
    fi
    echo

    # Execute installation steps
    build_container "$IDES" "$LSP_SERVERS"
    create_distrobox

    # Debug container state before export
    debug_container_state

    export_applications "$IDES"

    show_completion "$IDES"
}

# Run main function
main
