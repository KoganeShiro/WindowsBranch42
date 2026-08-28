<#
| Name            | [UserCreation.ps1](./Scripts/UserCreation.ps1)                                                                                                                                                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | In hashtable or in specification. We assume that
                    - mail address : name.surname@domaineName.com
                    - Basic password : fixed by the subject and obfuscated in this script
                    - UserPrincipalName : email address
                    The default password must not be written in clear text in the script |
| **Parameter**   | - Account name
                    - Organisation Unit to join (Where it will be stored in the AD)
                    - Desired group                                                                                                                                                                                    

https://www.it-connect.fr/chapitres/recuperer-des-informations-sur-les-utilisateurs-avec-powershell/
https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser?view=windowsserver2025-ps
https://learn.microsoft.com/en-us/powershell/module/activedirectory/add-adgroupmember?view=windowsserver2025-ps

Execute this script to create a user and optionally add it to a group:
```powershell
Z:\Scripts\UserCreation.ps1 -AccountName "testUser" -OrganizationalUnit "OU=Users,DC=domolia,DC=local" -GroupName "testGroup"
```
#>



param (
	[Parameter(Mandatory = $true)]
	[string]$AccountName,

	[Parameter(Mandatory = $true)]
	[string]$OrganizationalUnit,

	[Parameter(Mandatory = $true)]
	[string]$GroupName

	[Parameter()]
	[switch]$Interactive
)

. $PSScriptRoot\..\template.ps1

	# Optional interactive mode: show GUI confirmations/prompts when provided

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[USER CREATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	$result = Invoke-ActionSafely -ActionName 'Create user and assign group' -Action {
		Import-RequiredModules -Modules $requiredModules

		$escapedAccountName = $AccountName.Replace("'", "''")
		if (Get-ADUser -Filter "SamAccountName -eq '$escapedAccountName'" -ErrorAction SilentlyContinue) {
			throw "User '$AccountName' already exists."
		}

		function Get-DefaultPassword {
			param ([Parameter(Mandatory = $true)][string]$CipherText)
			$key = 0x5A
			$bytes = [Convert]::FromBase64String($CipherText)
			for ($i = 0; $i -lt $bytes.Length; $i++) {
				$bytes[$i] = $bytes[$i] -bxor $key
			}
			return [Text.Encoding]::UTF8.GetString($bytes)
		}

			$domain = (Get-ADDomain -ErrorAction Stop).DNSRoot
			$useDefault = Read-TextInput -Prompt 'Use the default temporary password? Enter Y or N.' -DefaultValue 'Y'
			# XOR-obfuscated form of the assignment's temporary password.
			$defaultCipher = 'DjUuOzYjFGouCT85Lyg/'

		if ($useDefault -match '^(Y|y)$') {
			$defaultPlain = Get-DefaultPassword -CipherText $defaultCipher
			$securePassword = ConvertTo-SecureString -String $defaultPlain -AsPlainText -Force
		} else {
				$securePassword = Read-SecureInput -Prompt 'Enter the temporary password'
		}

			$givenName = Read-TextInput -Prompt 'Enter the user given name.' -DefaultValue $AccountName
			$surname = Read-TextInput -Prompt 'Enter the user surname.'
			if ([string]::IsNullOrWhiteSpace($givenName) -or [string]::IsNullOrWhiteSpace($surname)) {
				throw 'Given name and surname are required to construct the mail address.'
			}
			$upn = "$AccountName@$domain"
			$mail = ('{0}.{1}@{2}' -f $givenName, $surname, $domain).ToLowerInvariant()

		# Verify that the target OU/container exists
		$ouExists = $null
		try {
			$ouExists = Get-ADObject -SearchBase $OrganizationalUnit -SearchScope Base -ErrorAction Stop
		} catch {
			$ouExists = $null
		}

		if (-not $ouExists) {
			throw "OrganizationalUnit '$OrganizationalUnit' does not exist. Pass an existing distinguished name."
		}
		if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
			throw "Group '$GroupName' does not exist."
		}

		New-ADUser `
				-Name $AccountName `
				-GivenName $givenName `
				-Surname $surname `
				-DisplayName "$givenName $surname" `
			-SamAccountName $AccountName `
			-UserPrincipalName $upn `
			-Path $OrganizationalUnit `
			-AccountPassword $securePassword `
			-Enabled $true `
			-ChangePasswordAtLogon $true `
			-OtherAttributes @{ mail = $mail } `
			-ErrorAction Stop

		Add-ADGroupMember -Identity $GroupName -Members $AccountName -ErrorAction Stop
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
	$problems = @()
	foreach ($m in $requiredModules) {
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

# Get-ADUser -Filter * -SearchBase "DC=domolia,DC=local"

# Verification: Get-ADUser -Identity $AccountName -Properties mail,UserPrincipalName
