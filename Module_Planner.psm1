$SqlServer = "sqlavalabplanner-dev.database.windows.net"
$SqlDatabase = "dbmigrationplanner"
$Username = "sqlroot"
$Password = "+2sp=+2pb"

#########################################################
##Log

function Write-Log {

    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory = $false)] 
        [Alias('LogPath')] 
        [string]$Path = 'C:\Logs\PowerShellLog.log', 
         
        [Parameter(Mandatory = $false)] 
        [ValidateSet("Error", "Warn", "Info")] 
        [string]$Level = "Info", 
         
        [Parameter(Mandatory = $false)] 
        [switch]$NoClobber 
    ) 
 
    Begin { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
    } 
    Process { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
        } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
        } 
 
        else { 
            # Nothing to see here yet. 
        } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
            } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
            } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
            } 
        } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End { 
    } 
}

#########################################################
##Planner Wave

Function New-PlannerWave() {
    param(
        [Parameter(Mandatory = $true)][string]$WaveName,
        [Parameter(Mandatory = $true)][datetime]$ScheduledDate,
        [Parameter(Mandatory = $true)][int]$ScheduleTimeZone,
        [Parameter(Mandatory = $true)][int]$MaxNumberOfUsers,
        [Parameter(Mandatory = $false)][boolean]$DisableEmails = $false, # default
        [Parameter(Mandatory = $false)][int]$Status = 0, # default "In Validation"
        [Parameter(Mandatory = $false)][boolean]$IsSalesUsers = $false, # default
        [Parameter(Mandatory = $false)][boolean]$IsVIP = $false, # default
        [Parameter(Mandatory = $false)][boolean]$IsPilot = $false # default
    )

    $QueryPlannerWave = "Insert Into [dbo].[waves] (Name, ScheduledDate, MaxNumberOfUsers, IsPilot, IsSalesUsersOnly, IsVipOnly, Status, DisableEmails, ScheduleTimeZoneId) 
                        VALUES ('$WaveName', '$ScheduledDate', '$MaxNumberOfUsers', '$IsPilot', '$IsSalesUsers', '$IsVIP', '$Status', '$DisableEmails', '$ScheduleTimeZone')
                        Select * from dbo.waves where name = '$WaveName'"

    try{
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $queryPlannerWave -OutputSqlErrors:$true   
        Write-Host "$WaveName has been successfully created." -ForegroundColor Green  
    } Catch {
        Write-error "Unable to create $WaveName - $($error[0])"
    }                   
}

Function Remove-PlannerWave() {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="High")] 
    param(
        [Parameter(Mandatory = $true)][string]$WaveName
    )

    $QueryPlannerWave = 
    "DELETE [dbo].[Waves]
    WHERE name = '$WaveName'"

    if ($PSCmdlet.ShouldProcess($WaveName,"Removing")) {
        try{
            Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $queryPlannerWave -OutputSqlErrors:$true 
            Write-Host "$WaveName has been successfully Removed." -ForegroundColor Green  
        } Catch {
            Write-error "Unable to remove $WaveName - $($error[0])"
        }
    }        
}

Function Get-PlannerWave() {
    param(
        [Parameter(Mandatory = $false)][string]$WaveName
    )
  
    If ($WaveName -eq $null -or $WaveName -eq "") {$QueryGetPlannerWave = "Select * from  [dbo].[Waves];"}
    Else { $QueryGetPlannerWave = "Select * from  [dbo].[Waves] WHERE Name = '$WaveName'"}

    try{
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryGetPlannerWave -OutputSqlErrors:$true 
    } Catch {
        Write-error "Unable to get wave $WaveName - $($error[0])"
    }
}

