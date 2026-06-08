<#
| Name            | [ListUserInGroup.ps1](./Scripts/ListUserInGroup.ps1)                             |
| --------------- | ----------------------------------------------- |
| **Description** | Retreive an exaustive list of user in the group |
| **Parameter**   | - Group name                                    |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adgroupmember?view=windowsserver2025-ps
https://www.it-connect.fr/active-directory-powershell-recuperer-la-liste-des-utilisateurs-de-plusieurs-ou/

Execute this script to list users in a group:
```powershell
Z:\Scripts\ListUserInGroup.ps1 -GroupName "testGroup"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$GroupName
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[LIST USER IN GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'List users in group' -Action {
		# Filter to user objects only.
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
			throw "Group '$GroupName' does not exist."
		}

		Get-ADGroupMember -Identity $GroupName -Recursive -ErrorAction Stop |
			Where-Object { $_.ObjectClass -eq 'user' }
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADGroupMember -Identity $GroupName -Recursive | Where-Object { $_.ObjectClass -eq 'user' }