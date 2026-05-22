<#
| Name            | [CreateDataBase.ps1](./Scripts/CreateDataBase.ps1)                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Create a data base to store every user and group from the Domain Controller                                            |
| **Parameter**   | - Path to save the result .CSV file
                    - Desired delimiter
                    - An undefined amount of parameter to compose the data base |
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