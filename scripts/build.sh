#!/bin/env bash

# Parse IDE selection (supports comma-separated list)
IDE_TO_INSTALL="${1:-all}"

install_common_tools() {
    echo "Installing common tools..."
    dnf install -y \
        zsh \
        fish \
        git \
        nodejs \
        wget \
        gnupg2 \
        dnf-plugins-core \
        kitty-terminfo \
        xdg-utils
}

# Create browser integration for distrobox
setup_browser_integration() {
    echo "Setting up browser integration for container..."

    # Install host-spawn if available (used by distrobox-host-exec)
    dnf install -y host-spawn 2>/dev/null || echo "host-spawn not available in repos, will use distrobox-host-exec directly"

    # Create a custom xdg-open script that forwards to host browser
    cat > /usr/local/bin/xdg-open-host << 'EOF'
#!/bin/bash
# Custom xdg-open wrapper for distrobox containers
# Forwards URL opening to the host system

# Log the attempt for debugging
echo "$(date): xdg-open-host called with: $*" >> /tmp/xdg-open-debug.log

# Function to try opening URL on host
try_host_open() {
    local url="$1"
    local method="$2"

    echo "$(date): Trying $method to open: $url" >> /tmp/xdg-open-debug.log

    case "$method" in
        "distrobox-host-exec")
            if command -v distrobox-host-exec >/dev/null 2>&1; then
                distrobox-host-exec xdg-open "$url" 2>/dev/null && return 0
            fi
            ;;
        "host-spawn")
            if command -v host-spawn >/dev/null 2>&1; then
                host-spawn xdg-open "$url" 2>/dev/null && return 0
            fi
            ;;
        "flatpak-spawn")
            if [ -n "$DISPLAY" ] && command -v flatpak-spawn >/dev/null 2>&1; then
                flatpak-spawn --host xdg-open "$url" 2>/dev/null && return 0
            fi
            ;;
        "direct-host")
            if [ -x /run/host/usr/bin/xdg-open ]; then
                /run/host/usr/bin/xdg-open "$url" 2>/dev/null && return 0
            elif [ -x /usr/bin/xdg-open.host ]; then
                /usr/bin/xdg-open.host "$url" 2>/dev/null && return 0
            fi
            ;;
    esac

    return 1
}

# Try different methods in order of preference
for method in "distrobox-host-exec" "host-spawn" "flatpak-spawn" "direct-host"; do
    if try_host_open "$1" "$method"; then
        echo "$(date): Successfully opened via $method" >> /tmp/xdg-open-debug.log
        exit 0
    fi
done

# All methods failed - show URL to user
echo "$(date): All methods failed, showing URL to user" >> /tmp/xdg-open-debug.log
echo "==================================================================="
echo "Unable to open URL automatically in host browser."
echo "Please copy and paste this URL into your host browser:"
echo ""
echo "$1"
echo ""
echo "==================================================================="

# Try to copy to clipboard if possible
if command -v wl-copy >/dev/null 2>&1; then
    echo "$1" | wl-copy 2>/dev/null && echo "(URL copied to clipboard)"
elif command -v xclip >/dev/null 2>&1; then
    echo "$1" | xclip -selection clipboard 2>/dev/null && echo "(URL copied to clipboard)"
fi

