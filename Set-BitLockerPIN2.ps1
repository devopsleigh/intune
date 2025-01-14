Start-Transcript -Path "C:\Logs\Set-BitLockerPIN2_$(((Get-Date).ToUniversalTime()).ToString("yyyyMMdd_hhmmZ")).log" -Force

$bitLockerStatus = Get-BitLockerVolume -MountPoint 'C:'
if ($bitLockerStatus.EncryptionMethod -ne 'XtsAes256') {
    if ($bitLockerStatus.VolumeStatus -eq "FullyEncrypted") {
        Disable-BitLocker -MountPoint 'C:'
        Write-Output 'Decrypting the system drive...'
    
        while ((Get-BitLockerVolume -MountPoint 'C:').VolumeStatus -ne 'FullyDecrypted') {
            Start-Sleep -Seconds 10
        }
        Write-Output 'Decryption complete.'
    }
    Write-Output "Prompting user to encrypt the system drive"
    control /name Microsoft.BitLockerDriveEncryption
} else {
    Write-Output 'BitLocker is already configured correctly.'
}

Stop-Transcript
