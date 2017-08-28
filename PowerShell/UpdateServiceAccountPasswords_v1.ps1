#This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
#THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#We grant you a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute
#the object code form of the Sample Code, provided that you agree:
#(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
#(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
#(iii) to indemnify, hold harmless, and defend Us and our suppliers from and against any claims or lawsuits, 
#      including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
#
# Developed By: Mohit K. Gupta (mogupta@microsoft.com)
# Last Updated: August 5, 2017
#      Version: 1.0

# This script uses V3 ChangeServiceAccountPassword_v3.ps1 solution to change password accross multiple computers
# with different service accounts and different passwords.

# Requires: SQLPS Module


# Location where the SvcAcctMgmt database is located with the 
param
(
    [Parameter(Mandatory=$true)][String] $SvcAcctMgmtSQLInstance,    
    [Parameter(Mandatory=$true)] [String] $Passkey,
    [Parameter(Mandatory=$false)] [String] $SvcAcctMgmtDBName = 'SvcAcctMgmt',
    [Parameter(Mandatory=$false)] [String] $ComputerName,
    [Parameter(Mandatory=$false)] [String] $ServiceAccountName,
    [Parameter(Mandatory=$false)] [Switch] $WhatIf
)

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

$TSQLQuery = "EXEC dbo.GetComputerInstance @Passphrase = N'$Passkey'"

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
    if (($SvcAcct.ServiceAccountNewPassword -eq [DBNull]::Value) -OR ($SvcAcct.ServiceAccountOldPassword -eq [DBNull]::Value))
    {
        throw "Passkey not valid for $($SvcAcct.ComputerName) computer and $($SvcAcct.ServiceAccountName) service account."
        return 
    }
    else
    {
        .\ChangeServiceAccountPassword_v3.ps1 -ComputerName $SvcAcct.ComputerName `
                                                -ServiceAccountName $SvcAcct.ServiceAccountName `
                                                -ServiceAccountOldPassword $SvcAcct.ServiceAccountOldPassword `
                                                -ServiceAccountNewPassword $SvcAcct.ServiceAccountNewPassword `
                                                -WhatIf:$WhatIf
    }    
}