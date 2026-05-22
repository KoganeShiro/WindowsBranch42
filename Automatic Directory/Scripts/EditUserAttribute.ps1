<#
| Name            | [EditUserAttribute.ps1](./Scripts/EditUserAttribute.ps1)                                     |
| --------------- | --------------------------------------------------------- |
| **Description** | Modify an attribute of the user and set it to a new value |
| **Parameter**   | - Account name- Attribute name<br>- Desired value     |
                    - Attribute name
                    - Desired value     |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser?view=windowsserver2025-ps
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$AccountName,

	[Parameter(Mandatory = $true)]
	[string]$AttributeName,

	[Parameter(Mandatory = $true)]
	[string]$NewValue
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[EDIT USER ATTRIBUTE] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Edit user attribute' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue)) {
			throw "User '$AccountName' does not exist."
		}

		Set-ADUser -Identity $AccountName -Replace @{ $AttributeName = $NewValue } -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}