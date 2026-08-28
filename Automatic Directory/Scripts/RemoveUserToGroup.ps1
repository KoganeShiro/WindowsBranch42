<#
| Name            | [RemoveUserToGroup.ps1](./Scripts/RemoveUserToGroup.ps1)                                                                                                                           |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Remove a user from the desired group. The script should block the deletion of an unknown user or a user who is not part of<br>the group. |
| **Parameter**   | - User name
                    - Group name  

https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-adgroupmember?view=windowsserver2025-ps

Execute this script to remove a user from a group:
```powershell
Z:\Scripts\RemoveUserToGroup.ps1 -UserName "testUser" -GroupName "testGroup"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$UserName,

	[Parameter(Mandatory = $true)]
	[string]$GroupName
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[REMOVE USER FROM GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Remove user from group' -Action {
		Import-RequiredModules -Modules $requiredModules

        if (-not (Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue)) {
            throw "User '$UserName' does not exist."
            return
        }
		if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
			throw "Group '$GroupName' does not exist."
			return
		}
        if (-not (Get-ADGroupMember -Identity $GroupName -ErrorAction SilentlyContinue | Where-Object { $_.SamAccountName -eq $UserName })) {
            throw "User '$UserName' is not a member of group '$GroupName'."
            return
        }
		Remove-ADGroupMember -Identity $GroupName -Members $UserName -Confirm:$false -ErrorAction Stop
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

# Verification: Get-ADGroupMember -Identity $GroupName -Recursive | Where-Object { $_.SamAccountName -eq $UserName }
