Function Test-SqlPath
{
<#
.SYNOPSIS
Tests if file or directory exists from the perspective of the SQL Server service account

.DESCRIPTION
Uses master.dbo.xp_fileexist to determine if a file or directory exists

.PARAMETER SqlServer
The SQL Server you want to run the test on.

.PARAMETER Path
The Path to tests. Can be a file or directory.

.PARAMETER SqlCredential
Allows you to login to servers using SQL Logins as opposed to Windows Auth/Integrated/Trusted. To use:

$scred = Get-Credential, then pass $scred object to the -SqlCredential parameter.

Windows Authentication will be used if SqlCredential is not specified. SQL Server does not accept Windows
credentials being passed as credentials. To connect as a different Windows user, run PowerShell as that user.


.NOTES
Author: Chrissy LeMaire (@cl), netnerds.net
Requires: Admin access to server (not SQL Services),
Remoting must be enabled and accessible if $sqlserver is not local

dbatools PowerShell module (https://dbatools.io, clemaire@gmail.com)
Copyright (C) 2016 Chrissy LeMaire

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

.LINK
https://dbatools.io/Test-SqlPath

.EXAMPLE
Test-SqlPath -SqlServer sqlcluster -Path L:\MSAS12.MSSQLSERVER\OLAP

Tests whether the service account running the "sqlcluster" SQL Server isntance can access L:\MSAS12.MSSQLSERVER\OLAP. Logs into sqlcluster using Windows credentials. 

.EXAMPLE
$credential = Get-Credential
Test-SqlPath -SqlServer sqlcluster -SqlCredential $credential -Path L:\MSAS12.MSSQLSERVER\OLAP

Tests whether the service account running the "sqlcluster" SQL Server isntance can access L:\MSAS12.MSSQLSERVER\OLAP. Logs into sqlcluster using SQL authentication. 
#>
	[CmdletBinding()]
    [OutputType([bool])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("ServerInstance", "SqlInstance")]
		[object]$SqlServer,
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[System.Management.Automation.PSCredential]$SqlCredential
	)

	$sql = Get-FileExistQuery -Path $Path
	$result = Execute-WithResult -SqlServer $SqlServer -SqlCredential $SqlCredential -Command $sql | ConvertTo-SqlFileExists

	Test-SqlFileExist $result
}

function Execute-WithResult ($SqlServer, $SqlCredential, $Command) {
    $connection = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential
	$connection.ConnectionContext.ExecuteWithResults($Command)
}

function Get-FirstTable ($SqlResult) { 
	$SqlResult.Tables
}

function New-PSObject ([hashtable]$Property) {
    New-Object -TypeName PSObject -Property $Property
}

function New-FileExistsObject ([bool]$FileExists, [bool]$DirectoryExists) {
    New-PSObject @{
        FileExists = $FileExists
        DirectoryExists = $DirectoryExists
    }
}

function ConvertTo-SqlFileExists {
    param (		
        [Parameter(ValueFromPipeline=$true)]
        $SqlResult 
    )
    process 
    {
        $firstTable = $SqlResult.Tables[0]
	    $firstRow = $firstTable.Rows[0]

        $fileExists = $firstRow[0]
        $directoryExists = $firstRow[1]

        return New-FileExistsObject -FileExists:$fileExists -DirectoryExists:$directoryExists
    }
}

function Test-SqlFileExist ($Result) {	
    $result.FileExists -or $result.DirectoryExists
}

function Get-FileExistQuery  {
        param
        (
        [Parameter(Mandatory=$true)]
        [String]
        $Path
        )

    "EXEC master.dbo.xp_fileexist '$Path'"
}
