$AllProtectors = (Get-BitlockerVolume -MountPoint $env:SystemDrive).KeyProtector 
$RecoveryProtector = ($AllProtectors | where-object { $_.KeyProtectorType -eq "RecoveryPassword" })
BackupToAAD-BitLockerKeyProtector $env:systemdrive -KeyProtectorId $RecoveryProtector.KeyProtectorID