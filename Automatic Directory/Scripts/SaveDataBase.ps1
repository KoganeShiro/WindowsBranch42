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

    [Parameter(Mandatory = $false)]
    [string]$Delimiter = ';',

    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Attributes
)

. $PSScriptRoot\..\template.ps1

try {
    Assert-Admin -Skip:$SkipAdminCheck
    Write-Log -Message " [ CREATE DATABASE ] Running as $env:USERNAME on $env:COMPUTERNAME"
    Invoke-ScriptAction -ActionName 'Create Database' -Action {
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
}
catch {
    Write-Log -Message $_.Exception.Message -Level 'ERROR'
    throw
}

# Verification: Import-Csv -Path $OutputPath -Delimiter $Delimiter | Select-Object -First 1