exit 0
EOF

    chmod +x /usr/local/bin/xdg-open-host

    # Replace system xdg-open with our wrapper
    if [ -f /usr/bin/xdg-open ]; then
        mv /usr/bin/xdg-open /usr/bin/xdg-open.orig
        ln -sf /usr/local/bin/xdg-open-host /usr/bin/xdg-open
    fi

    # Also create the wrapper as xdg-open in case some apps look for it specifically
    ln -sf /usr/local/bin/xdg-open-host /usr/local/bin/xdg-open

    # Set BROWSER environment variable for applications that respect it
    echo 'export BROWSER="/usr/local/bin/xdg-open-host"' >> /etc/environment

    # Create a desktop entry for URL handling
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/xdg-open-host.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Host Browser
Exec=/usr/local/bin/xdg-open-host %u
NoDisplay=true
MimeType=x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
EOF

    # Update desktop database
    update-desktop-database /usr/share/applications 2>/dev/null || true

    # Install the browser integration test scripts
    cp /ctx/scripts/test-browser-integration.sh /usr/local/bin/test-browser-integration
    chmod +x /usr/local/bin/test-browser-integration

    cp /ctx/scripts/test-cursor-login.sh /usr/local/bin/test-cursor-login
    chmod +x /usr/local/bin/test-cursor-login

    echo "Browser integration setup complete."
    echo "URLs opened by applications will now be forwarded to the host browser."
    echo "Run 'test-browser-integration' to test the setup."
    echo "Run 'test-cursor-login' to test Cursor-specific login scenarios."
}

# Create unified IDE extension setup script (called by all IDE installers)
create_unified_extension_setup() {
    # Only create once
    if [ -f /usr/local/bin/setup-ide-extensions ]; then
        return 0
    fi

    cat > /usr/local/bin/setup-ide-extensions << 'EOF'
#!/bin/bash
# Unified setup script for IDE extensions (VS Code, Windsurf, Cursor)
# Auto-detects installed IDEs and configures extensions for container development

EXTENSIONS=(
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-azuretools.vscode-docker"
    "DankLinux.dms-theme"
)

# IDE configuration: command_name, display_name, real_binary_path
declare -A IDES=(
    ["code"]="VS Code"
    ["windsurf"]="Windsurf"
    ["cursor"]="Cursor"
)

# Find the real IDE binary (unwrapped version)
find_real_ide_binary() {
    local ide_cmd="$1"

    # Check for .real version first
    if [ -f "/usr/bin/${ide_cmd}.real" ]; then
        echo "/usr/bin/${ide_cmd}.real"
    elif [ -f "/usr/local/bin/${ide_cmd}.real" ]; then
        echo "/usr/local/bin/${ide_cmd}.real"
    elif command -v "$ide_cmd" >/dev/null 2>&1; then
        which "$ide_cmd"
    else
        echo ""
    fi
}

# Check if extensions are installed for a specific IDE
check_ide_extensions() {
    local ide_binary="$1"

    if [ ! -f "$ide_binary" ]; then
        echo "0"
        return
    fi

    local installed_extensions
    installed_extensions=$("$ide_binary" --list-extensions 2>/dev/null || echo "")

    local missing=0
    for ext in "${EXTENSIONS[@]}"; do
        if ! echo "$installed_extensions" | grep -q "^${ext}$"; then
            ((missing++))
        fi
    done

    echo "$missing"
}

# Install extensions for a specific IDE
install_ide_extensions() {
    local ide_binary="$1"
    local ide_name="$2"
    local success=false

    echo "Installing $ide_name extensions for container development..."
    echo ""

    for ext in "${EXTENSIONS[@]}"; do
        # Check if already installed
        if "$ide_binary" --list-extensions 2>/dev/null | grep -q "^${ext}$"; then
            echo "  ✓ $ext (already installed)"
            success=true
        else
            echo -n "  Installing $ext... "
            local install_output
            install_output=$("$ide_binary" --install-extension "$ext" --force 2>&1)
            if echo "$install_output" | grep -q "successfully installed\|already installed\|Extension.*is already installed"; then
                echo "✓"
                success=true
            else
                echo "⚠ (failed)"
                echo "    Error: $install_output" | head -n 1
            fi
        fi
    done

    echo ""
    if [ "$success" = true ]; then
        echo "✓ $ide_name extension setup complete!"
    else
        echo "⚠ Some extensions failed to install. They will be retried on next launch."
    fi
    echo ""

    return 0
}

# Main execution: process all installed IDEs
for ide_cmd in "${!IDES[@]}"; do
    ide_binary=$(find_real_ide_binary "$ide_cmd")

    # Skip if IDE is not installed
    if [ -z "$ide_binary" ] || [ ! -f "$ide_binary" ]; then
        continue
    fi

    # Check if auto-install is disabled
    if [ "$DISABLE_IDE_AUTO_EXTENSIONS" = "1" ] || [ "$DISABLE_IDE_AUTO_EXTENSIONS" = "true" ]; then
        continue
    fi

    # Check if extensions are missing
    missing_count=$(check_ide_extensions "$ide_binary")
    if [ "$missing_count" -gt 0 ]; then
        install_ide_extensions "$ide_binary" "${IDES[$ide_cmd]}"
    fi
done

exit 0
EOF

    chmod +x /usr/local/bin/setup-ide-extensions
}

