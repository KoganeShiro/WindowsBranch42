<#
| Name            | [UserCreation.ps1](./Scripts/UserCreation.ps1)                                                                                                                                                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | In hashtable or in specification. We assume that
                    - mail address : name.surname@domaineName.com
                    - Basic password : DTAuMzAuMzgPNj8oOD8oPw== 
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

	[Parameter(Mandatory = $false)]
	[string]$OrganizationalUnit = "OU=Users,DC=domolia,DC=local",

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

		# Verify that the target OU/container exists
		$ouExists = $null
		try {
			$ouExists = Get-ADObject -SearchBase $OrganizationalUnit -SearchScope Base -ErrorAction Stop
		} catch {
			$ouExists = $null
		}

		if (-not $ouExists) {
			Write-Host "The OrganizationalUnit path '$OrganizationalUnit' does not exist."
			Write-Host "You can list available OUs/containers with the following command:"
			Write-Host 'Get-ADObject -LDAPFilter "(|(objectClass=organizationalUnit)(objectClass=container))" -SearchBase (Get-ADDomain).DistinguishedName -SearchScope Subtree | Select-Object Name, DistinguishedName, ObjectClass | Sort-Object DistinguishedName'
			$createOU = Read-Host "Create the OU (will attempt to create the left-most OU in the DN)? (Y/N)"
			if ($createOU -match '^(Y|y)$') {
				$dnParts = $OrganizationalUnit -split ','
				$rdn = $dnParts[0]
				$name = ($rdn -split '=')[1]
				$parent = ($dnParts[1..($dnParts.Length-1)] -join ',')
				if ([string]::IsNullOrWhiteSpace($parent)) {
					$parent = (Get-ADDomain).DistinguishedName
				}
				New-ADOrganizationalUnit -Name $name -Path $parent -ProtectedFromAccidentalDeletion $false -ErrorAction Stop
			} else {
				throw "OrganizationalUnit '$OrganizationalUnit' does not exist."
			}
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

# Get-ADUser -Filter * -SearchBase "DC=domolia,DC=local"

# Verification: Get-ADUser -Identity $AccountName -Properties mail,UserPrincipalName
