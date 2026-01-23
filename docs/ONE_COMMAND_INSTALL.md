# One-Command Installation Feature

Complete IDE installation with build, create, and export in a single command.

## Overview

The one-command installation feature eliminates the complexity of manually building containers, creating distroboxes, and exporting applications. Instead of running multiple commands and managing each step, users can install and configure their entire development environment with a single command.

## What It Does

The one-command installer:

1. **Builds** the container with selected IDEs
2. **Creates** the distrobox container  
3. **Exports** applications to host system
4. **Configures** desktop integration
5. **Verifies** installation success

All automatically, with comprehensive error handling and user feedback.

## Usage

### Simple IDE Installation

```bash
# Install single IDEs
just install-zed
just install-vscode  
just install-cursor
just install-jetbrains

# These commands do EVERYTHING:
# ✅ Build container with IDE
# ✅ Create distrobox
# ✅ Export to applications menu
# ✅ Ready to use immediately
```

### Advanced Installation Script

```bash
# Multiple IDEs
./install-ides.sh zed,cursor
./install-ides.sh vscode,jetbrains
./install-ides.sh jetbrains,zed,cursor

# All IDEs
./install-ides.sh all
./install-ides.sh  # defaults to all

# With options
./install-ides.sh --force zed         # Force reinstall
./install-ides.sh --no-export cursor  # Build only, skip export
./install-ides.sh --verbose all       # Detailed output
./install-ides.sh --help              # Show all options
```

## Command Comparison

| Task | Before (Manual) | After (One-Command) |
|------|----------------|---------------------|
| **Install Zed** | `just build-local zed` → `just create` → `just export-zed` | `just install-zed` |
| **Install Multiple** | `just build-local zed,cursor` → `just create` → `just export-all` | `./install-ides.sh zed,cursor` |
| **Time to Ready** | 5-10 minutes + manual steps | 5-10 minutes, fully automated |
| **User Intervention** | Required between steps | None required |
| **Error Recovery** | Manual debugging | Automatic with helpful messages |

## Installation Methods

### Method 1: Justfile Shortcuts (Easiest)

```bash
just install-zed        # Zed editor only
just install-vscode     # VS Code only  
just install-cursor     # Cursor editor only
just install-jetbrains  # JetBrains Toolbox only
```

**Perfect for**: First-time users, simple setups, quick installations

### Method 2: Full Installer Script (Most Flexible)

```bash
./install-ides.sh [OPTIONS] [IDE1,IDE2,...]
```

**Perfect for**: Multiple IDEs, custom configurations, advanced users

#### Available Options

- `-f, --force` - Force recreation of existing container
- `-n, --no-export` - Skip application export (build + create only)
- `-v, --verbose` - Detailed output for debugging
- `-h, --help` - Show complete help

## Real-World Examples

### Web Developer Setup
```bash
# Modern web development stack
./install-ides.sh vscode,cursor

# Result: VS Code for general development + Cursor for AI assistance
# Applications available: code, cursor
# Container size: ~60% smaller than "all" option
```

### Multi-Language Developer
```bash
# Comprehensive development environment
./install-ides.sh vscode,jetbrains

# Result: VS Code for general use + JetBrains for language-specific IDEs  
# Applications available: code, jetbrains-toolbox (+ all JetBrains IDEs)
# Perfect for: Java, Python, Go, JavaScript, etc.
```

### Performance-Focused Setup
```bash
# Fast, modern development environment
./install-ides.sh zed,cursor

# Result: Zed for speed + Cursor for AI features
# Applications available: zed, cursor
# Container size: Smallest multi-IDE option
```

### Full Development Suite
```bash
# Everything available
./install-ides.sh all
# or simply:
./install-ides.sh

# Result: All IDEs installed
# Applications available: zed, code, cursor, jetbrains-toolbox
# Perfect for: Experimentation, learning, comprehensive development
```

## What Happens During Installation

