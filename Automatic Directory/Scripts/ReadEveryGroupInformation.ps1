<#
| Name            | [ReadEveryGroupInformation.ps1](./Scripts/ReadEveryGroupInformation.ps1)                                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Description** | Retreive information(s) from every group in the domain.<br>If no property name are given, the script must retreive all<br>properties |
| **Parameter**   | - Optionnal : a property name   
Execute this script to read every group information:
```powershell
Z:\Scripts\ReadEveryGroupInformation.ps1 -Attributes "Name","Description","GroupScope"
```
#>
param (
	[Parameter(Mandatory = $false)]
	[string[]]$Attributes
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ EVERY GROUP INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Read all group information' -Action {
		# Load optional properties for all groups, defaulting to all properties.
		Import-RequiredModules -Modules $requiredModules

		$props = $Attributes
		if (-not $props -or $props.Count -eq 0) {
			$props = @('*')
		}

		Get-ADGroup -Filter * -Properties $props -ErrorAction Stop
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

# Verification: Get-ADGroup -Filter * -Properties $Attributes | Select-Object -First 1