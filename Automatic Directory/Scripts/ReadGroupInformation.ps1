<#
| Name            | [ReadGroupInformation.ps1](./Scripts/ReadGroupInformation.ps1)                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Description** | Retreive information(s) about a group.<br>If no property name are given, the script must retreive all<br>properties |
| **Parameter**   | - Group name<br>- Optionnal : a property name   

https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adgroup?view=windowsserver2025-ps

Execute this script to read one group's information:
```powershell
Z:\Scripts\ReadGroupInformation.ps1 -GroupName "testGroup" -Attributes "Name","Description","GroupScope"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$GroupName,

	[Parameter(Mandatory = $false)]
	[string[]]$Attributes
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ GROUP INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Read group information' -Action {
		# Load optional properties for the requested group, defaulting to all properties.
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
			throw "Group '$GroupName' does not exist."
		}

		$props = $Attributes
		if (-not $props -or $props.Count -eq 0) {
			$props = @('*')
		}

		Get-ADGroup -Identity $GroupName -Properties $props -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADGroup -Identity $GroupName -Properties $Attributes