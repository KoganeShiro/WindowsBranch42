<#
| Name            | [ImportGroup.ps1](./Scripts/ImportGroup.ps1)                                    |
| --------------- | -------------------------------------------------- |
| **Description** | Import the content of a group inside another group |
| **Parameter**   | - Origin group name
					- Destination group name    |

Execute this script to import members from one group into another:
```powershell
Z:\Scripts\ImportGroup.ps1 -SourceGroupName "GroupA" -DestinationGroupName "GroupB"
```


#>
param (
	[Parameter(Mandatory = $true)]
	[string]$SourceGroupName,

	[Parameter(Mandatory = $true)]
	[string]$DestinationGroupName
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[IMPORT GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Import group members' -Action {
		# Copy missing members from source to destination without duplicating entries.
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADGroup -Identity $SourceGroupName -ErrorAction SilentlyContinue)) {
			throw "Source group '$SourceGroupName' does not exist."
		}
		if (-not (Get-ADGroup -Identity $DestinationGroupName -ErrorAction SilentlyContinue)) {
			throw "Destination group '$DestinationGroupName' does not exist."
		}

		if ($SourceGroupName -eq $DestinationGroupName) {
			throw 'The source and destination groups must be different.'
		}

		# Preserve nested-group structure by copying direct members, not a flattened recursive list.
		$sourceMembers = Get-ADGroupMember -Identity $SourceGroupName -ErrorAction Stop |
			Select-Object -ExpandProperty DistinguishedName
		$destinationMembers = Get-ADGroupMember -Identity $DestinationGroupName -ErrorAction Stop |
			Select-Object -ExpandProperty DistinguishedName

		$membersToAdd = $sourceMembers | Where-Object { $_ -notin $destinationMembers }
		if (-not $membersToAdd) {
			Write-Log -Message "No new members to add from '$SourceGroupName' to '$DestinationGroupName'."
			return
		}

		Add-ADGroupMember -Identity $DestinationGroupName -Members $membersToAdd -ErrorAction Stop
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

# Verification: Get-ADGroupMember -Identity $DestinationGroupName -Recursive | Select-Object SamAccountName
