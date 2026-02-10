# mangosteenOS Developer Toolbox

This repository is for use with mangosteenOS. As mangosteenOS is a distribution based on Fedora Atomic, it doesn't have the capability of managing software in the traditional linux way, via a package manager, as root is read-only. To overcome this, mangosteenOS provides distrobox and podman out of the box, that can be used to install software not available, or the flatpak has limitations, via using a container. This repository sets up a developer toolbox, akin to ChromeOS's Linux Developer Environment. This script will create a container with the user specified tools, and export them to the desktop for integration with the host system. This allows the user to have a fully functional development environment without the need for root access. The install mounts the users home directory, so the user can access their files within the container. This is currently in development, and can be used in another distribution, provided the dependencies are installed.

In the future, I might ship a container with all tools, but using a script like this one, allows the user to select the tools they need.

A flexible container build system for creating development environments with your choice of IDE. This toolbox supports Zed, VS Code, and Cursor editors, allowing you to build lightweight containers with only the tools you need.

## Features

- **Selective IDE Installation**: Choose which IDE to install (Zed, VS Code, Cursor, or all)
- **Container-based Development**: Uses Fedora 42 as the base image
- **Distrobox Integration**: Easy integration with your host system
- **Browser Integration**: Automatic URL forwarding to host browser for IDE authentication and links
- **Justfile Automation**: Simple commands for building and managing containers

## Quick Start

### 🚀 One-Command Installation (Recommended)
```bash
# Install everything: build + create + export in one command
just install-zed
just install-vscode  
just install-cursor
just install-jetbrains

# Install multiple IDEs
./install-ides.sh zed,cursor
./install-ides.sh vscode,jetbrains

# Install all IDEs
./install-ides.sh
```

# Interactive IDE Selection
./install-ides.sh -i

### Manual Step-by-Step (Advanced)

#### Build with All IDEs (Default)
```bash
just build-local
```

#### Build with Specific IDE
```bash
# Build with only Zed
just build-local zed

# Build with only VS Code
just build-local vscode

# Build with multiple IDEs
just build-local zed,cursor
just build-local vscode,jetbrains
```

#### Complete Setup (Build + Create Container)
```bash
# Setup with all IDEs
just setup

# Setup with specific IDE
just setup zed
just setup vscode

# Setup with multiple IDEs
just setup "zed,cursor"
just setup "vscode,jetbrains"
```

## Available IDEs

| IDE | One-Command Install | Manual Commands |
|-----|---------------------|----------------|
| **Zed** | `just install-zed` | `just build-local zed` → `just create` → `just export-zed` |
| **VS Code** | `just install-vscode` | `just build-local vscode` → `just create` → `just export-vscode` |
| **Cursor** | `just install-cursor` | `just build-local cursor` → `just create` → `just export-cursor` |
| **JetBrains Toolbox** | `just install-jetbrains` | `just build-local jetbrains` → `just create` → `just export-jetbrains` |
| **Multiple IDEs** | `./install-ides.sh zed,cursor` | `just build-local zed,cursor` → `just create` → `just export-all` |
| **All IDEs** | `./install-ides.sh` | `just build-local` → `just create` → `just export-all` |

## Commands Reference

### 🚀 One-Command Installation (Recommended)
- `just install-zed` - Complete Zed installation
- `just install-vscode` - Complete VS Code installation  
- `just install-cursor` - Complete Cursor installation
- `just install-jetbrains` - Complete JetBrains installation
- `./install-ides.sh [ide1,ide2,...]` - Install any combination with options

### Advanced Installation Script Options
```bash
./install-ides.sh --help              # Show all options
./install-ides.sh --force zed         # Force reinstall
./install-ides.sh --no-export cursor  # Build only, skip export
./install-ides.sh --verbose all       # Detailed output
./install-ides.sh --debug zed,cursor  # Debug mode with diagnostics
```

### Manual Step-by-Step Commands

#### Building
- `just build-local [ide]` - Build container with specified IDE (defaults to "all")
- `just list-ides` - Show available IDE options

#### Container Management
- `just create` - Create distrobox container from built image
- `just setup [ide]` - Build and create container in one step

#### Application Export
- `just export [app]` - Export specific application to host system
- `just export-zed` - Export Zed editor
- `just export-vscode` - Export VS Code
- `just export-cursor` - Export Cursor
- `just export-jetbrains` - Export JetBrains Toolbox
- `just export-all` - Export all installed IDEs

## Installation Methods

