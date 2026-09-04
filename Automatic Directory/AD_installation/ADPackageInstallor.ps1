<#
.SYNOPSIS
    Active Directory Domain Controller Prerequisite Installation and Verification Script

.DESCRIPTION
    This script automates the prerequisites for promoting a Windows Server to an Active Directory Domain Controller.
    It performs comprehensive system checks and installs the AD DS (Active Directory Domain Services) role with
    management tools. The script includes a configuration-driven architecture with support for dynamic parameter
    handling, GUI input, and extensive validation.

.FEATURES
    - Administrator privilege verification
    - Operating System validation (Windows Server only)
    - Network and IP configuration analysis
    - DHCP vs Static IP detection and warnings
    - Automatic ServerManager module availability check
    - AD DS role installation with management tools
    - Installation verification and status reporting
    - Configuration-driven parameter system with GUI support
    - Type-specific parameter validation
    - Dynamic variable initialization from configuration

.PARAMETER
    This script uses a configuration-based parameter system rather than traditional parameters.
    Parameters are defined in the $CONFIG hashtable and can be provided via command line or GUI.

.CONFIGURATION
    The $CONFIG hashtable contains:
    - Parameters: Array of parameter definitions with type, validation, and GUI properties
    - MainLogic: Script block containing the main execution logic

.VALIDATES
    - Administrator rights
    - Operating system type (Windows Server)
    - Hostname conventions
    - Network adapter configuration
    - IP address assignment (Static vs DHCP)
    - ServerManager module availability
    - AD DS installation status

.OUTPUTS
    Colored console output with:
    - System information (OS, hostname, network config)
    - Configuration status and warnings
    - Installation progress and results
    - Next steps for domain controller promotion

.NOTES
    - Requires elevation (Administrator)
    - Designed for Windows Server only
    - Static IP configuration recommended before execution
    - Script provides guidance for next steps (forest creation or domain join)
    - Part of an automated AD deployment suite

.EXAMPLE
    & '.\ADPackageInstallor.ps1'
    Runs the script with GUI for parameter input or existing configuration

.LINK
    Related scripts: CreateNewForestDomainController.ps1, JoinExistingDomainController.ps1
#>
param () # No parameters defined here, we will handle them dynamically based on configuration

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================
# Define all parameters here with their properties
# ============================================================================

