# JetBrains Toolbox Integration

This document describes the JetBrains Toolbox integration added to the developer toolbox container system.

## Overview

JetBrains Toolbox is a unified launcher and manager for all JetBrains IDEs including:
- IntelliJ IDEA (Java, Kotlin, Scala)
- PyCharm (Python)
- WebStorm (JavaScript, TypeScript)
- PhpStorm (PHP)
- GoLand (Go)
- RubyMine (Ruby)
- CLion (C/C++)
- Rider (.NET)
- DataGrip (Database)
- And many more...

## Installation Method

The integration installs JetBrains Toolbox using the official tarball distribution from JetBrains, following their recommended silent installation approach for Linux systems.

### Installation Steps

1. **Dependencies Installation**: Installs required system packages
   - `libXi`, `libXrender`, `libXtst` - X11 libraries
   - `mesa-utils` - OpenGL utilities
   - `fontconfig` - Font configuration
   - `gtk3` - GTK3 libraries
   - `dbus-x11` - D-Bus X11 integration
   - `libfuse3` - FUSE filesystem support

2. **Download**: Downloads the official tarball from JetBrains servers
3. **Installation**: Extracts to `/opt/jetbrains-toolbox/`
4. **Integration**: Creates desktop entry and command-line symlink
5. **Cleanup**: Removes temporary files

## Usage

### Building Container with JetBrains Toolbox

```bash
# Build with JetBrains Toolbox only
just build-local jetbrains
./build.sh jetbrains
podman build . --build-arg IDE=jetbrains -t devtoolbox-jetbrains

# Build with all IDEs (includes JetBrains Toolbox)
just build-local
./build.sh
podman build . -t devtoolbox-full
```

### Using JetBrains Toolbox in Container

```bash
# Create container
just create

# Export JetBrains Toolbox to host
just export-jetbrains

# Or manually export
distrobox enter devtoolbox -- distrobox-export --app jetbrains-toolbox
```

### Launching JetBrains Toolbox

After export, you can launch JetBrains Toolbox:
- From applications menu: Search for "JetBrains Toolbox"
- From command line: `jetbrains-toolbox`
- From container: `distrobox enter devtoolbox -- jetbrains-toolbox`

## File Structure

### Installed Files
- **Binary**: `/opt/jetbrains-toolbox/jetbrains-toolbox`
- **Symlink**: `/usr/local/bin/jetbrains-toolbox`
- **Desktop Entry**: `/usr/share/applications/jetbrains-toolbox.desktop`

### Desktop Entry Content
```desktop
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
```

## Configuration and Data

JetBrains Toolbox stores its configuration and data in:
- `~/.local/share/JetBrains/Toolbox/` - Application data
- `~/.config/JetBrains/Toolbox/` - Configuration files
- Individual IDEs are installed in the Toolbox managed directories

## Benefits

1. **Centralized Management**: Single interface for all JetBrains IDEs
2. **Easy Updates**: Automatic updates for all installed IDEs
3. **Version Management**: Install multiple versions of the same IDE
4. **Project Management**: Quick access to recent projects
5. **License Management**: Unified license activation
6. **Plugin Management**: Consistent plugin installation across IDEs

## Troubleshooting

### Common Issues

1. **FUSE Not Available**
   ```bash
   # Install FUSE support
   dnf install libfuse3
   ```

2. **Permission Errors**
   ```bash
   # Check executable permissions
   ls -la /opt/jetbrains-toolbox/jetbrains-toolbox
   chmod +x /opt/jetbrains-toolbox/jetbrains-toolbox
   ```

3. **Desktop Integration Missing**
   ```bash
   # Verify desktop entry
   ls -la /usr/share/applications/jetbrains-toolbox.desktop
   ```

4. **Startup Issues**
   ```bash
   # Run from terminal to see errors
   /opt/jetbrains-toolbox/jetbrains-toolbox
   ```

### Alternative Installation

If the automatic installation fails, you can manually download and install:

```bash
# Download latest version
wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-VERSION.tar.gz

# Extract and install
sudo tar -xzf jetbrains-toolbox-VERSION.tar.gz -C /opt/
sudo mv /opt/jetbrains-toolbox-* /opt/jetbrains-toolbox
sudo chmod +x /opt/jetbrains-toolbox/jetbrains-toolbox
```

## Integration Points

### Build Script (`build.sh`)
- Function: `install_jetbrains()`
- Supports aliases: `jetbrains`, `toolbox`
- Included in `all` option

### Justfile
- `build-local jetbrains` - Build with JetBrains only
- `export-jetbrains` - Export to host system
- `setup jetbrains` - Build and create in one step

### Containerfile
- Accepts `--build-arg IDE=jetbrains`
- Passes argument to build script

## Security Considerations

- Downloads from official JetBrains servers
- Verifies download integrity (HTTP 200 responses)
- Installs to system directory with appropriate permissions
- No additional repositories or third-party sources

## Version Information

- **Current Version**: 2.5.2.32922 (as of implementation)
- **Update Method**: Manual update of download URL in build script
- **Compatibility**: Linux x86_64, glibc 2.28+

## Future Improvements

1. **Dynamic Version Detection**: Auto-detect latest version from JetBrains API
2. **Checksum Verification**: Verify download integrity with SHA-256 checksums
3. **Multi-arch Support**: Support for ARM64 architecture
4. **Configuration Presets**: Pre-configured settings for common development scenarios
5. **Plugin Presets**: Automatically install common plugins based on development type

## Related Documentation

- [JetBrains Toolbox Official Documentation](https://www.jetbrains.com/help/toolbox-app/)
- [Silent Installation Guide](https://www.jetbrains.com/help/toolbox-app/toolbox-app-silent-installation.html)
- [System Requirements](https://www.jetbrains.com/toolbox-app/system-requirements/)