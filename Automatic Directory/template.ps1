<# Shared functions. Dot-sourcing this file defines helpers but executes no task. #>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:LogPath = 'C:\AD-Automation\Logs'
$script:VerboseOutput = $false
$script:SkipAdminCheck = $false
$script:LogSourceName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)
if ([string]::IsNullOrWhiteSpace($script:LogSourceName)) { $script:LogSourceName = 'AD-Automation' }

function Write-Log {
	param (
		[Parameter(Mandatory = $true)][string]$Message,
		[ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
	)
	$entry = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
	if (-not (Test-Path -LiteralPath $script:LogPath)) {
		New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
	}
	Add-Content -LiteralPath (Join-Path $script:LogPath "$script:LogSourceName.log") -Value $entry
	if ($script:VerboseOutput) { Write-Host $entry }
}

function Assert-Admin {
	param ([switch]$Skip)
	if ($Skip) { Write-Log -Message 'Administrator check skipped.' -Level 'WARN'; return }
	$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = [Security.Principal.WindowsPrincipal]::new($identity)
	if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		throw 'This script must be run from an elevated PowerShell terminal.'
	}
}

function Import-RequiredModules {
	param ([Parameter(Mandatory = $true)][string[]]$Modules)
	foreach ($module in $Modules) {
		if (-not (Get-Module -ListAvailable -Name $module)) { throw "Required module not found: $module" }
		Import-Module $module -ErrorAction Stop
		Write-Log -Message "Imported module: $module"
	}
}

function Invoke-ScriptAction {
	param (
		[Parameter(Mandatory = $true)][string]$ActionName,
		[Parameter(Mandatory = $true)][scriptblock]$Action
	)
	Write-Log -Message "Starting: $ActionName"
	& $Action
	Write-Log -Message "Completed: $ActionName"
}

function Read-SecureInput {
	<# Display the masked pop-up requested by the project subject. #>
	param ([Parameter(Mandatory = $true)][string]$Prompt)
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	$form = [Windows.Forms.Form]::new()
	$form.Text = 'Active Directory automation'
	$form.StartPosition = 'CenterScreen'
	$form.ClientSize = [Drawing.Size]::new(440, 125)
	$form.TopMost = $true
	$label = [Windows.Forms.Label]::new()
	$label.Text = $Prompt
	$label.AutoSize = $true
	$label.Location = [Drawing.Point]::new(12, 15)
	$form.Controls.Add($label)
	$textBox = [Windows.Forms.TextBox]::new()
	$textBox.Location = [Drawing.Point]::new(15, 43)
	$textBox.Size = [Drawing.Size]::new(410, 23)
	$textBox.UseSystemPasswordChar = $true
	$form.Controls.Add($textBox)
	$ok = [Windows.Forms.Button]::new()
	$ok.Text = 'OK'
	$ok.Location = [Drawing.Point]::new(350, 82)
	$ok.DialogResult = [Windows.Forms.DialogResult]::OK
	$form.AcceptButton = $ok
	$form.Controls.Add($ok)
	if ($form.ShowDialog() -ne [Windows.Forms.DialogResult]::OK -or [string]::IsNullOrEmpty($textBox.Text)) {
		$form.Dispose()
		throw 'The password prompt was cancelled or left empty.'
	}
	$secureValue = ConvertTo-SecureString -String $textBox.Text -AsPlainText -Force
	$textBox.Clear()
	$form.Dispose()
	return $secureValue
}

function Read-TextInput {
	<# Display a simple text pop-up for additional information. #>
	param (
		[Parameter(Mandatory = $true)][string]$Prompt,
		[string]$DefaultValue = ''
	)
	Add-Type -AssemblyName Microsoft.VisualBasic
	return [Microsoft.VisualBasic.Interaction]::InputBox(
		$Prompt,
		'Active Directory automation',
		$DefaultValue
	)
}
