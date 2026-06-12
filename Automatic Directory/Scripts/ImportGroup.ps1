<#
| Name            | [ImportGroup.ps1](./Scripts/ImportGroup.ps1)                                    |
| --------------- | -------------------------------------------------- |
| **Description** | Import the content of a group inside another group |
| **Parameter**   | - Origin group name<br>- Destination group name    |

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
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[IMPORT GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Import group members' -Action {
		# Copy missing members from source to destination without duplicating entries.
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADGroup -Identity $SourceGroupName -ErrorAction SilentlyContinue)) {
			throw "Source group '$SourceGroupName' does not exist."
		}
		if (-not (Get-ADGroup -Identity $DestinationGroupName -ErrorAction SilentlyContinue)) {
			throw "Destination group '$DestinationGroupName' does not exist."
		}

		$sourceMembers = Get-ADGroupMember -Identity $SourceGroupName -Recursive -ErrorAction Stop |
			Select-Object -ExpandProperty DistinguishedName
		$destinationMembers = Get-ADGroupMember -Identity $DestinationGroupName -Recursive -ErrorAction Stop |
			Select-Object -ExpandProperty DistinguishedName

		$membersToAdd = $sourceMembers | Where-Object { $_ -notin $destinationMembers }
		if (-not $membersToAdd) {
			Write-Log -Message "No new members to add from '$SourceGroupName' to '$DestinationGroupName'."
			return
		}

		Add-ADGroupMember -Identity $DestinationGroupName -Members $membersToAdd -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADGroupMember -Identity $DestinationGroupName -Recursive | Select-Object SamAccountName