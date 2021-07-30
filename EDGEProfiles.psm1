<#
 .Synopsis
  Allows for easy backup and restore of Microsoft EDGE (Anaheim) Profiles.

 .Description
  Will backup all EDGE "User Data" for the current user. This data contains all the "Profiles" within the browser, and the corresponding registry keys will also be saved alongside the backup.
  Backups are zipped to allow for easy storage on locations like OneDrive.
  Before archiving the backup, all profiles have their Cache emptied.

  Restore will replace the current users EDGE data. The command requires that the user chooses how to handle existing data.

 .Parameter Verbose
  Enables extended output
  Applies to all functions

 .Parameter Destination 
  (optional)
  Location in which to save the backup ZIP and REG files
  Defaults to the users OneDrive
  Applies to the Backup-EDGEProfiles function

 .Parameter AddDate
  (optional - $true/$false)
  Applies a date stamp to the filenames.
  Defaults to $true
  Applies to the Backup-EDGEProfiles function

 .Parameter ZIPSource
  (Mandatory - file path)
  Location of the User Data backup archive file.  
  Applies to the Restore-EDGEProfiles function

 .Parameter REGSource
  (Mandatory - file path)
  Location of the profile data registry file.
  Applies to the Restore-EDGEProfiles function

 .Parameter ExistingDataAction
  (Mandatory - Rename/Remove)
  Choose weather to have the existing User Data removed completely or just renamed. Renaming will add a datestamp to the existing USer Data folder.
  Applies to the Restore-EDGEProfiles function

 .Example
   # Backup the current users EDGE Profiles to the _EdgeProfilesBackup folder in the users own OneDrive.
   Backup-EDGEProfiles

 .Example
   # Backup the current users EDGE Profiles to the users own TEMP folder.
   Backup-EDGEProfiles -Destination $env:TEMP

 .Example
   # Restore a previous backup and remove existing user data.
   Restore-EDGEProfiles -ZIPSource EDGE-UserData30July2021-MichaelMardahl.zip -REGSource EDGE-ProfilesRegistry30July2021-MichaelMardahl.reg -ExistingDataAction Remove

 .NOTES
        Author:      Michael Mardahl
        Contact:     @michael_mardahl
        Created:     2021-30-07
        Updated:     2021-30-07
        Version history:
        1.0.0 - (2021-30-07) Script created
  
#>
#Requires -Version 5

function Backup-EDGEProfiles {

    #Add the -verbose parameter to commandline to get extra output.
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,
                    HelpMessage="Destination of the EDGE profile backup (Defaults to OneDrive root \_EdgeProfilesBackup)")]
        [string]$Destination = (Join-Path -Path $env:OneDrive -ChildPath "\_EdgeProfilesBackup"),
        [Parameter(Mandatory=$false,
                    HelpMessage="Append the current date to the backup (Defaults to true)")]
        [bool]$AddDate = $true     
    )

    #region Execute

    #Verify that the entered destination exists
    if(-not (Test-Path $Destination)){
        Write-Warning "The entered destination path could not be validated ($Destination)"
        exit 1
    }

    #Verify EDGE is closed
    if (Get-Process msedge -ErrorAction SilentlyContinue) {
        Write-Warning "EDGE is still running, please close any open EDGE Browsers and try again."
        exit 1
    }

    Write-Host "Starting EDGE profiles backup for $($env:USERNAME) to ($Destination) - DON'T OPEN EDGE! and please wait..."
    Write-Verbose "Destination root   : $Destination"
    Write-Verbose "Append date        : $AddDate"

    #Date name addition check
    if($AddDate) {
        $dateName = (get-date -Format ddMMMMyyyy).ToString()
    } else {
        $dateName = ""
    }

    #Setting some important variables
    $edgeProfilesPath = (Join-Path -Path $env:LOCALAPPDATA -ChildPath "\Microsoft\Edge")
    $edgeProfilesRegistry = "HKCU\Software\Microsoft\Edge\PreferenceMACs"

    #Validate destination exists
    if (-not (Test-Path $Destination)){
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    #Export registry key
    $regBackupDestination = (Join-Path -Path $Destination -ChildPath "\EDGE-ProfilesRegistry$($dateName)-$($env:USERNAME).reg")
    Write-Verbose "Exporting Registry backup to $regBackupDestination"
    #Remove any existing destination file, else the export will stall.
    if(($regBackupDestination -ilike "*.reg") -and (Test-Path $regBackupDestination)) {
        Remove-Item $regBackupDestination -Force -ErrorAction SilentlyContinue
    }
    $regCMD = Invoke-Command {reg export "$edgeProfilesRegistry" "$regBackupDestination"}

    #Export user data

    #Cleaning cache
    Write-Verbose "Cleaning up cache before export."
    if(Test-Path $edgeProfilesPath){
        $cacheFolders = Get-ChildItem -Path $edgeProfilesPath -r  | ? { $_.PsIsContainer -and $_.Name -eq "Cache" }
        Foreach ($folder in $cacheFolders)
        {
            $rmPath = Join-Path -Path $folder.fullname -ChildPath "\*"
            Write-Verbose "Emptying $rmPath"
            Remove-Item $rmPath -Recurse -Force
        }
        Write-Verbose "Cleanup completed."
    } else {
        Write-Error "EDGE user data folder missing - terminating!"
        Exit 1
    }

    #Creating ZIP Archive
    $zipBackupDestination = (Join-Path -Path $Destination -ChildPath "\EDGE-UserData$($dateName)-$($env:USERNAME).zip")
    Write-Verbose "Exporting user data backup to $zipBackupDestination"
    #Remove any existing destination file, else the export will fail.
    if(($zipBackupDestination -ilike "*.zip") -and (Test-Path $zipBackupDestination)) {
        Remove-Item $zipBackupDestination -Force -ErrorAction SilentlyContinue
    }
    #Compressing data to backup location
    try {
        Get-ChildItem -Path $edgeProfilesPath | Compress-Archive -DestinationPath $zipBackupDestination -CompressionLevel Fastest
        Write-Host "EDGE Profile export completed to: $Destination"
    } catch {
        #Error out and cleanup
        Write-Error $_
        Remove-Item $zipBackupDestination -Force -ErrorAction SilentlyContinue
        Remove-Item $regBackupDestination -Force -ErrorAction SilentlyContinue
        Write-Error "EDGE Backup failed, did you forget to keep EDGE closed?!"
        exit 1
    }
    #endregion Execute
}

