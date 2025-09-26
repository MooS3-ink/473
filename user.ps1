$Users = @(
"JIuMoH4uk",
"barakuda",
"spacemarine_prime",
"hellOfaDiver",
"flugigehain",
"Arnold_footballheaded",
"bzjek_bzjekich",
"Bigdou",
"pipty_cent",
"fallen_skibidi",
"BoomBamColdRap"
)
$AdminUser = "bluud_admin"

$UserPasswordPlain  = "youshallnotpass"
$AdminPasswordPlain = "IMTHELAW!"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "Must be run as Administrator."
    exit 1
}
function Ensure-User {
    param([string]$Name, [string]$PlainPassword)

    $u = $null
    try {
        $u = Get-LocalUser -Name $Name -ErrorAction Stop
    } catch {
        $u = $null
    }

    if ($null -eq $u) {
        try {
            $secure = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
            New-LocalUser -Name $Name -Password $secure -PasswordNeverExpires -ErrorAction Stop
        } catch {
            try {
                net user $Name $PlainPassword /add | Out-Null
            } catch {
                # silent fail
            }
        }
    } else {
        try {
            if (-not $u.Enabled) {
                Enable-LocalUser -Name $Name -ErrorAction Stop
            }
        } catch {
            # fallback: попытка сброса пароля через net user (best-effort)
            try {
                net user $Name $PlainPassword | Out-Null
            } catch {
                # silent
            }
        }
    }
}

function Ensure-Is-Admin {
    param([string]$Name)
    $isMember = $false
    try {
        $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        foreach ($m in $members) {
            if ($m.Name -eq $Name -or ($m.Name -match [regex]::Escape($Name))) {
                $isMember = $true
                break
            }
        }
    } catch {
        $isMember = $false
    }

    if (-not $isMember) {
        try {
            Add-LocalGroupMember -Group "Administrators" -Member $Name -ErrorAction Stop
        } catch {
            try {
                net localgroup Administrators $Name /add | Out-Null
            } catch {
                # silent
            }
        }
    }
}

# Main: ensure ordinary users
foreach ($name in $Users) {
    try {
        Ensure-User -Name $name -PlainPassword $UserPasswordPlain
    } catch {
        # ignore
    }
}

# Ensure admin exists, enabled and is member of Administrators
try {
    Ensure-User -Name $AdminUser -PlainPassword $AdminPasswordPlain
    Ensure-Is-Admin -Name $AdminUser
} catch {
    # ignore
}
