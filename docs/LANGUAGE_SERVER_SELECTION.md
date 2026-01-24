# Language Server Selection Feature

This document describes the language server selection feature for Neovim and Helix installations in the MangosteenOS Developer Toolbox.

## Overview

When installing Neovim or Helix as part of the developer toolbox, you can now select which language servers to install alongside them. This provides enhanced IDE features like code completion, go-to-definition, diagnostics, and more.

## Table of Contents

- [Quick Start](#quick-start)
- [Available Language Servers](#available-language-servers)
- [Usage Methods](#usage-methods)
- [Interactive Selection](#interactive-selection)
- [Command-Line Selection](#command-line-selection)
- [Examples](#examples)
- [Technical Details](#technical-details)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Interactive Mode (Recommended)

```bash
# Run the setup script
./setup-dev-toolbox.sh

# When prompted, select neovim or helix
# You'll then be prompted to select language servers
```

### Command-Line Mode

```bash
# Install Neovim with TypeScript and Python language servers
./setup-dev-toolbox.sh neovim LSP:typescript,python

# Install Helix with Rust and C/C++ language servers
./setup-dev-toolbox.sh helix LSP:rust,clang

# Install both with all language servers
./setup-dev-toolbox.sh neovim,helix LSP:all
```

## Available Language Servers

| Server Name | Language/Framework | Implementation |
|-------------|-------------------|----------------|
| `typescript` | TypeScript/JavaScript | typescript-language-server |
| `python` | Python | pyright |
| `rust` | Rust | rust-analyzer |
| `go` | Go | gopls |
| `clang` | C/C++ | clangd |
| `lua` | Lua | lua-language-server |
| `bash` | Bash/Shell | bash-language-server |
| `html` | HTML | vscode-langservers-extracted |
| `css` | CSS | vscode-langservers-extracted |
| `json` | JSON | vscode-langservers-extracted |
| `yaml` | YAML | yaml-language-server |
| `docker` | Dockerfile | dockerfile-language-server-nodejs |
| `markdown` | Markdown | marksman |
| `all` | All of the above | - |

## Usage Methods

### Method 1: Interactive Menu (Recommended)

The interactive menu uses `gum` to provide a user-friendly selection interface.

1. Run the setup script without arguments or with `-i` flag:
   ```bash
   ./setup-dev-toolbox.sh
   # or
   ./setup-dev-toolbox.sh -i
   ```

2. Select your IDEs (including neovim or helix)

3. If neovim or helix is selected, you'll see a language server selection menu:
   ```
   Language Server Selection for Neovim/Helix:
   
   Select language servers to install (optional):
   ```

4. Use **Space** to select/deselect servers, **Enter** to confirm

5. The installation proceeds with your selections

### Method 2: Command-Line Arguments

Pass language servers using the `LSP:` prefix followed by comma-separated server names.

```bash
./setup-dev-toolbox.sh <IDEs> LSP:<servers>
```

#### Examples:

```bash
# Single IDE with specific language servers
./setup-dev-toolbox.sh neovim LSP:typescript,python,rust

# Multiple IDEs with all language servers
./setup-dev-toolbox.sh neovim,helix LSP:all

# Mix of GUI and CLI IDEs
./setup-dev-toolbox.sh vscode,neovim LSP:typescript,python
```

### Method 3: Direct Build Script (Advanced)

For container builds or automation, you can call the build script directly:

```bash
# First argument: IDEs
# Second argument: Language servers (no LSP: prefix)
./scripts/build.sh neovim typescript,python,rust
./scripts/build.sh helix rust,clang
./scripts/build.sh neovim,helix all
```

## Interactive Selection

### How It Works

1. **IDE Selection**: Choose neovim, helix, or both from the CLI IDE menu
2. **Automatic Detection**: If neovim or helix is selected, the script automatically prompts for language servers
3. **Multi-Select Menu**: Use the arrow keys and space bar to select multiple servers
4. **Optional**: Press Enter without selecting anything to skip language server installation

### Interactive Menu Features

- **Multi-select**: Select as many language servers as you need
- **Visual feedback**: Selected items are highlighted
- **Skip option**: Just press Enter to install without language servers
- **All option**: Select "all" to install every available language server

### Example Interactive Flow

```
Select IDEs to install (Space to select, Enter to confirm):

Select one or more CLI IDEs:
> [x] neovim
  [ ] emacs
  [ ] helix
  [ ] all

[Selected CLI IDEs: neovim]

Language Server Selection for Neovim/Helix:

Select language servers to install (optional):
  [x] typescript
  [x] python
  [x] rust
  [ ] go
  [ ] clang
  [ ] lua
  [ ] bash
  [ ] html
  [ ] css
  [ ] json
  [ ] yaml
  [ ] docker
  [ ] markdown
  [ ] all

[Selected language servers: typescript,python,rust]
```

## Command-Line Selection

### Syntax

```bash
./setup-dev-toolbox.sh <IDEs> LSP:<servers>
```

### Components

- `<IDEs>`: Comma-separated list of IDEs to install
- `LSP:<servers>`: Language servers to install (comma-separated)

### Rules

- Language servers are only installed if neovim or helix is in the IDE list
- If you specify `LSP:` but don't install neovim/helix, a warning is shown
- Case-insensitive: `LSP:TypeScript,Python` works the same as `LSP:typescript,python`
- Whitespace is trimmed: `LSP: typescript, python, rust` works fine

## Examples

### Basic Examples

```bash
# Install Neovim with TypeScript support
./setup-dev-toolbox.sh neovim LSP:typescript

# Install Helix with Python support
./setup-dev-toolbox.sh helix LSP:python

# Install both with Rust support
./setup-dev-toolbox.sh neovim,helix LSP:rust
```

### Web Development

```bash
# Frontend development stack
./setup-dev-toolbox.sh neovim LSP:typescript,html,css,json

# Full-stack JavaScript/TypeScript
./setup-dev-toolbox.sh neovim LSP:typescript,json,yaml,docker
```

### Systems Programming

```bash
# Rust development
./setup-dev-toolbox.sh neovim LSP:rust,yaml

# C/C++ development
./setup-dev-toolbox.sh helix LSP:clang,bash

# Systems polyglot
./setup-dev-toolbox.sh neovim LSP:rust,clang,go,python
```

### DevOps/Infrastructure

```bash
# DevOps setup
./setup-dev-toolbox.sh neovim LSP:yaml,docker,bash,python

# Kubernetes/Cloud development
./setup-dev-toolbox.sh helix LSP:yaml,go,python,docker
```

### Complete Installation

```bash
# Install everything
./setup-dev-toolbox.sh neovim,helix LSP:all

# Or use the "all" option for language servers
./setup-dev-toolbox.sh neovim LSP:all
```

### Mixed GUI and CLI IDEs

```bash
# VS Code for GUI work, Neovim for terminal work
./setup-dev-toolbox.sh vscode,neovim LSP:typescript,python

# Full setup with multiple IDEs
./setup-dev-toolbox.sh zed,cursor,neovim LSP:all
```

### No Language Servers

```bash
# Install Neovim without language servers
./setup-dev-toolbox.sh neovim

# Install Helix without language servers
./setup-dev-toolbox.sh helix

# In interactive mode, just press Enter when prompted
```

## Technical Details

### Architecture

```
setup-dev-toolbox.sh
    ├── Parse arguments (IDEs and LSP)
    ├── Interactive selection (if needed)
    │   ├── Select IDEs (GUI and CLI)
    │   └── Select LSPs (if neovim/helix chosen)
    ├── Build container
    │   └── Pass IDEs and LSPs to Containerfile
    │
Containerfile
    ├── Accept IDE and LSP build arguments
    └── Execute build.sh with arguments
        │
    build.sh
        ├── Install common tools
        ├── Install selected IDEs
        └── Install language servers (if specified)
```

### Build Process

1. **Argument Parsing**: `setup-dev-toolbox.sh` parses command-line arguments or presents interactive menus
2. **Container Build**: Passes IDE and LSP selections to Podman build as build arguments
3. **Installation**: `build.sh` receives arguments and installs components non-interactively
4. **Language Server Installation**: If LSPs are specified and neovim/helix is installed, LSPs are installed after IDEs

### Installation Methods by Language Server

| Server | Installation Method |
|--------|-------------------|
| TypeScript, HTML, CSS, JSON, Bash, YAML, Docker | npm (global) |
| Python (pyright) | npm (global) |
| Rust (rust-analyzer) | dnf package |
| Go (gopls) | Go toolchain |
| C/C++ (clangd) | dnf package |
| Lua | dnf package |
| Markdown (marksman) | Direct binary download |

### Environment Variables

When building via Containerfile:

```dockerfile
ARG IDE=all        # Default: install all IDEs
ARG LSP=""         # Default: no language servers
```

### File Locations

- **Setup Script**: `setup-dev-toolbox.sh`
- **Build Script**: `scripts/build.sh`
- **Container Definition**: `Containerfile`
- **Documentation**: `docs/LANGUAGE_SERVER_SELECTION.md` (this file)

## Troubleshooting

### Language Servers Not Working

**Issue**: Language server installed but not functioning in Neovim/Helix

**Solutions**:
1. Check if the language server binary is in PATH:
   ```bash
   distrobox enter devtoolbox -- which typescript-language-server
   ```

2. Verify installation:
   ```bash
   distrobox enter devtoolbox -- npm list -g
   ```

3. Check Neovim/Helix configuration for LSP setup

### Installation Fails

**Issue**: Language server installation fails during build

**Solutions**:
1. Check build logs with verbose mode:
   ```bash
   ./setup-dev-toolbox.sh --verbose neovim LSP:typescript
   ```

2. Verify network connectivity (some servers download from external sources)

3. Try installing servers individually to identify the problematic one:
   ```bash
   ./setup-dev-toolbox.sh neovim LSP:typescript
   ./setup-dev-toolbox.sh neovim LSP:python
   ```

### Wrong Servers Installed

**Issue**: Different language servers than expected were installed

**Solutions**:
1. Verify your command syntax:
   ```bash
   # Correct:
   ./setup-dev-toolbox.sh neovim LSP:typescript,python
   
   # Incorrect (missing LSP: prefix):
   ./setup-dev-toolbox.sh neovim typescript,python
   ```

2. Check the installation logs for confirmation of what was installed

3. Rebuild with `--force` flag:
   ```bash
   ./setup-dev-toolbox.sh --force neovim LSP:typescript,python
   ```

### No LSP Prompt in Interactive Mode

**Issue**: Interactive mode doesn't show language server selection

**Solutions**:
1. Ensure you selected neovim or helix in the IDE selection
2. Check that `gum` is installed:
   ```bash
   which gum
   ```
3. The prompt only appears if neovim or helix is selected

### Specific Language Server Issues

#### TypeScript/JavaScript
```bash
# Verify installation
distrobox enter devtoolbox -- typescript-language-server --version

# Reinstall if needed
distrobox enter devtoolbox -- npm install -g typescript-language-server typescript
```

#### Python (pyright)
```bash
# Verify installation
distrobox enter devtoolbox -- pyright --version

# Reinstall if needed
distrobox enter devtoolbox -- npm install -g pyright
```

#### Rust (rust-analyzer)
```bash
# Verify installation
distrobox enter devtoolbox -- rust-analyzer --version

# Reinstall if needed
distrobox enter devtoolbox -- sudo dnf install -y rust-analyzer
```

### Getting Help

If you continue to experience issues:

1. Enable debug mode:
   ```bash
   ./setup-dev-toolbox.sh --debug neovim LSP:typescript
   ```

2. Check the container logs:
   ```bash
   podman logs $(podman ps -a -q --filter ancestor=localhost/devtoolbox)
   ```

3. Open an issue with:
   - Your command
   - Error messages
   - Debug output
   - System information (`uname -a`, `podman version`)

## Related Documentation

- [Multiple IDE Selection](./MULTIPLE_IDE_SELECTION.md)
- [One-Command Installation](./ONE_COMMAND_INSTALL.md)
- [JetBrains Integration](./JETBRAINS_INTEGRATION.md)
- [Main README](../README.md)

## Contributing

To add a new language server:

1. Add installation logic to `install_language_servers()` function in `scripts/build.sh`
2. Add the server to the case statement
3. Update the available servers list in `show_usage()` in both scripts
4. Update this documentation
5. Test the installation

Example:

```bash
# In scripts/build.sh, add to the case statement:
"mylang")
    echo "Installing MyLang language server..."
    npm install -g mylang-language-server
    ;;
```

## Version History

- **v1.0** (2024): Initial language server selection feature
  - Interactive selection with gum
  - Command-line argument support
  - 13 language servers supported
  - Integration with setup-dev-toolbox.sh