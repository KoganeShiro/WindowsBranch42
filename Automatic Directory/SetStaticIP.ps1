<#
| Name            | [SetStaticIP.ps1](./SetStaticIP.ps1)                                            |
| --------------- | ------------------------------------------------------------------------------- |
| **Description** | Set static ip configuration to be able to join the domain                       |
| **Parameter**   | -IPAddress, -PrefixLength, -DefaultGateway, -DNSGateway, -InterfaceIndex        |
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$IPAddress,

    [Parameter(Mandatory = $false)]
    [int]$PrefixLength = 24,

    [Parameter(Mandatory = $true)]
    [string]$DefaultGateway,

    [Parameter(Mandatory = $false)]
    [string]$DNSGateway,

    [Parameter(Mandatory = $false)]
    [string]$DNSAlternateGateway,

    [Parameter(Mandatory = $false)]
    [int]$InterfaceIndex = 12,

    [switch]$SkipAdminCheck
)

# Dot source the template for common functions and variables
. $PSScriptRoot\template.ps1

try {
    Assert-Admin -Skip:$SkipAdminCheck
    Write-Log -Message "Running as $env:USERNAME on $env:COMPUTERNAME"

    Invoke-ScriptAction -ActionName 'Set Static IP Address' -Action {
        New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway
        Write-Log -Message "Static IP $IPAddress (Prefix $PrefixLength) set on interface $InterfaceIndex."
    }

    if (-not [string]::IsNullOrEmpty($DNSGateway)) {
        Invoke-ScriptAction -ActionName 'Set DNS Servers' -Action {
            $dnsServers = @($DNSGateway)
            if (-not [string]::IsNullOrEmpty($DNSAlternateGateway)) {
                $dnsServers += $DNSAlternateGateway
            }
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $dnsServers
            Write-Log -Message "DNS servers updated on interface $InterfaceIndex."
        }
    }

    Invoke-ScriptAction -ActionName 'Verify New IP Configuration' -Action {
        Get-NetIPConfiguration -InterfaceIndex $InterfaceIndex
    }
}
catch {
    Write-Log -Message $_.Exception.Message -Level 'ERROR'
    throw
}