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
,

  [switch]$Interactive
)

. $PSScriptRoot\..\template.ps1
$requiredModules = @('ActiveDirectory', 'ADDSDeployment')


try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "Running as $env:USERNAME on $env:COMPUTERNAME"
  $result = Invoke-ActionSafely -ActionName 'Create New Forest and Promote to Domain Controller' -Action {
 	Import-RequiredModules -Modules $requiredModules
    Install-ADDSForest `
    -DomainName $DomainAddress `
    -DomainNetbiosName $NetbiosName `
    -DomainMode "default" `
    -ForestMode "default" `
    -InstallDNS `
    -SafeModeAdministratorPassword (Read-SecureInput -Prompt 'Enter the Directory Services Restore Mode password') `
    -Force
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

# Verify with the server manager or with the command:
# Get-ADDomain -Identity $DomainAddress
# Nslookup $DomainAddress
# Get-ADUser -Filter *
# Verification: Get-ADDomainController -Filter * | Select-Object Name, Domain, Forest, IPv4Address
