<#
| Name            | [SetStaticIP.ps1](./SetStaticIP.ps1)                                            |
| --------------- | ------------------------------------------------------------------------------- |
| **Description** | Set static ip configuration to be able to join the domain                       |
| **Parameter**   | -IPAddress
                    -PrefixLength
                    -DefaultGateway
                    -DNSGateway
                    -DNSAlternateGateway
                    -InterfaceIndex        |


Execute this script on both servers to set a static IP configuration that will allow them to join the domain:
```powershell
Z:\SetStaticIP.ps1 -IPAddress "192.168.1.10" -PrefixLength 24 -DNSGateway "127.0.0.1" -DNSAlternateGateway "192.168.1.11" -InterfaceIndex 4  -DefaultGateway "192.168.1.254"
Z:\SetStaticIP.ps1 -IPAddress "192.168.1.11" -PrefixLength 24 -DNSAlternateGateway "127.0.0.1" -DNSGateway "192.168.1.10" -InterfaceIndex 5  -DefaultGateway "192.168.1.254"
```
#>
param (
    [Parameter(Mandatory = $false)]
    [string]$IPAddress,

    [Parameter(Mandatory = $false)]
    [int]$PrefixLength,

    [Parameter(Mandatory = $false)]
    [string]$DefaultGateway,

    [Parameter(Mandatory = $false)]
    [string]$DNSGateway,

    [Parameter(Mandatory = $false)]
    [string]$DNSAlternateGateway,

    [Parameter(Mandatory = $true)]
    [int]$InterfaceIndex,

    [switch]$SkipAdminCheck
)

# Dot source the template for common functions and variables
. $PSScriptRoot\template.ps1

try {
    Assert-Admin -Skip:$SkipAdminCheck
    Write-Log -Message "[Set Static IP] Running as $env:USERNAME on $env:COMPUTERNAME"

    Invoke-ScriptAction -ActionName 'Set Static IP Address' -Action {
        if (-not $InterfaceIndex -or $InterfaceIndex -eq 0) {
            $InterfaceIndex = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).ifIndex
        }
        if (-not $PrefixLength -or $PrefixLength -eq 0) {
            $PrefixLength = 24
        }
        
        if ($IPAddress) {
            New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway
            Write-Log -Message "Static IP $IPAddress (Prefix $PrefixLength) set on interface $InterfaceIndex."
        } else {
            Write-Log -Message "No IPAddress provided. Skipping static IP configuration."
        }
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
