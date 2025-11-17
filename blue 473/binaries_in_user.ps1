#List services whose binaries are in user or temp paths
Get-CimInstance Win32_Service |
  Where-Object { $_.PathName -match 'Users|Temp|AppData|ProgramData' } |
  Select-Object Name, State, StartMode, PathName

Write-Host "`n_____________________________________`n_____________________________________`n_____________________________________"

#Top 20 most recently installed services:
Get-CimInstance Win32_Service |
  Sort-Object InstallDate -Descending |
  Select-Object Name, DisplayName, State, StartMode, PathName, InstallDate -First 20

Write-Host "`n_____________________________________`n_____________________________________`n_____________________________________"

#Startup commands (Win32_StartupCommand):
Get-CimInstance Win32_StartupCommand |
  Select-Object Name, Command, Location, User
