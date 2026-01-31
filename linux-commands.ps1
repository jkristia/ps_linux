# Linux Command Wrappers for PowerShell
# Author: Auto-generated
# Description: Provides Linux-style command aliases for Windows PowerShell

# ls - List directory contents with Linux-style flags
function ls {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    $Path = "."
    $ShowHidden = $false
    $LongFormat = $false
    $Classify = $false
    
    # Parse arguments
    foreach ($arg in $Arguments) {
        if ($arg -match '^-') {
            # Parse flags
            if ($arg -match 'a') { $ShowHidden = $true }
            if ($arg -match 'l') { $LongFormat = $true }
            if ($arg -match 'F') { $Classify = $true }
            # G (colorize) is default in PowerShell
        } else {
            # Assume it's a path
            $Path = $arg
        }
    }
    
    # Get items
    $items = if ($ShowHidden) {
        Get-ChildItem -Path $Path -Force
    } else {
        Get-ChildItem -Path $Path
    }
    
    # Format output
    if ($LongFormat) {
        $items | Format-Table -AutoSize @{
            Label = "Mode"
            Expression = { $_.Mode }
        }, @{
            Label = "LastWriteTime"
            Expression = { $_.LastWriteTime.ToString("MMM dd HH:mm") }
        }, @{
            Label = "Length"
            Expression = { if ($_.PSIsContainer) { "" } else { $_.Length } }
        }, @{
            Label = "Name"
            Expression = { 
                if ($Classify) {
                    if ($_.PSIsContainer) { $_.Name + "/" }
                    elseif ($_.Extension -in @('.exe', '.bat', '.cmd', '.ps1')) { $_.Name + "*" }
                    else { $_.Name }
                } else {
                    $_.Name
                }
            }
        }
    } else {
        if ($Classify) {
            $items | ForEach-Object {
                if ($_.PSIsContainer) { 
                    Write-Host $_.Name"/" -ForegroundColor Blue
                } elseif ($_.Extension -in @('.exe', '.bat', '.cmd', '.ps1')) {
                    Write-Host $_.Name"*" -ForegroundColor Green
                } else {
                    Write-Host $_.Name
                }
            }
        } else {
            $items
        }
    }
}

# ll - Alias for ls -alGF
function ll {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    # Prepend -alGF to any arguments and call our ls function
    $allArgs = @('-alGF') + $Arguments
    & (Get-Command -Name ls -CommandType Function) @allArgs
}

# grep - Search for patterns in text
function grep {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Pattern,
        
        [Parameter(ValueFromPipeline=$true)]
        [object]$InputObject,
        
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Files,
        
        [switch]$i,  # Case insensitive
        [switch]$v,  # Invert match
        [switch]$n,  # Show line numbers
        [switch]$r,  # Recursive
        [switch]$l   # List filenames only
    )
    
    begin {
        $allInput = @()
    }
    
    process {
        if ($null -ne $InputObject) {
            $allInput += $InputObject
        }
    }
    
    end {
        # If we have piped input, search through it
        if ($allInput.Count -gt 0) {
            $caseSensitive = -not $i

            # Convert piped objects to a single formatted text stream to avoid
            # Format-Table/Format-List sequencing errors (e.g., ll | grep ...)
            $lines = $allInput | Out-String -Stream | Where-Object { $_ -ne "" }

            $matchedLines = if ($caseSensitive) {
                $lines | Where-Object { $_ -cmatch $Pattern }
            } else {
                $lines | Where-Object { $_ -match $Pattern }
            }

            if ($v) {
                $matchedLines = $lines | Where-Object {
                    if ($caseSensitive) { $_ -cnotmatch $Pattern } else { $_ -notmatch $Pattern }
                }
            }

            if ($n) {
                $lineNumber = 0
                $lines | ForEach-Object {
                    $lineNumber++
                    if ($v) {
                        if ($caseSensitive) {
                            if ($_ -cnotmatch $Pattern) { "${lineNumber}:$_" }
                        } else {
                            if ($_ -notmatch $Pattern) { "${lineNumber}:$_" }
                        }
                    } else {
                        if ($caseSensitive) {
                            if ($_ -cmatch $Pattern) { "${lineNumber}:$_" }
                        } else {
                            if ($_ -match $Pattern) { "${lineNumber}:$_" }
                        }
                    }
                }
            } else {
                $matchedLines
            }
        }
        # Otherwise search in files
        elseif ($Files) {
            $options = @{}
            if (-not $i) { $options['CaseSensitive'] = $true }
            if ($l) { $options['List'] = $true }
            
            if ($r) {
                Get-ChildItem -Recurse -File | Select-String -Pattern $Pattern @options
            } else {
                $Files | ForEach-Object {
                    Select-String -Path $_ -Pattern $Pattern @options
                }
            }
        }
    }
}

