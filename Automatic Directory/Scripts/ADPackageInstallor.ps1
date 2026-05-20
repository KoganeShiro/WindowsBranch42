<#
| Name            | [ADPackageInstallor.ps1](./Scripts/ADPackageInstallor.ps1)                              |
| --------------- | --------------------------------------------------------------------------------------- |
| **Description** | Install ActiveDirectory and every dependencies needed for the domain controller role |
| **Parameter**   | none                                                                                    |
You first need to install the ActiveDirectory module to be able to use the cmdlets needed for the domain controller role.
https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps

Verify that the module is installed and available if not install it:
#>
# Dot source the template for common functions and variables -> https://medium.com/@abshuemail/dot-sourcing-in-powershell-e12046ad6e10
. $PSScriptRoot\..\template.ps1


$requiredModules = @('ActiveDirectory')

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "Running as $env:USERNAME on $env:COMPUTERNAME"

	# Checks if the Active Directory Domain Services role is installed, and installs it if not
	Invoke-ScriptAction -ActionName 'Install AD DS role and management tools' -Action {
		# Get the status of the AD DS feature.
		$feature = Get-WindowsFeature -Name 'AD-Domain-Services'
		if (-not $feature.Installed) {
			# Install the feature. 'Out-Null' hides the progress bar from messing up the terminal view.
			Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
			Write-Log -Message 'AD DS role installed.'
		} else {
			Write-Log -Message 'AD DS role already installed.'
		}
	}

	# This block ensures the module is loaded and usable
	Invoke-ScriptAction -ActionName 'Import Active Directory module' -Action {
		Import-RequiredModules -Modules $requiredModules
		# Simple check to verify the module was loaded by counting its available commands
		$cmdletCount = (Get-Command -Module ActiveDirectory).Count
		Write-Log -Message "ActiveDirectory module ready. Cmdlets: $cmdletCount"
	}
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}