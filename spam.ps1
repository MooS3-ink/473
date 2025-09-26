$logDir = "C:\ProGramData\tennp"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

for ($i = 0; $i -lt 5; $i++) {
    $filename = "log_$((Get-Random).ToString('X')).txt"
    $content = "[INFO] Process checked at $(Get-Date)"
    $fullPath = Join-Path $logDir $filename
    $content | Out-File $fullPath -Encoding ASCII
}