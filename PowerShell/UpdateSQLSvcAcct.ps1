<# 
.Synopsis
This script is an add-on to https://github.com/sqlcan/SQLSvcAcctMgmt solution to allow DBA to manage
service account details using database.

.Description
This script extended the functionality of the parent script https://github.com/sqlcan/SQLSvcAcctMgmt.
Therefore both scripts are required.  This script also relies on the database, which controls the
server & service list for which to execute update against.

.Parameter SvcAcctMgmtSQLInstance
Service Account Management instance; where is the control database located?

.Parameter SvcAcctMgmtDBName
Default name for database is SvcAcctMgmt; however you can supply any other name.

.Parameter Passkey
The password to help decrypt the login information in the database; without this all information
will be in accessible.

.Parameter ComputerName
Target computer name for which you wish to update password or service account for.

.Parameter ServiceAccountName
Target service account for which the password needs to be updated for or for which the service account
needs to be changed for.

.Parameter ServiceType
Specify the SQL Service you wish to update the password or service account for; current supported are:
All, SqlServer, SqlAgent, and AnalysisServer.

.Example 
.\UpdateSQLSvcAcct.ps1 -SvcAcctMgmtSQLInstance Contoso -Passkey a54965a34d2407786456380953cedb89
Update all passwords or service account informations as defined in the database.

.Example
.\UpdateSQLSvcAcct.ps1 -SvcAcctMgmtSQLInstance Contoso -Passkey a54965a34d2407786456380953cedb89 -ServiceType SqlServer
Update all passwords or service account informations as defined in the database only SQL Engine.

.Example
.\UpdateSQLSvcAcct.ps1 -SvcAcctMgmtSQLInstance Contoso -Passkey a54965a34d2407786456380953cedb89 -ServiceType SqlServer -ServiceAccountName '.\SQLSvc' - Verbose
Change the service account for all SQL Services that have account Contoso\SQLSvc providing verbose output.

.Link 
https://github.com/sqlcan/SQLSvcAcctDBMgmt
http://sqlcan.com/

.Notes
Date         Version     Author      Comments
------------ ----------- ----------- ----------------------------------------------------------------
2017.08.08   1.00.0000   mogupta     Initial Release
2017.08.30   1.20.0000   mogupta     Added functionality to change service accounts.
                                     Also added ability to target service type (i.e. engine, ssrs,
                                     or agent).
#> 


# Location where the SvcAcctMgmt database is located with the 
param
(
    [Parameter(Mandatory=$true)][String] $SvcAcctMgmtSQLInstance,    
    [Parameter(Mandatory=$true)] [String] $Passkey,
    [Parameter(Mandatory=$false)] [String] $SvcAcctMgmtDBName = 'SvcAcctMgmt',
    [Parameter(Mandatory=$false)] [String] $ComputerName,
    [Parameter(Mandatory=$false)] [String] $ServiceAccountName,
    [Parameter(Mandatory=$false)] [String] $ServiceType = 'All',
    [Parameter(Mandatory=$false)] [Switch] $WhatIf
)

$ScriptPath = 'C:\Storage\GitHub\SQLSvcAcctMgmt\PowerShell'
$ParentScriptName = 'SQLSvcAcctMgmt.ps1'
$SQLSvcMgmt = Join-Path $ScriptPath $ParentScriptName

# Test connection
$Results = Invoke-Sqlcmd -ServerInstance $SvcAcctMgmtSQLInstance `
                            -Database master `
                            -Query "SELECT COUNT(*) AS DBCount FROM sys.databases WHERE name = '$SvcAcctMgmtDBName'"

if ($Results.DBCount -eq 0)
{
    throw "Database $SvcAcctMgmtDBName not found on $SvcAcctMgmtSQLInstance."
    return
}

# User may call this procedure three ways:
# Execute against all the computer accounts int the database.
# Execute against all the services on a computer.
# Execute against all computers with a service account.

$TSQLQuery = "EXEC dbo.GetComputerInstance @Passphrase = N'$Passkey', @ServiceType = '$ServiceType'"

if ($ComputerName)
{
    $TSQLQuery += ", @ComputerName = '$ComputerName'"
}

if ($ServiceAccountName)
{
    $TSQLQuery += ", @ServiceAccountName = '$ServiceAccountName'"
}

$SvcAccts = Invoke-Sqlcmd -ServerInstance $SvcAcctMgmtSQLInstance `
                            -Database $SvcAcctMgmtDBName `
                            -Query $TSQLQuery

ForEach ($SvcAcct IN $SvcAccts)
{
    if (($SvcAcct.NewServiceAccountName -eq [DBNull]::Value) -and (($SvcAcct.ServiceAccountNewPassword -eq [DBNull]::Value) -OR ($SvcAcct.ServiceAccountOldPassword -eq [DBNull]::Value)))
    {
        throw "Password Change: Passkey not valid for \\$($SvcAcct.ComputerName) service account $($SvcAcct.ServiceAccountName) service of type $($SvcAcct.ServiceType)."
        return 
    }

    if (($SvcAcct.NewServiceAccountName -ne [DBNull]::Value) -and ($SvcAcct.ServiceAccountNewPassword -eq [DBNull]::Value))
    {
        throw "Service Account Change: Passkey not valid for \\$($SvcAcct.ComputerName) service account $($SvcAcct.ServiceAccountName) service of type $($SvcAcct.ServiceType)."
        return 
    }

    & $SQLSvcMgmt -ComputerName $SvcAcct.ComputerName `
                    -ServiceAccountName $SvcAcct.ServiceAccountName `
                    -NewServiceAccountName $SvcAcct.NewServiceAccountName `
                    -ServiceType $SvcAcct.ServiceType `
                    -ServiceAccountOldPassword $SvcAcct.ServiceAccountOldPassword `
                    -ServiceAccountNewPassword $SvcAcct.ServiceAccountNewPassword `
                    -WhatIf:$WhatIf
  
}