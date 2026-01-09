# Active Discovery

This project introduces you to the basics of system administration under the Microsoft Server operating system.
In this project, you are introduced to the functionality and features of Active Directory (AD).

Here are some theory

### What is an active directory ?
why is it important ?
it is only a windows thing ?


### Requirement
In this project, you will install and configure the computer infrastructure for "Domolia," a company that specializes in selling home automation tools.
The company is divided into two buildings:
	• A workshop, managed by a supervisor, with several workers.
	• An office, where the company manager is located.
The company requires **two Microsoft Server installations**, one in each building, along with a **Windows workstation** that will connect to the respective building’s server.

what is the difference between the windows 11 workstation and windows server 2025 os ?

###### Forest creation
In this part, you have to install and configure the **server** located in the **administration** building.
The server must have the **Active Directory Domain Controller service** installed and
configured.
You need to add any necessary modules you think are required for this service.
The server must have a suitable name that allows easy identification on the network.
You should *create a forest on the server* and choose an intelligent name for it.


###### Domain controller configuration
In this part, you need to **connect the second server to the first one** in order to enable it to join the existing forest.
This server will be responsible for **hosting its own domain controller**.
Similar to the previous server, you should choose an appropriate name for this server.

###### Resources creation
In this part, you are required to create three different folders where users can store important files.
	• Create a folder on the **Administration server** specifically for storing administrative files.
	• Create another folder on the **Administration server** for storing generic data and files.
	• Lastly, create a folder on the **Workshop server** dedicated to storing working project files. (x2)
Ensure that you give clear and descriptive names to these resources so that you can easily identify the contents they hold.

###### User account creation
In this part, you need to create a user account on each of the previously created controllers.
The account on the administration server should have the ability to view and edit the administration resources folder and the generic resources folder.
On the workshop server, the account should have the capability to view and edit the working resources folder and the generic resources folder.


### Walkthrough

Since this is a farely new project from the 42 network, in our campus we still don't have access to the VM environment so we need an extra step to create it.


From what the subject is telling us, we need 2 VM of Microsoft Server and 2 Windows workstation that will connect to their respective server.

	You can get the ISO of Windows server 2025 LTS version [here](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025) and Windows 11 LTS version [here](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise)

You can then configure your vm on the manager of your choice. 
Don't forget to choose the core version (for the graphical interface) when installing your windows server !

Finish installing your 4 VM and connect to the windows server office (this may take some time). If you want, you can create partitions but it's ok if you don't. The reason we may want to create partitions would be if the files on one of our windows server get to big, where there are no removing file policy. The disk may become saturated meaning the windows server os may no longer work since they are on the same partitions. But for this project this is not really necessary.

Log in (go to input to send the ctrl+alt+sup signal) the windows manager application will appear.

From then, lets configure our forest !

##### But wait, what do we mean ? a forest ?


###### Now le'ts configure the Domain controller 


###### Let's create the appropriate folders now


###### User account creation



That's it !
That was the first project of the windows branch.


### Resources
• https://learn.microsoft.com/en-us/training/paths/administer-active-directory-domain-services/
• https://learn.microsoft.com/fr-fr/windows-server/identity/identity-and-access
• [Step by stp blog on how to configure an AD](https://www.transip.eu/knowledgebase/configuring-an-active-directory-in-windows-server-2019-or-2022)
• https://www.techtarget.com/searchwindowsserver/definition/Active-Directory-forest-AD-forest
• https://medium.com/@ademolaivamos7/building-my-homelab-part-1-setting-up-windows-server-2022-in-virtualbox-db09dfe55c4d

