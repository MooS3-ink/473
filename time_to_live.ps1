

$targets = @("powershell", "cmd", "explorer", "taskmgr")

foreach ($name in $targets) {
    try {
        Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force
    } catch {
        # Ignore if process not found or access denied
    }
}
