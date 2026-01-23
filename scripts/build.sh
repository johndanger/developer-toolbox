#!/bin/env bash

# Parse IDE selection (supports comma-separated list)
IDE_TO_INSTALL="${1:-all}"

install_common_tools() {
    echo "Installing common tools..."
    dnf install -y \
        zsh \
        fish \
        git \
        wget \
        gnupg2 \
        dnf-plugins-core \
        kitty-terminfo
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [IDE1,IDE2,...]"
    echo "Available GUI IDEs:"
    echo "  zed         - Install Zed editor"
    echo "  vscode      - Install Visual Studio Code"
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
    echo "Examples:"
    echo "  $0 zed                    # Install only Zed"
    echo "  $0 vscode,cursor          # Install VS Code and Cursor"
    echo "  $0 neovim,helix           # Install Neovim and Helix"
    echo "  $0 jetbrains,zed,neovim   # Install JetBrains, Zed, and Neovim"
    echo "  $0                        # Install all IDEs"
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
            echo "Available GUI IDEs: zed, vscode, cursor, jetbrains"
            echo "Available CLI IDEs: neovim, emacs, helix"
            return 1
            ;;
    esac
}

install_common_tools
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
        install_cursor
        install_jetbrains
        echo ""
        echo "=== Installing CLI IDEs ==="
        install_cli_ide "neovim"
        install_cli_ide "emacs"
        install_cli_ide "helix"
        echo ""
        echo "Installation completed for: all IDEs"
        ;;
    *)
        # Handle comma-separated list of IDEs
        if [[ "$IDE_TO_INSTALL" == *","* ]]; then
            echo "Installing multiple IDEs: ${IDE_TO_INSTALL}"
            IFS=',' read -ra IDES <<< "$IDE_TO_INSTALL"
            installed_ides=()
            for ide in "${IDES[@]}"; do
                # Trim whitespace
                ide=$(echo "$ide" | xargs)
                if [ -n "$ide" ]; then
                    echo ""
                    echo "Installing: $ide"
                    if install_ide "$ide"; then
                        installed_ides+=("$ide")
                    else
                        echo "Failed to install: $ide"
                        exit 1
                    fi
                fi
            done
            echo ""
            echo "Installation completed for: ${installed_ides[*]}"
        else
            # Handle single IDE
            echo "Installing single IDE: ${IDE_TO_INSTALL}"
            if install_ide "$IDE_TO_INSTALL"; then
                echo "Installation completed for: ${IDE_TO_INSTALL}"
            else
                echo ""
                show_usage
                exit 1
            fi
        fi
        ;;
esac
