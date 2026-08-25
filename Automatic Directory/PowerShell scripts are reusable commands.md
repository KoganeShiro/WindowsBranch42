---
Categories: Computer_Science
Tags: [Computer_Science, PowerShell, System_Administration]
Source(s):
  - "[[PowerShell scripts are reusable commands#Resources]]"
Start_Date: 2026-08-24
Edit_Date: 2026-08-24
Related:
  - "[[Windows cmd vs terminal vs powershell]]"
  - "[[Active Directory (AD)]]"
  - "[[Windows Server]]"
---

## TLDR

A PowerShell script is a saved command pipeline. A reliable script declares inputs, validates assumptions, calls cmdlets with named parameters, stops on errors, and returns objects another command can use.

## What is a PowerShell script?

### Definition

A `.ps1` file contains PowerShell statements. Unlike a traditional shell, PowerShell sends structured **objects** through the pipeline instead of only text.

```powershell
Get-ADUser -Filter * |
    Where-Object Enabled |
    Select-Object Name, SamAccountName
```

The commands filter user objects and select their properties; they do not parse printed columns.

### My Definition

A script turns a manual procedure into a repeatable command with a contract: inputs, effects, output, errors, and verification.

## How to create a PowerShell script

### 1. Define the contract

Write down what changes, parameters, prerequisites, output, and a command that proves it worked. Use a verb-noun filename such as `AddUserToGroup.ps1`.

### 2. Declare and validate parameters

```powershell
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,

    [ValidateSet('Global', 'Universal', 'DomainLocal')]
    [string]$GroupScope = 'Global'
)
```

Types and validation reject bad input at the boundary. Double-quoted strings expand variables; single-quoted strings do not.

### 3. Check prerequisites and state

```powershell
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Get-ADUser -Identity $AccountName -ErrorAction SilentlyContinue)) {
    throw "User '$AccountName' does not exist."
}
```

Checking first makes failures understandable and helps make scripts **idempotent**: repeating one should preserve the intended state or fail clearly.

### 4. Perform one focused operation

```powershell
try {
    Add-ADGroupMember -Identity $GroupName -Members $AccountName -ErrorAction Stop
}
catch {
    Write-Error "Could not add the user: $($_.Exception.Message)"
    throw
}
```

Prefer complete cmdlet and parameter names in scripts. Aliases make saved code harder to understand.

### 5. Return objects and document decisions

Emit useful objects and use logs for progress. Leave `Format-Table` to the caller because formatting normally ends the pipeline. Add comment help with `.SYNOPSIS`, `.PARAMETER`, and `.EXAMPLE`. Explain why checks exist rather than narrating syntax.

### 6. Parse, analyze, and test

```powershell
$errors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    '.\MyScript.ps1', [ref]$null, [ref]$errors
)
$errors
Invoke-ScriptAnalyzer -Path '.\MyScript.ps1' -Recurse
```

Test in a disposable VM with known fixtures, expected failures, and a verification command. `-WhatIf` is reliable only if the script correctly implements `SupportsShouldProcess`.

## Security habits

- Elevate only when needed.
- Prefer signed scripts or `Set-ExecutionPolicy -Scope Process RemoteSigned` for a temporary lab; avoid machine-wide `Unrestricted`.
- Accept passwords as `SecureString` or through `Get-Credential` and never log them.
- Base64 and XOR are obfuscation, not encryption. This project uses reversible obfuscation only because its subject demands a fixed default password that cannot appear literally.
- Use a disposable AD lab and never commit real directory data or credentials.

## Syntax worth remembering

| Syntax | Meaning |
| --- | --- |
| `$name` | variable |
| `@(...)` | array |
| `@{ Key = 'Value' }` | hashtable |
| `$_` | current pipeline object |
| `|` | pass objects to the next command |
| `.` plus a path | dot-source functions into the current scope |
| `&` | execute a command or script block |

Use splatting for readable calls with many parameters:

```powershell
$parameters = @{
    Identity = $GroupName
    Members = $AccountName
    ErrorAction = 'Stop'
}
Add-ADGroupMember @parameters
```

## In Summary

A useful script has a narrow purpose, validated inputs, prerequisite checks, predictable errors, object output, safe secrets, and a repeatable verification step.

## Resources

- [Microsoft Learn: about scripts](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_scripts)
- [Microsoft Learn: about functions](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions)
- [Microsoft Learn: error handling](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)
- [Microsoft Learn: Active Directory module](https://learn.microsoft.com/powershell/module/activedirectory/)

