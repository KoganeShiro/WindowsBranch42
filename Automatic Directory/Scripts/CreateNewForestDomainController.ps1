<#
| Name            | [CreateNewForestDomainController.ps1](./Scripts/CreateNewForestDomainController.ps1) |
| --------------- | --------------------------------------------------------------------- 				 |
| **Description** | Promote an AD server to Domain Controller by creating a new forest 				 |
| **Parameter**   | - DomainAddress
|                 | - NetbiosName                                      				 |
#>

. $PSScriptRoot\..\template.ps1


$requiredModules = @('ActiveDirectory')

param (
	# DomainAddress
	[Parameter(Mandatory = $true)]
	[string]$DomainAddress,

	# NetbiosName
	[Parameter(Mandatory = $true)]
	[string]$NetbiosName,

)


try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "Running as $env:USERNAME on $env:COMPUTERNAME"

    # Create the forest + promote the server to a domain controller
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}


Install-ADDSForest 
  -DomainName "domolia.local" 
  -DomainNetbiosName "DOMOLIA"
  -DomainMode "WinThreshold"
  -ForestMode "WinThreshold"
  -InstallDNS 
  -SafeModeAdministratorPassword (Read-Host -AsSecureString "Enter DSRM Password") 
  -Force

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "domolia.local" -DomainNetbiosName "DOMOLIA" -InstallDNS 
  -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password") -Force




DC1-ADMIN (192.168.1.10)
    DNS: localhost
DC2-WORKSHOP (192.168.1.11)
    DNS: DC1-ADMIN