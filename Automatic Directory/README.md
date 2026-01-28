# Automatic Directory

Active Directory (AD) works not only through a graphical interface, as you may have experienced previously, but also efficiently through scripting using a powerful tool:[PowerShell!

In this subject, you need to create scripts for various actions you perform by clicking buttons in the [previous project](./../Active%20Discovery/README.md).
Why rely on graphical interfaces when you can achieve the same results by typing a few hundred characters and take pride in your well-crafted outcome?

- Every action in the subject/evaluation must be executed from a PowerShell terminal.
- Every script must be commented to explain what it is doing.
- You should find a way to open a pop-up and ask the user for any information they need to provide


## Table of Content



### What is powershell ?




## Mandatory
Create script for the following list of actions to automate:
	• AD installation and dependency.
	• Server promotion via forest creation.
	• Server promotion via existing domain connection.
	• Database backup.
	• Database loading.
	• User creation.
	• Reset password.
	• Modification of an attribute off a user.
	• Recovering information from a user.
	• Retrieve information from all users.
	• Creation of a group.
	• Modification of an existing group.
	• Creation of a distribution group.
	• Add a user to the group.
	• Remove a user from a group.
	• Import members of group A into group B.
	• Retrieve information from a group.
	• List the members of a group.
	• Retrieve information from all groups.

### AD installation scripts

| Name            | ADPackageInstallor.ps1                                                                  |
| --------------- | --------------------------------------------------------------------------------------- |
| **Description** | Install ActiveDirectory and every dependencies needed for the<br>domain controller role |
| **Parameter**   | none                                                                                    |

| Name            | CreateNewForestDomainController.ps1                                   |
| --------------- | --------------------------------------------------------------------- |
| **Description** | Promote an AD server to Domain Controller by creating a new<br>forest |
| **Parameter**   | - DomainAddress<br>- NetbiosName                                      |

| Name            | JoinExistingDomainController.ps1                                                              |
| --------------- | --------------------------------------------------------------------------------------------- |
| **Description** | Promote an AD server to Domain Controller by joining an<br>already existing domain controller |
| **Parameter**   | - DomainAddress                                                                               |

### Data base scripts

| Name            | SaveDataBase.ps1                                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Create a data base to store every user and group from the<br>Domain Controller                                            |
| **Parameter**   | - Path to save the result .CSV file<br>- Desired delimiter<br>- An undefined amount of parameter to compose the data base |

| Name            | LoadDataBase.ps1                                |
| --------------- | ----------------------------------------------- |
| **Description** | Load a data base from a saving file             |
| **Parameter**   | - Path to .CSV file to load<br>- File delimiter |

### User scripts

| Name            | UserCreation.ps1                                                                                                                                                                                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | In hashtable or in specification<br>We assume that<br>- mail address : name.surname@domaineName.com<br>- Basic password : TotalyN0tSecure -> Change at the first co<br>- UserPrincipalName : email address<br>The default password must not be written in clear text<br>in the script |
| **Parameter**   | - Account name<br>- Organisation Unit to join<br>- Desired group                                                                                                                                                                                                                      |

| Name            | ResetUserPassword.ps1                  |
| --------------- | -------------------------------------- |
| **Description** | Reset the password of the desired user |
| **Parameter**   | - Account name                         |

| Name            | EditUserAttribute.ps1                                     |
| --------------- | --------------------------------------------------------- |
| **Description** | Modify an attribute of the user and set it to a new value |
| **Parameter**   | - Account name<br>- Attribute name<br>- Desired value     |

| Name            | ReadUserInformation.ps1                              |
| --------------- | ---------------------------------------------------- |
| **Description** | Retreive user information from the server            |
| **Parameter**   | - Account name<br>- Filter the attribute to retreive |

| Name            | ReadDataBaseInformation.ps1                          |
| --------------- | ---------------------------------------------------- |
| **Description** | Retreive every users informations from the server    |
| **Parameter**   | - Account name<br>- Filter the attribute to retreive |

### Group scripts

| Name            | CreateGroup.ps1                                                       |
| --------------- | --------------------------------------------------------------------- |
| **Description** | Create a new group                                                    |
| **Parameter**   | - Group name<br>- Organisation unit<br>- Group scope<br>- Description |

| Name            | ModifyGroup.ps1                                              |
| --------------- | ------------------------------------------------------------ |
| **Description** | Edit a group by modifying one attribute to a desired value   |
| **Parameter**   | - Group name<br>- Attribute to edit<br>- New attribute value |

| Name            | ListUserInGroup.ps1                             |
| --------------- | ----------------------------------------------- |
| **Description** | Retreive an exaustive list of user in the group |
| **Parameter**   | - Group name                                    |

| Name            | CreateDistributionGroup.ps1                                                         |
| --------------- | ----------------------------------------------------------------------------------- |
| **Description** | Creation of a new distribution group to send emails to multi-<br>ples users at once |
| **Parameter**   | - Group name<br>- Organisation unit<br>- Group scope<br>- Description               |

| Name            | AddUserToGroup.ps1                                                                              |
| --------------- | ----------------------------------------------------------------------------------------------- |
| **Description** | Add a user to the desired group. The script should block if<br>you want to add an unknown user. |
| **Parameter**   | - User name<br>- Group name                                                                     |

| Name            | RemoveUserToGroup.ps1                                                                                                                       |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Description** | Remove a user from the desired group. The script should block<br>the deletion of an unknown user or a user who is not part of<br>the group. |
| **Parameter**   | - User name<br>- Group name                                                                                                                 |

| Name            | ImportGroup.ps1                                    |
| --------------- | -------------------------------------------------- |
| **Description** | Import the content of a group inside another group |
| **Parameter**   | - Origin group name<br>- Destination group name    |

| Name            | ReadGroupInformation.ps1                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Description** | Retreive information(s) about a group.<br>If no property name are given, the script must retreive all<br>properties |
| **Parameter**   | - Group name<br>- Optionnal : a property name                                                                       |

| Name            | ReadEveryGroupInformation.ps1                                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Description** | Retreive information(s) from every group in the domain.<br>If no property name are given, the script must retreive all<br>properties |
| **Parameter**   | - Optionnal : a property name                                                                                                        |


Phew... That's it !
Now that you know how to write automating scripts on windows, how about to dig deeper on a system admin work by learning about GPO and SIEM for analyzing event log ? Check [[Administrative Directory]] !


### Resources
- [Windows course -> Learn automate scripting with powershell](https://learn.microsoft.com/en-us/training/paths/powershell/)
- [Powershell in a month of lunches book](https://studylib.net/doc/26258040/learn-powershell-in-a-month-of-lunches-covers-windows-lin...)
- [Don Jones Toolmaking - powershell in a month of lunches playlist](https://youtube.com/playlist?list=PL6D474E721138865A)
- [John Savill’s Powershell Master Class](https://youtube.com/playlist?list=PLlVtbbG169nFq_hR7FcMYg32xsSAObuq8)
- [Powershell on AD](https://www.it-connect.fr/cours/administrer-active-directory-avec-powershell/)
- [Powershell playlist](https://www.youtube.com/watch?v=ZOoCaWyifmI&list=PLmBNQq8ckUwsGrr1JAC8Iv14usVXMBLtp) 
 - [Beginner Resources](https://www.reddit.com/r/PowerShell/wiki/beginners/)


