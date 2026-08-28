<#
| Name            | [ADPackageInstallor.ps1](./Scripts/ADPackageInstallor.ps1)                              |
| --------------- | --------------------------------------------------------------------------------------- |
| **Description** | Install ActiveDirectory and every dependencies needed for the domain controller role |
| **Parameter**   | none                                                                                    |
You first need to install the ActiveDirectory module to be able to use the cmdlets needed for the domain controller role.
https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
https://rdr-it.com/active-directory-installer-adds-et-configurer-un-domaine-avec-powershell/

Execute this script on both servers:
```powershell
Z:\Scripts\ADPackageInstallor.ps1
```

Verify that the module is installed and available if not install it,
You can open the server manager to check if the role is installed.
#>
param (
	[switch]$Interactive
)

# Dot source the template for common functions and variables
. $PSScriptRoot\..\template.ps1

# Required modules for this script
$requiredModules = @('ActiveDirectory')

# Ensure we are running elevated (unless template SkipAdminCheck is used)
try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "[AD PACKAGE INSTALLOR] Running as $env:USERNAME on $env:COMPUTERNAME"

	# Install AD DS role if not present. Use safe invoker to capture failures.
	$installResult = Invoke-ActionSafely -ActionName 'Install AD DS role and management tools' -Action {
		# Get the status of the AD DS feature.
		$feature = Get-WindowsFeature -Name 'AD-Domain-Services'
		if (-not $feature.Installed) {
			if ($Interactive) {
				$confirm = Confirm-YesNo -Message 'AD DS role is not installed. Install it now?' -Title 'Install AD DS?'
				if (-not $confirm) { Throw-WithLog 'User declined AD DS installation.' }
			}
			# Install the feature. 'Out-Null' hides the progress bar from messing up the terminal view.
			Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
			Write-Log -Message 'AD DS role installed.'
		} else {
			Write-Log -Message 'AD DS role already installed.'
		}
	}

	if (-not $installResult.Success) {
		Throw-WithLog "AD DS installation step failed: $($installResult.Exception.Message)"
	}

	# Ensure the ActiveDirectory module is available and import it
	$importResult = Invoke-ActionSafely -ActionName 'Import Active Directory module' -Action {
		Import-RequiredModules -Modules $requiredModules
		# Simple check to verify the module was loaded by counting its available commands
		$cmdletCount = (Get-Command -Module ActiveDirectory).Count
		Write-Log -Message "ActiveDirectory module ready. Cmdlets: $cmdletCount"
	}

	if (-not $importResult.Success) {
		if ($Interactive) {
			$resp = Confirm-YesNo -Message "Import failed: $($importResult.Exception.Message)\nDo you want to continue and inspect manually?" -Title 'Import failed'
			if (-not $resp) { Throw-WithLog "Import failed and user elected to stop: $($importResult.Exception.Message)" }
		}
		else {
			Throw-WithLog "Import failed: $($importResult.Exception.Message)"
		}
	}

	# Final verification to ensure environment is ready
	$validation = Validate-Environment -RequiredModules $requiredModules -CheckADRole
	$problems = @()
	foreach ($m in $requiredModules) {
		$info = $validation.Modules[$m]
		if (-not $info.Available) { $problems += "Module not available: $m" }
		elseif (-not $info.Loaded) { $problems += "Module available but not loaded: $m" }
	}
	if ($validation.ContainsKey('ADRole')) {
		if (-not $validation.ADRole.Installed) { $problems += 'AD-Domain-Services role not installed' }
	}

	if ($problems.Count -gt 0) {
		$msg = "Environment validation failed:`n" + ($problems -join "`n")
		Write-Log -Message $msg -Level 'ERROR'
		if ($Interactive) { [System.Windows.Forms.MessageBox]::Show($msg, 'Validation failed', 'OK', 'Error') }
		Throw-WithLog $msg
	}

	Write-Log -Message '[AD PACKAGE INSTALLOR] Environment validated successfully.'
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}

# Verification helpers (run manually if needed): Get-WindowsFeature -Name 'AD-Domain-Services'; Get-Module ActiveDirectory -ListAvailable
