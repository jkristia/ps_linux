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
            
            foreach ($item in $allInput) {
                # Convert object to string representation
                $stringRep = if ($item -is [string]) {
                    $item
                } else {
                    # For objects, get a formatted string representation
                    $item | Out-String -Stream | Where-Object { $_ }
                }
                
                # Search through the string representation
                $matches = if ($caseSensitive) {
                    $stringRep | Where-Object { $_ -cmatch $Pattern }
                } else {
                    $stringRep | Where-Object { $_ -match $Pattern }
                }
                
                # If we found matches, output the original object
                if ($matches) {
                    if ($v) {
                        # Invert match - skip this item
                        continue
                    }
                    $item
                } elseif ($v) {
                    # Invert match - output non-matching items
                    $item
                }
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

# mc - Midnight Commander
Set-Alias mc "C:\Program Files\Midnight Commander\mc.exe"

Write-Host "Linux command wrappers loaded successfully!" -ForegroundColor Green
Write-Host "Available commands: ls, ll, grep, ps, find, mc" -ForegroundColor Cyan
