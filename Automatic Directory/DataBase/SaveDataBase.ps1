<#
.SYNOPSIS
Exports Active Directory users and groups to a CSV file with customizable properties and delimiter.

.DESCRIPTION
This script provides a flexible framework for exporting Active Directory objects (users and groups) to CSV format.
It features:
- Dynamic parameter configuration system
- GUI input form for missing required parameters
- Comprehensive parameter validation
- Support for custom AD properties
- Administrator privilege enforcement
- Configurable CSV delimiter

The script uses a configuration-driven approach where all parameters and validation rules are defined in the $CONFIG hashtable,
allowing easy customization without modifying core logic.

.PARAMETER OutFile
Path to the output CSV file. The directory must exist. This parameter is required.

.PARAMETER Delimiter
Single character delimiter for CSV export (e.g., ',', ';', '|'). This parameter is required.

.PARAMETER Parameters
Array of Active Directory property names to include in the export (one per line in GUI).
These are combined with default properties (Name, DistinguishedName, ObjectClass).
Minimum one property required.

.EXAMPLE
# Run with GUI (if required parameters missing)
.\SaveDataBase.ps1

# Run with command-line arguments
.\SaveDataBase.ps1 -OutFile "C:\exports\ad_export.csv" -Delimiter "," -Parameters "mail,department,title"

.NOTES
- Requires Administrator privileges
- Requires Active Directory module
- Missing properties in objects will be represented as empty values in CSV
- Only properties that exist on both users and groups may be used for meaningful exports
- The script automatically filters requested properties to those available on each object type

.FUNCTIONALITY
MainLogic:
1. Validates Administrator privileges
2. Imports Active Directory module
3. Combines user-specified properties with defaults
4. Retrieves AD users and groups with specified properties
5. Normalizes all objects to include complete property set (null for missing)
6. Exports combined results to CSV with specified delimiter

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
            Name = "OutFile"
            Type = "string"
            Required = $true
            Description = "Path to output csv file"
            Validation = @{
                PathExists = $true
            }
            GuiControl = "TextBox"
        },
        @{
            Name = "Delimiter"
            Type = "string"
            Required = $true
            Description = "Delimiter for the database export (e.g., ',', ';', '|')"
            Validation = @{
                MinLength = 1
                MaxLength = 1
            }
            GuiControl = "TextBox"
        },
        @{
            Name = "Parameters"
            Type = "string[]"
            Required = $true
            Description = "List of parameters (one per line)"
            Validation = @{
                MinCount = 1
            }
            GuiControl = "TextBox-Multiline"
        }
    )
    
    # Main Logic Configuration, can be a script block or a reference to a function
    MainLogic = {
        param($params)

        $OutputPath = $params["OutFile"]
        $Delimiter = $params["Delimiter"]
        $Attributes = $params["Parameters"].ToLower()
        # Validate that the script is running with Administrator privileges, this is important because accessing certain Active Directory properties may require elevated permissions, and it ensures the script can run successfully without permission issues
        if (-not ([Security.Principal.WindowsPrincipal] `
           [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

            Write-Error "This script must be run as Administrator."
            exit 1
        }
        # Import the Active Directory module
        Import-Module ActiveDirectory

        # Default properties
        $baseProps = @("name","distinguishedname","objectclass")

        # Combine default and custom attributes
        Write-Host "Combining default properties with user-specified attributes..." -ForegroundColor Cyan
        # Remove duplicates and ensure we only have unique properties, this is important because if the user specifies a property that is already in the default list it will not cause issues and we will have a clean list of properties to work with
        $props = ($baseProps + $Attributes) | Select-Object -Unique


        Write-Host "Final properties to retrieve: $($props -join ', ')" -ForegroundColor Green
        # Get the list of all properties available for users and groups, this is important because we need to filter the user-specified properties to those that actually exist on the objects we are retrieving, if a property does not exist it will be ignored and we will avoid errors during retrieval
        $userPropsAll = (Get-ADUser -Filter * -Properties * | Select-Object -First 1).PSObject.Properties.Name
        $groupPropsAll = (Get-ADGroup -Filter * -Properties * | Select-Object -First 1).PSObject.Properties.Name
        
        #Write-Host "All User Props: $($userPropsAll -join ', ')" -ForegroundColor Green
        #Write-Host "All Group Props: $($groupPropsAll -join ', ')" -ForegroundColor Green
        
        # Filter the user-specified properties to those that exist on users and groups, this ensures that we only attempt to retrieve properties that are valid for each object type, if a property is not valid for a particular object type it will simply be ignored for that type and we will not have errors during retrieval
        $userprops = $props | Where-Object { $userPropsAll -contains $_ }
        $groupprops = $props | Where-Object { $groupPropsAll -contains $_ }

        # Get users
        Write-Host "Retrieving users with properties: $($userprops -join ', ')" -ForegroundColor Cyan
        $users = Get-ADUser -Filter * -Properties $userprops | Select-Object $userprops

        # Get groups
        Write-Host "Retrieving groups with properties: $($groupprops -join ', ')" -ForegroundColor Cyan
        $groups = Get-ADGroup -Filter * -Properties $groupprops | Select-Object $groupprops
        # Normalize objects to have the same set of properties, this is important because when we combine users and groups into a single collection for export, we need to ensure that all objects have the same set of properties, if a property is missing on an object it will be represented as null in the CSV, this allows us to have a consistent structure in the exported CSV file
        $allProps = $props
        $users = $users | ForEach-Object { # Convert to PSObject with all properties, missing properties will be null
            $obj = @{} # Create a hashtable to hold properties for this object
            foreach ($p in $allProps) { $obj[$p] = $_.$p } # Populate the hashtable with values for all properties, if a property is missing it will be null
            New-Object PSObject -Property $obj # Create a new PSObject with the complete set of properties
        }
        $groups = $groups | ForEach-Object {
            $obj = @{}
            foreach ($p in $allProps) { $obj[$p] = $_.$p }
            New-Object PSObject -Property $obj
        }

        # Combine results
        $results = $users + $groups

        # Export to CSV        
        $results | Export-Csv -Path $OutputPath -Delimiter $Delimiter -NoTypeInformation

        Write-Host "Database exported to $OutputPath"

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