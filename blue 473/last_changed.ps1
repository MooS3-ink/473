#List recently changed files in suspicious dirs (last 24h):
$since = (Get-Date).AddDays(-1)
Get-ChildItem "C:\ProgramData","C:\Users\Public" -Recurse -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -gt $since -and -not $_.PSIsContainer } |
  Sort-Object LastWriteTime -Descending |
  Select-Object FullName, Length, LastWriteTime -First 100