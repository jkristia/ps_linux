# Agent Instructions

## Project Overview

This is a PowerShell utility project that provides Linux command aliases and wrappers for Windows PowerShell environments. The goal is to enable Linux users to use familiar commands (`ls -alGF`, `grep`, `ps -aux`, `find`) seamlessly on Windows.

## Architecture & Patterns

### Script Structure
- **Main script**: PowerShell profile script (`.ps1`) that defines function wrappers for Linux commands
- **Target location**: User's PowerShell profile directory (typically `$PROFILE` path)
- **Loading mechanism**: Auto-loaded via PowerShell profile, similar to `.zshrc` for zsh

### Command Implementation Patterns

**Alias-based approach** (simple commands):
```powershell
Set-Alias -Name grep -Value Select-String
```

**Function wrapper approach** (commands with arguments):
```powershell
function ls {
    param([string]$Options)
    if ($Options -match "a") { Get-ChildItem -Force }
    # Parse and map Linux flags to PowerShell cmdlets
}
```

### Key Technical Considerations

1. **Argument parsing**: Linux flags (e.g., `-alGF`) need manual parsing in PowerShell functions
2. **Piping behavior**: Must preserve PowerShell's object-based pipeline while mimicking text-based grep
3. **Case sensitivity**: PowerShell is case-insensitive by default; some commands may need `-CaseSensitive` flags
4. **Profile loading**: Use `$PROFILE` variable to identify correct profile path (multiple profiles exist for different hosts)

## Developer Workflows

### Testing scripts locally
```powershell
. .\script-name.ps1  # Dot-source to load functions in current session
```

### Installing to profile
```powershell
# Create profile directory and file if they don't exist
$ProfileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $ProfileDir)) {
    New-Item -Path $ProfileDir -ItemType Directory -Force
}
New-Item -Path $PROFILE -ItemType File -Force

# Copy linux-commands.ps1 to profile directory
$LinuxCommandsPath = Join-Path $ProfileDir "linux-commands.ps1"
Copy-Item -Path "linux-commands.ps1" -Destination $LinuxCommandsPath -Force

# Copy aliases.ps1 to profile directory
$AliasesPath = Join-Path $ProfileDir "aliases.ps1"
Copy-Item -Path "aliases.ps1" -Destination $AliasesPath -Force

# Add sourcing lines to profile
Add-Content -Path $PROFILE -Value ". `"$LinuxCommandsPath`""
Add-Content -Path $PROFILE -Value ". `"$AliasesPath`""

# Verify installation
Write-Host "Linux commands installed!"
Write-Host "Available commands: ls, grep, ps, find"
Write-Host "Available aliases: mc, btop, open"
Write-Host "Location: $PROFILE"
```

### Profile locations
- **Current User, Current Host**: `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` (PS 7+)
- **Current User, Current Host**: `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` (PS 5.1)
- Use `$PROFILE.CurrentUserCurrentHost` to target the right one

## Command Equivalency Reference

| Linux Command | PowerShell Native | Implementation Strategy |
|---------------|-------------------|-------------------------|
| `ls -alGF` | `Get-ChildItem` | Parse flags, map to `-Force`, `-File`, `-Directory` |
| `grep` | `Select-String` | Function wrapper to handle piped input |
| `ps -aux` | `Get-Process` | Map flags to `-IncludeUserName`, format output |
| `find` | `Get-ChildItem -Recurse` | Parse path and predicates |

## Project-Specific Conventions

- **Documentation**: Keep `summary.md` updated with installation instructions and supported commands
- **Cross-version support**: Test with both PowerShell 5.1 (Windows PowerShell) and 7+ (PowerShell Core)
- **Error handling**: Fail gracefully when Linux flags have no PowerShell equivalent
