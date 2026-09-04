<#
.SYNOPSIS
    Joins an existing Active Directory domain by promoting the current server to a Domain Controller.

.DESCRIPTION
    This script automates the process of promoting a Windows Server to a Domain Controller and joining it to an existing Active Directory domain. It validates all inputs, checks system prerequisites, configures DNS settings, and initiates the ADDS promotion process.

    The script uses a configuration-driven approach with dynamic parameter validation and an optional GUI for input collection.

.PARAMETERS
    DomainAddress (Required)
        Type: String
        Description: The fully qualified domain name (FQDN) to join
        Validation: 1-50 characters, must be a valid domain format (e.g., contoso.com)

    DC_DNS (Required)
        Type: String
        Description: The IP address of an existing Domain Controller's DNS server
        Validation: Valid IPv4 address format

.PREREQUISITES
    - Script must be run as Administrator
    - Active Directory Domain Services (AD-Domain-Services) role must be installed
    - No pending system reboot
    - Network connectivity to the existing Domain Controller
    - Valid Active Directory domain credentials

.EXAMPLE
    .\JoinExistingDomainController.ps1 -DomainAddress "contoso.com" -DC_DNS "192.168.1.10"

    Or run without parameters to display the GUI for interactive input.

.NOTES
    - The server will automatically reboot once Domain Controller promotion completes
    - DNS is configured to point to the existing Domain Controller
    - Domain credentials are required during promotion (prompted via Get-Credential)
    - A pending reboot check is performed before promotion begins

.FUNCTIONALITY
    1. Validates administrator privileges
    2. Checks for pending system reboots
    3. Verifies no existing forest
    4. Validates AD-Domain-Services role installation
    5. Configures DNS to point to existing Domain Controller
    6. Validates DNS resolution
    7. Promotes server to Domain Controller
    8. Initiates automatic system reboot

#>
param () # No parameters defined here, we will handle them dynamically based on configuration

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================
# Define all parameters here with their properties
# ============================================================================

$CONFIG = @{
    Parameters = @(
        @{
            Name = "DomainAddress"
            Type = "string"
            Required = $true
            Description = "Domain address"
            Validation = @{
                MinLength = 1
                MaxLength = 50
                Pattern = "^(?=.+\..+)[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$" # Must contain at least one dot and contain only alphanumeric characters, dots, and hyphens
            }
            GuiControl = "TextBox"
        },
        @{
            Name = "DC_DNS"
            Type = "string"
            Required = $true
            Description = "Domain Controller DNS"
            Validation = @{
                MinLength = 1
                MaxLength = 50
                Pattern = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$" # Valid IPv4 address format
            }
            GuiControl = "TextBox"
        }         
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

        # Check if reboot is pending
        if (Test-PendingReboot) {
            Write-Host "Server must be restarted before running Install-ADDSForest." -ForegroundColor Red
            exit 1
        }
        # Check if forest already exists, this is important because you cannot join a Domain Controller to an existing forest, it must be promoted within the context of the existing forest, if a forest is detected it means we are already part of a domain and cannot join another one as a Domain Controller
        try {
           Get-ADForest
            Write-Host "Forest already exists, will not join DomainController." -ForegroundColor Yellow
            exit 1
        }
        catch {
            Write-Host "No forest detected"
        }
        # Variables
        $DomainName = $params.DomainAddress
        $DC_DNS = $params.DC_DNS
               
        Write-Host "Promoting server to Domain Controller for domain $DomainName ..." -ForegroundColor Green
        
        # Check if AD DS role is installed, if not prompt user to install it first, this is important because Install-ADDSDomainController requires the AD DS role to be installed before it can run successfully
        if (Get-WindowsFeature -Name AD-Domain-Services | Where-Object { $_.InstallState -ne "Installed" } )
        {
            Write-Host "Active Directory Domain Services Role... you can use this script to install it:" -ForegroundColor Yellow 
            Write-Host "ADPackageInstallor.ps1" -ForegroundColor Cyan
            exit 1
        }
        
        # Import ADDS Deployment Module
        Import-Module ADDSDeployment

        # Configure DNS to point to existing Domain Controller, this is important because during the promotion process the server needs to communicate with the existing Domain Controller for replication and other operations, if DNS is not configured correctly it can cause the promotion to fail or have issues after promotion
        Write-Host "Get the active network adapter to use for Domain Controller promotion..." -ForegroundColor Green        
        $Interface = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
        
        # Check if we found an active network adapter
        if (-not $Interface) {
            Write-Host "No active network adapter found. Please ensure the server is connected to the network." -ForegroundColor Red
            exit 1
        }
        # Set DNS server to existing Domain Controller, this is done using the Set-DnsClientServerAddress cmdlet, we specify the interface index of the active network adapter and set the server address to the IP of the existing Domain Controller's DNS server
        Write-Host "Set DNS server to existing Domain Controller..." -ForegroundColor Green        
        Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses $DC_DNS

        Write-Host "DNS server changed to $DC_DNS" -ForegroundColor Green

        # Test if domain resolves
        Write-Host "Testing DNS resolution for $DomainName..."

        if (Resolve-DnsName $DomainName -ErrorAction SilentlyContinue) {
            Write-Host "Domain DNS resolution successful"
        }
        else {
            Write-Host "DNS resolution failed. Check DNS configuration." -ForegroundColor Red
            exit 1
        }
        
        # Promote Server to Domain Controller and Create New Forest
        # Build parameters hashtable for Install-ADDSDomainController, using the values from the parameters and some fixed settings, this allows us to easily modify the parameters for Install-ADDSDomainController in one place if needed
        $forestParams = @{
            DomainName = $DomainName            
            InstallDns = $true
            Credential = (Get-Credential)            
            NoRebootOnCompletion = $false
            Force = $true
            ErrorAction = 'Stop'
        }

        Write-Host "Starting Domain Controller promotion... you will be asked to enter the Credentials of the Domaincontroller, enter" -ForegroundColor Green
        Write-Host "enter the username like this: $DomainName\Domainadmin" -ForegroundColor Green

        # Call Install-ADDSDomainController with the parameters, this cmdlet will promote the server to a domain controller and join it to the existing Active Directory domain, it will automatically reboot the server once the process is complete unless NoRebootOnCompletion is set to $true
        Install-ADDSDomainController @forestParams
        Write-Host "Domain Controller promotion initiated. The server will reboot automatically once the process is complete." -ForegroundColor Green    
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing



# ============================================================================
# Test for pending reboot function, this is important to ensure the server is in a clean state before promoting to DC, as pending reboots can cause issues with ADDS installation
# ============================================================================



function Test-PendingReboot {
    $pending = $false

    # Component-Based Servicing
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
        $pending = $true
    }

    # Windows Update
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $pending = $true
    }

    # Pending File Rename Operations
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    $value = "PendingFileRenameOperations"
    if (Test-Path $key) {
        $pendingFileRename = Get-ItemProperty -Path $key -Name $value -ErrorAction SilentlyContinue
        if ($pendingFileRename.$value) { $pending = $true }
    }

    return $pending
}




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
        if ($ParamConfig.Type -eq "string" -or $ParamConfig.Type -eq "SecureString") {
            if ($validation.Pattern -and -not ($Value -match $validation.Pattern)) {
                throw "$paramName must match pattern: $($validation.Pattern)"
            }
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