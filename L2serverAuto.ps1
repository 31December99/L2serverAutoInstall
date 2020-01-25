#GitHub 25/01/2020
param([string]$install="man")
Add-Type -AssemblyName System.IO.Compression.FileSystem
#requires -Version 2
function Set-EnvironmentVariable
{
  param
  (
    [Parameter(Mandatory=$true)]
    [String]
    $Name,
    
    [Parameter(Mandatory=$true)]
    [String]
    $Value,
    
    [Parameter(Mandatory=$true)]
    [EnvironmentVariableTarget]
    $Target
  )
    $PATH = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
    $PATH += ";" + $Value 
    $regexAddPath = [regex]::Escape($Value)
    $arrPath = $PATH -split ';' | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
    $newPath = ($arrPath + $Value) -join ';'
    [System.Environment]::SetEnvironmentVariable($Name,$newPath, [System.EnvironmentVariableTarget]::User)
}
 function Unzip
 {
     param([string]$zipfile, [string]$outpath)
     Expand-Archive -Path $zipfile -DestinationPath $outpath
 }
    
 function UnzipOnlyFiles {
  param([string]$zipfile, [string]$out)
  $Archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
  Foreach ($entry in $Archive.Entries.Where( { $_.Name.length -gt 0 })) {
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "$out\$($entry.Name)")
  }
  $Archive.Dispose()
}
   Function get-gitClone ([String]$message){

    Set-location $gitRepoLocalFolder
    $arg1 = " clone " 
    $allArgs = @($arg1, $gitRepoUri)
    Start-Process -FilePath "git" $allArgs -Wait -NoNewWindow 
   }
   function get-OpenJDK {

    (New-Object System.Net.WebClient).DownloadFile($jdkDownloadLink,$jdkDownloadPathName)
    Unzip $jdkDownloadPathName $installJavaAntPath
    $zip =  [io.compression.zipfile]::OpenRead($jdkDownloadPathName).Entries
    $jdkFolder = (($zip | Where-Object FullName -match '/' | Select-Object -First 1).Fullname -Split '/')[0]
    $jdkInstallFolder ="$($installJavaAntPath)\$($jdkFolder)\Bin"
    Set-EnvironmentVariable -name PATH -Value $jdkInstallFolder -Target User 
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME",$absolutePathJdk, [System.EnvironmentVariableTarget]::User)
   }

   function get-ApacheAnt {

    (New-Object System.Net.WebClient).DownloadFile($antDownloadLink,$antDownloadPathName)
    Unzip $antDownloadPathName $installJavaAntPath
    $zip =  [io.compression.zipfile]::OpenRead($antDownloadPathName).Entries
    $antFolder = (($zip | Where-Object FullName -match '/' | Select-Object -First 1).Fullname -Split '/')[0]
    $antInstallFolder ="$($installJavaAntPath)\$($antFolder)\Bin"
    Set-EnvironmentVariable -name PATH -Value $antInstallFolder -Target User 
    [System.Environment]::SetEnvironmentVariable("ANT_HOME",$absolutePathAnt, [System.EnvironmentVariableTarget]::User)
   }
   
   Function get-Git ([String]$message){

    (New-Object System.Net.WebClient).DownloadFile($gitDownloadLink,$gitDownloadPathName)
    $arg1 = "-o" + $installJavaAntPath + "\Git -y /VERYSILENT"
    Start-Process -FilePath $gitDownloadPathName -ArgumentList $arg1 -Wait -NoNewWindow 
         
    #Set PATH for GIT
    Set-EnvironmentVariable -name PATH -Value $($installJavaAntPath + "\Git") -Target User 
    Set-EnvironmentVariable -name PATH -Value $($installJavaAntPath + "\Git\bin") -Target User 
    Set-EnvironmentVariable -name PATH -Value $($installJavaAntPath + "\Git\usr") -Target User 
    Set-EnvironmentVariable -name PATH -Value $($installJavaAntPath + "\Git\mingw64") -Target User 
    #Refresh enviroment variables
   $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

   }
  function get-SourceCompiled ([String]$localFolder,[String]$message){
    $arg1 =   "-Ddest=system" 
    $arg2 =   "-f"
    $arg3 =   $localFolder + "build.xml"
    $allArgs = @($arg1,$arg2,$arg3)
    ant $allArgs
  }
  function set-Server {

    Set-location $installJavaServerPath
    #------------ Gameserver
    Copy-Item -Path $gitLocalGameSBuildPath      -Destination $installJavaServerPath -recurse -Force
    Copy-Item -Path $gitLocalLoginSBuildPath     -Destination $installJavaServerPath -recurse -Force
  }
  function set-Login {
    Set-location $installJavaServerPath
    #------------ Datapack
    Copy-Item -Path $gitLocalDataPGameSBuildPath  -Destination $installJavaServerPath -recurse -Force
    Copy-Item -Path $gitLocalDataPLoginSBuildPath -Destination $installJavaServerPath -recurse -Force
    Copy-Item -Path $gitLocalDataPSQLBuildPath    -Destination $installJavaServerPath -recurse -Force
    Copy-Item -Path $gitLocalDataPToolsBuildPath  -Destination $installJavaServerPath -recurse -Force
  }


  function set-ConfigDbName  { 
      
      PARAM (
      [CmdletBinding()]
      [parameter(Mandatory=$true)]
      [String]
      $dbn,
      [parameter(Mandatory=$true)]
      [String]
      $configFile
      )
  
  copy-item $configFile -Destination $configFile".bak" -Force
  [string[]]$lineInput = Get-Content -Path $configFile
  Remove-Item $configFile

  for($n=0; $n -le $lineInput.Length; $n++) {
     $extractNamePos = ( $lineInput[$n] | Select-String "(?<=\/\/)[^:]*" -AllMatches).Matches.Index
     if ($extractNamePos -gt 0) { 
        $updatedline = $lineInput[$n].Remove($extractNamePos).Insert($extractNamePos, $ipDatabase + "/"+ $dbn)
        $lineInput[$n] = $updatedline

        Add-Content $configFile $updatedline
     } else {
        Add-Content $configFile $lineInput[$n]
       }
  }  
}
  function set-Config {

    $psw = "Password =" + $dbPsw + "`n"
    $user ="Login = root" + "`n"
    ((Get-Content -path $JavaServerGameS_properties -Raw) -replace 'Login =',$user) | Set-Content -Path $JavaServerGameS_properties
    ((Get-Content -path $JavaServerGameS_properties -Raw) -replace 'Password =',$psw) | Set-Content -Path $JavaServerGameS_properties
    ((Get-Content -path $JavaServerLoginS_properties -Raw) -replace 'Login =',$user) | Set-Content -Path $JavaServerLoginS_properties
    ((Get-Content -path $JavaServerLoginS_properties -Raw) -replace 'Password =',$psw) | Set-Content -Path $JavaServerLoginS_properties
    ((Get-Content -path $JavaServerGeodata_properties -Raw) -replace "CoordSynchronize = 2","CoordSynchronize = 2`nGeoDataFormat = l2D`nGeoData = 2") | Set-Content -Path $JavaServerGeodata_properties

    set-ConfigDbName -dbn $dbName -configFile $JavaServerGameS_properties
    set-ConfigDbName -dbn $dbName -configFile $JavaServerLoginS_properties
  }
  function get-MariaDB {
    (New-Object System.Net.WebClient).DownloadFile($MariaDbDownloadLink,$MariaDbDownloadPathName)
    Unzip $MariaDbDownloadPathName $installJavaAntPath
    Set-EnvironmentVariable -name PATH -Value $($installJavaAntPath + "\" + $MariaDbVersionName) -Target User 
    Set-EnvironmentVariable -name PATH -Value $($installJavaAntPath + "\" + $MariaDbVersionName + "\bin") -Target User 
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
  }

function set-MariaDbservice {

  if (-not (Test-Path -LiteralPath $dataDir)) {
    Write-Host "New folder [" $dataDir "]" -ForegroundColor Yellow
    new-item $dataDir -itemtype directory  | out-null
    Start-Process powershell.exe " -NoProfile -ExecutionPolicy Bypass -File $script -dataDir $dataDir -serviceDb $dbServicename -dbpsw $dbPsw -installJavaAntPath $installJavaAntPath -MariaDbVersionName $MariaDbVersionName" -Wait -Verb RunAs
  } else {
      "service is already running !"
      Pause
    }
}

function set-Account {
  set-location $installJavaServerPath\login
  &$installJavaServerPath\login\startSQLAccountManager.bat
  }
function set-Admin ([string]$dbName,[String]$dbAccount,[String]$charName){

      mysql "--user=root" "--password=$dbPsw" "--execute=INSERT INTO ``$dbName``.``accounts`` (``login``,``password``,``access_level``,``lastServer``) VALUES ('$dbAccount','bJc+iAOz+6q/sJ3ZFuKV7STaHUM=','8',1)"
      mysql "--user=root" "--password=$dbPsw" "--execute=INSERT INTO ``$dbName``.``characters`` (``account_name``,``obj_id``,``char_name``,``level``,``maxHp``,``curHp``,``x``,``y``,``z``,``maxCp``,``curCp``,``maxMp``,``curMp``,``accesslevel``)
      VALUES ('$dbAccount',268480250,'$charName',80,5000,5000,-13911,123442,-2995,5000,5000,3000,3000,8);"
  }
function set-SqlAll {

  $allSql = 0;
  $sql = @(
      ($JavaServerSqlConfigPath   + "All.sql"),
      ($JavaServerToolsConfigPath + "full_install.sql"),
      ($JavaServerSqlConfigPath   + "accounts.sql"),
      ($JavaServerSqlConfigPath   + "auction.sql"),
      ($JavaServerSqlConfigPath   + "auction_bid.sql"),
      ($JavaServerSqlConfigPath   + "augmentations.sql"),
      ($JavaServerSqlConfigPath   + "bookmarks.sql"),
      ($JavaServerSqlConfigPath   + "buffer_schemes.sql"),
      ($JavaServerSqlConfigPath   + "buylists.sql"),
      ($JavaServerSqlConfigPath   + "castle_doorupgrade.sql"),
      ($JavaServerSqlConfigPath   + "castle_manor_procure.sql"),
      ($JavaServerSqlConfigPath   + "castle_manor_production.sql"),
      ($JavaServerSqlConfigPath   + "castle_trapupgrade.sql"),
      ($JavaServerSqlConfigPath   + "character_friends.sql"),
      ($JavaServerSqlConfigPath   + "character_hennas.sql"),
      ($JavaServerSqlConfigPath   + "character_macroses.sql"),
      ($JavaServerSqlConfigPath   + "character_mail.sql"),
      ($JavaServerSqlConfigPath   + "character_memo.sql"),
      ($JavaServerSqlConfigPath   + "character_quests.sql"),
      ($JavaServerSqlConfigPath   + "character_raid_points.sql"),
      ($JavaServerSqlConfigPath   + "character_recipebook.sql"),
      ($JavaServerSqlConfigPath   + "character_recommends.sql"),
      ($JavaServerSqlConfigPath   + "character_shortcuts.sql"),
      ($JavaServerSqlConfigPath   + "character_skills.sql"),
      ($JavaServerSqlConfigPath   + "character_skills_save.sql"),
      ($JavaServerSqlConfigPath   + "character_subclasses.sql"),
      ($JavaServerSqlConfigPath   + "characters.sql"),
      ($JavaServerSqlConfigPath   + "clan_data.sql"),
      ($JavaServerSqlConfigPath   + "clan_privs.sql"),
      ($JavaServerSqlConfigPath   + "clan_skills.sql"),
      ($JavaServerSqlConfigPath   + "clan_subpledges.sql"),
      ($JavaServerSqlConfigPath   + "clan_wars.sql"),
      ($JavaServerSqlConfigPath   + "clanhall.sql"),
      ($JavaServerSqlConfigPath   + "clanhall_functions.sql"),
      ($JavaServerSqlConfigPath   + "cursed_weapons.sql"),
      ($JavaServerSqlConfigPath   + "fishing_championship.sql"),
      ($JavaServerSqlConfigPath   + "forums.sql"),
      ($JavaServerSqlConfigPath   + "games.sql"),
      ($JavaServerSqlConfigPath   + "gameservers.sql"),
      ($JavaServerSqlConfigPath   + "grandboss_list.sql"),
      ($JavaServerSqlConfigPath   + "heroes_diary.sql"),
      ($JavaServerSqlConfigPath   + "heroes.sql"),
      ($JavaServerSqlConfigPath   + "items.sql"),
      ($JavaServerSqlConfigPath   + "items_on_ground.sql"),
      ($JavaServerSqlConfigPath   + "mdt_bets.sql"),
      ($JavaServerSqlConfigPath   + "mdt_history.sql"),
      ($JavaServerSqlConfigPath   + "mods_wedding.sql"),
      ($JavaServerSqlConfigPath   + "olympiad_data.sql"),
      ($JavaServerSqlConfigPath   + "olympiad_fights.sql"),
      ($JavaServerSqlConfigPath   + "olympiad_nobles_eom.sql"),
      ($JavaServerSqlConfigPath   + "olympiad_nobles.sql"),
      ($JavaServerSqlConfigPath   + "pets.sql"),
      ($JavaServerSqlConfigPath   + "posts.sql"),
      ($JavaServerSqlConfigPath   + "server_memo.sql"),
      ($JavaServerSqlConfigPath   + "seven_signs.sql"),
      ($JavaServerSqlConfigPath   + "seven_signs_festival.sql"),
      ($JavaServerSqlConfigPath   + "seven_signs_status.sql"),
      ($JavaServerSqlConfigPath   + "siege_clans.sql"),
      ($JavaServerSqlConfigPath   + "spawnlist.sql"),
      ($JavaServerSqlConfigPath   + "spawnlist_4s.sql"),
      ($JavaServerSqlConfigPath   + "topic.sql"),
      ($JavaServerSqlConfigPath   + "raidboss_spawnlist.sql"),
      ($JavaServerSqlConfigPath   + "random_spawn.sql"),
      ($JavaServerSqlConfigPath   + "random_spawn_loc.sql")
  )   

      set-content $sql[$allSql] -Value ""
  for($file=1; $file -le 63 ; $file++) {
       $FileContent = get-content $sql[$file]
       Add-Content $sql[$allSql] $FileContent
  }
}
function set-installDb([String]$sql) {

  Write-Host "Working..." -ForegroundColor Green
    mysql "--user=root" "--password=$dbPsw" "--execute=create database  IF NOT EXISTS $dbName;" 
    mysql "--user=root" "--password=$dbPsw" "-D$dbName" "--execute=Source $sql"
    Write-Host "Done." -ForegroundColor Green
}
function set-DatabaseGame{

    if (-not (Test-Path -LiteralPath $installJavaAntPath)) {
      Write-Host "New folder [" $installJavaAntPath "]" -ForegroundColor Yellow
      new-item $installJavaAntPath -itemtype directory  | out-null
      Set-location $installJavaAntPath
    }
    $menu ="
    aCis database installation
    __________________________

    OPTIONS :(f) Full install, it will destroy all (need validation)................. [ if the DB doesn't exist then create it ]
             (s) Skip characters data, it will install only static server tables..... [ Install only static server table ]
             (b) <-BACK"
    Clear-Host
    get-dbList 
    Write-Host $menu
    set-SqlAll
do {
        $option = Read-host "make your choice---->"
        if ($option -eq "s") {        
          set-ConfigDbName -dbn $dbName -configFile $JavaServerGameS_properties
          set-ConfigDbName -dbn $dbName -configFile $JavaServerLoginS_properties
          set-installDb @($JavaServerToolsConfigPath + "/gs_install.sql")
        }
        if ($option -eq "f") {
            $option = Read-host "Are you sure ? (y/n) "
            if($option -ne "y") { break }
            set-ConfigDbName -dbn $dbName -configFile $JavaServerGameS_properties
            set-ConfigDbName -dbn $dbName -configFile $JavaServerLoginS_properties
            set-installDb @($JavaServerSqlConfigPath + "/all.sql")
            
        }
    } while ($option -ne "b")
}
function get-dbList {
 mysql "--user=root" "--password=$dbPsw" "--execute=SHOW DATABASES;"
}
#------------------------------------------------------------------------------------------------------------------------------------#
function set-fullInstall {

  if (-not (Test-Path -LiteralPath $installJavaAntPath)) {
    Write-Host "New folder [" $installJavaAntPath "]"  -ForegroundColor Yellow
    new-item $installJavaAntPath -itemtype directory  | out-null
    Set-location $installJavaAntPath
    } else {
      " Already exists " + "'" + $installJavaAntPath + "' folder" 
      exit
    }
  Write-Host "Download openJDK [" $jdkDownloadLink "]" -ForegroundColor Green  
  get-OpenJDK
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Download Apache Ant [" $antDownloadLink "]" -ForegroundColor Green  
  get-ApacheAnt
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Download GIT [" $gitDownloadLink "]" -ForegroundColor Green  
  get-Git
  Write-Host "Done." -ForegroundColor Green  
  
  Write-Host "Clone repository " $gitDownloadLink  -ForegroundColor Green
  Write-Host "New folder [" $gitRepoLocalFolder "]" -ForegroundColor Yellow  
  new-item $gitRepoLocalFolder  -itemtype directory | Out-Null
  get-gitClone
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Build aCis_GameServer"  -ForegroundColor Green
  get-SourceCompiled $gitLocalGameserverPath
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Build aCis_Datapack"  -ForegroundColor Green
  get-SourceCompiled $gitLocalDataPackPath
  Write-Host "Done." -ForegroundColor Green  
  
  Write-Host "New folder [" $installJavaServerPath "]" -ForegroundColor Yellow 
  Write-host "Move GameServer to " $installJavaServerPath -ForegroundColor Green
  new-item $installJavaServerPath -itemtype directory | Out-Null
  set-Server
  Write-Host "Done." -ForegroundColor Green  
  
  Write-host "Move LoginServer to " $installJavaServerPath -ForegroundColor Green
  set-Login
  Write-Host "Done." -ForegroundColor Green  

  Write-host "Verify geodata " -ForegroundColor Green
  if (Test-Path @($PSScriptRoot + "\" + $geoDataFileName) -PathType Leaf) {
    UnzipOnlyFiles $geoDataFileName $JavaServerGeoDataPath
  }else {
    Write-Host "Geodata file not found.(l2d_geodata.zip)" -ForegroundColor red
  }  
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Download MariaDB [" $MariaDbDownloadLink "]" -ForegroundColor Green
  get-MariaDB
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Create MariaDB service"  -ForegroundColor Green
  Read-host "run MariaDB service needs admin rights. Press Enter to continue [Enter]"
  set-MariaDbservice
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Write to Config file proprierties Gameserver and LoginServer"  -ForegroundColor Green
  set-Config
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Install database Game"  -ForegroundColor Green
  set-SqlAll
  set-installDb @($JavaServerSqlConfigPath + "/all.sql")
  Write-Host "Done." -ForegroundColor Green  

  Write-Host "Register game server"  -ForegroundColor Green
  set-register
  Write-Host "Done." -ForegroundColor Green  
    
  set-Admin $dbName "user" "X92"
  Write-Host "..another Admin has been born"  -ForegroundColor Green
  Write-host "User: user"
  Write-host "Psw : joker"
  
  Start-Process $installJavaServerPath\login\startLoginServer.bat -WorkingDirectory $installJavaServerPath\login
  Start-Sleep -s 10  
  Start-Process $installJavaServerPath\Gameserver\startGameServer.bat  -WorkingDirectory $installJavaServerPath\Gameserver
}
function set-register {
  set-location $installJavaServerPath\login
  &$installJavaServerPath\login\RegisterGameServer.bat
  Copy-Item "hexid(server **).txt" -Destination $JavaServerGameConfigPath\hexid.txt
  Write-Host "copy hexid to" $JavaServerGameConfigPath

}
function  get-statusInstallation{
    $installFolder = Test-Path -LiteralPath $installJavaAntPath
    $serverFolder =  Test-Path -LiteralPath $installJavaServerPath
    return $installFolder -and $serverFolder
}
##################################################################################################################################################################
### Load configuration 
if (Test-Path @($PSScriptRoot,"\config.cfg") -PathType Leaf) {
  
Get-Content @($PSScriptRoot + "\" +"config.cfg") | foreach-object -begin {$config=@{}} -process {
      $ht = [regex]::split($_,'=');
      if(($ht[0].CompareTo("") -ne 0) -and ($ht[0].StartsWith("[") -ne $True)) {
        $config.Add($ht[0], $ht[1]) 
      }
  }
  
    $installDrive         	= $config.'installDrive'     
    $installJavaAntFolder   = $config.'installJavaAntFolder'
    $installJavaServerFolder= $config.'installJavaServerFolder'
    $dataDir                = $installDrive + $config.'dataDir'
    $dbName                 = $config.'dbName'
    $dbPsw                  = $config.'dbPsw'
    $dbServicename          = $config.'dbServicename'
    $localFolderRepository  = $config.'localFolderRepository'
    $ipDatabase             = $config.'ipDatabase'
    $antDownloadLink        = $config.'antDownloadLink'
    $antVersionName         = $config.'antVersionName'   
    $jdkDownloadLink        = $config.'jdkDownloadLink'
    $jdkVersionName         = $config.'jdkVersionName'
    $MariaDbVersionName     = $config.'MariaDbVersionName'
    $gitDownloadLink        = $config.'gitDownloadLink'
    $MariaDbDownloadLink    = $config.'MariaDbDownloadLink'
    $geoDataFileName	      = $config.'geoDataFileName'
}   

############################################# LOCAL INSTALLATED SERVER FOLDERS #######################################################
$installJavaAntPath		      = $installDrive + "\" + $installJavaAntFolder
$installJavaServerPath		  = $installDrive + "\" + $installJavaServerFolder
$JavaServerGeoDataPath		  = $installDrive + "\" + $installJavaServerFolder   + "\" + "gameserver\data\geodata\"
$JavaServerGameConfigPath	  = $installDrive + "\" + $installJavaServerFolder   + "\" + "gameserver\config\"
$JavaServerLoginConfigPath	  = $installDrive + "\" + $installJavaServerFolder + "\" + "login\config\"
$JavaServerToolsConfigPath	  = $installDrive + "/" + $installJavaServerFolder + "/" + "tools/"
$JavaServerSqlConfigPath	    = $installDrive + "/" + $installJavaServerFolder + "/" + "sql/"
$JavaServerGameS_properties   = $JavaServerGameConfigPath 	+ "server.properties"
$JavaServerGeodata_properties = $JavaServerGameConfigPath 	+ "geoengine.properties"
$JavaServerLoginS_properties  = $JavaServerLoginConfigPath	+ "loginserver.properties"
################################################# LOCAL NAMES FOR DOWNLOADED FILES #####################################################
$antDownloadPathName          = $installJavaAntPath  + "\" + $antVersionName     + ".zip"
$jdkDownloadPathName   	      = $installJavaAntPath  + "\" + $jdkVersionName     + ".zip"
$gitDownloadPathName   	      = $installJavaAntPath  + "\" + "Git-7zip.exe"
$MariaDbDownloadPathName      = $installJavaAntPath  + "\" + $MariaDbVersionName + ".zip"
$absolutePathAnt 		          = $installJavaAntPath  + "\" + $antVersionName
$absolutePathJdk 	            = $installJavaAntPath  + "\" + $jdkVersionName 
$script                       = $PSScriptRoot        + "\MariaDB.ps1"
################################################## LOCAL REPOSITORY FOLDERS #############################################################
#------------- Local folders for repository clone
$gitRepoLocalFolder  	    = $installDrive + "\" + $localFolderRepository
$gitNameFolder            = "acis_public"
$gitRepoUri 			        = "https://gitlab.com/Tryskell/acis_public.git"
$gitRepoGameFolder		    = "aCis_gameserver"
$gitRepoDataPackFolder	  = "aCis_datapack"
#------------ Gameserver
$gitLocalFolderPath	        = $gitRepoLocalFolder + "\" + $gitNameFolder
$gitLocalGameserverPath	    = $gitLocalFolderPath + "\" + $gitRepoGameFolder     + "\"
$gitLocalDataPackPath		    = $gitLocalFolderPath + "\" + $gitRepoDataPackFolder + "\"
$gitLocalGameSBuildPath	    = $gitLocalFolderPath + "\" + $gitRepoGameFolder 	 + "\" + "build\dist\gameserver"
$gitLocalLoginSBuildPath	  = $gitLocalFolderPath + "\" + $gitRepoGameFolder 	 + "\" + "build\dist\login"
#------------ Datapack
$gitLocalDataPGameSBuildPath  = $gitLocalFolderPath + "\" + $gitRepoDataPackFolder + "\" + "build\gameserver"
$gitLocalDataPLoginSBuildPath = $gitLocalFolderPath + "\" + $gitRepoDataPackFolder + "\" + "build\login"
$gitLocalDataPSQLBuildPath    = $gitLocalFolderPath + "\" + $gitRepoDataPackFolder + "\" + "build\sql"
$gitLocalDataPToolsBuildPath  = $gitLocalFolderPath + "\" + $gitRepoDataPackFolder + "\" + "build\tools"
#######################################################################################################################   
    
    if ($install -ne "man" ) {
      pause
      set-fullInstall
      exit
     }
$mainMenu ="`n
                                                L2 acis Installation
    _______________________________________________________________________________________________________________

    OPTIONS :   (1) Full Install from scrach.----------------- [ Download and Install jdk,ant,git,mariadb,database]
                (2) Install database ------------------------- [ Install database ]
                (3) Account manager -------------------------- [ Manage standard and admin account]
                (4) Register server -------------------------- [ game server ID]
                (5) Advanced options ------------------------- [ Manage services]
                (Q) Quit"            
    Clear-Host
   do {

        Write-Host $mainMenu
        $option = Read-host "make your choice (main)>"

        if ($option -eq "1") { 
        set-fullInstall
        }
        if ($option -eq "2") {
        set-DatabaseGame
        }
        if ($option -eq "3") {
        set-Account
        }
        if ($option -eq "4") {
        set-register
        }
        if ($option -eq "5") {

        $menu ="
        Advanced options (Admin rights)
        __________________________
            
        OPTIONS :  (r) Restart MariaDB service............... [only restart the service]
                   (i) Install MariaDB service............... [only if it doesn't exist]
                   (b) <-BACK"
      
        Clear-Host
        Write-Host $menu
        $advOption = Read-host "make your choice(advanced)---->"

        if ($advOption -eq "r") {
             Start-Process powershell.exe " -NoProfile -ExecutionPolicy Bypass -File $script -restart $dbServicename" -Verb RunAs
        }
        if ($advOption -eq "i") {      
          set-MariaDbservice
        }
     }  
    } while ($option -ne "q")