# Create wrapper script for an IDE command
create_ide_wrapper() {
    local ide_cmd="$1"
    local original_path="$2"

    # Validate inputs
    if [ -z "$ide_cmd" ] || [ -z "$original_path" ]; then
        echo "Error: IDE command or path not provided to wrapper creation"
        return 1
    fi

    # Only wrap if original exists and isn't already wrapped
    if [ ! -f "${original_path}" ]; then
        echo "Warning: ${original_path} not found, skipping wrapper creation"
        return 1
    fi

    # Check if it's a symlink pointing to our wrapper (already wrapped)
    if [ -L "${original_path}" ] && readlink "${original_path}" | grep -q "${ide_cmd}-wrapped"; then
        echo "IDE ${ide_cmd} already wrapped, skipping..."
        return 0
    fi

    if [ -f "${original_path}.real" ]; then
        echo "IDE ${ide_cmd} already has .real file, skipping..."
        return 0
    fi

    echo "Creating wrapper for ${ide_cmd} at ${original_path}..."

    # Create the wrapper script with proper variable escaping
    cat > "/usr/local/bin/${ide_cmd}-wrapped" << 'WRAPPER_EOF'
#!/bin/bash
# Wrapper for IDE to auto-install extensions on first launch

# Create a marker file to confirm wrapper was executed
touch /tmp/ide-wrapper-executed-$$.tmp

# Determine which IDE we are by checking what we're linked to
REAL_SCRIPT=$(readlink -f "$0")
SCRIPT_NAME=$(basename "$REAL_SCRIPT")
IDE_CMD="${SCRIPT_NAME%-wrapped}"

# If we couldn't determine from the script name, check the symlink
if [ -z "$IDE_CMD" ] || [ "$IDE_CMD" = "$SCRIPT_NAME" ]; then
    # Check what symlink points to us
    SYMLINK_NAME=$(basename "$(readlink -f "$0" | xargs dirname)")/$(basename "$0")
    if [[ "$SYMLINK_NAME" == *"code"* ]]; then
        IDE_CMD="code"
    elif [[ "$SYMLINK_NAME" == *"windsurf"* ]]; then
        IDE_CMD="windsurf"
    elif [[ "$SYMLINK_NAME" == *"cursor"* ]]; then
        IDE_CMD="cursor"
    fi
fi

# Find the real binary - check multiple possible locations
REAL_BINARY=""
for path in "/usr/bin/${IDE_CMD}.real" "/usr/local/bin/${IDE_CMD}.real" "/opt/${IDE_CMD}/${IDE_CMD}.real"; do
    if [ -f "$path" ]; then
        REAL_BINARY="$path"
        break
    fi
done

if [ -z "$REAL_BINARY" ]; then
    echo "Error: Real binary for ${IDE_CMD} not found!" >&2
    echo "Searched locations:" >&2
    echo "  /usr/bin/${IDE_CMD}.real" >&2
    echo "  /usr/local/bin/${IDE_CMD}.real" >&2
    echo "  /opt/${IDE_CMD}/${IDE_CMD}.real" >&2
    exit 1
fi

# Log that we found the binary and are about to start background process
echo "$(date): Wrapper executed for ${IDE_CMD}, binary: ${REAL_BINARY}" >> /tmp/ide-wrapper-trace.log

# Launch extension installer in background (properly detached from shell)
# We need to fully detach this process so it survives the exec below
if [ "$DISABLE_IDE_AUTO_EXTENSIONS" != "1" ] && [ "$DISABLE_IDE_AUTO_EXTENSIONS" != "true" ]; then
    if command -v setup-ide-extensions >/dev/null 2>&1; then
        echo "$(date): Starting background extension installer for ${IDE_CMD}" >> /tmp/ide-wrapper-trace.log
        # Fork into background with nohup and redirect all file descriptors
        # This ensures the process survives when we exec below
        nohup bash -c "
            # Wait for IDE to fully initialize
            sleep 12

            # Run extension setup and log output
            LOG_FILE=\"/tmp/ide-extension-setup-${IDE_CMD}-\$(date +%s).log\"
            echo \"=== IDE Extension Setup Log for ${IDE_CMD} ===\" > \"\$LOG_FILE\"
            echo \"Started at: \$(date)\" >> \"\$LOG_FILE\"
            echo \"\" >> \"\$LOG_FILE\"

            setup-ide-extensions >> \"\$LOG_FILE\" 2>&1

            echo \"\" >> \"\$LOG_FILE\"
            echo \"Completed at: \$(date)\" >> \"\$LOG_FILE\"

            # Keep only the 3 most recent log files
            ls -t /tmp/ide-extension-setup-${IDE_CMD}-*.log 2>/dev/null | tail -n +4 | xargs -r rm -f
        " >/dev/null 2>&1 </dev/null &

        # Disown the background job so it's not tied to this shell
        disown -a 2>/dev/null || true
        echo "$(date): Background process started for ${IDE_CMD}" >> /tmp/ide-wrapper-trace.log
    else
        echo "$(date): setup-ide-extensions not found for ${IDE_CMD}" >> /tmp/ide-wrapper-trace.log
    fi
else
    echo "$(date): Auto-extensions disabled for ${IDE_CMD}" >> /tmp/ide-wrapper-trace.log
fi

# Launch the real IDE with all arguments (foreground)
echo "$(date): Executing real binary for ${IDE_CMD}" >> /tmp/ide-wrapper-trace.log
exec "$REAL_BINARY" "$@"
WRAPPER_EOF

    chmod +x "/usr/local/bin/${ide_cmd}-wrapped"

    # Move original binary and replace with wrapper
    echo "  Moving ${original_path} to ${original_path}.real"
    if ! mv "${original_path}" "${original_path}.real"; then
        echo "Error: Failed to move ${original_path} to ${original_path}.real"
        rm -f "/usr/local/bin/${ide_cmd}-wrapped"
        return 1
    fi

    echo "  Creating symlink ${original_path} -> /usr/local/bin/${ide_cmd}-wrapped"
    if ! ln -sf "/usr/local/bin/${ide_cmd}-wrapped" "${original_path}"; then
        echo "Error: Failed to create symlink"
        mv "${original_path}.real" "${original_path}"  # Restore original
        rm -f "/usr/local/bin/${ide_cmd}-wrapped"
        return 1
    fi

    echo "✓ Wrapper created for ${ide_cmd}"
    return 0
}

