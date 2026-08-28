<#
| Name            | [LoadDataBase.ps1](./Scripts/LoadDataBase.ps1)  |
| --------------- | ----------------------------------------------- |
| **Description** | Load a data base from a saving file             |
| **Parameter**   | - Path to .CSV file to load
                    - File delimiter |
                    
# https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.utility/import-csv?view=powershell-7.6

```powershell
Z:\Scripts\LoadDataBase.ps1 -InputPath "Z:\Database\AD_Database.csv" -Delimiter ';'
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$InputPath,

	[Parameter(Mandatory = $true)]
	[string]$Delimiter = ';'
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[LOAD DATABASE] Running as $env:USERNAME on $env:COMPUTERNAME"

	# Validate delimiter: allow a single character or the special token '\t' for tab.
	if ($Interactive) {
		while ($true) {
			$inputDel = Read-TextInput -Prompt "Enter the CSV delimiter (single character). Use \\t for TAB." -DefaultValue $Delimiter
			if ([string]::IsNullOrWhiteSpace($inputDel)) { Throw-WithLog 'Delimiter selection cancelled by user.' }
			if ($inputDel -eq '\t') { $Delimiter = "`t"; break }
			if ($inputDel.Length -eq 1) { $Delimiter = $inputDel; break }
			[System.Windows.Forms.MessageBox]::Show('Delimiter must be a single character or the special token "\\t" for TAB.', 'Invalid delimiter', 'OK', 'Warning')
			$tryAgain = Confirm-YesNo -Message 'Delimiter invalid. Do you want to try again?' -Title 'Invalid delimiter'
			if (-not $tryAgain) { Throw-WithLog 'User aborted delimiter selection.' }
		}
	} else {
		if ($Delimiter -eq '\t') { $Delimiter = "`t" }
		if ($Delimiter.Length -ne 1) { Throw-WithLog "Invalid delimiter provided in non-interactive mode: '$Delimiter' (must be a single character or '\\t')" }
	}

	$result = Invoke-ActionSafely -ActionName 'Load database from CSV' -Action {
		if (-not (Test-Path -Path $InputPath)) {
			throw "Input file '$InputPath' does not exist."
		}

		Import-Csv -Path $InputPath -Delimiter $Delimiter -ErrorAction Stop
        Write-Log -Message "Database loaded from '$InputPath' with delimiter '$Delimiter'."
	}

	if (-not $result.Success) {
		if ($Interactive) {
			$resp = Confirm-YesNo -Message "Action failed: $($result.Exception.Message)`nDo you want to continue?" -Title 'Action failed'
			if (-not $resp) { Throw-WithLog "Action failed: $($result.Exception.Message)" }
		} else {
			Throw-WithLog "Action failed: $($result.Exception.Message)"
		}
	}

	$validation = Validate-Environment -RequiredModules @()
	# No required modules for simple CSV import; still keeping consistent pattern
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Import-Csv -Path $InputPath -Delimiter $Delimiter | Select-Object -First 1