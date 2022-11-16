function Backup-EdgeProfiles {
    <#
     .Synopsis
      Backup current users Microsoft Edge (Anaheim) Profiles.
    
     .Description
      Will backup all Edge "User Data" for the current user.
    
     .Parameter Verbose
      Enables extended output
    
     .Parameter Destination
      (optional)
      Location in which to save the backup ZIP and REG files
      Defaults to the users OneDrive
    
     .Parameter AddDate
      (optional - $true/$false)
      Applies a date stamp to the filenames.
      Defaults to $true
    
     .Example
       # Backup the current users Edge Profiles to the _EdgeProfilesBackup folder in the users own OneDrive.
       Backup-EdgeProfiles
    
     .Example
       # Backup the current users Edge Profiles to the users own TEMP folder.
       Backup-EdgeProfiles -Destination $env:TEMP
    #>
    
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$false,HelpMessage="Destination of the Edge profile backup (Defaults to OneDrive root \_EdgeProfilesBackup)")][string]$Destination = (Join-Path -Path $env:OneDrive -ChildPath "\_EdgeProfilesBackup"),
            [Parameter(Mandatory=$false,HelpMessage="Append the current date to the backup (Defaults to true)")][bool]$AddDate = $true,
            [Parameter(Mandatory=$false,HelpMessage="Add option to exclude folders from the backup (Defaults to exclude 'Code Cache', 'Service Worker' and 'Cache' folders)")][String[]]$FoldersToExclude = @("Code Cache", "Service Worker", "Cache"),
            [Parameter(Mandatory=$false,HelpMessage="Force close all instances of Edge")][bool]$CloseEdge
        )
    
        #region Execute
    
        #Verify that the entered destination exists
        if ((-not (Test-Path $Destination) -and ($Destination -eq (Join-Path -Path $env:OneDrive -ChildPath "\_EdgeProfilesBackup")))){
            #Create default destination
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        elseif (-not (Test-Path $Destination)){
            Write-Warning "The entered destination path could not be validated ($Destination)"
            break
        }
    
        #Verify Edge is closed
        $EdgeRunning = Get-Process msEdge -ErrorAction SilentlyContinue
        if ($EdgeRunning)
            {if ($CloseEdge) {Stop-Process -Name msEdge}
            else { Write-Error "Edge is still running, please close any open Edge Browsers and try again."
            break}

            }
          
        Write-Output "Starting Edge profiles backup for $($env:USERNAME) to ($Destination) - DON'T OPEN Edge! and please wait..."
        Write-Verbose "Destination root   : $Destination"
        Write-Verbose "Append date        : $AddDate"
    
        #Date name addition check
        if($AddDate) {
            $dateName = (get-date -Format ddMMMMyyyy).ToString()
        } else {
            $dateName = ""
        }
    
        #Setting some important variables
        $EdgeProfilesPath = (Join-Path -Path $env:LOCALAPPDATA -ChildPath "\Microsoft\Edge")
        $EdgeProfilesRegistry = "HKCU\Software\Microsoft\Edge\PreferenceMACs"
    
        #Export registry key
        $regBackupDestination = (Join-Path -Path $Destination -ChildPath "\Edge-ProfilesRegistry$($dateName)-$($env:USERNAME).reg")
        Write-Verbose "Exporting Registry backup to $regBackupDestination"
        #Remove any existing destination file, else the export will stall.
        if(($regBackupDestination -ilike "*.reg") -and (Test-Path $regBackupDestination)) {
            Remove-Item $regBackupDestination -Force -ErrorAction SilentlyContinue
        }
        $regCMD = Invoke-Command {reg export "$EdgeProfilesRegistry" "$regBackupDestination"}
    
        #Export user data
    
        #Creating ZIP Archive
        $zipBackupDestination = (Join-Path -Path $Destination -ChildPath "\Edge-UserData$($dateName)-$($env:USERNAME).zip")
        Write-Verbose "Exporting user data backup to $zipBackupDestination"
        #Remove any existing destination file, else the export will fail.
        if(($zipBackupDestination -ilike "*.zip") -and (Test-Path $zipBackupDestination)) {
            Remove-Item $zipBackupDestination -Force -ErrorAction SilentlyContinue
        }
        #Compressing data to backup location
        try {
            Get-ChildItem -Path $EdgeProfilesPath -Directory -Recurse | Where-Object {$_.Name -notin $FoldersToExclude} | Compress-Archive -DestinationPath $zipBackupDestination -CompressionLevel Fastest
            Write-Output "Edge Profile export completed to: $Destination"
        } catch {
            #Error out and cleanup
            Write-Error $_
            Remove-Item $zipBackupDestination -Force -ErrorAction SilentlyContinue
            Remove-Item $regBackupDestination -Force -ErrorAction SilentlyContinue
            Write-Error "Edge Backup failed, did you forget to keep Edge closed?!"
            break
        }
        #endregion Execute
    }