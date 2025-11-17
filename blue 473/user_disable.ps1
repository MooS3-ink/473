# Single list of accounts that must not be disabled
$keep = @(
    "falken",
    "joshua",
    "lightman",
    "wopr",
    "norad",
    "david",
    "greyteam",
    "grayteam",
    
    "Administrator",
    "DefaultAccount",
    "Guest",
    "WDAGUtilityAccount"
)

# Detect the interactive user correctly when running elevated
$current = (Get-WmiObject -Class Win32_ComputerSystem).UserName
if ($current) {
    $current = $current.Split("\")[-1]
}

# Add the current user if not already present
if ($current -and ($keep -notcontains $current)) {
    $keep += $current
}

$users = Get-LocalUser

foreach ($u in $users) {
    if ($keep -notcontains $u.Name) {
        if ($u.Enabled) {
            Disable-LocalUser -Name $u.Name
        }
    }
}

# Show all users after processing
Get-LocalUser