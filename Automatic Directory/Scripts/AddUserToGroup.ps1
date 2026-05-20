<#
| Name            | [AddUserToGroup.ps1](./Scripts/AddUserToGroup.ps1)                                                                              |
| --------------- | ----------------------------------------------------------------------------------------------- |
| **Description** | Add a user to the desired group. The script should block if<br>you want to add an unknown user. |
| **Parameter**   | - User name<br>- Group name                                                                     |

#>


New-ADUser -Name "Alice Manager" -SamAccountName "admin.user" -UserPrincipalName "admin.user@domolia.local" `
  -Path "OU=Administration,DC=domolia,DC=local" -AccountPassword (Read-Host -AsSecureString "Password") `
  -Enabled $true -ChangePasswordAtLogon $false
Add-ADGroupMember -Identity "GG_Admin_RW" -Members "admin.user"
Add-ADGroupMember -Identity "GG_Generic_RW" -Members "admin.user"