function Restore-EDGEProfiles {

    #Add the -verbose parameter to commandline to get extra output.
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                    HelpMessage="Source of the EDGE User Data profile backup archive")]
        [string]$ZIPSource,
        [Parameter(Mandatory=$true,
                    HelpMessage="Source of the EDGE Registry profile backup file")]
        [string]$REGSource,
        [Parameter(Mandatory=$true,
                    HelpMessage="How to handle the existing profiles? Options are Backup or Remove")]
        [ValidateSet('Rename','Remove')]
        [string]$ExistingDataAction    
    )

    #region Execute

    #Verify that the entered sources exits and have the right fileextention
    if(-not ((Test-Path $ZIPSource) -or (-not ($ZIPSource -ilike "*.zip")))){
        Write-Warning "The entered source file could not be validated ($ZIPSource)"
        exit 1
    }
    if(-not ((Test-Path $REGSource) -or (-not ($REGSource -ilike "*.reg")))){
        Write-Warning "The entered source file could not be validated ($REGSource)"
        exit 1
    }

    #Verify EDGE is closed
    if (Get-Process msedge -ErrorAction SilentlyContinue) {
        Write-Warning "EDGE is still running, please close any open EDGE Browsers and try again."
        exit 1
    }

    Write-Host "Starting EDGE profiles restore for $($env:USERNAME) - (DON'T OPEN EDGE!) please wait..."
    Write-Verbose "Source archive   : $ZIPSource"
    Write-Verbose "Source registry  : $REGSource"

    #Define location of EDGE Profile for current user
    $edgeProfilesPath = (Join-Path -Path $env:LOCALAPPDATA -ChildPath "\Microsoft\Edge")

    #Handle existing User Data
    $UserData = (Join-Path -Path $edgeProfilesPath -ChildPath "\User Data")
    if (Test-Path $UserData){
        Write-Verbose "Existing User Data folder found in $edgeProfilesPath"
        if($ExistingDataAction -eq "Rename") {
            $renameFolder = "$($UserData)-$((get-date -Format ddMMMMyyyy-HHmmss).ToString())"
            Write-Verbose "Rename parameter set - Renaming folder to '$renameFolder'"
            Rename-Item $UserData $renameFolder
        }
        else {
            Write-Verbose "Remove parameter set - Deleting existing data."
            Remove-Item $UserData -Recurse -Force
        }
    }

    #Import registry key
    Write-Verbose "Importing Registry backup from $REGSource"
    $regCMD = Invoke-Command {reg import "$REGSource"}

    #Import user data
    #
    Write-Verbose "Decompressing '$ZIPSource' to $edgeProfilesPath"
    try {
        Expand-Archive -Path $ZIPSource -DestinationPath $edgeProfilesPath -Force
        Write-Host "EDGE Profile import completed to: $UserData"
    } catch {
        #Error out and cleanup
        Write-Error $_
        Remove-Item $zipBackupDestination -Force -ErrorAction SilentlyContinue
        Remove-Item $regBackupDestination -Force -ErrorAction SilentlyContinue
        Write-Error "EDGE import failed, did you forget to keep EDGE closed?!"
        exit 1
    }
    #endregion Execute
}

Export-ModuleMember -Function Backup-EDGEProfiles, Restore-EDGEProfiles