# IDE Extension Installation Debugging Guide

## Overview

The developer toolbox automatically installs container development extensions for VS Code, Windsurf, and Cursor when you first launch them. This document explains how the system works and how to debug issues.

## How It Works

### 1. Build Time
When an IDE is installed (e.g., `code`, `windsurf`, `cursor`):
- A unified extension setup script is created at `/usr/local/bin/setup-ide-extensions`
- The IDE's binary is wrapped to auto-install extensions on first launch
- Original binary is moved to `<path>.real` (e.g., `/usr/bin/code.real`)
- A symlink is created pointing to the wrapper at `/usr/local/bin/<ide>-wrapped`

### 2. First Launch
When you run the IDE command (e.g., `code`):
- The wrapper script intercepts the command
- It immediately launches the real IDE binary
- In the background, it waits 12 seconds for the IDE to initialize
- Then it runs `setup-ide-extensions` to install missing extensions
- Output is logged to `/tmp/ide-extension-setup-<ide>-<timestamp>.log`

### 3. Extension Installation
The `setup-ide-extensions` script:
- Detects all installed VS Code-based IDEs
- Checks which extensions are missing
- Installs each missing extension using `<ide> --install-extension <ext> --force`
- Reports success or failure for each extension

## Extensions Installed

The following extensions are automatically installed:
- `ms-vscode-remote.remote-containers` - Dev Containers support
- `ms-vscode-remote.remote-ssh` - Remote SSH support
- `ms-azuretools.vscode-docker` - Docker integration
- `DankLinux.dms-theme` - MangosteenOS theme

## Debugging

### Check if wrapper is installed
```bash
# Check if the IDE binary is wrapped
ls -la $(which code)
# Should show: /usr/bin/code -> /usr/local/bin/code-wrapped

# Check if the real binary exists
ls -la /usr/bin/code.real
# Should exist if wrapping was successful
```

### Check extension setup script
```bash
# Verify the setup script exists and is executable
ls -la /usr/local/bin/setup-ide-extensions
# Should show: -rwxr-xr-x ... /usr/local/bin/setup-ide-extensions
```

### Manual extension installation
```bash
# Run the extension setup manually
setup-ide-extensions

# This will show real-time output of what's being installed
```

### Check installation logs
```bash
# View the most recent extension setup log for VS Code
cat /tmp/ide-extension-setup-code-*.log | tail -n 50

# View for Windsurf
cat /tmp/ide-extension-setup-windsurf-*.log | tail -n 50

# View for Cursor
cat /tmp/ide-extension-setup-cursor-*.log | tail -n 50

# List all extension setup logs
ls -lht /tmp/ide-extension-setup-*.log

# Check wrapper trace log (shows if wrapper is executing)
cat /tmp/ide-wrapper-trace.log

# Check for wrapper execution markers
ls -lht /tmp/ide-wrapper-executed-*.tmp
```

### Check which extensions are installed
```bash
# For VS Code
code --list-extensions

# For Windsurf
windsurf --list-extensions

# For Cursor
cursor --list-extensions
```

### Test wrapper directly
```bash
# The wrapper script is at
cat /usr/local/bin/code-wrapped

# Test if it can find the real binary
/usr/local/bin/code-wrapped --version
```

## Common Issues

### Issue: Extensions not installing
**Symptoms:** IDE launches but extensions never appear

**Diagnosis:**
```bash
# Check if wrapper is being called
cat /tmp/ide-wrapper-trace.log

# Check if background process is running
ps aux | grep -i "setup-ide-extensions"

# Check extension installation logs
tail -f /tmp/ide-extension-setup-code-*.log

# Check if wrapper execution markers exist
ls -l /tmp/ide-wrapper-executed-*.tmp
```

**Solutions:**
1. Run manual installation: `setup-ide-extensions`
2. Check if auto-install is disabled: `echo $DISABLE_IDE_AUTO_EXTENSIONS`
3. Verify IDE binary exists: `ls -la /usr/bin/code.real`
4. Check extension marketplace access: `code --install-extension ms-vscode-remote.remote-containers --force`

### Issue: Wrapper not created
**Symptoms:** IDE binary is not wrapped, direct binary still in place

**Diagnosis:**
```bash
# Check if binary was moved
ls -la /usr/bin/code
ls -la /usr/bin/code.real

# Check for wrapper
ls -la /usr/local/bin/code-wrapped
```

**Solutions:**
1. Re-run the IDE installation from build script
2. Manually create wrapper by sourcing build.sh functions
3. Check file permissions

### Issue: Extension installation fails silently
**Symptoms:** Logs show installation attempts but extensions don't appear

**Diagnosis:**
```bash
# Test extension installation directly
/usr/bin/code.real --install-extension ms-vscode-remote.remote-containers --force

# Check for extension marketplace connectivity
curl -I https://marketplace.visualstudio.com
```

**Solutions:**
1. Ensure network connectivity to extension marketplace
2. Try installing extensions manually within the IDE
3. Check IDE version compatibility with extensions
4. Clear extension cache: `rm -rf ~/.vscode/extensions` (backup first!)

