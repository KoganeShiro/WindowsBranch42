<#
| Name            | [LoadDataBase.ps1](./Scripts/LoadDataBase.ps1)  |
| --------------- | ----------------------------------------------- |
| **Description** | Load a data base from a saving file             |
| **Parameter**   | - Path to .CSV file to load
                    - File delimiter |
                    
# https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.utility/import-csv?view=powershell-7.6
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$InputPath,

	[Parameter(Mandatory = $false)]
	[string]$Delimiter = ';'
)

. $PSScriptRoot\..\template.ps1

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[LOAD DATABASE] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Load database from CSV' -Action {
		if (-not (Test-Path -Path $InputPath)) {
			throw "Input file '$InputPath' does not exist."
		}

		Import-Csv -Path $InputPath -Delimiter $Delimiter -ErrorAction Stop
        Write-Log -Message "Database loaded from '$InputPath' with delimiter '$Delimiter'."
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}