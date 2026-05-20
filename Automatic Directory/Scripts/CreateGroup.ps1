<#
| Name            | [CreateGroup.ps1](./Scripts/CreateGroup.ps1)                                                       |
| --------------- | --------------------------------------------------------------------- |
| **Description** | Create a new group                                                    |
| **Parameter**   | - Group name<br>- Organisation unit<br>- Group scope<br>- Description |
#>


New-ADGroup -Name "GG_Admin_RW" -GroupScope Global -Path "OU=Groups,DC=domolia,DC=local"

New-ADGroup -Name "GG_Generic_RW" -GroupScope Global -Path "OU=Groups,DC=domolia,DC=local"

New-ADGroup -Name "GG_Projects_RW" -GroupScope Global -Path "OU=Groups,DC=domolia,DC=local"