Function Set-PlannerWave() {
    param(
        [Parameter(Mandatory = $true)][string]$WaveName,
        [Parameter(Mandatory = $false)][string]$NewWaveName,
        [Parameter(Mandatory = $false)][datetime]$NewScheduledDate,
        [Parameter(Mandatory = $false)][int]$NewMaxNumberOfUSers,
        [Parameter(Mandatory = $false)][int]$NewStatus,
        [Parameter(Mandatory = $false)][int]$NewScheduleTimeZoneId,
        [Parameter(Mandatory = $false)][boolean]$IsPilot,
        [Parameter(Mandatory = $false)][boolean]$IsSalesUsers,
        [Parameter(Mandatory = $false)][boolean]$IsVIP,
        [Parameter(Mandatory = $false)][boolean]$DisableEmails
    )

    $TechnicalIdUpdatePlannerWave = "SELECT TechnicalID FROM [dbo].[Waves] WHERE Name = '$WaveName'"
    $ResultTechnicalIdUpdatePlannerWave = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $TechnicalIdUpdatePlannerWave -OutputSqlErrors:$true 
    $WaveTechnicalId = $ResultTechnicalIdUpdatePlannerWave.TechnicalId

    If ($NewWaveName -ne $null -or $NewWaveName -ne "") {$QueryUpdatePlannerWaveNewName = "UPDATE [dbo].[waves] SET Name = '$NewWaveName' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewName = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewName -OutputSqlErrors:$true 

    If ($NewScheduledDate -ne $null -or $NewScheduledDate -ne "") {$QueryUpdatePlannerWaveNewScheduledDate = "UPDATE [dbo].[waves] SET ScheduledDate = '$NewScheduledDate' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewScheduledDate = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewScheduledDate -OutputSqlErrors:$true 

    If ($NewMaxNumberOfUSers -ne $null -or $NewMaxNumberOfUSers -ne "") {$QueryUpdatePlannerWaveNumberOfUSers = "UPDATE [dbo].[waves] SET MaxNumberOfUSers = '$NewMaxNumberOfUSers' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNumberOfUSers = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNumberOfUSers -OutputSqlErrors:$true 

    If ($NewStatus -ne $null -or $NewStatus -ne "") {$QueryUpdatePlannerWaveNewStatus = "UPDATE [dbo].[waves] SET Status = '$NewStatus' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewStatus = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewStatus -OutputSqlErrors:$true 

    If ($NewScheduleTimeZoneId -ne $null -or $NewScheduleTimeZoneId -ne "") {$QueryUpdatePlannerWaveNewScheduleTimeZoneId = "UPDATE [dbo].[waves] SET ScheduleTimeZoneId = '$NewScheduleTimeZoneId' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewScheduleTimeZoneId = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewScheduleTimeZoneId -OutputSqlErrors:$true 

   If ($IsPilot -ne $null -or $IsPilot -ne "") {$QueryUpdatePlannerWaveIsPilot = "UPDATE [dbo].[waves] SET IsPilot = '$IsPilot' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveIsPilot = $null}
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveIsPilot -OutputSqlErrors:$true 

   If ($IsSalesUsers -ne $null -or $IsSalesUsers -ne "") {$QueryUpdatePlannerWaveIsSalesUsers = "UPDATE [dbo].[waves] SET IsSalesUsersOnly = '$IsSalesUsers' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveIsSalesUsers = $null}
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveIsSalesUsers -OutputSqlErrors:$true 

   If ($IsVIP -ne $null -or $IsVIP -ne "") {$QueryUpdatePlannerWaveIsVIP = "UPDATE [dbo].[waves] SET IsVipOnly = '$IsVIP' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveIsVIP = $null} 
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveIsVIP -OutputSqlErrors:$true 

   If ($DisableEmails -ne $null -or $DisableEmails -ne "") {$QueryUpdatePlannerWaveDisableEmails = "UPDATE [dbo].[waves] SET DisableEmails = '$DisableEmails' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveDisableEmails = $null} 
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveDisableEmails -OutputSqlErrors:$true 

}

Function Set-PlannerWave-2() {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="High")] 
    param(
        [Parameter(Mandatory = $true)][string]$WaveName,
        [Parameter(Mandatory = $false)][string]$NewWaveName,
        [Parameter(Mandatory = $false)][datetime]$NewScheduledDate,
        [Parameter(Mandatory = $false)][int]$NewMaxNumberOfUSers,
        [Parameter(Mandatory = $false)][int]$NewStatus,
        [Parameter(Mandatory = $false)][int]$NewScheduleTimeZoneId,
        [Parameter(Mandatory = $false)][boolean]$IsPilot,
        [Parameter(Mandatory = $false)][boolean]$IsSalesUsers,
        [Parameter(Mandatory = $false)][boolean]$IsVIP,
        [Parameter(Mandatory = $false)][boolean]$DisableEmails
    )

    $GetWaveQuery = "SELECT * FROM [dbo].[Waves] WHERE Name = '$WaveName'"
    
    try{
        $WaveInformation = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $GetWaveQuery -OutputSqlErrors:$true
    } Catch {
        Write-error "Unable to get wave $WaveName - $($error[0])"
        Break
    }

    if (!$NewWaveName)              {$NewWaveName           = $WaveInformation.name}
    if (!$NewScheduledDate)         {$NewScheduledDate      = $WaveInformation.ScheduledDate}
    if (!$NewMaxNumberOfUSers)      {$NewMaxNumberOfUSers   = $WaveInformation.MaxNumberOfUSers}
    if (!$NewStatus)                {$NewStatus             = $WaveInformation.Status}
    if (!$NewScheduleTimeZoneId)    {$NewScheduleTimeZoneId = $WaveInformation.ScheduleTimeZoneId}
    if (!$IsPilot)                  {$IsPilot               = $WaveInformation.IsPilot}
    if (!$IsSalesUsers)             {$IsSalesUsers          = $WaveInformation.IsSalesUsers}
    if (!$IsVIP)                    {$IsVIP                 = $WaveInformation.IsVIP}
    if (!$DisableEmails)            {$DisableEmails         = $WaveInformation.DisableEmails}

    $QueryUpdatePlannerWave = "UPDATE [dbo].[waves] SET 
                                    Name                = '$NewWaveName',
                                    ScheduledDate       = '$NewScheduledDate',
                                    MaxNumberOfUSers    = '$NewMaxNumberOfUSers',
                                    Status              = '$NewStatus',
                                    ScheduleTimeZoneId  = '$NewScheduleTimeZoneId',
                                    IsPilot             = '$IsPilot',
                                    IsSalesUsers        = '$IsSalesUsers',
                                    IsVIP               = '$IsVIP',
                                    DisableEmails       = '$DisableEmails',
                                WHERE name          = '$WaveName'"
    
    
    if ($PSCmdlet.ShouldProcess($WaveName,"Updating")) {
        try{
            Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWave -OutputSqlErrors:$true 
            Write-Host "$WaveName has been successfully updated." -ForegroundColor Green             
        } Catch {
            Write-error "Unable to update $WaveName - $($error[0])"
        }
    }          
}

#########################################################
#Planner User

Function New-PlannerUser() {
    param(
        [Parameter(Mandatory = $true )][string]$PrimarySmtpAddress,
        [Parameter(Mandatory = $false)][string]$SamAccountName,
        [Parameter(Mandatory = $false)][string]$DisplayName,
        [Parameter(Mandatory = $false)][string]$FirstName,
        [Parameter(Mandatory = $false)][string]$LastName,
        [Parameter(Mandatory = $false)][string]$GivenName,
        [Parameter(Mandatory = $false)][string]$Sn,
        [Parameter(Mandatory = $false)][string]$PhysicalDeliveryOfficeName,
        #[Parameter(Mandatory = $false)][GUID]$MSDSConsistencyGuid,
        [Parameter(Mandatory = $false)][string]$DistinguishedName,
        [Parameter(Mandatory = $false)][datetime]$LastLogonTimestamp,
        [Parameter(Mandatory = $false)][string]$ObjectCategory,
        [Parameter(Mandatory = $false)][string]$Department,
        [Parameter(Mandatory = $false)][string]$Title,
        [Parameter(Mandatory = $false)][string]$Company,
        [Parameter(Mandatory = $false)][string]$Description,
        [Parameter(Mandatory = $false)][string]$Division,
        [Parameter(Mandatory = $false)][int]$EmployeeID,
        [Parameter(Mandatory = $false)][string]$Manager,
        [Parameter(Mandatory = $false)][int]$TelephoneNumber,
        [Parameter(Mandatory = $false)][string]$UserPrincipalName,
        [Parameter(Mandatory = $false)][string]$Co,
        [Parameter(Mandatory = $false)][boolean]$IsEnabled = $true, #Default
        [Parameter(Mandatory = $false)][int]$VipLevel  = 0, #Default
        [Parameter(Mandatory = $false)][int]$MailboxSize,
        [Parameter(Mandatory = $false)][int]$NumberOfArchives,
        [Parameter(Mandatory = $false)][int]$ArchivesSize,
        [Parameter(Mandatory = $false)][int]$NumberOfMissed,
        [Parameter(Mandatory = $false)][datetime]$AbsentFrom,
        [Parameter(Mandatory = $false)][datetime]$AbsentTo,
        [Parameter(Mandatory = $false)][string]$Site,
        [Parameter(Mandatory = $false)][string]$Entity,
        [Parameter(Mandatory = $false)][boolean]$IsPilot  = $False, #Default
        [Parameter(Mandatory = $false)][boolean]$IsSalesUser  = $False, #Default
        [Parameter(Mandatory = $false)][boolean]$IsPriority  = $False, #Default
        [Parameter(Mandatory = $false)][int]$MigrationStatus  = 0, #Default
        [Parameter(Mandatory = $false)][int]$WaveName,
        [Parameter(Mandatory = $false)][datetime]$WhenMailboxCreated,
        [Parameter(Mandatory = $false)][int]$RecipientTypeDetails,
        [Parameter(Mandatory = $false)][string]$Forest,
        [Parameter(Mandatory = $false)][string]$Domain,
        [Parameter(Mandatory = $false)][string]$Country,
        [Parameter(Mandatory = $false)][string]$Area,       
        [Parameter(Mandatory = $false)][boolean]$IsSharedMailbox  = $False, #Default
        [Parameter(Mandatory = $false)][boolean]$IsResource  = $False, #Default
        [Parameter(Mandatory = $false)][boolean]$IsApplicativeMailbox  = $False, #Default
        [Parameter(Mandatory = $false)][string]$Delegation,
        [Parameter(Mandatory = $false)][string]$SiteName,
        [Parameter(Mandatory = $false)][boolean]$HasDeviceMDM,
        [Parameter(Mandatory = $false)][string]$Region,
        [Parameter(Mandatory = $false)][string]$CBU,
        [Parameter(Mandatory = $false)][string]$UserProfile,
        [Parameter(Mandatory = $false)][string]$languageName
        
    )

    if (!$languageName) {$languageID = 1}
    Else {$SQLQueryLanguage = "Select TechnicalID from dbo.languages where languageName = '$language'"
            $LanguageID = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $SQLQueryLanguage -OutputSqlErrors:$true
         }
     
    if ($WaveName)
         {$SQLQueryLWaveID = "Select TechnicalID from dbo.waves where name = '$WaveName'"
            $WaveID = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $SQLQueryLWaveID -OutputSqlErrors:$true
         }

    if ($WaveName)
       {$QueryPlannerUser = "Insert Into [dbo].[users] 
                        (
                            SamAccountName,DisplayName,FirstName,LastName,GivenName,Sn,PrimarySmtpAddress,
                            PhysicalDeliveryOfficeName,DistinguishedName,LastLogonTimestamp,ObjectCategory,
                            Department,Title,Company,Description,Division,EmployeeID,Manager,TelephoneNumber,
                            UserPrincipalName,Co,IsEnabled,VipLevel,MailboxSize,NumberOfArchives,ArchivesSize,
                            NumberOfMissed,AbsentFrom,AbsentTo,Site,Entity,IsPilot,IsSalesUser,IsPriority,
                            MigrationStatus,WhenMailboxCreated,RecipientTypeDetails,Forest,Domain,
                            Country,Area,LanguageId,IsSharedMailbox,IsResource,IsApplicativeMailbox,Delegation,
                            SiteName,HasDeviceMDM,Region,CBU,UserProfile      
                        ) 

                        VALUES (
                            '$SamAccountName','$DisplayName','$FirstName','$LastName','$GivenName','$Sn','$PrimarySmtpAddress',
                            '$PhysicalDeliveryOfficeName','$DistinguishedName','$LastLogonTimestamp','$ObjectCategory',
                            '$Department','$Title','$Company','$Description','$Division','$EmployeeID','$Manager','$TelephoneNumber',
                            '$UserPrincipalName','$Co','$IsEnabled','$VipLevel','$MailboxSize','$NumberOfArchives','$ArchivesSize',
                            '$NumberOfMissed','$AbsentFrom','$AbsentTo','$Site','$Entity','$IsPilot','$IsSalesUser','$IsPriority',
                            '$MigrationStatus','$WhenMailboxCreated','$RecipientTypeDetails','$Forest','$Domain',
                            '$Country','$Area','$LanguageId','$IsSharedMailbox','$IsResource','$IsApplicativeMailbox','$Delegation',
                            '$SiteName','$HasDeviceMDM','$Region','$CBU','$UserProfile'                     
                        )
                        select * from dbo.users where primarysmtpaddress = '$PrimarySmtpAddress'"}
    Else {$QueryPlannerUser = "Insert Into [dbo].[users] 
                        (
                            SamAccountName,DisplayName,FirstName,LastName,GivenName,Sn,PrimarySmtpAddress,
                            PhysicalDeliveryOfficeName,DistinguishedName,LastLogonTimestamp,ObjectCategory,
                            Department,Title,Company,Description,Division,EmployeeID,Manager,TelephoneNumber,
                            UserPrincipalName,Co,IsEnabled,VipLevel,MailboxSize,NumberOfArchives,ArchivesSize,
                            NumberOfMissed,AbsentFrom,AbsentTo,Site,Entity,IsPilot,IsSalesUser,IsPriority,
                            MigrationStatus,WhenMailboxCreated,RecipientTypeDetails,Forest,Domain,
                            Country,Area,LanguageId,IsSharedMailbox,IsResource,IsApplicativeMailbox,Delegation,
                            SiteName,HasDeviceMDM,Region,CBU,UserProfile,WaveID     
                        ) 

                        VALUES (
                            '$SamAccountName','$DisplayName','$FirstName','$LastName','$GivenName','$Sn','$PrimarySmtpAddress',
                            '$PhysicalDeliveryOfficeName','$DistinguishedName','$LastLogonTimestamp','$ObjectCategory',
                            '$Department','$Title','$Company','$Description','$Division','$EmployeeID','$Manager','$TelephoneNumber',
                            '$UserPrincipalName','$Co','$IsEnabled','$VipLevel','$MailboxSize','$NumberOfArchives','$ArchivesSize',
                            '$NumberOfMissed','$AbsentFrom','$AbsentTo','$Site','$Entity','$IsPilot','$IsSalesUser','$IsPriority',
                            '$MigrationStatus','$WhenMailboxCreated','$RecipientTypeDetails','$Forest','$Domain',
                            '$Country','$Area','$LanguageId','$IsSharedMailbox','$IsResource','$IsApplicativeMailbox','$Delegation',
                            '$SiteName','$HasDeviceMDM','$Region','$CBU','$UserProfile','$WaveID'                     
                        )
                        select * from dbo.users where primarysmtpaddress = '$PrimarySmtpAddress'"}     
    
    try{
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $queryPlannerUser -OutputSqlErrors:$true 
        Write-Host "$PrimarySmtpAddress has been successfully created." -ForegroundColor Green             
    } Catch {
        Write-error "Unable to create $PrimarySmtpAddress - $($error[0])"
    }  
}

Function Remove-PlannerUser() {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="High")] 
    param(
        [Parameter(Mandatory = $true)][string]$Identity   
    )

    $QueryRemovePlannerWave = "DELETE FROM dbo.WaveUserMailTemplates
                                WHERE userid = (select technicalid from dbo.users where primarysmtpaddress = '$Identity')
                                DELETE from dbo.users where primarysmtpaddress = '$Identity'"
    
    if ($PSCmdlet.ShouldProcess($Identity,"Removing")) {
        try{
            Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryRemovePlannerWave -OutputSqlErrors:$true 
            Write-Host "$PrimarySmtpAddress has been successfully Deleted." -ForegroundColor Green
        } Catch {
            Write-error "Unable to delete $PrimarySmtpAddress - $($error[0])"
        }
    }
    
}

Function Get-PlannerUser() {
    param(
        [Parameter(Mandatory = $false)][string]$Identity, 
        [Parameter(Mandatory = $false)][string]$AllProperties = $False #Default, 
    )

    if ($AllProperties = $True) {$Properties = "*"}
    else {$Properties = "Primarysmtpaddress, FirstName, LastName, Entity"}
  
    If ($Identity -eq $null -or $Identity -eq "") {
        $QueryGetPlannerUser = "Select $Properties from  [dbo].[Users];"
        }
    Else{
        $QueryGetPlannerUser = "Select $Properties from  [dbo].[Users] WHERE PrimarySmtpAddress = '$Identity'"
        }

    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryGetPlannerUser -OutputSqlErrors:$true 
 
}

Function Set-PlannerUser() {

}

########################################################
#Planner User's wave

Function New-PlannerUserWave() {
}

Function Remove-PlannerUserWave() {
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = "High")]   
    param(
        [Parameter(Mandatory = $true)][string]$Identity
    )
 
    $QueryRemovePlannerUserWave = "
    UPDATE [dbo].[Users]
    SET WaveId = null
    WHERE PrimarySmtpAddress = '$Identity'
    "
    if ($PSCmdlet.ShouldProcess($Identity, "Removing from his wave")) {
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryRemovePlannerUserWave -WarningAction -OutputSqlErrors:$true 
    }

}

Function Get-PlannerUserWave() {
    param(
        [Parameter(Mandatory = $true)][string]$Identity
    )

    $PlannerUserWave = @()

    $QueryPlannerUserWave1 = "Select PrimarySmtpAddress, WaveID from [dbo].[users] WHERE PrimarySmtpAddress = '$Identity'"
    $ResultPlannerUserWave1 = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryPlannerUserWave1 -OutputSqlErrors:$true 

    $WaveTechnicalID = $ResultPlannerUserWave1.WaveId

    $QueryPlannerUserWave2 = "SELECT Name, ScheduledDate, Status FROM [dbo].[Waves] WHERE TechnicalId = '$WaveTechnicalID'"
    $ResultPlannerUserWave2 = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryPlannerUserWave2 -OutputSqlErrors:$true 

    $WaveName = $ResultPlannerUserWave2.Name
    $WaveScheduledDate = $ResultPlannerUserWave2.ScheduledDate
    $WaveStatus = $ResultPlannerUserWave2.Status


    $Object = New-object PSobject
    $Object | add-member Noteproperty "PrimarySmtpAddress" -Value "$Identity"
    $Object | add-member Noteproperty "WaveName" "$WaveName"
    $Object | add-member Noteproperty "ScheduledDate" "$WaveScheduledDate"
    $Object | add-member Noteproperty "Status" "$WaveStatus"
    $PlannerUserWave += $Object 

    $PlannerUserWave
}

Function Set-PlannerUserWave() {
    param(
        [Parameter(Mandatory = $true)][string]$Identity,
        [Parameter(Mandatory = $true)][string]$WaveName
    )
 

    $QuerySetPlannerUserWaveTechID = "Select TechnicalId from [dbo].[waves] WHERE Name = '$WaveName'"
    $ResultSetPlannerUserWaveTechID = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QuerySetPlannerUserWaveTechID -OutputSqlErrors:$true 
    $WaveTechnicalID = $ResultSetPlannerUserWaveTechID.TechnicalId

    $QuerySetPlannerUserWave = "
    UPDATE [dbo].[Users]
    SET WaveId = $WaveTechnicalID
    WHERE PrimarySmtpAddress = '$Identity'
    "
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QuerySetPlannerUserWave -OutputSqlErrors:$true 

}

########################################################
#Planner Country
Function New-PlannerCountry() {
    param(
        [Parameter(Mandatory = $true)][string]$name
    )
 

    $QueryNewCountry = "Insert into dbo.countries (Name) Values ($name)
                        select * from dbo.countries where name = $Name
                        "
    
    try{
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryNewCountry -OutputSqlErrors:$true 
        Write-Host "$Name has been successfully added." -ForegroundColor Green
    } Catch {
        Write-error "Unable to add $Name - $($error[0])"
    }

}

Function Remove-PlannerCountry() {
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = "High")]   
    param(
        [Parameter(Mandatory = $true)][string]$name
    )
 
    $QueryNewCountry = "delete from dbo.countries (Name) where name = $Name"
    
    if ($PSCmdlet.ShouldProcess($Name, "Removing Country")) {
        try{
            Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryNewCountry -OutputSqlErrors:$true 
            Write-Host "$Name has been successfully removed." -ForegroundColor Green
        } Catch {
            Write-error "Unable to remove $Name - $($error[0])"
        }
    }
}