$CONFIG = @{
    Parameters = @(       
    )
    
    # Main Logic Configuration, can be a script block or a reference to a function
    MainLogic = {
        param($params)
        
        # Run PowerShell as Administrator

        if (-not ([Security.Principal.WindowsPrincipal] `
           [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

            Write-Error "This script must be run as Administrator."
            exit 1
        }

        Write-Host "=== Active Directory Domain Controller Prerequisite Check ===" -ForegroundColor Cyan

        # Check OS
        $os = Get-CimInstance Win32_OperatingSystem
        Write-Host "Operating System:" $os.Caption

        if ($os.Caption -notmatch "Server") {
            Write-Host "ERROR: Active Directory Domain Services can only be installed on Windows Server." -ForegroundColor Red
            exit
        }

        # Check hostname
        $hostname = $env:COMPUTERNAME
        Write-Host "Hostname:" $hostname

        if ($hostname -match "WIN-|DESKTOP") {
            Write-Host "WARNING: Hostname appears to be default. Consider renaming before promoting to DC." -ForegroundColor Yellow
        }

        # Check network configuration
        Write-Host "`nChecking network configuration..."

        $ipConfig = Get-NetIPConfiguration | Where-Object {$_.IPv4Address -ne $null}

        foreach ($adapter in $ipConfig) {
            Write-Host "Adapter:" $adapter.InterfaceAlias
            Write-Host "IPv4 Address:" $adapter.IPv4Address.IPAddress
            Write-Host "DHCP Enabled:" $adapter.NetAdapter.DhcpEnabled
        }

        # Check if static IP is configured
        $dhcp = Get-NetIPInterface -AddressFamily IPv4 | Where-Object {$_.Dhcp -eq "Enabled"}

        if ($dhcp) {
            Write-Host "WARNING: DHCP is enabled. Domain Controllers should use a STATIC IP." -ForegroundColor Yellow
        } else {
            Write-Host "Static IP appears to be configured." -ForegroundColor Green
        }
        # Check if ServerManager module is available
        Write-Host "`nChecking if ServerManager module is available..."
        if (-not (Get-Module -ListAvailable -Name ServerManager)) {
            Write-Host "ServerManager module is not available... Installing it" -ForegroundColor Red            
            Import-Module ServerManager -ErrorAction Stop
        }
        
        # Check AD DS installation status
        Write-Host "`nChecking if AD DS role is installed..."


        # Get-WindowsFeature is part of the ServerManager module, it checks if the AD-Domain-Services feature is installed
        $feature = Get-WindowsFeature AD-Domain-Services

        if ($feature.Installed) {
            Write-Host "Active Directory Domain Services is already installed." -ForegroundColor Green
        } else {
            Write-Host "Installing Active Directory Domain Services and management tools..." -ForegroundColor Cyan

        # Install-WindowsFeature is a cmdlet that installs Windows features, here we are installing the AD-Domain-Services feature along with its management tools, -Verbose provides detailed output during installation
        Install-WindowsFeature `
            -Name AD-Domain-Services `
            -IncludeManagementTools `
            -Verbose
        }

        # Verify installation
        $feature = Get-WindowsFeature AD-Domain-Services

        if ($feature.Installed) {
            Write-Host "`nAD DS role successfully installed." -ForegroundColor Green
        } else {
            Write-Host "`nERROR: AD DS installation failed." -ForegroundColor Red
        }

        Write-Host "`nNext step: Promote server to Domain Controller using CreateNewForestDomainController.ps1 or JoinExistingDomainController.ps1."        
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================================
# VALIDATION FUNCTION
# ============================================================================

function Validate-Parameter {
    param (
        [hashtable]$ParamConfig, # Parameter configuration from $CONFIG, hashtable is used for easier access to properties
        $Value
    )
    
    $paramName = $ParamConfig.Name
    
    # Check required
    if ($ParamConfig.Required -and ($null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)))) {
        throw "$paramName is required."
    }
    
    # Skip validation if value is null and not required
    if ($null -eq $Value -and -not $ParamConfig.Required) {
        return
    }
    
    # Type-specific validation
    if ($ParamConfig.Validation) {
        $validation = $ParamConfig.Validation
        
        # String validations
        if ($ParamConfig.Type -eq "string") {
            if ($validation.MinLength -and $Value.Length -lt $validation.MinLength) {
                throw "$paramName must be at least $($validation.MinLength) characters."
            }
            if ($validation.MaxLength -and $Value.Length -gt $validation.MaxLength) {
                throw "$paramName must be at most $($validation.MaxLength) characters."
            }
            if ($validation.FileExists -and -not (Test-Path $Value)) {
                throw "File does not exist: $Value"
            }
        }
        
        # Integer validations
        if ($ParamConfig.Type -eq "int") {
            if ($validation.Min -and $Value -lt $validation.Min) {
                throw "$paramName must be at least $($validation.Min)."
            }
            if ($validation.Max -and $Value -gt $validation.Max) {
                throw "$paramName must be at most $($validation.Max)."
            }
        }
        
        # Array validations
        if ($ParamConfig.Type -eq "string[]") {
            if ($validation.MinCount -and $Value.Count -lt $validation.MinCount) {
                throw "$paramName must have at least $($validation.MinCount) items."
            }
            foreach ($item in $Value) {
                if ([string]::IsNullOrWhiteSpace($item)) {
                    throw "$paramName list contains an empty value."
                }
            }
        }
    }
}

# ============================================================================
# GUI FUNCTION
# ============================================================================

function Show-Gui {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Script Input"
    $form.Size = New-Object System.Drawing.Size 450, 400
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    
    $controls = @{}
    $yPosition = 20
    
    foreach ($paramConfig in $CONFIG.Parameters) {
        # Label
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "$($paramConfig.Name):$(if($paramConfig.Required){'*'})"
        $label.Location = New-Object System.Drawing.Point 10, $yPosition
        $label.Size = New-Object System.Drawing.Size 150, 20
        $form.Controls.Add($label)
        
        # Control based on type
        $ctrl = $null
        switch ($paramConfig.GuiControl) {
            "CheckBox" {
                $ctrl = New-Object System.Windows.Forms.CheckBox
                $ctrl.Checked = if ($paramConfig.DefaultValue) { $paramConfig.DefaultValue } else { $false }
                $ctrl.Height = 20
            }
            "ComboBox" {
                $ctrl = New-Object System.Windows.Forms.ComboBox
                if ($paramConfig.Validation.ValidValues) {
                    $ctrl.Items.AddRange($paramConfig.Validation.ValidValues)
                }
                $ctrl.DropDownStyle = "DropDownList"
                $ctrl.Height = 20
            }
            "TextBox-Multiline" {
                $ctrl = New-Object System.Windows.Forms.TextBox
                $ctrl.Multiline = $true
                $ctrl.ScrollBars = "Vertical"
                $ctrl.Height = 70
            }
            default {
                $ctrl = New-Object System.Windows.Forms.TextBox
                $ctrl.Height = 20
            }
        }
        
        $ctrl.Location = New-Object System.Drawing.Point 170, $yPosition
        $ctrl.Width = 240
        $form.Controls.Add($ctrl)
        $controls[$paramConfig.Name] = $ctrl
        
        if ($paramConfig.GuiControl -eq "TextBox-Multiline") {
            $yPosition += 90
        } else {
            $yPosition += 45
        }
    }
    
    # OK Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point 170, ($yPosition + 10)
    $okButton.Size = New-Object System.Drawing.Size 75, 23
    $okButton.Add_Click({
        try {
            foreach ($paramConfig in $CONFIG.Parameters) {
                $paramName = $paramConfig.Name
                $ctrl = $controls[$paramName]
                
                $value = switch ($paramConfig.GuiControl) {
                    "CheckBox" { $ctrl.Checked }
                    "ComboBox" { $ctrl.SelectedItem }
                    "TextBox-Multiline" { 
                        $ctrl.Text -split "`r?`n" | Where-Object { $_.Trim() }
                    }
                    default { 
                        if ($paramConfig.Type -eq "int") {
                            [int]$ctrl.Text
                        } else {
                            $ctrl.Text
                        }
                    }
                }
                
                Validate-Parameter -ParamConfig $paramConfig -Value $value
                Set-Variable -Name $paramName -Value $value -Scope Script
            }
            
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_, "Validation Error", "OK", "Error")
        }
    })
    $form.Controls.Add($okButton)
    
    # Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point 255, ($yPosition + 10)
    $cancelButton.Size = New-Object System.Drawing.Size 75, 23
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)
    
    $result = $form.ShowDialog()
    return $result -eq [System.Windows.Forms.DialogResult]::OK
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    # Initialize parameter variables from configuration
    foreach ($paramConfig in $CONFIG.Parameters) {
        $paramName = $paramConfig.Name
        $value = $null
        
        # Try to get from command line arguments first
        if ($args -and $args.Count -gt 0) {
            # Simple argument parsing: -Name John -Age 30 etc
            for ($i = 0; $i -lt $args.Count; $i += 2) {
                if ($args[$i] -eq "-$paramName" -and $i + 1 -lt $args.Count) {
                    if ($paramConfig.Type -eq "int") {
                        $value = [int]$args[$i + 1]
                    } elseif ($paramConfig.Type -eq "string[]") {
                        $value = $args[$i + 1] -split ","
                    } else {
                        $value = $args[$i + 1]
                    }
                    break
                }
            }
        }
        
        Set-Variable -Name $paramName -Value $value -Scope Script # Initialize parameter variable, Set-Variable is used to create variables dynamically based on configuration, Scope Script ensures they are accessible throughout the script
    }
    
    # Check if any required parameters are missing
    $missing = @()
    foreach ($paramConfig in $CONFIG.Parameters) {
        if ($paramConfig.Required) {
            $value = Get-Variable -Name $paramConfig.Name -ValueOnly -ErrorAction SilentlyContinue # Get the value of the parameter variable, Get-Variable is used to access variables by name
            if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) {
                $missing += $paramConfig.Name
            }
        }
    }
    
    # Show GUI if required parameters are missing
    if ($missing.Count -gt 0) {
        Write-Host "Missing required parameters: $($missing -join ', ')" -ForegroundColor Yellow
        Write-Host "Opening GUI..." -ForegroundColor Cyan
        
        $guiResult = Show-Gui
        if (-not $guiResult) {
            Write-Host "Script cancelled by user." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Validate all parameters
    foreach ($paramConfig in $CONFIG.Parameters) {
        $value = Get-Variable -Name $paramConfig.Name -ValueOnly -ErrorAction SilentlyContinue # Get the value of the parameter variable
        Validate-Parameter -ParamConfig $paramConfig -Value $value
    }
    
    Write-Host "`nAll inputs validated successfully!" -ForegroundColor Green
    
    # Build parameters hashtable for main logic
    $params = @{}
    foreach ($paramConfig in $CONFIG.Parameters) {
        $value = Get-Variable -Name $paramConfig.Name -ValueOnly -ErrorAction SilentlyContinue
        $params[$paramConfig.Name] = $value
    }
    
    # Execute main logic from configuration
    & $CONFIG.MainLogic -params $params # Call the main logic script block defined in configuration, passing the parameters as a hashtable, & is used to invoke the script block
    
}
catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    exit 1
}