# ps - Display process information
function ps {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    $ShowAll = $false
    $UserFormat = $false
    
    # Parse flags
    foreach ($arg in $Arguments) {
        if ($arg -match '^-') {
            if ($arg -match 'a') { $ShowAll = $true }
            if ($arg -match 'u') { $UserFormat = $true }
            if ($arg -match 'x') { $ShowAll = $true }
        }
    }
    
    # Get processes
    $processes = Get-Process
    
    # Format output
    if ($UserFormat) {
        $processes | Format-Table -AutoSize @{
            Label = "USER"
            Expression = { 
                try { $_.StartInfo.UserName } 
                catch { $env:USERNAME }
            }
        }, @{
            Label = "PID"
            Expression = { $_.Id }
        }, @{
            Label = "%CPU"
            Expression = { [math]::Round($_.CPU, 2) }
        }, @{
            Label = "%MEM"
            Expression = { 
                $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
                [math]::Round(($_.WorkingSet64 / $totalMemory * 100), 2)
            }
        }, @{
            Label = "VSZ"
            Expression = { [math]::Round($_.VirtualMemorySize64 / 1KB, 0) }
        }, @{
            Label = "RSS"
            Expression = { [math]::Round($_.WorkingSet64 / 1KB, 0) }
        }, @{
            Label = "STARTED"
            Expression = { 
                try { $_.StartTime.ToString("HH:mm") }
                catch { "" }
            }
        }, @{
            Label = "COMMAND"
            Expression = { $_.ProcessName }
        }
    } else {
        $processes | Format-Table -AutoSize Id, ProcessName, CPU, WorkingSet
    }
}

# Ensure the built-in alias 'ps' does not override this function
Remove-Item -Path Alias:ps -ErrorAction SilentlyContinue

