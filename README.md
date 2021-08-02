# EDGEProfiles
PowerShell module to handle backup and restore of EDGE browser profiles for the current user.

# Installation
Install-Module EDGEProfiles

# Works/tested on
- Windows 10 20H2 and newer
- Windows 11 Preview and newer
- All EDGE Chromium versions should theoretically be supported.

#Help

**.Synopsis**

  Allows for easy backup and restore of Microsoft EDGE (Anaheim) Profiles.
  EDGE MUST BE CLOSED DURING!

**.Description**

  Will backup all EDGE "User Data" for the current user. This data contains all the "Profiles" within the browser, and the corresponding registry keys will also be saved alongside the backup.
  Backups are zipped to allow for easy storage on locations like OneDrive.
  Before archiving the backup, all profiles have their Cache emptied.

  Restore will replace the current users EDGE data. The command requires that the user chooses how to handle existing data.

 **.Example**
 
   Backup the current users EDGE Profiles to the \_EdgeProfilesBackup folder in the users own OneDrive.
   
   *Backup-EDGEProfiles*

 **.Example**
 
   Backup the current users EDGE Profiles to the users own TEMP folder.
   
   *Backup-EDGEProfiles -Destination $env:TEMP*

 **.Example**
 
   Restore a previous backup and remove existing user data.
   
   *Restore-EDGEProfiles -ZIPSource EDGE-UserData30July2021-MichaelMardahl.zip -REGSource EDGE-ProfilesRegistry30July2021-MichaelMardahl.reg -ExistingDataAction Remove*
