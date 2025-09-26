
$logFile = "C:\RedTeam\users_created.log"
if (!(Test-Path "C:\RedTeam")) {
    New-Item -ItemType Directory -Path "C:\RedTeam" | Out-Null
}

for ($i = 1; $i -le 10; $i++) {
    $uname = "default_user_$i"
    $password = "youshallnotpass"
    net user $uname $password /add | Out-Null
    Add-Content -Path $logFile -Value "$uname added"
}

# Create admin user
net user blue_admin "youshallnotpass" /add | Out-Null
net localgroup Administrators blue_admin /add | Out-Null
Add-Content -Path $logFile -Value "blue_admin added to Administrators"
