<#
| Name            | [UserCreation.ps1](./Scripts/UserCreation.ps1)                                                                                                                                                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | In hashtable or in specification. We assume that
                    - mail address : name.surname@domaineName.com
                    - Basic password : DTAuMzAuMzgPNj8oOD8oPw== 
                    - UserPrincipalName : email address
                    The default password must not be written in clear text in the script |
| **Parameter**   | - Account name
                    - Organisation Unit to join
                    - Desired group                                                                                                                                                                                    

https://www.it-connect.fr/chapitres/recuperer-des-informations-sur-les-utilisateurs-avec-powershell/
https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser?view=windowsserver2025-ps
https://learn.microsoft.com/en-us/powershell/module/activedirectory/add-adgroupmember?view=windowsserver2025-ps
#>



param (
	[Parameter(Mandatory = $true)]
	[string]$AccountName,

	[Parameter(Mandatory = $true)]
	[string]$OrganizationalUnit,

	[Parameter(Mandatory = $false)]
	[string]$GroupName
)

. $PSScriptRoot\..\template.ps1

$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[USER CREATION] Running as $env:USERNAME on $env:COMPUTERNAME"

	Invoke-ScriptAction -ActionName 'Create user and assign group' -Action {
		Import-RequiredModules -Modules $requiredModules

		if (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue) {
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

		$domain = $env:USERDNSDOMAIN
		$useDefault = Read-Host "Use default temporary password? (Y/N)"
		$defaultCipher = 'DTAuMzAuMzgPNj8oOD8oPw=='

		if ($useDefault -match '^(Y|y)$') {
			$defaultPlain = Get-DefaultPassword -CipherText $defaultCipher
			$securePassword = ConvertTo-SecureString -String $defaultPlain -AsPlainText -Force
		} else {
			$securePassword = Read-Host -AsSecureString "Enter temporary password"
		}

		$surname = Read-Host "Enter surname (optional, leave blank to use default mail)"
		$upn = "$AccountName@$domain"

		if ([string]::IsNullOrWhiteSpace($surname)) {
			$mail = $upn
		} else {
			$mail = "$AccountName.$surname@$domain"
		}

		New-ADUser `
			-Name $AccountName `
			-SamAccountName $AccountName `
			-UserPrincipalName $upn `
			-Path $OrganizationalUnit `
			-AccountPassword $securePassword `
			-Enabled $true `
			-ChangePasswordAtLogon $true `
			-OtherAttributes @{ mail = $mail } `
			-ErrorAction Stop

		if ($GroupName) {
			if (-not (Get-ADGroup -Identity $GroupName -ErrorAction SilentlyContinue)) {
				throw "Group '$GroupName' does not exist."
			}
			Add-ADGroupMember -Identity $GroupName -Members $AccountName -ErrorAction Stop
		}
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}