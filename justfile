_default:
    @just --list

# Run podman build with optional IDE selection
build-local ide="all":
    podman build . --build-arg IDE={{ide}} -t localhost/devtoolbox

# Create distrobox
create local="local":
    #!/usr/bin/env bash

    if [ $(distrobox list | grep -oP '(?<=| )devtoolbox(?= | )') ]; then
        echo "Error: container already exists"
        read -p "Do you want to force remove it (this will stop all currently open processess) (y/n)?"$'\n' -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing container"
            distrobox rm devtoolbox --force
        else
            echo "Aborting"
            exit 1
        fi
    fi

    echo "Creating container"

    if [ "{{local}}" = "local" ]; then
        distrobox create -n devtoolbox -i localhost/devtoolbox --yes
    else
        echo "Error: non-local builds are not supported yet"
        exit 1
    fi

# Export specific application
export app:
    distrobox enter devtoolbox -- distrobox-export --app {{app}}

# Export commonly used IDEs
export-zed:
    just export zed

export-vscode:
    just export code

export-cursor:
    just export cursor

export-jetbrains:
    just export jetbrains-toolbox

# Export all available IDEs
export-all:
    #!/usr/bin/env bash
    echo "Exporting available IDEs..."

    # Check which IDEs are installed and export them
    if distrobox enter devtoolbox -- which zed >/dev/null 2>&1; then
        echo "Exporting Zed..."
        just export zed
    fi

    if distrobox enter devtoolbox -- which code >/dev/null 2>&1; then
        echo "Exporting VS Code..."
        just export code
    fi

    if distrobox enter devtoolbox -- which cursor >/dev/null 2>&1; then
        echo "Exporting Cursor..."
        just export cursor
    fi

    if distrobox enter devtoolbox -- which jetbrains-toolbox >/dev/null 2>&1; then
        echo "Exporting JetBrains Toolbox..."
        just export jetbrains-toolbox
    fi

# Build and create container with specific IDE
setup ide="all":
    just build-local {{ide}}
    just create

# Complete installation: build, create, and export in one command
install ide="all":
    #!/usr/bin/env bash
    echo "=== Complete IDE Installation: {{ide}} ==="
    echo "This will build container, create distrobox, and export applications"
    echo

    # Build the container
    echo "Step 1/3: Building container with {{ide}}..."
    just build-local {{ide}}

    # Create the distrobox
    echo
    echo "Step 2/3: Creating distrobox container..."
    just create

    # Export applications based on what was installed
    echo
    echo "Step 3/3: Exporting applications to host system..."

    if [ "{{ide}}" = "all" ]; then
        echo "Exporting all installed IDEs..."
        just export-all
    elif [[ "{{ide}}" == *","* ]]; then
        # Handle multiple IDEs
        echo "Exporting multiple IDEs: {{ide}}"
        IFS=',' read -ra IDES <<< "{{ide}}"
        for ide_name in "${IDES[@]}"; do
            ide_name=$(echo "$ide_name" | xargs)  # Trim whitespace
            case "${ide_name,,}" in
                "zed")
                    if distrobox enter devtoolbox -- which zed >/dev/null 2>&1; then
                        echo "Exporting Zed..."
                        just export zed
                    fi
                    ;;
                "vscode"|"code")
                    if distrobox enter devtoolbox -- which code >/dev/null 2>&1; then
                        echo "Exporting VS Code..."
                        just export code
                    fi
                    ;;
                "cursor")
                    if distrobox enter devtoolbox -- which cursor >/dev/null 2>&1; then
                        echo "Exporting Cursor..."
                        just export cursor
                    fi
                    ;;
                "jetbrains"|"toolbox")
                    if distrobox enter devtoolbox -- which jetbrains-toolbox >/dev/null 2>&1; then
                        echo "Exporting JetBrains Toolbox..."
                        just export jetbrains-toolbox
                    fi
                    ;;
            esac
        done
    else
        # Handle single IDE
        case "{{ide}}" in
            "zed")
                just export-zed
                ;;
            "vscode"|"code")
                just export-vscode
                ;;
            "cursor")
                just export-cursor
                ;;
            "jetbrains"|"toolbox")
                just export-jetbrains
                ;;
        esac
    fi

    echo
    echo "✅ Installation complete! Your IDEs are ready to use."
    echo "You can now launch them from your applications menu or command line."

# Show available IDEs for building
list-ides:
    @echo "Available IDEs for building:"
    @echo "  zed         - Zed editor"
    @echo "  vscode      - Visual Studio Code"
    @echo "  cursor      - Cursor editor"
    @echo "  jetbrains   - JetBrains Toolbox"
    @echo "  all         - All IDEs (default)"
    @echo ""
    @echo "Single IDE examples:"
    @echo "  just build-local zed"
    @echo "  just build-local jetbrains"
    @echo "  just setup vscode"
    @echo "  just install zed                    # Build + Create + Export"
    @echo ""
    @echo "Multiple IDE examples:"
    @echo "  just build-local zed,cursor"
    @echo "  just build-local vscode,jetbrains"
    @echo "  just build-local zed,cursor,jetbrains"
    @echo "  just setup 'vscode,cursor'"
    @echo "  just install 'zed,cursor'          # Build + Create + Export"
    @echo "  just install 'vscode,jetbrains'    # Build + Create + Export"
    @echo ""
    @echo "All IDEs:"
    @echo "  just build-local"
    @echo "  just install                       # Build + Create + Export all"

# Test browser integration in the container
test-browser:
    #!/usr/bin/env bash
    echo "Testing browser integration..."
    echo "This will test if URLs can be opened in the host browser from within the container."
    echo ""
    if ! distrobox list | grep -q devtoolbox; then
        echo "Error: devtoolbox container not found"
        echo "Run 'just create' first to create the container"
        exit 1
    fi
    distrobox enter devtoolbox -- test-browser-integration

# Check browser integration status
check-browser:
    #!/usr/bin/env bash
    echo "Checking browser integration status..."
    if ! distrobox list | grep -q devtoolbox; then
        echo "Error: devtoolbox container not found"
        echo "Run 'just create' first to create the container"
        exit 1
    fi
    echo "Checking if xdg-open-host wrapper is installed..."
    distrobox enter devtoolbox -- ls -la /usr/local/bin/xdg-open-host
    echo ""
    echo "Checking if system xdg-open is redirected..."
    distrobox enter devtoolbox -- ls -la /usr/bin/xdg-open
    echo ""
    echo "Checking available host integration tools..."
    distrobox enter devtoolbox -- bash -c 'for tool in distrobox-host-exec host-spawn flatpak-spawn; do echo -n "$tool: "; if command -v $tool >/dev/null 2>&1; then echo "Available"; else echo "Not found"; fi; done'

# Test Cursor login scenarios
test-cursor-login:
    #!/usr/bin/env bash
    echo "Testing Cursor login browser integration..."
    echo "This simulates what happens when Cursor tries to open login URLs."
    echo ""
    if ! distrobox list | grep -q devtoolbox; then
        echo "Error: devtoolbox container not found"
        echo "Run 'just create' first to create the container"
        exit 1
    fi
    distrobox enter devtoolbox -- test-cursor-login

# Complete installation wrapper using enhanced script
install-complete ide="all":
    ./install-ides.sh {{ide}}

# Force installation (recreate existing container)
install-force ide="all":
    ./install-ides.sh --force {{ide}}

# Quick install shortcuts for single IDEs
install-zed:
    ./install-ides.sh zed

install-vscode:
    ./install-ides.sh vscode

install-cursor:
    ./install-ides.sh cursor

install-jetbrains:
    ./install-ides.sh jetbrains
