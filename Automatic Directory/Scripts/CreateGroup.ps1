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

	[Parameter(Mandatory = $true)]
	[string]$Description
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[CREATE GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Create group' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue) {
			throw "Group '$GroupName' already exists."
		}

		New-ADGroup -Name $GroupName -Path $OrganizationalUnit -GroupScope $GroupScope -Description $Description -ErrorAction Stop
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

# Verification: Get-ADGroup -Identity $GroupName -Properties *