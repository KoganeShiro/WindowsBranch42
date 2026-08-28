<#
| Name            | [ReadGroupInformation.ps1](./Scripts/ReadGroupInformation.ps1)                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Description** | Retreive information(s) about a group.<br>If no property name are given, the script must retreive all<br>properties |
| **Parameter**   | - Group name
					- Optionnal : a property name   

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
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ GROUP INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Read group information' -Action {
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

	if (-not $result.Success) {
		if ($Interactive) {
			$resp = Confirm-YesNo -Message "Action failed: $($result.Exception.Message)`nDo you want to continue?" -Title 'Action failed'
			if (-not $resp) { Throw-WithLog "Action failed: $($result.Exception.Message)" }
		} else {
			Throw-WithLog "Action failed: $($result.Exception.Message)"
		}
	}

	$validation = Validate-Environment -RequiredModules $requiredModules
	$problems = @()
	foreach ($m in $requiredModules) {
		$info = $validation.Modules[$m]
		if (-not $info.Available) { $problems += "Module not available: $m" }
		elseif (-not $info.Loaded) { $problems += "Module available but not loaded: $m" }
	}
	if ($problems.Count -gt 0) {
		$msg = "Environment validation failed:`n" + ($problems -join "`n")
		Write-Log -Message $msg -Level 'ERROR'
		if ($Interactive) { [System.Windows.Forms.MessageBox]::Show($msg, 'Validation failed', 'OK', 'Error') }
		Throw-WithLog $msg
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADGroup -Identity $GroupName -Properties $Attributes