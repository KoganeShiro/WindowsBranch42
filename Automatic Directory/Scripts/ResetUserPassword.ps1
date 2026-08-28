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
	[switch]$Interactive

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[RESET USER PASSWORD] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Reset user password' -Action {
		# Prompt for a secure password and confirm before resetting.
	$result = Invoke-ActionSafely -ActionName 'Reset user password' -Action {
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
	}

	if (-not $result.Success) {
		if ($Interactive) {
			$resp = Confirm-YesNo -Message "Action failed: $($result.Exception.Message)`nDo you want to continue?" -Title 'Action failed'
			if (-not $resp) { Throw-WithLog "Action failed: $($result.Exception.Message)" }
		} else {
			Throw-WithLog "Action failed: $($result.Exception.Message)"
		}
	}

	$validation = Validate-Environment -RequiredModules $requiredModules
	$problems = @();
	foreach ($m in $requiredModules) { 
		$info = $validation.Modules[$m]; 
		if (-not $info.Available) { 
			$problems += "Module not available: $m"
		} elseif (-not $info.Loaded) {
			$problems += "Module available but not loaded: $m"
		}
	}
	if ($problems.Count -gt 0) { $msg = "Environment validation failed:`n" + ($problems -join "`n"); Write-Log -Message $msg -Level 'ERROR'; if ($Interactive) { [System.Windows.Forms.MessageBox]::Show($msg, 'Validation failed', 'OK', 'Error') }; Throw-WithLog $msg }
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification: Get-ADUser -Identity $AccountName -Properties PasswordLastSet | Select-Object Name, PasswordLastSet