install_language_servers() {
    local servers="$1"

    if [ -z "$servers" ]; then
        echo "No language servers specified, skipping..."
        return 0
    fi

    echo "Installing language servers: $servers"

    # Parse comma-separated list
    IFS=',' read -ra SERVER_LIST <<< "$servers"

    for server in "${SERVER_LIST[@]}"; do
        server=$(echo "$server" | xargs)  # Trim whitespace
        case "${server,,}" in
            "typescript"|"ts")
                echo "Installing TypeScript language server..."
                npm install -g typescript-language-server typescript
                ;;
            "html")
                echo "Installing HTML language server..."
                npm install -g vscode-langservers-extracted
                ;;
            "css")
                echo "Installing CSS language server..."
                npm install -g vscode-langservers-extracted
                ;;
            "json")
                echo "Installing JSON language server..."
                npm install -g vscode-langservers-extracted
                ;;
            "bash")
                echo "Installing Bash language server..."
                npm install -g bash-language-server
                ;;
            "python")
                echo "Installing Python language server (pyright)..."
                npm install -g pyright
                ;;
            "rust")
                echo "Installing Rust language server (rust-analyzer)..."
                dnf install -y rust-analyzer
                ;;
            "go")
                echo "Installing Go language server (gopls)..."
                dnf install -y golang
                # Allow Go to auto-download newer toolchain if needed
                GOTOOLCHAIN=auto go install golang.org/x/tools/gopls@latest || {
                    echo "Warning: gopls installation via go install failed, trying dnf package..."
                    dnf install -y golang-x-tools-gopls 2>/dev/null || {
                        echo "Warning: gopls not available via dnf, installing compatible version..."
                        # Install last version compatible with Go 1.24
                        GOTOOLCHAIN=auto go install golang.org/x/tools/gopls@v0.16.2
                    }
                }
                ;;
            "clang"|"c"|"cpp")
                echo "Installing C/C++ language server (clangd)..."
                dnf install -y clang-tools-extra
                ;;
            "lua")
                echo "Installing Lua language server..."
                dnf install -y lua-language-server
                ;;
            "yaml")
                echo "Installing YAML language server..."
                npm install -g yaml-language-server
                ;;
            "docker")
                echo "Installing Dockerfile language server..."
                npm install -g dockerfile-language-server-nodejs
                ;;
            "markdown")
                echo "Installing Markdown language server (marksman)..."
                # Download latest marksman release
                MARKSMAN_VERSION="2023-12-09"
                curl -L "https://github.com/artempyanykh/marksman/releases/download/${MARKSMAN_VERSION}/marksman-linux-x64" -o /usr/local/bin/marksman
                chmod +x /usr/local/bin/marksman
                ;;
            "all")
                echo "Installing all common language servers..."
                npm install -g typescript-language-server typescript vscode-langservers-extracted bash-language-server pyright yaml-language-server dockerfile-language-server-nodejs
                dnf install -y rust-analyzer clang-tools-extra lua-language-server
                ;;
            *)
                echo "Warning: Unknown language server '$server', skipping..."
                ;;
        esac
    done

    echo "Language server installation complete!"
}



