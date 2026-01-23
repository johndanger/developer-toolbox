# Multiple IDE Selection Feature

This document describes the multiple IDE selection capability added to the developer toolbox container system, allowing users to install specific combinations of IDEs in a single container build.

## Overview

Previously, the system only supported installing either a single IDE or all IDEs. Now you can select any combination of IDEs to create a customized development environment that fits your exact needs.

## Supported IDEs

- **Zed** (`zed`) - Modern, fast editor with collaboration features
- **VS Code** (`vscode`, `code`) - Microsoft's popular IDE with extensive extensions
- **Cursor** (`cursor`) - AI-powered code editor with smart completion
- **JetBrains Toolbox** (`jetbrains`, `toolbox`) - Unified manager for all JetBrains IDEs

## Syntax

The system accepts comma-separated lists of IDE names:

```bash
# Single IDE
./build.sh zed

# Multiple IDEs
./build.sh zed,cursor
./build.sh vscode,jetbrains
./build.sh zed,cursor,jetbrains

# All IDEs (traditional)
./build.sh all
./build.sh  # defaults to all
```

## Usage Examples

### Build Script Usage

```bash
# Install specific combinations
./build.sh zed,cursor                    # Zed + Cursor
./build.sh vscode,jetbrains             # VS Code + JetBrains Toolbox
./build.sh zed,cursor,jetbrains         # Three IDEs
./build.sh zed,vscode,cursor,jetbrains  # All four IDEs explicitly

# Whitespace is automatically handled
./build.sh "zed, cursor, jetbrains"     # Spaces are trimmed

# Aliases work in combinations
./build.sh code,toolbox                 # VS Code + JetBrains Toolbox
```

### Justfile Usage

```bash
# Build with multiple IDEs
just build-local zed,cursor
just build-local vscode,jetbrains
just build-local zed,cursor,jetbrains

# Setup (build + create) with multiple IDEs
just setup "zed,cursor"
just setup "vscode,jetbrains"

# Export all installed IDEs (detects what's available)
just export-all
```

### Container Build Usage

```bash
# Direct container builds
podman build . --build-arg IDE=zed,cursor -t devtoolbox-zed-cursor
podman build . --build-arg IDE=vscode,jetbrains -t devtoolbox-vs-jetbrains
podman build . --build-arg IDE=zed,cursor,jetbrains -t devtoolbox-multi
```

## Benefits

### Resource Optimization
- **Smaller Images**: Only install what you need
- **Faster Builds**: Skip unused IDEs
- **Reduced Storage**: Eliminate redundant tools

### Workflow Flexibility
- **Language-Specific**: Install IDEs for your tech stack
- **Role-Based**: Different combinations for different roles
- **Project-Specific**: Match IDE selection to project requirements

### Common Combinations

```bash
# Web Development
./build.sh vscode,cursor              # Traditional + AI-powered

# Multi-Language Development  
./build.sh vscode,jetbrains           # General IDE + JetBrains ecosystem

# Modern Development
./build.sh zed,cursor                 # Fast editor + AI assistance

# Full Stack
./build.sh zed,vscode,jetbrains       # Multiple approaches covered
```

## Error Handling

The system validates each IDE name and provides helpful error messages:

```bash
# Invalid IDE name
$ ./build.sh zed,invalid
Installing multiple IDEs: zed,invalid

Installing: zed
✓ Installing Zed...

Installing: invalid
✗ Error: Unknown IDE 'invalid'
Available IDEs: zed, vscode, cursor, jetbrains
Failed to install: invalid
```

## Implementation Details

### Parsing Logic
1. Input is converted to lowercase for case-insensitive matching
2. Comma-separated values are split into an array
3. Whitespace is trimmed from each IDE name
4. Each IDE is validated before installation
5. Installation stops on first error

### Aliases Support
- `code` → `vscode`
- `toolbox` → `jetbrains`

### Installation Order
IDEs are installed in the order specified in the comma-separated list.

## Advanced Usage

### Container Tagging Strategy

Use descriptive tags to track your combinations:

```bash
# Tag by IDE combination
podman build . --build-arg IDE=zed,cursor -t devtoolbox:zed-cursor
podman build . --build-arg IDE=vscode,jetbrains -t devtoolbox:vs-jetbrains

# Tag by use case
podman build . --build-arg IDE=zed,cursor -t devtoolbox:ai-dev
podman build . --build-arg IDE=vscode,jetbrains -t devtoolbox:enterprise
```

### Environment-Specific Builds

```bash
# Development environment
just build-local zed,cursor

# Production debugging environment  
just build-local vscode,jetbrains

# Learning/experimentation environment
just build-local all
```

### Script Integration

```bash
#!/bin/bash
# Build different environments for different projects

case "$PROJECT_TYPE" in
    "web")
        just build-local vscode,cursor
        ;;
    "java")
        just build-local jetbrains
        ;;
    "go"|"rust")
        just build-local zed,cursor
        ;;
    "mixed")
        just build-local all
        ;;
esac
```

## Troubleshooting

### Common Issues

1. **Quoting for Shell**
   ```bash
   # Correct - quotes prevent shell interpretation
   just setup "zed,cursor"
   
   # May cause issues in some shells
   just setup zed,cursor
   ```

2. **Case Sensitivity**
   ```bash
   # All of these work (case insensitive)
   ./build.sh Zed,CURSOR
   ./build.sh ZED,cursor
   ./build.sh zed,Cursor
   ```

3. **Whitespace Handling**
   ```bash
   # All of these work (whitespace is trimmed)
   ./build.sh zed,cursor
   ./build.sh zed, cursor
   ./build.sh "zed , cursor , jetbrains"
   ```

### Validation

Use the test script to verify parsing logic:

```bash
./test-multi-ide.sh
```

This will test all combinations and show exactly what would be installed.

## Migration Guide

### From Single IDE Builds

**Before:**
```bash
# Had to choose one or all
just build-local zed     # Only Zed
just build-local         # All IDEs (heavyweight)
```

**After:**
```bash
# Can choose optimal combination
just build-local zed,cursor           # Zed + AI assistance
just build-local vscode,jetbrains     # VS Code + JetBrains tools
```

### From All IDEs Builds

**Before:**
```bash
just build-local  # ~2GB+ with all IDEs
```

**After:**
```bash
# Smaller, focused builds
just build-local zed,cursor      # ~500MB lighter
just build-local vscode,jetbrains # Only what you need
```

## Future Enhancements

### Planned Features
- **Preset Combinations**: Named combinations for common workflows
- **Dependency Detection**: Automatic inclusion of complementary tools
- **Build Caching**: Faster rebuilds when adding IDEs to existing combinations

### Preset Examples (Future)
```bash
# Potential future syntax
just build-local --preset web-dev     # vscode,cursor
just build-local --preset java-dev    # jetbrains
just build-local --preset modern-dev  # zed,cursor
```

## Related Files

- `build.sh` - Main installation logic with multiple IDE support
- `justfile` - Automation commands supporting multiple IDE selection
- `test-multi-ide.sh` - Test script for validation
- `README.md` - User documentation with examples
- `example.sh` - Interactive examples of multiple IDE usage

## Best Practices

1. **Start Small**: Begin with 1-2 IDEs and expand as needed
2. **Match Workflow**: Choose IDEs that complement your development style
3. **Consider Resources**: More IDEs = larger containers and longer builds
4. **Use Descriptive Tags**: Tag containers by IDE combination for easy identification
5. **Test Combinations**: Use the test script to verify complex combinations before building

This feature provides the flexibility to create perfectly tailored development environments while maintaining the simplicity and power of the existing toolbox system.