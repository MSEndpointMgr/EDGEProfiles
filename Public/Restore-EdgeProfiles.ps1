function Restore-EdgeProfiles {
    <#
     .Synopsis
      Restore Microsoft Edge (Anaheim) Profiles to the current users Edge Browser.
    
     .Description
      Will restore all Edge "User Data" for the current user from an archive created by the Backup-EdgeProfiles function.
    
     .Parameter Verbose
      Enables extended output
    
     .Parameter ZIPSource
      (Mandatory - file path)
      Location of the User Data backup archive file.
    
     .Parameter REGSource
      (Mandatory - file path)
      Location of the profile data registry file.
    
     .Parameter ExistingDataAction
      (Mandatory - Rename/Remove)
      Choose wheather to have the existing User Data removed completely or just renamed. Renaming will add a datestamp to the existing USer Data folder.
    
     .Example
       # Restore a previous backup and remove existing user data.
       Restore-EdgeProfiles -ZIPSource Edge-UserData30July2021-MichaelMardahl.zip -REGSource Edge-ProfilesRegistry30July2021-MichaelMardahl.reg -ExistingDataAction Remove
    #>
    
        #Add the -verbose parameter to commandline to get extra output.
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true,
                        HelpMessage="Source of the Edge User Data profile backup archive")]
            [string]$ZIPSource,
            [Parameter(Mandatory=$true,
                        HelpMessage="Source of the Edge Registry profile backup file")]
            [string]$REGSource,
            [Parameter(Mandatory=$true,
                        HelpMessage="How to handle the existing profiles? Options are Backup or Remove")]
            [ValidateSet('Rename','Remove')]
            [string]$ExistingDataAction
        )
    
        #region Execute
    
        #Verify that the entered sources exits and have the right fileextention
        if(-not ((Test-Path $ZIPSource) -or (-not ($ZIPSource -ilike "*.zip")))){
            Write-Error "The entered source file could not be validated ($ZIPSource)"
            break
        }
        if(-not ((Test-Path $REGSource) -or (-not ($REGSource -ilike "*.reg")))){
            Write-Error "The entered source file could not be validated ($REGSource)"
            break
        }
    
        #Verify Edge is closed
        if (Get-Process msEdge -ErrorAction SilentlyContinue) {
            Write-Error "Edge is still running, please close any open Edge Browsers and try again."
            Break
        }
    
        Write-Output "Starting Edge profiles restore for $($env:USERNAME) - (DON'T OPEN Edge!) please wait..."
        Write-Verbose "Source archive   : $ZIPSource"
        Write-Verbose "Source registry  : $REGSource"
    
        #Define location of Edge Profile for current user
        $EdgeProfilesPath = (Join-Path -Path $env:LOCALAPPDATA -ChildPath "\Microsoft\Edge")
    
        #Handle existing User Data
        $UserData = (Join-Path -Path $EdgeProfilesPath -ChildPath "\User Data")
        if (Test-Path $UserData){
            Write-Verbose "Existing User Data folder found in $EdgeProfilesPath"
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
        Write-Verbose "Decompressing '$ZIPSource' to $EdgeProfilesPath"
        try {
            Expand-Archive -Path $ZIPSource -DestinationPath $EdgeProfilesPath -Force
            Write-Output "Edge Profile import completed to: $UserData"
        } catch {
            #Error out and cleanup
            Write-Error $_
            Remove-Item $zipBackupDestination -Force -ErrorAction SilentlyContinue
            Remove-Item $regBackupDestination -Force -ErrorAction SilentlyContinue
            Write-Error "Edge import failed, did you forget to keep Edge closed?!"
            break
        }
        #endregion Execute
    }