# Function to install Zed
install_zed() {
    echo "Installing Zed..."
    dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
    # Install Zed
    dnf install -y zed
}

# Function to install VS Code
install_vscode() {
    echo "Installing VS Code..."

    # Create unified extension setup script (shared with Windsurf/Cursor)
    create_unified_extension_setup

    # Import Microsoft GPG key
    rpm --import https://packages.microsoft.com/keys/microsoft.asc

    # Add VS Code repository
    cat > /etc/yum.repos.d/vscode.repo << EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    # Install VS Code
    dnf install -y code

    # Create wrapper for VS Code command
    CODE_PATH=$(which code 2>/dev/null)
    if [ -n "$CODE_PATH" ] && [ -f "$CODE_PATH" ]; then
        create_ide_wrapper "code" "$CODE_PATH" || echo "Warning: Failed to create wrapper for VS Code"
    else
        echo "Warning: VS Code binary not found, skipping wrapper creation"
    fi

    echo ""
    echo "✓ VS Code installed successfully!"
    echo ""
    echo "Extensions will be auto-installed when you first launch VS Code."
    echo "If extensions don't install automatically, run: setup-ide-extensions"
    echo ""
}

# Function to install Windsurf
install_windsurf() {
    echo "Installing Windsurf..."

    # Import Windsurf GPG key
    rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf

    # Add Windsurf repository
    cat > /etc/yum.repos.d/windsurf.repo << EOF
[windsurf]
name=Windsurf Repository
baseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/
enabled=1
autorefresh=1
gpgcheck=1
gpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
EOF

    # Update and install Windsurf
    dnf check-update || true
    dnf install -y windsurf

    # Create unified extension setup script
    create_unified_extension_setup

    # Create wrapper for Windsurf command
    WINDSURF_PATH=$(which windsurf 2>/dev/null)
    if [ -n "$WINDSURF_PATH" ] && [ -f "$WINDSURF_PATH" ]; then
        create_ide_wrapper "windsurf" "$WINDSURF_PATH" || echo "Warning: Failed to create wrapper for Windsurf"
    else
        echo "Warning: Windsurf binary not found, skipping wrapper creation"
    fi

    echo ""
    echo "✓ Windsurf installed successfully!"
    echo ""
    echo "Extensions will be auto-installed when you first launch Windsurf."
    echo "If extensions don't install automatically, run: setup-ide-extensions"
    echo ""
}

