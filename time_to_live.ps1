#close all ps1 processes
Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID } | ForEach-Object {
    try {
        $_.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 500
        if (!$_.HasExited) { $_.Kill() }
    } catch {}
}

# close allcmd.exe
Get-Process cmd -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $_.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 500
        if (!$_.HasExited) { $_.Kill() }
    } catch {}
}

# close all explorer that was opended by hands
Get-Process explorer -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        if ($_.MainWindowHandle -ne 0) {
            $_.CloseMainWindow() | Out-Null
            Start-Sleep -Milliseconds 500
            if (!$_.HasExited) { $_.Kill() }
        }
    } catch {}
}

