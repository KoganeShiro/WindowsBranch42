<#
Template used for all scripts in the Automatic Directory project.
It contains the shared backbone for scripts in ./Scripts.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param (
	# The default path to store automation logs
	[Parameter(Mandatory = $false)]
	[string]$LogPath = "C:\AD-Automation\Logs",

	# A switch to enable echoing logs to the terminal
	[Parameter(Mandatory = $false)]
	[switch]$VerboseOutput,

	# Allow scripts to skip the admin
	[Parameter(Mandatory = $false)]
	[switch]$SkipAdminCheck
)

# This forces strict variable declaration and stops execution on any error
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


<#
Appends logs with timestamps to C:\AD-Automation\Logs\[ScriptName].log.
If you pass -VerboseOutput when running your script,
it prints the log to the terminal too.
#>
function Write-Log {
	param (
		[Parameter(Mandatory = $true)][string]$Message,
		[Parameter(Mandatory = $false)][ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
	)

	# Format the current date and time
	$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
	$entry = "$timestamp [$Level] $Message"

	# If the log directory doesn't exist, create it forcefully
	if (-not (Test-Path -Path $LogPath)) {
		New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
	}

	# Construct the full log file path based on the calling script's name and append the entry
	$logFile = Join-Path $LogPath ("{0}.log" -f $MyInvocation.MyCommand.Name)
	Add-Content -Path $logFile -Value $entry

	# Print to the console if the -VerboseOutput switch was used
	if ($VerboseOutput) {
		Write-Host $entry
	}
}


<#
Checks if the terminal running the script has Administrator privileges 
If it doesn't, the script stops.
#>
function Assert-Admin {
	param ([switch]$Skip)

	# Bypass the check immediately if the flag is provided
	if ($Skip) {
		Write-Log -Message 'Admin check skipped by flag.' -Level 'WARN'
		return
	}

	# Retrieve the currently logged in Windows user
	$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
	
	# Verify if this user token is a part of the Built-In Administrator group
	$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

	if (-not $isAdmin) {
		throw 'This script must be run as Administrator.'
	}
}


<#
Ensures that required modules (like ActiveDirectory or ServerManager)
are actually installed on the system before trying to load them
#>
function Import-RequiredModules {
	param (
		[Parameter(Mandatory = $true)][string[]]$Modules
	)

	# Loop through the list of module names passed in
	foreach ($module in $Modules) {
		# -ListAvailable searches the system for the module without loading it
		if (-not (Get-Module -ListAvailable -Name $module)) {
			throw "Required module not found: $module"
		}
        Write-Log -Message "Importing module: $module..."
		
		# Load the module. -ErrorAction Stop ensures that if it fails, it triggers the catch block immediately
		Import-Module $module -ErrorAction Stop
		Write-Log -Message "$module module imported successfully."
	}
}


<#
"wrapper" function for executing script actions.
It allows you to run your scripts with the -WhatIf flag to test
what would happen without actually making changes.
#>
function Invoke-ScriptAction {
	param (
		[Parameter(Mandatory = $true)][string]$ActionName,
		[Parameter(Mandatory = $true)][scriptblock]$Action
	)

	Write-Log -Message "Starting: $ActionName"

	# ShouldProcess checks if WhatIf was passed.
	if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, $ActionName)) {
		# The ampersand (&) is the "call operator", it executes the script block
		& $Action
		Write-Log -Message "Completed: $ActionName"
	} else {
		# Execution skips the & $Action and lands here
		Write-Log -Message "Skipped (WhatIf): $ActionName" -Level 'WARN'
	}
}

try {
	Assert-Admin -Skip:$SkipAdminCheck
	Write-Log -Message "Running as $env:USERNAME on $env:COMPUTERNAME"

	# Example: import required modules per script
	# Import-RequiredModules -Modules @('ActiveDirectory')

	# Script-specific logic goes here
	# Invoke-ScriptAction -ActionName 'Describe the action' -Action { }
}
catch {
	Write-Log -Message $_.Exception.Message -Level 'ERROR'
	throw
}
