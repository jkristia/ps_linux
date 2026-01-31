# Linux Commands for PowerShell - Summary

## Overview

This project provides PowerShell function wrappers that enable Linux-style commands on Windows. The script redefines common Linux commands (`ls`, `ll`, `grep`, `ps`, `find`) to work seamlessly in PowerShell environments.

## Supported Commands

### `ls` - List Directory Contents
- **Supported flags:**
  - `-a` : Show all files including hidden
  - `-l` : Long format (detailed listing)
  - `-G` : Colorize output (enabled by default in PowerShell)
  - `-F` : Append indicators (/ for directories, * for executables)

**Examples:**
```powershell
ls -alGF
ls -la C:\Users
ls -F
```

### `ll` - Long List (Alias for ls -alGF)
Convenient shortcut that combines all flags for a detailed, classified listing with hidden files.

**Examples:**
```powershell
ll
ll C:\Projects
```

### `grep` - Search Text Patterns
- **Supported flags:**
  - `-i` : Case insensitive search
  - `-v` : Invert match
  - `-n` : Show line numbers
  - `-r` : Recursive search
  - `-l` : List filenames only

**Examples:**
```powershell
Get-Content file.txt | grep "pattern"
grep "error" log.txt
grep -r "TODO" *.cs
```

### `ps` - Process Information
- **Supported flags:**
  - `-a` : Show all processes
  - `-u` : User-oriented format (detailed)
  - `-x` : Include all processes

**Examples:**
```powershell
ps -aux
ps
```

### `find` - Search for Files
- **Supported options:**
  - `-name` : Search by filename pattern
  - `-iname` : Case-insensitive name search
  - `-type f` : Files only
  - `-type d` : Directories only

**Examples:**
```powershell
find . -name "*.txt"
find C:\Projects -type f -name "*.ps1"
find . -type d
```

### `mc` - Midnight Commander
Terminal-based file manager with a text user interface.

**Installation:**
```powershell
winget install GNU.MidnightCommander
```

**Usage:**
```powershell
mc
```

### `btop` - Resource Monitor
Advanced resource monitor showing CPU, memory, disks, network and processes.

**Installation:**
```powershell
winget install -e --id aristocratos.btop4win
```

**Note:** After installation, restart PowerShell or refresh your PATH:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
```

**Usage:**
```powershell
btop
```

### `nano` - Text Editor
Simple and user-friendly terminal text editor.

**Installation:**
```powershell
winget install GNU.Nano
```

**Usage:**
```powershell
nano filename.txt
```

## Installation

To make these commands available automatically whenever you start PowerShell (like `.zshrc` for zsh), run this single block from the directory containing `linux-commands.ps1` (same approach as in agent.md):

```powershell
# Create profile directory and file if they don't exist
$ProfileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $ProfileDir)) {
  New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $PROFILE)) {
  New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}

# Copy linux-commands.ps1 and aliases.ps1 to profile directory
$LinuxCommandsPath = Join-Path $ProfileDir "linux-commands.ps1"
$AliasesPath = Join-Path $ProfileDir "aliases.ps1"
Copy-Item -Path "linux-commands.ps1" -Destination $LinuxCommandsPath -Force
Copy-Item -Path "aliases.ps1" -Destination $AliasesPath -Force

# Add sourcing line to profile (only if missing)
$SourceLine = ". `"$LinuxCommandsPath`""
if (-not (Get-Content -Path $PROFILE -ErrorAction SilentlyContinue | Select-String -SimpleMatch -Pattern $SourceLine)) {
  Add-Content -Path $PROFILE -Value $SourceLine
}

# Reload profile for current session
. $PROFILE
```

## Testing Without Installation

To test the commands without modifying your profile:

```powershell
# Dot-source the script in your current session
. .\linux-commands.ps1
```

This loads the functions temporarily for the current session only.

## Compatibility

- **PowerShell 5.1** (Windows PowerShell): Fully supported
- **PowerShell 7+** (PowerShell Core): Fully supported
- **Windows 10/11**: Tested and working
- **Cross-platform**: Script is Windows-specific but can be adapted for Linux/macOS

## Known Limitations

1. **Flag combinations**: Complex flag combinations (e.g., `-alFG`) work, but some edge cases may differ from native Linux behavior
2. **grep piping**: Works with PowerShell pipelines but operates on objects, not raw text streams
3. **ps user info**: May require elevated privileges to show user information for all processes
4. **find predicates**: Supports basic predicates; advanced options like `-exec`, `-mtime` not yet implemented

## Additional Linux Commands (Not Yet Implemented)

These are commonly used Linux commands that do NOT exist in PowerShell and would benefit from wrappers:

### File Operations
- **`touch`** - Create empty file or update timestamp
  - PowerShell equivalent: `New-Item`, `Set-ItemProperty`
  - Supported flags:
    - (none for basic usage)
  - Example: `touch newfile.txt`

- **`diff`** - Compare files line by line
  - PowerShell equivalent: `Compare-Object`
  - Supported flags:
    - `-u` : Unified diff format
    - `-q` : Report only if files differ
  - Example: `diff file1.txt file2.txt`

### Permissions
- **`chmod`** - Change file permissions
  - PowerShell equivalent: `icacls`, `Set-Acl`
  - Supported flags:
    - Symbolic mode (e.g., `u+x`, `g-w`, `o=r`)
    - Octal mode (e.g., `755`, `644`)
  - Example: `chmod +x script.sh`

## Future Enhancements

Potential additions:
- `cat`, `head`, `tail` wrappers for file viewing
- `wc`, `sort`, `uniq`, `cut` for text processing
- `sed`, `awk` equivalents for advanced text manipulation
- `touch`, `diff` for file operations
- More `find` predicates (e.g., `-exec`, `-mtime`)
- `chmod`, `chown` wrappers for permission management
- Color customization options
- Performance optimizations for large directories

## Troubleshooting

### "Cannot be loaded because running scripts is disabled"
Enable script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Commands not working after installation
- Verify profile path: `$PROFILE`
- Check profile exists: `Test-Path $PROFILE`
- Reload profile: `. $PROFILE`
- Check for syntax errors in profile

### Functions conflict with existing aliases
The script overrides default PowerShell behavior. To restore originals, remove functions from profile and restart PowerShell.
