#Requires -RunAsAdministrator
param([string]$dataDir, [string]$serviceDb,[string]$dbpsw,[string]$installJavaAntPath,[string]$MariaDbVersionName,[string]$restart)
function set-MariaDbservice {

  $arg1 = "--datadir="  + $dataDir
  $arg2 = "--service="  + $serviceDb
  $arg3 = "--password=" + $dbPsw
  $allArgs = @($arg1,$arg2,$arg3)
  $MariaDBbinFolder = $installJavaAntPath + "\" + $MariaDbVersionName + "\bin"

  Start-Process  -FilePath "mysql_install_db.exe" -ArgumentList $allArgs -wait -WorkingDirectory $MariaDBbinFolder
  $service = Get-Service $serviceDb
  Start-service $service
  Write-host "Status MariaDB service " $service.status
}
function set-RestartService {
  
  $service = Get-Service $restart
  Stop-service $service
  Write-host "Status MariaDB service " $service.status
  Start-service $service
  Write-host "Status MariaDB service " $service.status
  Pause
}
if ($restart) { set-RestartService } else { set-MariaDbservice }