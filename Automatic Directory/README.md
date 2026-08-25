# Automatic Directory

Active Directory (AD) works not only through a graphical interface, as you may have experienced previously, but also efficiently through scripting using a powerful tool: PowerShell!

In this subject, you need to create scripts for various actions you perform by clicking buttons in the [previous project](./../Active%20Discovery/README.md).
Why rely on graphical interfaces when you can achieve the same results by typing a few hundred characters and take pride in your well-crafted outcome?


- Every action in the subject/evaluation must be executed from a PowerShell terminal.
- Every script must be commented to explain what it is doing.
- You should find a way to open a pop-up and ask the user for any information they need to provide



## Table of Content
- [What is powershell ?](#what-is-powershell-)
- [Walkthrough](#walkthrough)
- [Mandatory](#mandatory)
	- [AD installation scripts](#ad-installation-scripts)
	- [Data base scripts](#data-base-scripts)
	- [User scripts](#user-scripts)
	- [Group scripts](#group-scripts)
- [Resources](#resources)


### What is powershell ?
PowerShell is a command-line shell and scripting language developed by Microsoft. It is designed for system administrators and power users to automate tasks and manage configurations on Windows. Providing a powerful and flexible environment for executing commands, creating scripts, and managing various aspects of the Windows ecosystem.
We will be using PowerShell to automate the configuration of our Active Directory server and the management of users and groups on it. By writing scripts, we can perform tasks more efficiently and consistently, reducing the chances of human error and saving time in the long run.

## Walkthrough
Since this is a fairely new project from the 42 network, in our campus we still don't have access to the VM environment so we need an extra step to create it.

Since this project is about doing the same as the previous one but with scripts, we need to create the same environment as before, which is 2 windows server (2025 LTS version) but i don't think the workstations are necessary since we could just prove that our scripts did in fact work.
> You can get the ISO of Windows server 2025 LTS version [here](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025)

You can then configure your vm on the manager of your choice. 
Don't forget to choose the **desktop version** (for the graphical interface) when installing your windows server !

You can finish installing your 2 server VM.
	If you want, you can create partitions but it's ok if you don't. The reason we may want to create partitions would be if the files on one of our windows server get to big, where there are no removing file policy. The disk may become saturated meaning the windows server os may no longer work since they are on the same partitions. But for this project this is not really necessary.

Make sure to create a network that will link them all together. With virtualbox, go to `settings>networks` and create a new NAT network by clicking to `file>host network manager` and create a new network.
Then click on `adapter 2`, enable and attached to "`host only adapter`" and choose the same network name for the 2 vm.

Log in (go to input to send the ctrl+alt+sup signal) the windows manager application will appear.
If you ever have some update, it could be good to install them !

From then, lets create our script to automate the configuration of our AD server and the management of users and groups on it !
Click on each script to see what it does, comments will be there to explain how it works and how to use it. You can also check the resources at the end of this readme if you want to learn more about powershell.

## Mandatory
Create script for the following list of actions to automate:
- AD installation and dependency.
- Server promotion via forest creation.
- Server promotion via existing domain connection.
- Database backup.
- Database loading.
- User creation.
- Reset password.
- Modification of an attribute off a user.
- Recovering information from a user.
- Retrieve information from all users.
- Creation of a group.
- Modification of an existing group.
- Creation of a distribution group.
- Add a user to the group.
- Remove a user from a group.
- Import members of group A into group B.
- Retrieve information from a group.
- List the members of a group.
- Retrieve information from all groups.

Run the terminal as Administrator. For a temporary lab session, allow local scripts only in the current PowerShell process:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Do not permanently set the machine to `Unrestricted`. Follow [PROJECT-GUIDE.md](./PROJECT-GUIDE.md), and read [[PowerShell scripts are reusable commands]] for the scripting concepts.

Get-WinEvent -LogName "Directory Service" -MaxEvents 30 

Get-DnsClientServerAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.10
ipconfig /flushdns
Restart-Service netlogon
klist purge
### AD installation scripts

| Name            | [ADPackageInstallor.ps1](./Scripts/ADPackageInstallor.ps1)                              |
| --------------- | --------------------------------------------------------------------------------------- |
| **Description** | Install ActiveDirectory and every dependencies needed for the domain controller role |
| **Parameter**   | none                                                                                    |

| Name            | [CreateNewForestDomainController.ps1](./Scripts/CreateNewForestDomainController.ps1) |
| --------------- | --------------------------------------------------------------------- 				 |
| **Description** | Promote an AD server to Domain Controller by creating a new forest 				 |
| **Parameter**   | - DomainAddress - NetbiosName                                      				 |

| Name            | [JoinExistingDomainController.ps1](./Scripts/JoinExistingDomainController.ps1)                |
| --------------- | --------------------------------------------------------------------------------------------- |
| **Description** | Promote an AD server to Domain Controller by joining an already existing domain controller |
| **Parameter**   | - DomainAddress                                                                               |

### Data base scripts

| Name            | [SaveDataBase.ps1](./Scripts/SaveDataBase.ps1)                                    |
| --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Create a data base to store every user and group from the Domain Controller                                            |
| **Parameter**   | - Path to save the result .CSV file - Desired delimiter - An undefined amount of parameter to compose the data base |

| Name            | [LoadDataBase.ps1](./Scripts/LoadDataBase.ps1)  |
| --------------- | ----------------------------------------------- |
| **Description** | Load a data base from a saving file             |
| **Parameter**   | - Path to .CSV file to load - File delimiter |


### User scripts

| Name            | [UserCreation.ps1](./Scripts/UserCreation.ps1)                      |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | In hashtable or in specification We assume that - mail address : name.surname@domaineName.com - Basic password : TotalyN0tSecure -> Change at the first co - UserPrincipalName : email address The default password must not be written in clear text in the script |
| **Parameter**   | - Account name - Organisation Unit to join - Desired group                                                                                                                                                                                                                      |

| Name            | [ResetUserPassword.ps1](./Scripts/ResetUserPassword.ps1)                  |
| --------------- | -------------------------------------- |
| **Description** | Reset the password of the desired user |
| **Parameter**   | - Account name                         |

| Name            | [EditUserAttribute.ps1](./Scripts/EditUserAttribute.ps1)                                     |
| --------------- | --------------------------------------------------------- |
| **Description** | Modify an attribute of the user and set it to a new value |
| **Parameter**   | - Account name - Attribute name - Desired value     |

| Name            | [ReadUserInformation.ps1](./Scripts/ReadUserInformation.ps1)                              |
| --------------- | ---------------------------------------------------- |
| **Description** | Retreive user information from the server            |
| **Parameter**   | - Account name - Filter the attribute to retreive |

| Name            | [ReadDataBaseInformation.ps1](./Scripts/ReadDataBaseInformation.ps1)                          |
| --------------- | ---------------------------------------------------- |
| **Description** | Retreive every users informations from the server    |
| **Parameter**   | - Account name - Filter the attribute to retreive |


### Group scripts

| Name            | [CreateGroup.ps1](./Scripts/CreateGroup.ps1)                                                       |
| --------------- | --------------------------------------------------------------------- |
| **Description** | Create a new group                                                    |
| **Parameter**   | - Group name - Organisation unit - Group scope - Description |

| Name            | [ModifyGroup.ps1](./Scripts/ModifyGroup.ps1)                                              |
| --------------- | ------------------------------------------------------------ |
| **Description** | Edit a group by modifying one attribute to a desired value   |
| **Parameter**   | - Group name - Attribute to edit - New attribute value |

| Name            | [ListUserInGroup.ps1](./Scripts/ListUserInGroup.ps1)                             |
| --------------- | ----------------------------------------------- |
| **Description** | Retreive an exaustive list of user in the group |
| **Parameter**   | - Group name                                    |

| Name            | [CreateDistributionGroup.ps1](./Scripts/CreateDistributionGroup.ps1)                                  |
| --------------- | ----------------------------------------------------------------------------------- |
| **Description** | Creation of a new distribution group to send emails to multi- ples users at once |
| **Parameter**   | - Group name - Organisation unit - Group scope - Description               |

| Name            | [AddUserToGroup.ps1](./Scripts/AddUserToGroup.ps1)                          |
| --------------- | ----------------------------------------------------------------------------------------------- |
| **Description** | Add a user to the desired group. The script should block if you want to add an unknown user. |
| **Parameter**   | - User name - Group name                                                                     |

| Name            | [RemoveUserToGroup.ps1](./Scripts/RemoveUserToGroup.ps1)                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Remove a user from the desired group. The script should block the deletion of an unknown user or a user who is not part of the group. |
| **Parameter**   | - User name - Group name                                                                                                                 |

| Name            | [ImportGroup.ps1](./Scripts/ImportGroup.ps1)                                    |
| --------------- | -------------------------------------------------- |
| **Description** | Import the content of a group inside another group |
| **Parameter**   | - Origin group name - Destination group name    |

| Name            | [ReadGroupInformation.ps1](./Scripts/ReadGroupInformation.ps1)                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Description** | Retreive information(s) about a group. If no property name are given, the script must retreive all properties |
| **Parameter**   | - Group name - Optionnal : a property name                                                                       |

| Name            | [ReadEveryGroupInformation.ps1](./Scripts/ReadEveryGroupInformation.ps1)                     |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Description** | Retreive information(s) from every group in the domain. If no property name are given, the script must retreive all properties |
| **Parameter**   | - Optionnal : a property name                                                                                                        |


Phew... That's it !
Now that you know how to write automating scripts on windows, how about to dig deeper on a system admin work by learning about GPO and SIEM for analyzing event log ? Check [[Administrative Directory]] !


### Resources
- https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2025-ps
- https://www.it-connect.fr/cours/administrer-active-directory-avec-powershell/
- https://openclassrooms.com/en/courses/7938616-planifiez-vos-taches-avec-des-scripts-powershell-sur-windows-server/8094005-automatisez-la-configuration-d-active-directory-avec-powershell
- https://youtu.be/-zDXTLiX_wk?si=St8MwIu7vUfke8E5
- [Windows course -> Learn automate scripting with powershell](https://learn.microsoft.com/en-us/training/paths/powershell/)
- [Powershell in a month of lunches book](https://studylib.net/doc/26258040/learn-powershell-in-a-month-of-lunches-covers-windows-lin...)
- [Don Jones Toolmaking - powershell in a month of lunches playlist](https://youtube.com/playlist?list=PL6D474E721138865A)
- [John Savill’s Powershell Master Class](https://youtube.com/playlist?list=PLlVtbbG169nFq_hR7FcMYg32xsSAObuq8)
- [Powershell on AD](https://www.it-connect.fr/cours/administrer-active-directory-avec-powershell/)
- [Powershell playlist](https://www.youtube.com/watch?v=ZOoCaWyifmI&list=PLmBNQq8ckUwsGrr1JAC8Iv14usVXMBLtp) 
 - [Beginner Resources](https://www.reddit.com/r/PowerShell/wiki/beginners/)
