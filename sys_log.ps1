$TargetDir = "C:\ProGramData\tennp"
$SizeBytes = 100 * 1024 * 1024   # 100 MB

# Ensure directory exists
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

# Unique filename
$fname = "temp_" + (Get-Date -Format "yyyyMMdd_HHmmss") + "_" + ((Get-Random).ToString("X")) + ".bin"
$fullPath = Join-Path $TargetDir $fname

# Try fast native tool fsutil first (creates file with given length)
try {
    & fsutil file createnew $fullPath $SizeBytes
    exit 0
} catch {
    # fallback: create empty file and set length via .NET
    try {
        $fs = [System.IO.File]::Open($fullPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $fs.SetLength([int64]$SizeBytes)
        $fs.Close()
        exit 0
    } catch {
        # if both methods fail, exit nonzero
        exit 1
    }
}

try {
    # Clear PSReadLine file history
    $histFile = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (Test-Path $histFile) {
        Remove-Item $histFile -Force -ErrorAction SilentlyContinue
    }

    # Clear in-memory session history
    Clear-History -ErrorAction SilentlyContinue

    # Clear PowerShell event log
    wevtutil cl "Windows PowerShell" 2>$null
} catch {
    # Ignore any errors during cleanup
}