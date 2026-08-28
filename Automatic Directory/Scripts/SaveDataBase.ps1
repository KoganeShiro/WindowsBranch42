<#
| Name            | [SaveDataBase.ps1](./Scripts/SaveDataBase.ps1)                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Create a data base to store every user and group from the Domain Controller                                            |
| **Parameter**   | - Path to save the result .CSV file
                    - Desired delimiter
                    - An undefined amount of parameter to compose the data base |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser?view=windowsserver2025-ps
https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adgroup?view=windowsserver2025-ps
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-csv?view=powershell-7.6

```powershell
Z:\Scripts\SaveDataBase.ps1 -OutputPath "Z:\Database\AD_Database.csv" -Delimiter ';' -Attributes 'Name'
```
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $true)]
    [string]$Delimiter = ';',

    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Attributes
,

	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

try {
    Assert-Admin -Skip:$SkipAdminCheck
    Write-Log -Message " [ CREATE DATABASE ] Running as $env:USERNAME on $env:COMPUTERNAME"
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

    $result = Invoke-ActionSafely -ActionName 'Create Database' -Action {
        Import-RequiredModules -Modules @('ActiveDirectory')

        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        $users = Get-ADUser -Filter * -Properties $Attributes -ErrorAction Stop
        $groups = Get-ADGroup -Filter * -Properties $Attributes -ErrorAction Stop

        # Initialize an empty array to collect user/group records.
        $dataBase = @()
        foreach ($user in $users) {
            $entry = @{
                Type = 'User'
            }
            foreach ($attr in $Attributes) {
                $entry[$attr] = $user.$attr
            }
            $dataBase += New-Object PSObject -Property $entry
        }

        foreach ($group in $groups) {
            $entry = @{
                Type = 'Group'
            }
            foreach ($attr in $Attributes) {
                $entry[$attr] = $group.$attr
            }
            $dataBase += New-Object PSObject -Property $entry
        }

        $dataBase | Export-Csv -Path $OutputPath -Delimiter $Delimiter -NoTypeInformation -ErrorAction Stop
        Write-Log -Message "Database created at '$OutputPath' with delimiter '$Delimiter'."
    }

    if (-not $result.Success) {
        if ($Interactive) {
            $resp = Confirm-YesNo -Message "Action failed: $($result.Exception.Message)`nDo you want to continue?" -Title 'Action failed'
            if (-not $resp) { Throw-WithLog "Action failed: $($result.Exception.Message)" }
        } else {
            Throw-WithLog "Action failed: $($result.Exception.Message)"
        }
    }

    $validation = Validate-Environment -RequiredModules @('ActiveDirectory')
    $problems = @()
    foreach ($m in @('ActiveDirectory')) {
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

# Verification: Import-Csv -Path $OutputPath -Delimiter $Delimiter | Select-Object -First 1