# Active Directory scripting project guide

This turns the subject into a build-and-test sequence. Read [[PowerShell scripts are reusable commands]] for the language and [[Active Directory (AD)]] for the directory model.

## Required deliverables

The subject requires 19 scripts: three AD DS setup operations, two CSV operations, five user operations, and nine group operations. Every action starts in PowerShell, each script is commented, and secrets are requested through a pop-up. The shared `template.ps1` provides logging, prerequisite checks, and the masked password dialog.

## Lab topology

Use two disposable Windows Server VMs on the same private network:

| Server | Example name | Address | DNS before promotion |
| --- | --- | --- | --- |
| First DC | `DC1-ADMIN` | `192.168.1.10/24` | itself |
| Additional DC | `DC2-WORKSHOP` | `192.168.1.11/24` | first DC |

The second server must query AD DNS to discover the domain. Replace example gateway, interface, domain, and distinguished-name values with your lab values.

## Safe execution order

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Get-NetAdapter
```

On both servers, set the name and network, then install AD DS:

```powershell
.\ChangeComputerName.ps1 -ChangeComputerName 'DC1-ADMIN'
.\SetStaticIP.ps1 -IPAddress '192.168.1.10' -PrefixLength 24 `
    -DefaultGateway '192.168.1.254' -DNSGateway '127.0.0.1' -InterfaceIndex 4
.\Scripts\ADPackageInstallor.ps1
```

Create the forest only on the first server:

```powershell
.\Scripts\CreateNewForestDomainController.ps1 `
    -DomainAddress 'domolia.local' -NetbiosName 'DOMOLIA'
```

After restart, verify DNS and AD:

```powershell
Get-ADDomain
Get-ADForest
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.domolia.local
```

Point the second server's DNS to the first DC, install AD DS, promote it, and test replication:

```powershell
.\Scripts\JoinExistingDomainController.ps1 -DomainAddress 'domolia.local'
Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, Site
repadmin /replsummary
```

## Build isolated test objects

```powershell
$domainDn = (Get-ADDomain).DistinguishedName
New-ADOrganizationalUnit -Name 'ProjectUsers' -Path $domainDn
New-ADOrganizationalUnit -Name 'ProjectGroups' -Path $domainDn
$userOu = "OU=ProjectUsers,$domainDn"
$groupOu = "OU=ProjectGroups,$domainDn"

.\Scripts\CreateGroup.ps1 -GroupName 'Project-A' -OrganizationalUnit $groupOu -GroupScope Global
.\Scripts\CreateGroup.ps1 -GroupName 'Project-B' -OrganizationalUnit $groupOu -GroupScope Global
.\Scripts\UserCreation.ps1 -AccountName 'alice' -OrganizationalUnit $userOu -GroupName 'Project-A'
```

## Acceptance checklist

- [ ] AD DS and management tools install on a fresh server.
- [ ] The forest survives restart; the second DC has healthy DNS and replication.
- [ ] CSV save includes both `User` and `Group` rows; load uses the same delimiter.
- [ ] User creation produces the expected UPN/mail, enabled state, forced password change, OU, and membership.
- [ ] Password reset and attribute edit work; unknown users fail clearly.
- [ ] One-user/all-user readers return requested properties; omitted properties return all.
- [ ] Security/distribution groups have the right category, scope, OU, and description.
- [ ] Group edit, add, remove, import, member list, and information scripts produce the requested state.
- [ ] Import copies direct members without flattening nested groups.
- [ ] Each script writes a separate log under `C:\AD-Automation\Logs`.

Also test duplicates, unknown identities, removing a non-member, self-import, a nonexistent OU, and an invalid CSV path. Each should stop clearly and leave AD unchanged.


