<#
.SYNOPSIS
Automated Active Directory user creation script with GUI input and validation.

.DESCRIPTION
This script provides a framework for creating new Active Directory user accounts with the following features:
- Dynamic parameter configuration through a CONFIG hashtable
- Input validation with customizable rules (length, pattern, type)
- GUI form generation for interactive parameter entry
- Command-line argument support for automated deployments
- Active Directory operations including user creation, OU validation, and group membership
- Comprehensive error handling and user feedback

.PARAMETER None
This script uses dynamic parameters defined in the $CONFIG hashtable rather than formal parameters.
Configuration includes:
    - AccountName: User account name (1-20 characters, alphanumeric with dots, dashes, underscores)
    - OrganisationUnitToJoin: Target OU for user creation (required)
    - DesiredGroup: Optional group membership assignment

.EXAMPLE
# Run with GUI
.\UserCreation.ps1

# Run with command-line arguments
.\UserCreation.ps1 -AccountName "john.doe" -OrganisationUnitToJoin "Users" -DesiredGroup "MyGroup"

.NOTES
- Requires Administrator privileges for Active Directory operations
- Requires ActiveDirectory PowerShell module
- Generates a random 12-character password with special characters
- User is forced to change password on first logon
- Email is automatically set to username@domain format

.FUNCTIONALITY
1. Configuration: Define parameters with validation rules and GUI controls
2. Input Validation: Validate parameters against defined rules
3. GUI Rendering: Generate Windows Forms based on configuration
4. Execution: Create user account, validate OU, manage group membership
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
            Description = "Name of the account to be created"
            Validation = @{
                MinLength = 1
                MaxLength = 20
                Pattern = "^[a-zA-Z0-9._-]+$"
            }
            GuiControl = "TextBox"
        },
        @{
            Name = "OrganisationUnitToJoin"
            Type = "string"
            Required = $true
            Description = "Name of the organisation unit to join"
            Validation = @{
                MinLength = 1
                MaxLength = 20
                Pattern = "^(?![ #])(?!.*[ .]$)(?!.*[/\\\[\]:;|=,+*?<>""])[^/\\\[\]:;|=,+*?<>""]+$" # No leading/trailing spaces, no special characters that are not allowed in OU names
            }
            GuiControl = "TextBox"
        },
        @{
            Name = "DesiredGroup"
            Type = "string"
            Required = $false
            Description = "Name of the group to add the user to"
            Validation = @{
                MinLength = 1
                MaxLength = 20
                Pattern = "^[a-zA-Z0-9._-]+$"
            }
            GuiControl = "TextBox"
        }
    )
    
    # Main Logic Configuration, can be a script block or a reference to a function
    MainLogic = {
        param($params)
        $accountName = $params["AccountName"]
        $ou = $params["OrganisationUnitToJoin"]
        $group = $params["DesiredGroup"]        
        
        # Validate that the script is running with Administrator privileges, this is important because accessing certain Active Directory properties may require elevated permissions, and it ensures the script can run successfully without permission issues
        if (-not ([Security.Principal.WindowsPrincipal] `
           [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "This script must be run as Administrator."
            exit 1
        }

        # Import the Active Directory module
        Import-Module ActiveDirectory        

        try {
            $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
            Write-Host "Current domain: $domain" -ForegroundColor Green
        }
        catch {
            Write-Host "Error retrieving domain information: $_" -ForegroundColor Red
            exit 1        
        }

        # Validate OU exists
        $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction Stop
        if ($ouExists -ne $null) {
            $ou = $ouExists.DistinguishedName | Select-Object -First 1            
            Write-Host "OU '$ou' found." -ForegroundColor Green        
        } else {
            Write-Host "OU '$ou' not found" -ForegroundColor Red
            exit 1
        }

        # Validate user does not already exist
        $userExists = Get-ADUser -Filter "SamAccountName -eq '$accountName'" -ErrorAction Stop            
        if ($userExists -ne $null) {
            Write-Host "User '$accountName' already exists." -ForegroundColor Red
            exit 1
        } else {
            Write-Host "User '$accountName' does not exist, proceeding with creation." -ForegroundColor Green
        }                    

        # Create a secure random password
        $length = 12
        $nonAlpha = 4

        $letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
        $special = '!@#$%^&*()-_=+[]{}<>?'.ToCharArray()

        $passwordChars = @()

        # Generate random letters and numbers
        $passwordChars += 1..($length - $nonAlpha) | ForEach-Object { $letters | Get-Random }

        # Generate random special characters
        $passwordChars += 1..$nonAlpha | ForEach-Object { $special | Get-Random }

        # Shuffle the characters to ensure randomness and join them into a single string                
        $password = ($passwordChars | Get-Random -Count $length) -join ''

        #Write-Host "Generated password for user '$accountName': $password" -ForegroundColor Yellow
        Write-Host "Creating user '$accountName' in OU '$ou'..." -ForegroundColor Cyan
        
        # Convert the plain text password to a secure string, this is required by the New-ADUser cmdlet to set the account password securely, and it ensures that the password is not stored in plain text in memory
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        
        # Build the parameters hashtable for New-ADUser, using a hashtable allows us to easily manage and pass multiple parameters to the cmdlet, and it keeps the code cleaner and more maintainable
        $UserParams = @{
            Name=$accountName
            SamAccountName=$accountName
            UserPrincipalName="$accountName@$domain"
            EmailAddress="$accountName@$domain"
            AccountPassword=$securePassword
            Enabled=$true
            ChangePasswordAtLogon=$true
            Path=$ou            
            ErrorAction = "Stop"
        }
        # Create the user account with error handling, using a try-catch block allows us to handle any exceptions that may occur during user creation gracefully, and it provides feedback on what went wrong if the operation fails
        try {        
            New-ADUser @UserParams
            Write-Host "User '$accountName' created successfully in OU '$ou'." -ForegroundColor Green
            Write-Host "User needs to change password at first logon." -ForegroundColor Yellow
            Write-Host "Generated first-timepassword for user '$accountName': $password" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Error creating user: $_" -ForegroundColor Red
            exit 1
        }

        # Retrieve the created user to confirm it was created successfully and to get the user object for group membership
        try {
            $createdUser = Get-ADUser -Identity $accountName -ErrorAction Stop
            Write-Host "Retrieved created user '$accountName' successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Error retrieving created user: $_" -ForegroundColor Red
            exit 1
        }

        # If a group was specified, validate it exists and add the user to the group
        if ($group) {
            $groupObj = Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction Stop
            if ($groupObj -ne $null) {
                Write-Host "Group '$group' found." -ForegroundColor Green
            } else {
                Write-Host "Group '$group' not found. User was not added to any group." -ForegroundColor Red
                exit 1
            }
            try {
                Add-ADGroupMember -Identity $groupObj -Members $createdUser -ErrorAction Stop
                Write-Host "User '$accountName' added to group '$group' successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Error adding user to group: $_" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "No group specified, skipping group membership." -ForegroundColor Yellow
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