<#
| Name            | [CreateNewForestDomainController.ps1](./Scripts/CreateNewForestDomainController.ps1) |
| --------------- | --------------------------------------------------------------------- 				 |
| **Description** | Promote an AD server to Domain Controller by creating a new forest 				 |
| **Parameter**   | - DomainAddress
|                 | - NetbiosName                                      				 |
https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest?view=windowsserver2025-ps

Execute this script on the server that will be the first domain controller to create a new forest:
```powershell
Z:\Scripts\CreateNewForestDomainController.ps1 -DomainAddress "domolia.local" -NetbiosName "DOMOLIA"
```
#>

param (
	[Parameter(Mandatory = $true)]
	[string]$DomainAddress,

	[Parameter(Mandatory = $true)]
	[string]$NetbiosName
)

. $PSScriptRoot\..\template.ps1
$requiredModules = @('ActiveDirectory', 'ADDSDeployment')


try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "Running as $env:USERNAME on $env:COMPUTERNAME"
  Invoke-ScriptAction -ActionName 'Create New Forest and Promote to Domain Controller' -Action {
	Import-RequiredModules -Modules $requiredModules
    Install-ADDSForest `
    -DomainName $DomainAddress `
    -DomainNetbiosName $NetbiosName `
    -DomainMode "default" `
    -ForestMode "default" `
    -InstallDNS `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "Enter DSRM Password") `
    -Force
  }
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verify with the server manager or with the command:
# Get-ADDomain -Identity $DomainAddress
# Nslookup $DomainAddress
# Get-ADDUser -Filter * 