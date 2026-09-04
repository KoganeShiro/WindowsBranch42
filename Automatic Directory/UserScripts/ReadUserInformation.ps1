<#
.SYNOPSIS
Reads and retrieves user information from Active Directory based on specified account name and attributes.

.DESCRIPTION
This script provides a flexible framework for querying Active Directory user properties with validation,
GUI input support, and command-line argument parsing. It validates user existence before attempting to
retrieve attributes and supports selective attribute retrieval for performance optimization.

The script uses a configuration-driven approach where all parameters, validation rules, and main logic
are defined in a $CONFIG hashtable, making it easy to extend and maintain.

.PARAMETER AccountName
Specifies the SAM account name of the user to query. Must be 1-20 characters and contain only
alphanumeric characters, dots, underscores, or hyphens. This parameter is required.

.PARAMETER Attributes
Specifies which Active Directory attributes to retrieve. If not provided, all attributes are returned.
Multiple attributes should be entered one per line in the GUI or comma-separated from command line.

.EXAMPLE
# Run with GUI prompt for parameters
.\ReadUserInformation.ps1

# Run with command-line arguments
.\ReadUserInformation.ps1 -AccountName "jdoe" -Attributes "DisplayName,Mail,Department"

.NOTES
- Requires Administrator privileges to access Active Directory properties
- Requires the Active Directory PowerShell module
- Uses dynamic parameter validation based on configuration
- Displays GUI form if required parameters are missing from command line
- Validates user existence before attempting attribute retrieval

.OUTPUTS
System.Management.Automation.PSCustomObject
Returns the specified or all AD user attributes for the queried account.

.ERROR HANDLING
- Throws error if script is not run as Administrator
- Throws error if specified user account does not exist
- Throws validation errors for invalid parameter values
- Displays MessageBox for validation errors when using GUI
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
            Name = "AccountName"
            Type = "string"
            Required = $true
            Description = "Name of the account"
            Validation = @{
                MinLength = 1
                MaxLength = 20
                Pattern = "^[a-zA-Z0-9._-]+$"
            }
            GuiControl = "TextBox"
        },
        @{
            Name = "Attributes"
            Type = "string[]"            
            Description = "List of attributes to retrieve (one per line)"
            Validation = @{
                MinCount = 0
            }
            GuiControl = "TextBox-Multiline"
        }
    )
    
    # Main Logic Configuration, can be a script block or a reference to a function
    MainLogic = {
        param($params)
        $accountName = $params["AccountName"]
        $attributes = $params["Attributes"]
        
        # Validate that the script is running with Administrator privileges, this is important because accessing certain Active Directory properties may require elevated permissions, and it ensures the script can run successfully without permission issues
        if (-not ([Security.Principal.WindowsPrincipal] `
           [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "This script must be run as Administrator."
            exit 1
        }

        # Import the Active Directory module
        Import-Module ActiveDirectory        
        
        # Validate user exists before attempting to retrieve attributes, this prevents errors that would occur if we try to access attributes of a non-existent user, and it provides clear feedback to the user about the issue
        $userExists = Get-ADUser -Filter "SamAccountName -eq '$accountName'" -ErrorAction Stop            
        if ($userExists -ne $null) {
            Write-Host "User '$accountName' exists." -ForegroundColor Green
            
        } else {
            Write-Host "User '$accountName' does not exist, exiting." -ForegroundColor Red
            exit 1
        }
        # Retrieve user attributes, if specific attributes are provided, retrieve only those, otherwise retrieve all attributes, this allows for flexibility in retrieving user information based on the user's needs, and it can improve performance by only retrieving necessary attributes
        if ($attributes -and $attributes.Count -gt 0) {
            Write-Host "Retrieving attributes for user '$accountName': $($attributes -join ', ')" -ForegroundColor Cyan
            get-aduser -Identity $accountName -Properties * | Select-Object -Property $attributes
        } else {
            Write-Host "Retrieving all attributes for user '$accountName'..." -ForegroundColor Cyan
            get-aduser -Identity $accountName -Properties *
        }
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
            if ($validation.PathExists -and -not (Test-Path (Split-Path $Value))) {  
                throw "Directory does not exist: $(Split-Path $Value)"
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