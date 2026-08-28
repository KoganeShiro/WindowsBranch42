<#
| Name            | [EditUserAttribute.ps1](./Scripts/EditUserAttribute.ps1)                                     |
| --------------- | --------------------------------------------------------- |
| **Description** | Modify an attribute of the user and set it to a new value |
| **Parameter**   | - Account name
					- Attribute name
					- Desired value     |


https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser?view=windowsserver2025-ps

Execute this script to update a user attribute:
```powershell
Z:\Scripts\EditUserAttribute.ps1 -AccountName "testUser" -AttributeName "Title" -NewValue "System Administrator"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$AccountName,

	[Parameter(Mandatory = $true)]
	[string]$AttributeName,

	[Parameter(Mandatory = $true)]
	[string]$NewValue
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[EDIT USER ATTRIBUTE] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Edit user attribute' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue)) {
			throw "User '$AccountName' does not exist."
		}

		Set-ADUser -Identity $AccountName -Replace @{ $AttributeName = $NewValue } -ErrorAction Stop
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

# Verification: Get-ADUser -Identity $AccountName -Properties $AttributeName