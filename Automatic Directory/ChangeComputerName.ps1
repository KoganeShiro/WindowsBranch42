

<#
| Name            | [ChangeComputerName.ps1](./ChangeComputerName.ps1)                              |
| --------------- | ------------------------------------------------------------------------------- |
| **Description** | Change the computer name to match the domain controller naming convention       |
| **Parameter**   | -ChangeComputerName                                                             |

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/rename-computer?view=powershell-7.6

Execute this script on both servers to change their computer name to match the domain controller naming convention:
```powershell
Z:\ChangeComputerName.ps1 -ChangeComputerName "DC1-ADMIN"
Z:\ChangeComputerName.ps1 -ChangeComputerName "DC2-WORKSHOP"
```
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$ChangeComputerName,
    
    [switch]$SkipAdminCheck
)

# Dot source the template for common functions and variables
. $PSScriptRoot\template.ps1

try {
    Assert-Admin -Skip:$SkipAdminCheck
    Write-Log -Message " [Change Computer Name] Running as $env:USERNAME on $env:COMPUTERNAME"

    Invoke-ScriptAction -ActionName 'Change Computer Name' -Action {
        Rename-Computer -NewName $ChangeComputerName -Force -Restart
        Write-Log -Message "Computer renaming requested to $ChangeComputerName. Restarting..."
    }
}
catch {
    Write-Log -Message $_.Exception.Message -Level 'ERROR'
    throw
}
    
# Type `hostname` or `$env:COMPUTERNAME` to check if the name of the computer did change correctly