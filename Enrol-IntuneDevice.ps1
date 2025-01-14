[CmdletBinding()]
param (
    
    [Parameter(Position=0,Mandatory=$true)]
    [ValidateSet('PAW', 'SPE', 'ENT', IgnoreCase = $true)]  
    [String]
    $GroupTag
)

Write-Verbose "Checking prerequisites"
try {
    if ($(Get-ExecutionPolicy) -notin ('RemoteSigned', 'Bypass')) {
        throw
    }
} catch {
    Write-Error 'Run Set-ExecutionPolicy RemoteSigned'
    exit 1
}

try {
    if ($null -eq $(Get-PackageProvider -Name NuGet)) {
        Write-Verbose "Installing NuGet"
        Install-PackageProvider -Name NuGet -Force | Out-Null 
    }    if ($null -eq $(Get-InstalledScript -Name Get-WindowsAutopilotInfo)) {
        Write-Verbose "Installing Get-WindowsAutopilotInfo"
        Install-Script -Name Get-WindowsAutopilotInfo -Force | Out-Null
    }
    if ($null -eq (Get-Module -Name PSWindowsUpdate)) {
        Write-Verbose "Installing PSWindowsUpdate"
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name PSWindowsUpdate | Out-Null
    }
} catch {
    Write-Error $Error[0]
    exit 1
}

Write-Verbose "Checking for Windows, driver and firmware updates"
$updates = @()
$updates = Get-Windowsupdate -Download -AcceptAll
Write-Verbose "$($Updates.Count) update(s) found"
if ($updates.Count -ne 0) {
    Install-WindowsUpdate -AcceptAll -Autoreboot
}

Write-Verbose "Enrolling $((Get-WmiObject -Class Win32_BIOS | Select-Object -Property SerialNumber).SerialNumber) into Intune"
Get-WindowsAutoPilotInfo.ps1 -Online -Assign -GroupTag $GroupTag