### Phase 1: Pre-Installation Checks
- ✅ Verify `podman` and `distrobox` are installed
- ✅ Check script dependencies
- ✅ Validate IDE selection

### Phase 2: Container Build
- 🏗️ Build container with selected IDEs
- 📦 Install all dependencies
- ⚙️ Configure IDE-specific settings
- 🔍 Verify successful installation

### Phase 3: Distrobox Creation
- 📋 Check for existing containers
- 🔄 Handle container recreation (with user confirmation)
- 🚀 Create new distrobox container
- ⚡ Initialize container environment

### Phase 4: Application Export
- 🔍 Detect installed applications
- 🔗 Export to host system
- 🖥️ Create desktop entries
- ⌨️ Setup command-line access

### Phase 5: Verification & Completion
- ✅ Verify all exports successful
- 📊 Report installation summary
- 💡 Provide usage instructions
- 🎉 Ready-to-use confirmation

## Error Handling

### Automatic Recovery
- **Missing Dependencies**: Automatically installs required tools
- **Network Issues**: Retries with exponential backoff
- **Container Conflicts**: Prompts for resolution with clear options
- **Export Failures**: Attempts alternative export methods

### Clear Error Messages
```bash
[ERROR] JetBrains Toolbox installation failed
💡 Troubleshooting tips:
   • Run with --verbose for more details
   • Check ./troubleshoot-jetbrains.sh for specific issues
   • Try --force to recreate everything
```

### Helpful Diagnostics
- Pre-installation system checks
- Step-by-step progress indicators
- Detailed logs in verbose mode
- Specific troubleshooting suggestions

## Advanced Features

### Force Reinstallation
```bash
./install-ides.sh --force zed,cursor

# What it does:
# • Removes existing container without prompting
# • Rebuilds container image from scratch  
# • Recreates distrobox container
# • Re-exports all applications
# • Perfect for: Updates, fixing issues, starting fresh
```

### Build-Only Mode
```bash
./install-ides.sh --no-export vscode

# What it does:
# • Builds container with VS Code
# • Creates distrobox container
# • Skips application export
# • Perfect for: Testing, CI/CD, custom export workflows
```

### Verbose Debugging
```bash
./install-ides.sh --verbose jetbrains

# What you get:
# • Detailed build output
# • Step-by-step progress
# • Error details and stack traces
# • Container logs and diagnostics
# • Perfect for: Troubleshooting, development, learning
```

## Integration Examples

### Automation Scripts
```bash
#!/bin/bash
# setup-dev-environment.sh

echo "Setting up development environment..."

case "$PROJECT_TYPE" in
    "web")
        ./install-ides.sh vscode,cursor
        ;;
    "java")  
        ./install-ides.sh jetbrains
        ;;
    "system"|"rust"|"go")
        ./install-ides.sh zed,cursor
        ;;
    *)
        ./install-ides.sh all
        ;;
esac

echo "Development environment ready!"
```

### CI/CD Integration
```yaml
# .github/workflows/setup-dev-env.yml
- name: Setup Development Environment
  run: |
    cd developer_toolbox
    ./install-ides.sh --force --verbose vscode,jetbrains
```

### Docker/Podman Scripts
```bash
# Custom container naming
./install-ides.sh zed,cursor
podman tag localhost/devtoolbox my-registry/dev-environment:latest
podman push my-registry/dev-environment:latest
```

## Performance Characteristics

### Installation Times (Approximate)

| IDE Selection | Build Time | Total Time | Container Size |
|---------------|------------|------------|----------------|
| Single IDE (zed) | 3-5 min | 4-6 min | ~1.2GB |
| Two IDEs (zed,cursor) | 5-7 min | 6-8 min | ~1.8GB |
| Three IDEs (vscode,jetbrains,cursor) | 8-12 min | 10-14 min | ~2.5GB |
| All IDEs | 12-18 min | 15-20 min | ~3.2GB |

*Times vary based on internet speed, system specs, and selected IDEs*