### Method 1: One-Command Installation (Easiest)
```bash
# Single IDEs
just install-zed
just install-vscode
just install-cursor
just install-jetbrains

# Multiple IDEs
./install-ides.sh zed,cursor
./install-ides.sh vscode,jetbrains

# With options
./install-ides.sh --force all          # Reinstall everything
./install-ides.sh --no-export zed      # Build only, no export
```

### Method 2: Manual Step-by-Step

#### Build Script
```bash
# Install all IDEs
./build.sh

# Install specific IDE
./build.sh zed
./build.sh vscode

# Install multiple IDEs
./build.sh zed,cursor
./build.sh vscode,jetbrains,cursor

# Show help
./build.sh --help
```

### Container Build
```bash
# Build with all IDEs
podman build . -t localhost/devtoolbox

# Build with specific IDE
podman build . --build-arg IDE=zed -t localhost/devtoolbox
podman build . --build-arg IDE=vscode -t localhost/devtoolbox

# Build with multiple IDEs
podman build . --build-arg IDE=zed,cursor -t localhost/devtoolbox
podman build . --build-arg IDE=vscode,jetbrains -t localhost/devtoolbox
```

## IDE Details

### Zed
- **Source**: Terra repository (Fyra Labs)
- **Command**: `zed`
- **Features**: Fast, modern editor with built-in collaboration
- **Note**: Zed uses its own extension system (not VS Code extensions)

### VS Code
- **Source**: Microsoft official repository
- **Command**: `code`
- **Features**: Full-featured IDE with extensive extension ecosystem

### Windsurf
- **Source**: Official Windsurf repository (Codeium)
- **Command**: `windsurf`
- **Features**: AI-powered collaborative editor

### Cursor
- **Source**: Official Cursor repository (downloads.cursor.com)
- **Command**: `cursor`
- **Features**: AI-powered code editor with advanced completion
- **Note**: Uses official repository, not third-party COPR packages

