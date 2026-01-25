# mangosteenOS Developer Toolbox

This repository is for use with mangosteenOS. As mangosteenOS is a distribution based on Fedora Atomic, it doesn't have the capability of managing software in the traditional linux way, via a package manager, as root is read-only. To overcome this, mangosteenOS provides distrobox and podman out of the box, that can be used to install software not available, or the flatpak has limitations, via using a container. This repository sets up a developer toolbox, akin to ChromeOS's Linux Developer Environment. This script will create a container with the user specified tools, and export them to the desktop for integration with the host system. This allows the user to have a fully functional development environment without the need for root access. The install mounts the users home directory, so the user can access their files within the container. This is currently in development, and can be used in another distribution, provided the dependencies are installed.

In the future, I might ship a container with all tools, but using a script like this one, allows the user to select the tools they need.

A flexible container build system for creating development environments with your choice of IDE. This toolbox supports Zed, VS Code, and Cursor editors, allowing you to build lightweight containers with only the tools you need.

## Features

- **Selective IDE Installation**: Choose which IDE to install (Zed, VS Code, Cursor, or all)
- **Container-based Development**: Uses Fedora 42 as the base image
- **Distrobox Integration**: Easy integration with your host system
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

### VS Code
- **Source**: Microsoft official repository
- **Command**: `code`
- **Features**: Full-featured IDE with extensive extension ecosystem
- **First-run setup**: Extensions auto-install on first login, or run `setup-vscode-dev-extensions` manually

### Windsurf
- **Source**: Official Windsurf repository (Codeium)
- **Command**: `windsurf`
- **Features**: AI-powered collaborative editor
- **First-run setup**: Extensions auto-install on first login, or run `setup-windsurf-dev-extensions` manually

### Cursor
- **Source**: Official Cursor repository (downloads.cursor.com)
- **Command**: `cursor`
- **Features**: AI-powered code editor with advanced completion
- **First-run setup**: Extensions auto-install on first login, or run `setup-cursor-dev-extensions` manually
- **Note**: Uses official repository, not third-party COPR packages

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

Extensions are **automatically installed on first login** for container-based development. You'll see a message like:

```
╔════════════════════════════════════════════════════════════╗
║  First-time setup: Installing VS Code extensions...       ║
╚════════════════════════════════════════════════════════════╝
```

If automatic installation fails, you can run the setup manually:

**VS Code:**
```bash
setup-vscode-dev-extensions
```

**Windsurf:**
```bash
setup-windsurf-dev-extensions
```

**Cursor:**
```bash
setup-cursor-dev-extensions
```

#### Installed Extensions:
- Remote - Containers (`ms-vscode-remote.remote-containers`)
- Remote - SSH (`ms-vscode-remote.remote-ssh`)
- Docker (`ms-azuretools.vscode-docker`)
- DMS Theme (`DankLinux.dms-theme`)

You can also install additional extensions manually using:
- VS Code: `code --install-extension <extension-id>`
- Windsurf: `windsurf --install-extension <extension-id>`
- Cursor: `cursor --install-extension <extension-id>`

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
