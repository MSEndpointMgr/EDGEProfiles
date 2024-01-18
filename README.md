# EdgeProfiles
PowerShell module to handle backup and restore of Edge browser profiles for the current user.

## Installation
Install-Module EdgeProfiles

## Works/tested on
- Windows 10 20H2 and newer
- Windows 11 Preview and newer
- All Edge Chromium versions should theoretically be supported.

# Help

**.Synopsis**

  Allows for easy backup and restore of Microsoft Edge (Anaheim) Profiles.
  EDGE MUST BE CLOSED DURING!

**.Description**

  Will backup all Edge "User Data" for the current user. This data contains all the "Profiles" within the browser, and the corresponding registry keys will also be saved alongside the backup.
  Backups are zipped to allow for easy storage on locations like OneDrive.
  Before archiving the backup, all profiles have their Cache emptied.

  Restore will replace the current users Edge data. The command requires that the user choose how to handle existing data.

  NB: Authentication tokens can't be exported, so users will have to sign-in again to services using modern authentication.

 **.Example**
 
   Backup the current users Edge Profiles to the \_EdgeProfilesBackup folder in the users own OneDrive.
   
   *Backup-EdgeProfiles*

 **.Example**
 
   Backup the current users Edge Profiles to the users own TEMP folder.
   
   *Backup-EdgeProfiles -Destination $env:TEMP*

 **.Example**
 
   Restore a previous backup and remove existing user data.
   
   *Restore-EdgeProfiles -ZIPSource Edge-UserData30July2021-MichaelMardahl.zip -REGSource Edge-ProfilesRegistry30July2021-MichaelMardahl.reg -ExistingDataAction Remove*