# Function to install Cursor
install_cursor() {
    echo "Installing Cursor..."

    # Download the Cursor .rpm package for Fedora
    CURSOR_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/2.4"

    # Create temp directory
    TEMP_DIR=$(mktemp -d)

    echo "Downloading Cursor RPM package..."
    curl -L -o "$TEMP_DIR/cursor.rpm" "$CURSOR_URL"

    # Install the .rpm package
    rpm -i "$TEMP_DIR/cursor.rpm" || dnf install -y "$TEMP_DIR/cursor.rpm"

    # Cleanup
    rm -rf "$TEMP_DIR"

    echo "Cursor installed successfully!"

    # Create unified extension setup script
    create_unified_extension_setup

    # Create wrapper for Cursor command
    CURSOR_PATH=$(which cursor 2>/dev/null)
    if [ -n "$CURSOR_PATH" ] && [ -f "$CURSOR_PATH" ]; then
        create_ide_wrapper "cursor" "$CURSOR_PATH" || echo "Warning: Failed to create wrapper for Cursor"
    else
        echo "Warning: Cursor binary not found, skipping wrapper creation"
    fi

    echo ""
    echo "✓ Cursor installed successfully!"
    echo ""
    echo "Extensions will be auto-installed when you first launch Cursor."
    echo "If extensions don't install automatically, run: setup-ide-extensions"
    echo "You can also check logs at: /tmp/ide-extension-setup-cursor-*.log"
    echo ""
}

