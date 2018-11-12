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
        [Parameter(Mandatory = $true)][string]$ScheduledDate,
        [Parameter(Mandatory = $true)][string]$ScheduleTimeZone,
        [Parameter(Mandatory = $true)][string]$MaxNumberOfUsers,
        [Parameter(Mandatory = $false)][string]$DisableEmails,
        [Parameter(Mandatory = $false)][string]$Status,
        [Parameter(Mandatory = $false)][string]$IsSalesUsers,
        [Parameter(Mandatory = $false)][string]$IsVIP,
        [Parameter(Mandatory = $false)][string]$IsPilot
    )

    If ($DisableEmails -eq $null) { $DisableEmails = 0 }
    If ($Status -eq $null) { $Status = 0 }
    If ($IsSalesUsers -eq $null) { $IsSalesUsers = 0 }
    If ($IsVIP -eq $null) { $IsVIP = 0 }
    If ($IsPilot -eq $null) { $IsPilot = 0 }

    $QueryPlannerWave = "
    Insert Into [dbo].[waves] (Name, ScheduledDate, MaxNumberOfUsers, IsPilot, IsSalesUsersOnly, IsVipOnly, Status, DisableEmails, ScheduleTimeZoneId) 
    VALUES ('$WaveName', '$ScheduledDate', '$MaxNumberOfUsers', '$IsPilot', '$IsSalesUsers', '$IsVIP', '$Status', '$DisableEmails', '$ScheduleTimeZone') "

    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $queryPlannerWave
    
    Write-Host "$WaveName has been successfully created." -ForegroundColor Green                      

}
Function Remove-PlannerWave() {
    param(
        [Parameter(Mandatory = $true)][string]$WaveName
    )

    $QueryPlannerWave = 
    "DELETE [dbo].[Waves]
    WHERE name = '$WaveName'"

    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $queryPlannerWave
 
}
Function Get-PlannerWave() {
    param(
        [Parameter(Mandatory = $false)][string]$WaveName
    )
  
    If ($WaveName -eq $null -or $WaveName -eq "") {$QueryGetPlannerWave = "Select * from  [dbo].[Waves];"}
    Else { $QueryGetPlannerWave = "Select * from  [dbo].[Waves] WHERE Name = '$WaveName'"}

    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryGetPlannerWave
 
}
Function Set-PlannerWave() {
    param(
        [Parameter(Mandatory = $true)][string]$WaveName,
        [Parameter(Mandatory = $false)][string]$NewWaveName,
        [Parameter(Mandatory = $false)][string]$NewScheduledDate,
        [Parameter(Mandatory = $false)][string]$NewMaxNumberOfUSers,
        [Parameter(Mandatory = $false)][string]$NewStatus,
        [Parameter(Mandatory = $false)][string]$NewScheduleTimeZoneId,
        [Parameter(Mandatory = $false)][string]$IsPilot,
        [Parameter(Mandatory = $false)][string]$IsSalesUsers,
        [Parameter(Mandatory = $false)][string]$IsVIP,
        [Parameter(Mandatory = $false)][string]$DisableEmails
    )

    $TechnicalIdUpdatePlannerWave = "SELECT TechnicalID FROM [dbo].[Waves] WHERE Name = '$WaveName'"
    $ResultTechnicalIdUpdatePlannerWave = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $TechnicalIdUpdatePlannerWave
    $WaveTechnicalId = $ResultTechnicalIdUpdatePlannerWave.TechnicalId

    If ($NewWaveName -ne $null -or $NewWaveName -ne "") {$QueryUpdatePlannerWaveNewName = "UPDATE [dbo].[waves] SET Name = '$NewWaveName' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewName = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewName

    If ($NewScheduledDate -ne $null -or $NewScheduledDate -ne "") {$QueryUpdatePlannerWaveNewScheduledDate = "UPDATE [dbo].[waves] SET ScheduledDate = '$NewScheduledDate' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewScheduledDate = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewScheduledDate

    If ($NewMaxNumberOfUSers -ne $null -or $NewMaxNumberOfUSers -ne "") {$QueryUpdatePlannerWaveNumberOfUSers = "UPDATE [dbo].[waves] SET MaxNumberOfUSers = '$NewMaxNumberOfUSers' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNumberOfUSers = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNumberOfUSers

    If ($NewStatus -ne $null -or $NewStatus -ne "") {$QueryUpdatePlannerWaveNewStatus = "UPDATE [dbo].[waves] SET Status = '$NewStatus' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewStatus = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewStatus

    If ($NewScheduleTimeZoneId -ne $null -or $NewScheduleTimeZoneId -ne "") {$QueryUpdatePlannerWaveNewScheduleTimeZoneId = "UPDATE [dbo].[waves] SET ScheduleTimeZoneId = '$NewScheduleTimeZoneId' WHERE TechnicalId = '$WaveTechnicalId'"}
    ELSE {$QueryUpdatePlannerWaveNewScheduleTimeZoneId = $null}
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveNewScheduleTimeZoneId

   If ($IsPilot -ne $null -or $IsPilot -ne "") {$QueryUpdatePlannerWaveIsPilot = "UPDATE [dbo].[waves] SET IsPilot = '$IsPilot' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveIsPilot = $null}
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveIsPilot

   If ($IsSalesUsers -ne $null -or $IsSalesUsers -ne "") {$QueryUpdatePlannerWaveIsSalesUsers = "UPDATE [dbo].[waves] SET IsSalesUsersOnly = '$IsSalesUsers' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveIsSalesUsers = $null}
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveIsSalesUsers

   If ($IsVIP -ne $null -or $IsVIP -ne "") {$QueryUpdatePlannerWaveIsVIP = "UPDATE [dbo].[waves] SET IsVipOnly = '$IsVIP' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveIsVIP = $null} 
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveIsVIP

   If ($DisableEmails -ne $null -or $DisableEmails -ne "") {$QueryUpdatePlannerWaveDisableEmails = "UPDATE [dbo].[waves] SET DisableEmails = '$DisableEmails' WHERE TechnicalId = '$WaveTechnicalId'"}
   ELSE {$QueryUpdatePlannerWaveDisableEmails = $null} 
   Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryUpdatePlannerWaveDisableEmails

}

#########################################################
#Planner User
Function Update-PlannerUser() {

}
Function Get-PlannerUser() {
    param(
        [Parameter(Mandatory = $false)][string]$Identity
    )
  
    If ($Identity -eq $null -or $Identity -eq "") {$QueryGetPlannerUser = "Select * from  [dbo].[Users];"}
    Else { $QueryGetPlannerUser = "Select * from  [dbo].[Users] WHERE PrimarySmtpAddress = '$Identity'"}

    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryGetPlannerUser
 
}
Function New-PlannerUser() {
    param(
        [Parameter(Mandatory = $true)][string]$PrimarySmtpAddress,
        [Parameter(Mandatory = $false)][string]$Lastname,
        [Parameter(Mandatory = $false)][string]$Firstname,
        [Parameter(Mandatory = $false)][string]$UserPrincipalName,
        [Parameter(Mandatory = $false)][string]$Region,
        [Parameter(Mandatory = $false)][string]$Country,
        [Parameter(Mandatory = $false)][string]$CBU,
        [Parameter(Mandatory = $false)][string]$IsPilot,
        [Parameter(Mandatory = $false)][string]$IsVIP,
        [Parameter(Mandatory = $false)][string]$IsEnabled,
        [Parameter(Mandatory = $true)][string]$Language
    )

    If ($IsEnabled -eq $null -or $IsEnabled -eq "") { $IsEnabled = "1" }
    If ($UserPrincipalName -eq $null -or $UserPrincipalName -eq "") { $UserPrincipalName = "$PrimarySmtpAddress" }
    $separator = ".","@"
    If ($Firstname -eq $null -or $Firstname -eq "") { $Firstname = $PrimarySmtpAddress.Split($separator)[0] }
    If ($Lastname -eq $null -or $Lastname -eq "") { $Lastname = $PrimarySmtpAddress.Split($separator)[1] }

    $QueryPlannerUser = 
    "Insert Into [dbo].[users] (PrimarySmtpAddress, Lastname, Firstname, UserPrincipalName, Region, Country, CBU, IsPilot, VipLevel, IsEnabled, LanguageId) 
    VALUES ('$PrimarySmtpAddress', '$Lastname', '$Firstname', '$UserPrincipalName', '$Region', '$Country', '$CBU', '$IsPilot', '$IsVIP', '$IsEnabled', '$Language')"
        
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $queryPlannerUser
    Write-Host "$PrimarySmtpAddress has been successfully created." -ForegroundColor Cyan             
   
}
Function Remove-PlannerUser() {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="High")] 
    param(
        [Parameter(Mandatory = $true)][string]$Identity
        
    )

    $QueryRemovePlannerWave = 
    "
    DELETE FROM dbo.WaveUserMailTemplates
    WHERE userid = (select technicalid from dbo.users where primarysmtpaddress = '$Identity')
    DELETE from dbo.users where primarysmtpaddress = '$Identity'"
    
    if ($PSCmdlet.ShouldProcess($Identity,"Removing")) {
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryRemovePlannerWave
                }
    
}

########################################################
#Planner User's wave
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
        Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryRemovePlannerUserWave -WarningAction
    }

}
Function Set-PlannerUserWave() {
    param(
        [Parameter(Mandatory = $true)][string]$Identity,
        [Parameter(Mandatory = $true)][string]$WaveName
    )
 

    $QuerySetPlannerUserWaveTechID = "Select TechnicalId from [dbo].[waves] WHERE Name = '$WaveName'"
    $ResultSetPlannerUserWaveTechID = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QuerySetPlannerUserWaveTechID
    $WaveTechnicalID = $ResultSetPlannerUserWaveTechID.TechnicalId

    $QuerySetPlannerUserWave = "
    UPDATE [dbo].[Users]
    SET WaveId = $WaveTechnicalID
    WHERE PrimarySmtpAddress = '$Identity'
    "
    Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QuerySetPlannerUserWave

}
Function Get-PlannerUserWave() {
    param(
        [Parameter(Mandatory = $true)][string]$Identity
    )

    $PlannerUserWave = @()

    $QueryPlannerUserWave1 = "Select PrimarySmtpAddress, WaveID from [dbo].[users] WHERE PrimarySmtpAddress = '$Identity'"
    $ResultPlannerUserWave1 = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryPlannerUserWave1

    $WaveTechnicalID = $ResultPlannerUserWave1.WaveId

    $QueryPlannerUserWave2 = "SELECT Name, ScheduledDate, Status FROM [dbo].[Waves] WHERE TechnicalId = '$WaveTechnicalID'"
    $ResultPlannerUserWave2 = Invoke-Sqlcmd -ServerInstance "$SqlServer" -Database "$SqlDatabase" -Username "$Username" -Password "$Password" -Query $QueryPlannerUserWave2

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


