<#
| Name            | [JoinExistingDomainController.ps1](./Scripts/JoinExistingDomainController.ps1)                |
| --------------- | --------------------------------------------------------------------------------------------- |
| **Description** | Promote an AD server to Domain Controller by joining an<br>already existing domain controller |
| **Parameter**   | - DomainAddress    
#>

# add a paramater if local or distant

Set hostname: DC2-WORKSHOP
Set static IP: 192.168.1.11, subnet 255.255.255.0, gateway 192.168.1.1
Set DNS to 192.168.1.10 (first DC's IP)
Join the server to the domolia.local domain first 

DC1-ADMIN (192.168.1.10)
    DNS: localhost
DC2-WORKSHOP (192.168.1.11)
    DNS: DC1-ADMIN