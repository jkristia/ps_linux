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

## Installation

To make these commands available automatically whenever you start PowerShell (like `.zshrc` for zsh), you need to add the script to your PowerShell profile.

### Step 1: Locate Your PowerShell Profile

PowerShell uses profile scripts that load automatically on startup. Check your profile path:

```powershell
$PROFILE
```

Or see all profile locations:

```powershell
$PROFILE | Select-Object -Property *
```

**Common profile locations:**
- **PowerShell 7+**: `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- **PowerShell 5.1**: `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

### Step 2: Create Profile (if it doesn't exist)

```powershell
# Check if profile exists
Test-Path $PROFILE

# Create profile if needed
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}
```

### Step 3: Add Script to Profile

**Option A: Copy script content into profile**
```powershell
# Open profile in default editor
notepad $PROFILE

# Or use VS Code
code $PROFILE
```

Then paste the entire content of `linux-commands.ps1` into your profile.

**Option B: Dot-source the script from profile**
```powershell
# Add this line to your profile
. "C:\Path\To\linux-commands.ps1"
```

Replace `C:\Path\To\` with the actual path to `linux-commands.ps1`.

### Step 4: Reload Profile

After editing your profile, reload it:

```powershell
. $PROFILE
```

Or restart PowerShell.

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

## Future Enhancements

Potential additions:
- `tail`, `head`, `cat` wrappers
- `awk`, `sed` equivalents
- More `find` predicates
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
