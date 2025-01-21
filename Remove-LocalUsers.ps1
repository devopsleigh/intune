$groups = @(
    'Administrators'
    , 'Guests')

$users = @(
    'Administrator'  
    , 'Guest'
)

function Remove-PAWLocalGroupUsers {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $groupName
    )

    $groupMembers = @()
    $groupMembers = Get-LocalGroupMember -Group $groupName
    if ($groupMembers.Count -gt 0) {
        foreach ($member in $groupMembers) {
            if ($member -notlike "$env:COMPUTERNAME\Administrator") {
                Remove-LocalGroupMember -Group $groupName -Member $member 
            }
        }
    }
}

function Disable-PAWLocalUsers {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $userName
    )

    $localUsers = @()
    $localUsers = Get-LocalUser -Name $userName
    if ($localUsers.Count -gt 0) {
        Disable-LocalUser -Name $userName
    }
}

foreach ($group in $groups)
{ Remove-PAWLocalGroupUsers -groupName $group }

foreach ($user in $users)
{ Disable-PAWLocalUsers -userName $user }

$cfgFile = "C:\secedit.inf"
# $policyPath = "MACHINE\Software\Microsoft\Windows NT\CurrentVersion\SeCEdit\Inf\Default"
$allowLogonLocally = secedit /export /areas USER_RIGHTS /cfg $cfgFile | Select-String -Pattern 'SeInteractiveLogonRight'
$updatedPolicy = $allowLogonLocally -replace "SeInteractiveLogonRight = .*", "SeInteractiveLogonRight = "
$updatedPolicy | Out-File $cfgFile
secedit /configure /db scedit.sdb /cfg $cfgFile /areas USER_RIGHTS
Remove-Item $cfgFile