### Issue: "Real binary not found" error
**Symptoms:** Wrapper runs but can't find the `.real` binary

**Diagnosis:**
```bash
# Check all possible locations
ls -la /usr/bin/code.real
ls -la /usr/local/bin/code.real
ls -la /opt/code/code.real
```

**Solutions:**
1. Restore from backup: `mv /usr/bin/code.real /usr/bin/code`
2. Re-install the IDE
3. Remove wrapper symlink: `rm /usr/bin/code && mv /usr/bin/code.real /usr/bin/code`

## Disabling Auto-Installation

If you want to disable automatic extension installation:

```bash
# Set environment variable (add to your shell rc file)
export DISABLE_IDE_AUTO_EXTENSIONS=1

# Or set it before launching the IDE
DISABLE_IDE_AUTO_EXTENSIONS=1 code
```

## Manual Extension Installation

If automatic installation doesn't work, you can install extensions manually:

### Option 1: Using the command line
```bash
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-azuretools.vscode-docker
code --install-extension DankLinux.dms-theme
```

### Option 2: Using the IDE
1. Launch the IDE (VS Code, Windsurf, or Cursor)
2. Open the Extensions view (Ctrl+Shift+X)
3. Search for and install:
   - "Dev Containers"
   - "Remote - SSH"
   - "Docker"
   - "DankLinux DMS Theme"

## Verifying Success

After installation (automatic or manual), verify extensions are working:

```bash
# List installed extensions
code --list-extensions | grep -E "remote-containers|remote-ssh|docker|dms-theme"

# Should output:
# ms-azuretools.vscode-docker
# ms-vscode-remote.remote-containers
# ms-vscode-remote.remote-ssh
# DankLinux.dms-theme
```

## Advanced Debugging

### Enable verbose logging
Edit `/usr/local/bin/setup-ide-extensions` and add `set -x` at the top to enable bash debugging:

```bash
#!/bin/bash
set -x  # Add this line
# ... rest of script
```

### Watch extension installation in real-time
```bash
# In one terminal, launch the IDE
code

# In another terminal, watch the logs
watch -n 1 'echo "=== Wrapper Trace ===" && tail -10 /tmp/ide-wrapper-trace.log 2>/dev/null && echo && echo "=== Extension Logs ===" && ls -lht /tmp/ide-extension-setup-*.log 2>/dev/null | head -5 && echo && tail -20 /tmp/ide-extension-setup-code-*.log 2>/dev/null | tail -20'
```

### Check wrapper execution
```bash
# Add debug output to wrapper
# Edit /usr/local/bin/code-wrapped and add:
echo "DEBUG: Wrapper executed at $(date)" >> /tmp/wrapper-debug.log
echo "DEBUG: Real binary: $REAL_BINARY" >> /tmp/wrapper-debug.log
```

## Getting Help

If you continue to have issues:

1. Collect diagnostic information:
   ```bash
   {
     echo "=== System Info ==="
     uname -a
     echo ""
     echo "=== IDE Binaries ==="
     ls -la /usr/bin/code* /usr/local/bin/code* 2>/dev/null
     echo ""
     echo "=== Extension Setup Script ==="
     ls -la /usr/local/bin/setup-ide-extensions
     echo ""
     echo "=== Wrapper Trace Log ==="
     cat /tmp/ide-wrapper-trace.log 2>/dev/null || echo "No trace log found"
     echo ""
     echo "=== Wrapper Execution Markers ==="
     ls -l /tmp/ide-wrapper-executed-*.tmp 2>/dev/null || echo "No markers found"
     echo ""
     echo "=== Recent Logs ==="
     ls -lht /tmp/ide-extension-setup-*.log 2>/dev/null | head -5
     echo ""
     echo "=== Latest Log Content ==="
     tail -50 /tmp/ide-extension-setup-*.log 2>/dev/null | tail -50
     echo ""
     echo "=== Installed Extensions ==="
     code --list-extensions 2>/dev/null
   } > ~/ide-extension-debug.txt
   ```

2. Share the `~/ide-extension-debug.txt` file with the MangosteenOS team

## Cleanup

To remove the wrapper and restore original IDE behavior:

```bash
# For VS Code
sudo rm /usr/local/bin/code-wrapped
sudo rm /usr/bin/code
sudo mv /usr/bin/code.real /usr/bin/code

# For Windsurf
sudo rm /usr/local/bin/windsurf-wrapped
sudo rm /usr/bin/windsurf
sudo mv /usr/bin/windsurf.real /usr/bin/windsurf

# For Cursor
sudo rm /usr/local/bin/cursor-wrapped
sudo rm /usr/bin/cursor
sudo mv /usr/bin/cursor.real /usr/bin/cursor

# Clean up logs and trace files
rm /tmp/ide-extension-setup-*.log
rm /tmp/ide-wrapper-trace.log
rm /tmp/ide-wrapper-executed-*.tmp
```
