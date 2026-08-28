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

	[Parameter(Mandatory = $true)]
	[string[]]$Attributes
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[READ USER INFORMATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Read user information' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue)) {
			throw "User '$AccountName' does not exist."
		}

		$props = $Attributes
		if (-not $props -or $props.Count -eq 0) { $props = @('*') }
		Get-ADUser -Identity $AccountName -Properties $props -ErrorAction Stop
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

# Get-ADUser -Identity $AccountName -Properties $Attributes
