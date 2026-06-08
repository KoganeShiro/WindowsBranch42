<#
| Name            | [CreateGroup.ps1](./Scripts/CreateGroup.ps1)                                                       |
| --------------- | --------------------------------------------------------------------- |
| **Description** | Create a new group                                                    |
| **Parameter**   | - Group name
                    - Organisation unit
                    - Group scope
                    - Description |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-adgroup?view=windowsserver2025-ps

```powershell
Z:\Scripts\CreateGroup.ps1 -GroupName Test -OrganizationalUnit "" -GroupScope Global -Description "A test group"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$GroupName,

	[Parameter(Mandatory = $true)]
	[string]$OrganizationalUnit,

	[Parameter(Mandatory = $true)]
	[string]$GroupScope,

	[Parameter(Mandatory = $false)]
	[string]$Description
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[CREATE GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Create group' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue) {
			throw "Group '$GroupName' already exists."
		}

		New-ADGroup -Name $GroupName -Path $OrganizationalUnit -GroupScope $GroupScope -Description $Description -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADGroup -Identity $GroupName -Properties *