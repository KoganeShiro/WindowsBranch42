<#
| Name            | [ResetUserPassword.ps1](./Scripts/ResetUserPassword.ps1)                  |
| --------------- | -------------------------------------- |
| **Description** | Reset the password of the desired user |
| **Parameter**   | - Account name                         |

https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-adaccountpassword?view=windowsserver2025-ps
https://www.it-connect.fr/modifier-le-mot-de-passe-dun-compte-local-avec-powershell/

For service accounts, use Reset-ADServiceAccountPassword instead:
https://learn.microsoft.com/en-us/powershell/module/activedirectory/reset-adserviceaccountpassword?view=windowsserver2025-ps

Execute this script to reset a user password:
```powershell
Z:\Scripts\ResetUserPassword.ps1 -AccountName "testUser"
```
#>
param (
	[Parameter(Mandatory = $true)]
	[string]$AccountName
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[RESET USER PASSWORD] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Reset user password' -Action {
		# Prompt for a secure password and confirm before resetting.
		Import-RequiredModules -Modules $requiredModules

		if (-not (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue)) {
			throw "User '$AccountName' does not exist."
		}

		function ConvertTo-PlainText {
			param ([Parameter(Mandatory = $true)][securestring]$SecureValue)
			$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
			try {
				[Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
			} finally {
				[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
			}
		}

			$firstPassword = Read-SecureInput -Prompt 'Enter the new password'
			$secondPassword = Read-SecureInput -Prompt 'Confirm the new password'
		if ((ConvertTo-PlainText -SecureValue $firstPassword) -ne (ConvertTo-PlainText -SecureValue $secondPassword)) {
			throw 'Password confirmation does not match.'
		}

		Set-ADAccountPassword -Identity $AccountName -NewPassword $firstPassword -Reset -ErrorAction Stop
		Set-ADUser -Identity $AccountName -ChangePasswordAtLogon $true -ErrorAction Stop
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADUser -Identity $AccountName -Properties PasswordLastSet | Select-Object Name, PasswordLastSet
