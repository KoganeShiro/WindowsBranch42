<#
| Name            | [ReadEveryGroupInformation.ps1](./Scripts/ReadEveryGroupInformation.ps1)                                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Description** | Retreive information(s) from every group in the domain.<br>If no property name are given, the script must retreive all<br>properties |
| **Parameter**   | - Optionnal : a property name   
#>
param (
	[Parameter(Mandatory = $false)]
	[string[]]$Attributes
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ EVERY GROUP INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Read all group information' -Action {
		# Load optional properties for all groups, defaulting to all properties.
		Import-RequiredModules -Modules $requiredModules

		$props = $Attributes
		if (-not $props -or $props.Count -eq 0) {
			$props = @('*')
		}

		Get-ADGroup -Filter * -Properties $props -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}