**Extension Auto-Setup**: All VS Code-based editors (VS Code, Windsurf, Cursor) automatically have their extensions checked and installed on first login. See [Post-Installation Setup](#post-installation-setup) below.

### JetBrains Toolbox
- **Source**: Official JetBrains download (jetbrains.com)
- **Command**: `jetbrains-toolbox`
- **Features**: Unified installer and updater for all JetBrains IDEs
- **Note**: Provides access to IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains tools

## Requirements

- **Container Runtime**: Podman or Docker
- **Distrobox**: For container integration
- **Just**: For running the automation commands

### Installing Requirements

#### Fedora/RHEL/CentOS
```bash
sudo dnf install podman distrobox just
```

#### Ubuntu/Debian
```bash
sudo apt install podman
# Install distrobox and just separately
```

## Container Architecture

The build system uses a multi-stage approach:

1. **Context Stage**: Copies build scripts into container
2. **Build Stage**: Runs installation based on IDE parameter
3. **Final Image**: Clean Fedora 42 with selected development tools

## Post-Installation Setup

### IDE Extensions (VS Code, Windsurf, Cursor)

**Note**: This only applies to VS Code-based editors. Other IDEs (Zed, JetBrains, CLI editors) use different extension systems and are not affected by this auto-setup.

Extensions are **automatically checked and installed** when you first launch VS Code, Windsurf, or Cursor. The system:
- Launches the IDE immediately (no delay waiting for extensions)
- Waits 5 seconds for the IDE to fully start
- Checks and installs missing extensions in the background
- Auto-detects which IDE you're using
- Runs silently if all extensions are present

**Important**: The auto-setup runs when you **launch the IDE** (run `code`, `cursor`, or `windsurf` commands), not when opening regular terminals. Extensions install a few seconds after the IDE opens, so you may need to reload the IDE window once to activate them.

#### Disabling Auto-Installation

If you prefer to manage extensions manually, you can disable automatic installation by setting an environment variable.

**Option 1: Set on Host (Recommended)**

With distrobox, environment variables set on your host system are passed through to the container:

```bash
# On your host system - Disable permanently
echo 'export DISABLE_IDE_AUTO_EXTENSIONS=1' >> ~/.bashrc
source ~/.bashrc

# Now enter container and launch IDE
distrobox enter dev-toolbox
code myproject/  # No automatic extension installation
```

**Option 2: Set Inside Container**

Alternatively, set it inside the container:

```bash
# Inside container - Disable for current session
export DISABLE_IDE_AUTO_EXTENSIONS=1

# Inside container - Disable permanently
echo 'export DISABLE_IDE_AUTO_EXTENSIONS=1' >> ~/.bashrc
source ~/.bashrc

# Launch IDE (no automatic extension installation)
code myproject/
```

**To re-enable automatic installation:**
```bash
# Remove from your ~/.bashrc (host or container)
# Or temporarily override:
unset DISABLE_IDE_AUTO_EXTENSIONS
```

**Note:** Setting on the host is recommended because it persists across container recreations and applies to all containers automatically.

**Check if auto-install is disabled:**
```bash
# Check current status
echo $DISABLE_IDE_AUTO_EXTENSIONS
# Output: 1 or true = disabled, empty = enabled
```

When extensions need to be installed (happens in background after IDE launches), you may see installation messages in a terminal. After installation completes, reload the IDE window to activate the extensions:

- **VS Code**: Press `Ctrl+Shift+P` → "Developer: Reload Window"
- **Cursor**: Press `Ctrl+Shift+P` → "Developer: Reload Window"  
- **Windsurf**: Press `Ctrl+Shift+P` → "Developer: Reload Window"

#### Manual Setup

If you want to manually trigger extension installation without launching the IDE, run:

```bash
setup-ide-extensions
```

This single command will check and install extensions for **all installed IDEs** (VS Code, Windsurf, and Cursor).

This is useful if you want to pre-install extensions, troubleshoot installation issues, or manually manage extensions after disabling auto-installation.

#### Installed Extensions:
- Remote - Containers (`ms-vscode-remote.remote-containers`)
- Remote - SSH (`ms-vscode-remote.remote-ssh`)
- Docker (`ms-azuretools.vscode-docker`)
- DMS Theme (`DankLinux.dms-theme`)

#### Additional Extensions

You can install additional extensions manually using:
- VS Code: `code --install-extension <extension-id>`
- Windsurf: `windsurf --install-extension <extension-id>`
- Cursor: `cursor --install-extension <extension-id>`

### Browser Integration

The developer toolbox includes automatic browser integration that allows applications running inside the container (like Cursor, VS Code, etc.) to open URLs in your host browser instead of requiring a browser inside the container.

#### How It Works

When an application tries to open a URL (like for authentication or external links), the system automatically forwards the request to your host browser using:

1. **distrobox-host-exec** - Primary method for distrobox containers
2. **host-spawn** - Alternative method if available  
3. **flatpak-spawn** - For flatpak-based setups
4. **Direct host access** - Fallback for mounted host tools

#### Testing Browser Integration

To test if browser integration is working correctly:

```bash
# Test the integration
just test-browser

# Check integration status
just check-browser

# Manual test from inside container
distrobox enter devtoolbox -- test-browser-integration
```

#### Common Browser Integration Issues

**URLs don't open in host browser:**
1. Make sure you're using distrobox (not plain podman/docker)
2. Verify the container was built with the latest version that includes browser integration
3. Test the integration: `just test-browser`

**Authentication fails in IDEs (Cursor, VS Code):**
1. The login URL should automatically open in your host browser
2. Complete the authentication in the host browser
3. The IDE should detect the successful authentication automatically

**Manual URL opening:**
If automatic opening fails, the system will display the URL and copy it to clipboard (if available). You can manually paste it into your host browser.

**Debug information:**
Check `/tmp/xdg-open-debug.log` inside the container for detailed information about URL opening attempts.

### Docker/Podman Host Access (Optional)

The developer toolbox can optionally configure access to the host's Docker and Podman daemons, allowing you to use the host's container runtime from inside the container.

**⚠️ Important Note:** Mounting Docker/Podman sockets may interfere with `distrobox export`. If you need host container runtime access, either:
1. Export applications first, then recreate the container with `--mount-containers`
2. Or manually mount sockets after export is complete

#### Enabling Host Access

To enable host Docker/Podman access, use the `--mount-containers` flag:

```bash
# Create container with host Docker/Podman access
./setup-dev-toolbox.sh --mount-containers zed

# Or with multiple IDEs
./setup-dev-toolbox.sh --mount-containers zed,cursor
```

#### How It Works

When the container is created with `--mount-containers`, the setup script:
1. **Mounts Docker socket** (`/var/run/docker.sock`) if available on the host
2. **Mounts Podman socket** (`/run/podman/podman.sock` or user socket) if available on the host
3. **Sets up Podman** to automatically use the host socket when available

**Note:** Hostname resolution for `host.docker.internal` and `host.containers.internal` is not configured automatically to avoid interfering with distrobox export. If you need these hostnames, configure them manually after export (see below).

#### Recommended Workflow

If you need both export and host access:

1. First, create and export without socket mounts (default):
   ```bash
   ./setup-dev-toolbox.sh zed
   ```

2. Then, if you need host Docker/Podman access, recreate with socket mounts:
   ```bash
   ./setup-dev-toolbox.sh --force --mount-containers zed
   ```

#### Using Host Docker/Podman

Once sockets are mounted, you can use the host's container runtime:

```bash
# Enter the container
distrobox enter devtoolbox

# Use host Docker (if docker client is installed)
docker ps
docker run hello-world

# Use host Podman (automatic)
podman ps
podman run quay.io/fedora/fedora:42 echo "Hello from host Podman"

# Access host services via special hostnames (if manually configured)
# See "Hostname Access" section below for configuration instructions
curl http://host.docker.internal:8080
curl http://host.containers.internal:8080
```

#### Hostname Access

If you need special hostnames for accessing the host, you can manually configure them:

- **`host.docker.internal`** - Resolves to the host machine (for Docker compatibility)
- **`host.containers.internal`** - Resolves to the host machine (for Podman compatibility)

To configure these hostnames manually:

```bash
# Enter the container
distrobox enter devtoolbox

# Get the host IP (gateway IP)
HOST_IP=$(ip route show default | awk '{print $3}' | head -n1)

# Add hostname entries
echo "$HOST_IP host.docker.internal host.containers.internal" | sudo tee -a /etc/hosts

# Now you can access services running on the host
curl http://host.docker.internal:8080
curl http://host.containers.internal:8080
```

**Note:** These hostnames are not configured automatically to avoid interfering with distrobox export.

#### Testing Container Runtime Access

To test if Docker/Podman host access is working:

```bash
# Test from setup script
./setup-dev-toolbox.sh --test-containers

# Or test manually from inside container
distrobox enter devtoolbox -- bash -c '
    echo "Testing Docker..."
    docker ps 2>&1 || echo "Docker not available"
    
    echo "Testing Podman..."
    podman ps 2>&1 || echo "Podman not available"
    
    echo "Testing hostname resolution (if configured)..."
    ping -c 1 host.docker.internal 2>&1 || echo "host.docker.internal not configured"
    ping -c 1 host.containers.internal 2>&1 || echo "host.containers.internal not configured"
'
```

## Troubleshooting

### Container Already Exists
If you get an error about the container already existing, the `create` command will prompt you to force remove it.

### Official Repository Issues (Cursor)
If Cursor installation from official repository fails:
1. Ensure repository is properly added: Check `/etc/yum.repos.d/cursor.repo`
2. Update package cache: `dnf check-update`
3. Try installing manually: `dnf install cursor`
4. **Important**: This uses the official Cursor repository, not unofficial COPR packages
5. Note: Official repository may occasionally be behind latest releases

### Repository Comparison (Cursor)
- **Official Repository**: `https://downloads.cursor.com/yumrepo/` (used by this script)
- **Unofficial COPR**: Various third-party repositories exist but are not officially supported
- **Recommendation**: Use official repository for stability and official support

### JetBrains Toolbox Issues
If JetBrains Toolbox installation or startup fails:

**Quick Diagnosis**: Run the troubleshooting script:
```bash
./troubleshoot-jetbrains.sh
```

**Common Issues**:
1. **Download failures**: The script tries multiple download methods (curl, wget). If all fail:
   - Check internet connectivity in container
   - Verify the download URL is still valid
   - Try manual download: `curl -L -o /tmp/toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-VERSION.tar.gz`
2. **Missing dependencies**: Ensure FUSE is installed: `dnf install libfuse3`
3. **Permission issues**: Check that `/opt/jetbrains-toolbox/jetbrains-toolbox` is executable
4. **Desktop integration**: Desktop file should be at `/usr/share/applications/jetbrains-toolbox.desktop`
5. **First run**: Run `jetbrains-toolbox` from terminal to see error messages
6. **AppImage alternative**: If issues persist, download AppImage from jetbrains.com manually

### Repository Issues
If package installation fails:
1. Update package cache: `dnf check-update`
2. Clear package cache: `dnf clean all`
3. Verify repository connectivity

## Customization

### Adding New IDEs
1. Add installation function to `build.sh`
2. Update the case statement in the main logic
3. Add export commands to `justfile`
4. Update this README

### Base Image
To use a different base image, modify the `FROM` line in `Containerfile`:
```dockerfile
FROM quay.io/fedora/fedora:41  # or your preferred image
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your changes with appropriate tests
4. Update documentation
5. Submit a pull request

## License

This project is open source. Please check the repository for specific license terms.
