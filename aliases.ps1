# Aliases and helper commands

# mc - Midnight Commander
Set-Alias mc "C:\Program Files\Midnight Commander\mc.exe"

# btop - Resource monitor (btop4win)
Set-Alias btop btop4win

# open - Open File Explorer (use /select for files)
function open {
    param(
        [Parameter(Position=0, ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    $target = if ($Arguments -and $Arguments.Count -gt 0) { $Arguments[0] } else { "." }

    if ($target -eq ".") {
        $resolved = (Resolve-Path -Path ".").Path
        Start-Process explorer.exe $resolved
        return
    }

    $resolvedTarget = Resolve-Path -Path $target -ErrorAction SilentlyContinue
    if ($resolvedTarget) {
        $resolvedTarget = $resolvedTarget.Path
    } else {
        $resolvedTarget = $target
    }

    if (Test-Path -Path $resolvedTarget -PathType Container) {
        Start-Process explorer.exe $resolvedTarget
    } else {
        Start-Process explorer.exe "/select,`"$resolvedTarget`""
    }
}
