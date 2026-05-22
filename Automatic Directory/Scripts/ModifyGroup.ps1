<#
| Name            | [ModifyGroup.ps1](./Scripts/ModifyGroup.ps1)                                              |
| --------------- | ------------------------------------------------------------ |
| **Description** | Edit a group by modifying one attribute to a desired value   |
| **Parameter**   | - Group name
                    - Attribute to edit
                    - New attribute value |
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$GroupName,

	[Parameter(Mandatory = $true)]
	[string]$AttributeName,

	[Parameter(Mandatory = $true)]
	[string]$NewValue
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[MODIFY GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Modify group attribute' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
			throw "Group '$GroupName' does not exist."
		}

		Set-ADGroup -Identity $GroupName -Replace @{ $AttributeName = $NewValue } -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}