<#
 .Synopsis
  Allows for easy backup and restore of Microsoft Edge (Anaheim) Profiles.
  Edge MUST BE CLOSED DURING!

 .Description
  Will backup all Edge "User Data" for the current user. This data contains all the "Profiles" within the browser, and the corresponding registry keys will also be saved alongside the backup.
  Backups are zipped to allow for easy storage on locations like OneDrive.


  Restore will replace the current users Edge data. The command requires that the user chooses how to handle existing data.

 .Example
   # Backup the current users Edge Profiles to the _EdgeProfilesBackup folder in the users own OneDrive.
   Backup-EdgeProfiles

 .Example
   # Backup the current users Edge Profiles to the users own TEMP folder.
   Backup-EdgeProfiles -Destination $env:TEMP

 .Example
   # Restore a previous backup and remove existing user data.
   Restore-EdgeProfiles -ZIPSource Edge-UserData30July2021-MichaelMardahl.zip -REGSource Edge-ProfilesRegistry30July2021-MichaelMardahl.reg -ExistingDataAction Remove

 .NOTES
        Author:      Michael Mardahl
        Contact:     @michael_mardahl
        Created:     2021-30-07
        Updated:     2021-31-07
        Version history:
        1.0.0 - (2021-30-07) Script created
        1.0.1 - (2021-31-07) Minor output fixes
        1.0.2 - (2021-01-08) Changed from exit codes to breaks
        1.0.3 - (2021-01-08) Changed from exit codes to breaks
        1.0.4 - (2021-01-08) Default destination validation bug fix (Thanks @byteben)
        1.0.5 - (2022-17-11) Move functions to separate file
                             Rename module and functions from "Edge" to "Edge"
                             Change cache clean to function so multiple folders can be emptied before backup
                             Added support to close edge forcefully
                             Added support to backup multiple channels
#>
[CmdletBinding()]
Param()
Process {
    # Locate all the public and private function specific files
    $PublicFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "Public") -Filter "*.ps1" -ErrorAction SilentlyContinue
    $PrivateFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "Private") -Filter "*.ps1" -ErrorAction SilentlyContinue

    # Dot source the function files
    foreach ($FunctionFile in @($PublicFunctions + $PrivateFunctions)) {
        try {
            . $FunctionFile.FullName -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Error -Message "Failed to import function '$($FunctionFile.FullName)' with error: $($_.Exception.Message)"
        }
    }

    Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
}