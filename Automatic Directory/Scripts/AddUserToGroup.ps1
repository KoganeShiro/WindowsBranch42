<#
| Name            | [AddUserToGroup.ps1](./Scripts/AddUserToGroup.ps1)                                                                              |
| --------------- | ----------------------------------------------------------------------------------------------- |
| **Description** | Add a user to the desired group. The script should block if you want to add an unknown user. |
| **Parameter**   | - User name
                    - Group name                                                                     |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/add-adgroupmember?view=windowsserver2025-ps

Execute this script to add a user to a group:
```powershell
Z:\Scripts\AddUserToGroup.ps1 -UserName "testUser" -GroupName "testGroup"
```
#>

param (
  [Parameter(Mandatory = $true)]
  [string]$UserName,

  [Parameter(Mandatory = $true)]
  [string]$GroupName
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
  Assert-Admin -Skip:$SkipAdminCheck
  Write-Log -Message "[ADD USER TO GROUP] Running as $env:USERNAME on $env:COMPUTERNAME"

  Invoke-ScriptAction -ActionName 'Add user to group' -Action {
    Import-RequiredModules -Modules $requiredModules

    if (-not (Get-ADUser -Identity $UserName -ErrorAction SilentlyContinue)) {
      throw "User '$UserName' does not exist."
      return
    }
    if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
      throw "Group '$GroupName' does not exist."
      return
    }
    $alreadyMember = Get-ADGroupMember -Identity $GroupName -Recursive -ErrorAction SilentlyContinue |
      Where-Object { $_.SamAccountName -eq $UserName }
    if ($alreadyMember) {
      Write-Log -Message "User '$UserName' is already a member of '$GroupName'."
      return
    }

    Add-ADGroupMember -Identity $GroupName -Members $UserName -ErrorAction Stop
  }
}
catch {
  Write-Log -Message $_.Exception.Message -Level 'ERROR'
  throw
}

# Verification: Get-ADGroupMember -Identity $GroupName -Recursive | Where-Object { $_.SamAccountName -eq $UserName }