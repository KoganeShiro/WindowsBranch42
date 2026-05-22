<#
| Name            | [ReadDataBaseInformation.ps1](./Scripts/ReadDataBaseInformation.ps1)                          |
| --------------- | ---------------------------------------------------- |
| **Description** | Retreive every users informations from the server    |
| **Parameter**   | - Filter the attribute to retreive |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser?view=windowsserver2025-ps
#>
param (
	[Parameter(Mandatory = $false)]
	[string[]]$Attributes
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ DATABASE INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Read user information' -Action {
		# Return every user record with the requested properties.
		Import-RequiredModules -Modules $requiredModules

		$props = $Attributes
		if (-not $props -or $props.Count -eq 0) {
			$props = @('*')
		}

		Get-ADUser -Filter * -Properties $props -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}