### Resource Usage

- **CPU**: High during build, minimal after installation
- **Memory**: 4GB+ recommended during build, 512MB+ for running containers  
- **Disk**: See container sizes above + 20% overhead
- **Network**: 500MB-2GB download depending on IDE selection

## Troubleshooting

### Common Issues and Solutions

1. **"podman not found"**
   ```bash
   # Install podman
   sudo dnf install podman          # Fedora/RHEL
   sudo apt install podman          # Ubuntu/Debian
   ```

2. **"distrobox not found"**
   ```bash
   # Install distrobox
   curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh
   ```

3. **"Container already exists"**
   ```bash
   # Use force flag to recreate
   ./install-ides.sh --force zed
   ```

4. **Build failures**
   ```bash
   # Get detailed information
   ./install-ides.sh --verbose zed
   
   # Check specific IDE issues
   ./troubleshoot-jetbrains.sh      # For JetBrains issues
   ```

5. **Export failures**
   - Check if container is running: `distrobox list`
   - Verify application exists: `distrobox enter devtoolbox -- which zed`
   - Manual export: `distrobox enter devtoolbox -- distrobox-export --app zed`

### Getting Help

1. **Built-in Help**: `./install-ides.sh --help`
2. **Verbose Logs**: `./install-ides.sh --verbose [ide]`
3. **Test Logic**: `./test-multi-ide.sh`
4. **JetBrains Issues**: `./troubleshoot-jetbrains.sh`
5. **Documentation**: `README.md`, `MULTIPLE_IDE_SELECTION.md`

## Migration Guide

### From Manual Installation

**Before:**
```bash
just build-local zed
just create  
just export-zed
# 3 commands, manual error handling, ~10 minutes with user intervention
```

**After:**
```bash
just install-zed
# 1 command, automatic error handling, ~6 minutes fully automated
```

### From All-IDE Installation

**Before:**
```bash
just build-local    # Installs everything, ~3GB container
just create
just export-all
```

**After:**
```bash
./install-ides.sh zed,cursor    # Install only what you need, ~1.8GB container
```

## Best Practices

### Choosing IDEs

1. **Start Small**: Begin with one or two IDEs
2. **Match Workflow**: Choose IDEs that complement your development style
3. **Consider Resources**: More IDEs = larger containers and longer builds  
4. **Experiment**: Easy to reinstall with `--force` flag

### Container Management

1. **Descriptive Names**: Consider custom container names for multiple setups
2. **Regular Updates**: Use `--force` periodically to get latest versions
3. **Cleanup**: Remove unused containers with `distrobox rm container_name`
4. **Monitoring**: Check container status with `distrobox list`

### Development Workflow

1. **Project-Specific**: Different IDE combinations for different projects
2. **Team Consistency**: Share installation commands for team environments
3. **Documentation**: Document your chosen IDE combinations
4. **Backup**: Export container configurations for disaster recovery

## Future Enhancements

### Planned Features

- **Preset Configurations**: Named combinations for common workflows
- **IDE Version Selection**: Choose specific versions of IDEs
- **Plugin Pre-installation**: Automatically install common plugins
- **Configuration Sync**: Sync settings across installations
- **Update Management**: Smart updates that preserve configurations

### Community Contributions

- IDE-specific optimization scripts
- Custom preset definitions
- Integration with other container systems
- Performance improvements and caching

## Related Files

- `install-ides.sh` - Main installation script
- `justfile` - Convenience commands and shortcuts
- `build.sh` - Core IDE installation logic
- `test-multi-ide.sh` - Installation logic testing
- `troubleshoot-jetbrains.sh` - JetBrains-specific diagnostics
- `README.md` - General documentation
- `MULTIPLE_IDE_SELECTION.md` - Multi-IDE selection guide

---

The one-command installation feature represents a significant improvement in user experience, transforming a complex multi-step process into a simple, reliable, and automated workflow that gets developers up and running quickly with their preferred development environment.