# Function to install JetBrains Toolbox
install_jetbrains() {
    echo "Installing JetBrains Toolbox..."

    # Install dependencies (Fedora package names)
    echo "Installing dependencies..."
    dnf install -y \
        tar \
        libXi \
        libXrender \
        libXtst \
        mesa-dri-drivers \
        fontconfig \
        gtk3 \
        dbus-x11 \
        fuse-libs

    # Get the download URL
    TOOLBOX_URL="https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.5.2.32922.tar.gz"

    # Try different download methods based on what's available
    echo "Downloading JetBrains Toolbox from: $TOOLBOX_URL"

    # Method 1: Try curl
    if command -v curl >/dev/null 2>&1; then
        echo "Using curl for download..."
        if curl -L -f -o /tmp/jetbrains-toolbox.tar.gz "$TOOLBOX_URL"; then
            echo "Download successful with curl"
        else
            echo "Curl download failed, trying alternatives..."
            rm -f /tmp/jetbrains-toolbox.tar.gz
        fi
    fi

    # Method 2: Try wget if curl failed or isn't available
    if [ ! -f /tmp/jetbrains-toolbox.tar.gz ]; then
        if command -v wget >/dev/null 2>&1; then
            echo "Using wget for download..."
            if wget -O /tmp/jetbrains-toolbox.tar.gz "$TOOLBOX_URL"; then
                echo "Download successful with wget"
            else
                echo "Wget download failed"
                rm -f /tmp/jetbrains-toolbox.tar.gz
            fi
        fi
    fi

    # Method 3: Install curl/wget if neither worked
    if [ ! -f /tmp/jetbrains-toolbox.tar.gz ]; then
        echo "Installing curl and trying again..."
        dnf install -y curl
        if curl -L -f -o /tmp/jetbrains-toolbox.tar.gz "$TOOLBOX_URL"; then
            echo "Download successful with newly installed curl"
        else
            echo "Error: All download methods failed"
            return 1
        fi
    fi

    # Verify download
    if [ ! -f /tmp/jetbrains-toolbox.tar.gz ] || [ ! -s /tmp/jetbrains-toolbox.tar.gz ]; then
        echo "Error: Download file not found or empty"
        return 1
    fi

    echo "Download successful. File size: $(du -h /tmp/jetbrains-toolbox.tar.gz | cut -f1)"

    # Create installation directory
    mkdir -p /opt/jetbrains-toolbox

    # Extract to installation directory
    echo "Extracting JetBrains Toolbox..."
    if ! tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /opt/jetbrains-toolbox --strip-components=1; then
        echo "Error: Failed to extract JetBrains Toolbox"
        return 1
    fi

    # Verify extraction
    if [ ! -f /opt/jetbrains-toolbox/jetbrains-toolbox ]; then
        echo "Error: JetBrains Toolbox binary not found after extraction"
        return 1
    fi

    # Make executable
    chmod +x /opt/jetbrains-toolbox/jetbrains-toolbox

    # Create symlink for command line usage
    ln -sf /opt/jetbrains-toolbox/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox

    # Create desktop entry
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/jetbrains-toolbox.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=JetBrains Toolbox
Icon=jetbrains-toolbox
Exec=/opt/jetbrains-toolbox/jetbrains-toolbox
Comment=JetBrains Toolbox App - Manage JetBrains IDEs
Categories=Development;IDE;
StartupWMClass=jetbrains-toolbox
StartupNotify=true
EOF

    # Cleanup
    rm -f /tmp/jetbrains-toolbox.tar.gz

    echo "JetBrains Toolbox installed successfully!"
    echo "Binary location: /opt/jetbrains-toolbox/jetbrains-toolbox"
    echo "Command available as: jetbrains-toolbox"
}

# Function to install CLI IDEs
install_cli_ide() {
    local ide="${1,,}"  # Convert to lowercase

    case "$ide" in
        "neovim"|"nvim")
            echo "Installing Neovim..."
            dnf install -y neovim
            ;;
        "emacs")
            echo "Installing Emacs..."
            dnf install -y emacs
            ;;
        "helix")
            echo "Installing Helix..."
            dnf install -y helix
            ;;
        *)
            echo "Error: Unknown CLI IDE '$ide'"
            echo "Available CLI IDEs: neovim, emacs, helix"
            return 1
            ;;
    esac
}

# Function to check if an IDE is a CLI IDE that uses LSP
is_cli_lsp_ide() {
    local ide="${1,,}"
    case "$ide" in
        "neovim"|"nvim"|"helix")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [IDE1,IDE2,...] [LSP_SERVERS]"
    echo "Available GUI IDEs:"
    echo "  zed         - Install Zed editor"
    echo "  vscode      - Install Visual Studio Code"
    echo "  windsurf    - Install Windsurf editor"
    echo "  cursor      - Install Cursor editor"
    echo "  jetbrains   - Install JetBrains Toolbox"
    echo ""
    echo "Available CLI IDEs:"
    echo "  neovim      - Install Neovim"
    echo "  emacs       - Install Emacs"
    echo "  helix       - Install Helix"
    echo ""
    echo "  all         - Install all IDEs (default)"
    echo ""
    echo "Language Servers (for neovim/helix):"
    echo "  Pass as second argument: comma-separated list of servers"
    echo "  Available: typescript, html, css, json, bash, python, rust, go, clang, lua, yaml, docker, markdown, all"
    echo ""
    echo "Examples:"
    echo "  $0 zed                              # Install only Zed"
    echo "  $0 vscode,windsurf                  # Install VS Code and Windsurf"
    echo "  $0 cursor                           # Install Cursor"
    echo "  $0 neovim typescript,python         # Install Neovim with TS and Python LSP"
    echo "  $0 helix rust,clang,lua             # Install Helix with Rust, C/C++, and Lua LSP"
    echo "  $0 neovim,helix all                 # Install Neovim and Helix with all LSPs"
    echo "  $0 all                              # Install all IDEs"
}

