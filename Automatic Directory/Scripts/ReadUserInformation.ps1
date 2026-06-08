<#
| Name            | [ReadUserInformation.ps1](./Scripts/ReadUserInformation.ps1)                              |
| --------------- | ---------------------------------------------------- |
| **Description** | Retreive user information from the server            |
| **Parameter**   | - Account name
                    - Filter the attribute to retreive |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser?view=windowsserver2025-ps

Execute this script to read one user's information:
```powershell
Z:\Scripts\ReadUserInformation.ps1 -AccountName "testUser" -Attributes "Name","SamAccountName","Mail"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$AccountName,

	[Parameter(Mandatory = $false)]
	[string[]]$Attributes
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ USER INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Read user information' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue)) {
			throw "User '$AccountName' does not exist."
		}

		Get-ADUser -Identity $AccountName -Properties $Attributes -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADUser -Identity $AccountName -Properties $Attributes