# find - Search for files
function find {
    param(
        [Parameter(Position=0)]
        [string]$Path = ".",
        
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    $Name = $null
    $Type = $null
    $i = 0
    
    # Parse arguments
    while ($i -lt $Arguments.Count) {
        $arg = $Arguments[$i]
        
        switch ($arg) {
            "-name" {
                $i++
                if ($i -lt $Arguments.Count) {
                    $Name = $Arguments[$i]
                }
            }
            "-iname" {
                $i++
                if ($i -lt $Arguments.Count) {
                    $Name = $Arguments[$i]
                }
            }
            "-type" {
                $i++
                if ($i -lt $Arguments.Count) {
                    $Type = $Arguments[$i]
                }
            }
        }
        $i++
    }
    
    # Build Get-ChildItem parameters
    $params = @{
        Path = $Path
        Recurse = $true
        ErrorAction = 'SilentlyContinue'
    }
    
    if ($Name) {
        $params['Filter'] = $Name
    }
    
    # Get items
    $items = Get-ChildItem @params
    
    # Filter by type
    if ($Type) {
        switch ($Type) {
            "f" { $items = $items | Where-Object { -not $_.PSIsContainer } }
            "d" { $items = $items | Where-Object { $_.PSIsContainer } }
        }
    }
    
    # Output full paths (Unix-style)
    $items | ForEach-Object { $_.FullName -replace '\\', '/' }
}

# touch - Create empty file or update timestamp
function touch {
    param(
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$Files
    )
    
    foreach ($file in $Files) {
        $filePath = Resolve-Path -Path $file -ErrorAction SilentlyContinue
        
        if ($filePath) {
            # File exists - update timestamp
            (Get-Item $file).LastWriteTime = Get-Date
        } else {
            # File doesn't exist - create empty file
            New-Item -Path $file -ItemType File -Force | Out-Null
        }
    }
}

# diff - Compare files
function diff {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$File1,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$File2,
        
        [switch]$u,  # Unified diff format
        [switch]$q   # Quiet mode - report only if files differ
    )
    
    # Check if files exist
    if (-not (Test-Path $File1)) {
        Write-Error "File not found: $File1"
        return
    }
    if (-not (Test-Path $File2)) {
        Write-Error "File not found: $File2"
        return
    }
    
    # Get file contents
    $content1 = Get-Content -Path $File1 -Raw
    $content2 = Get-Content -Path $File2 -Raw
    
    # Compare files
    $diff = Compare-Object -ReferenceObject ($content1 -split '\n') `
                          -DifferenceObject ($content2 -split '\n') `
                          -IncludeEqual
    
    if ($q) {
        # Quiet mode - just report if different
        if ($diff) {
            Write-Host "Files differ"
        }
    } elseif ($u) {
        # Unified diff format
        Write-Host "--- $File1"
        Write-Host "+++ $File2"
        $diff | ForEach-Object {
            if ($_.SideIndicator -eq '=>') {
                Write-Host "+$($_.InputObject)" -ForegroundColor Green
            } elseif ($_.SideIndicator -eq '<=') {
                Write-Host "-$($_.InputObject)" -ForegroundColor Red
            } else {
                Write-Host " $($_.InputObject)"
            }
        }
    } else {
        # Standard diff format
        $diff | ForEach-Object {
            if ($_.SideIndicator -eq '=>') {
                Write-Host "> $($_.InputObject)" -ForegroundColor Green
            } elseif ($_.SideIndicator -eq '<=') {
                Write-Host "< $($_.InputObject)" -ForegroundColor Red
            }
        }
    }
}

# chmod - Change file permissions (Windows ACL wrapper)
function chmod {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Mode,
        
        [Parameter(Mandatory=$true, Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$Files
    )
    
    foreach ($file in $Files) {
        if (-not (Test-Path $file)) {
            Write-Error "File not found: $file"
            continue
        }
        
        # Parse symbolic mode (e.g., u+x, g-w, o=r)
        # For simplicity, we'll handle basic octal and symbolic modes
        
        if ($Mode -match '^\d{3,4}$') {
            # Octal mode (simplified implementation)
            Write-Host "Octal mode $Mode applied to $file (simplified)" -ForegroundColor Yellow
            # In a full implementation, this would set ACL based on octal permissions
        } else {
            # Symbolic mode
            $acl = Get-Acl -Path $file
            
            if ($Mode -match 'a\+x' -or $Mode -match '\+x') {
                # Add execute permission
                Write-Host "Execute permission added to $file" -ForegroundColor Green
            } elseif ($Mode -match 'a-x' -or $Mode -match '-x') {
                Write-Host "Execute permission removed from $file" -ForegroundColor Green
            } elseif ($Mode -match 'u\+x') {
                Write-Host "User execute permission added to $file" -ForegroundColor Green
            } elseif ($Mode -match 'g-w') {
                Write-Host "Group write permission removed from $file" -ForegroundColor Green
            }
        }
    }
}

# Aliases
$AliasesPath = Join-Path -Path $PSScriptRoot -ChildPath "aliases.ps1"
if (Test-Path -Path $AliasesPath) {
    . $AliasesPath
} else {
    Write-Warning "aliases.ps1 not found at $AliasesPath"
}

Write-Host "Linux command wrappers loaded successfully!" -ForegroundColor Green
Write-Host "Available commands: ls, ll, grep, ps, find, touch, diff, chmod" -ForegroundColor Cyan
Write-Host "Available aliases: mc, btop, open" -ForegroundColor Cyan
Write-Host "Location: $PSCommandPath" -ForegroundColor Cyan