# Function to install IDE by name
install_ide() {
    local ide="${1,,}"  # Convert to lowercase

    case "$ide" in
        "zed")
            install_zed
            ;;
        "vscode"|"code")
            install_vscode
            ;;
        "windsurf")
            install_windsurf
            ;;
        "cursor")
            install_cursor
            ;;
        "jetbrains"|"toolbox")
            install_jetbrains
            ;;
        "neovim"|"nvim")
            install_cli_ide "neovim"
            ;;
        "emacs")
            install_cli_ide "emacs"
            ;;
        "helix")
            install_cli_ide "helix"
            ;;
        *)
            echo "Error: Unknown IDE '$ide'"
            echo "Available GUI IDEs: zed, vscode, windsurf, cursor, jetbrains"
            echo "Available CLI IDEs: neovim, emacs, helix"
            return 1
            ;;
    esac
}

# Parse LSP argument if provided (second argument)
LSP_SERVERS="${2:-}"

install_common_tools
setup_browser_integration

# Main installation logic
case "${IDE_TO_INSTALL,,}" in
    "help"|"-h"|"--help")
        show_usage
        exit 0
        ;;
    "all")
        echo "Installing all IDEs..."
        echo ""
        echo "=== Installing GUI IDEs ==="
        install_zed
        install_vscode
        install_windsurf
        install_cursor
        install_jetbrains
        echo ""
        echo "=== Installing CLI IDEs ==="
        install_cli_ide "neovim"
        install_cli_ide "emacs"
        install_cli_ide "helix"
        echo ""
        # Install language servers if specified
        if [ -n "$LSP_SERVERS" ]; then
            install_language_servers "$LSP_SERVERS"
        fi
        echo "Installation completed for: all IDEs"
        ;;
    *)
        # Handle comma-separated list of IDEs
        if [[ "$IDE_TO_INSTALL" == *","* ]]; then
            echo "Installing multiple IDEs: ${IDE_TO_INSTALL}"
            IFS=',' read -ra IDES <<< "$IDE_TO_INSTALL"
            installed_ides=()
            WILL_INSTALL_CLI_IDE=false
            for ide in "${IDES[@]}"; do
                # Trim whitespace
                ide=$(echo "$ide" | xargs)
                if [ -n "$ide" ]; then
                    echo ""
                    echo "Installing: $ide"
                    if install_ide "$ide"; then
                        installed_ides+=("$ide")
                        if is_cli_lsp_ide "$ide"; then
                            WILL_INSTALL_CLI_IDE=true
                        fi
                    else
                        echo "Failed to install: $ide"
                        exit 1
                    fi
                fi
            done
            echo ""
            # Install language servers if specified and CLI IDE was installed
            if [ "$WILL_INSTALL_CLI_IDE" = true ] && [ -n "$LSP_SERVERS" ]; then
                install_language_servers "$LSP_SERVERS"
            fi
            echo "Installation completed for: ${installed_ides[*]}"
        else
            # Handle single IDE
            echo "Installing single IDE: ${IDE_TO_INSTALL}"
            if install_ide "$IDE_TO_INSTALL"; then
                # Install language servers if specified and CLI IDE was installed
                if is_cli_lsp_ide "$IDE_TO_INSTALL" && [ -n "$LSP_SERVERS" ]; then
                    install_language_servers "$LSP_SERVERS"
                fi
                echo "Installation completed for: ${IDE_TO_INSTALL}"
            else
                echo ""
                show_usage
                exit 1
            fi
        fi
        ;;
esac
