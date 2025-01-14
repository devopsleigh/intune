Start-Transcript -Path "C:\Logs\Set-BitLockerPIN_$(((Get-Date).ToUniversalTime()).ToString("yyyyMMdd_hhmmZ")).log" -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-InputBox {
    param (
        [string]$message
        , [string]$title
    )

    $form = New-Object System.Windows.Forms.Form
    $form.TopMost = $true
    $form.Activate()
    $form.Text = $title
    $form.Width = 300
    $form.Height = 150
    $form.StartPosition = 'CenterScreen'

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.AutoSize = $true
    $label.Left = 10
    $label.Top = 10
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Left = 10
    $textbox.Top = 40
    $textbox.Width = 260
    $form.Controls.Add($textbox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'OK'
    $okButton.Left = 100
    $okButton.Top = 70
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    $form.AcceptButton = $okButton

    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textbox.Text
    } else { return $null }
}

function Set-BitLockerPin {
    $pin = ConvertTo-SecureString -AsPlainText -String $(Show-InputBox -message 'Enter BitLocker PIN:' -title "BitLocker PIN Entry") -Force
    if ($null -ne $pin -and $pin.length -ge 6) {
        Write-Output 'Setting BitLocker PIN...'
        try {
            Enable-BitLocker -MountPoint 'C:' -TpmAndPinProtector -Pin $pin -UsedSpaceOnly
        } catch {
            Write-Error 'Failed to set BitLocker PIN:'
            Write-Output $error[0]
            throw
        }
    } else {
        Write-Output 'Invalid PIN. BitLocker PIN not set.'
    }
}

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
    Write-Output "Encrypting system drive with with XTS-AES-256"
    Set-BitLockerPin
    Write-Output 'Process completed.'
} else {
    Write-Output 'BitLocker is already using XTS-AES-256 encryption.'
}

Stop-Transcript
