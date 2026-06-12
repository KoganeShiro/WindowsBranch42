<#
| Name            | [JoinExistingDomainController.ps1](./Scripts/JoinExistingDomainController.ps1)                |
| --------------- | --------------------------------------------------------------------------------------------- |
| **Description** | Promote an AD server to Domain Controller by joining an<br>already existing domain controller |
| **Parameter**   | - DomainAddress    
                    - TargetServer (optional, default: localhost)   
                    
https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsdomaincontroller?view=windowsserver2025-ps

Execute this script on the server that will be other domain controller to join the existing domain:
```powershell
Z:\Scripts\JoinExistingDomainController.ps1 -DomainAddress "domolia.local" #-TargetServer "192.168.1.11"
```

domolia\administrator
#>

# add a parameter if local or distant
param (
	[Parameter(Mandatory = $true)]
	[string]$DomainAddress,

	[Parameter(Mandatory = $false)]
	[string]$TargetServer = "localhost"
)

. $PSScriptRoot\..\template.ps1
$requiredModules = @('ActiveDirectory', 'ADDSDeployment')


try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message " [ JOIN EXISTING DOMAIN CONTROLLER ] Running as $env:USERNAME on $env:COMPUTERNAME"
    Invoke-ScriptAction -ActionName 'Join Existing Domain and Promote to Domain Controller' -Action {
	Import-RequiredModules -Modules $requiredModules
    $dsrmPassword = Read-Host -AsSecureString "Enter DSRM Password for the new DC"
    $domainCreds = Get-Credential -Message "Enter Domain Admin credentials (e.g., domolia\admin)"

    $promoteScript = {
        param($dom, $dsrm, $cred)
        Install-ADDSDomainController `
            -DomainName $dom `
            -InstallDns `
            -SafeModeAdministratorPassword $dsrm `
            -Credential $cred `
            -Force
    }

    if ($TargetServer -eq "localhost" -or $TargetServer -eq $env:COMPUTERNAME) {
        Write-Log -Message "Promoting local server to Domain Controller..."
        & $promoteScript -dom $DomainAddress -dsrm $dsrmPassword -cred $domainCreds
    } else {
        Write-Log -Message "Promoting distant server '$TargetServer' to Domain Controller..."
        Invoke-Command -ComputerName $TargetServer -ScriptBlock $promoteScript -ArgumentList $DomainAddress, $dsrmPassword, $domainCreds
    }
  }
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

<#
 Get-AdDomainController -filter * | Select Name, Domain, Forest, IPv4Address, Site                                                                                                                                       
Name        : DC2-WORKSHOP
Domain      : domolia.local
Forest      : domolia.local
IPv4Address : 192.168.1.11
Site        : Default-First-Site-Name

Name        : DC1-ADMIN
Domain      : domolia.local
Forest      : domolia.local
IPv4Address : 192.168.1.10
Site        : Default-First-Site-Name
#>

# Verification: Get-ADDomainController -Filter * | Select-Object Name, Domain, Forest, IPv4Address
