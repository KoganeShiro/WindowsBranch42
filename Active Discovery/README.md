# Active Discovery

This project introduces you to the basics of system administration under the Microsoft Server operating system.
In this project, you are introduced to the functionality and features of Active Directory (AD).

### What is an active directory ?

**Active Directory (AD)** is Microsoft's directory service built into Windows Server. It is a centralized system that stores information about users (+ their devices like pc or printer etc..) and also handles logging in (authentication) and permissions (authorization).

**Here are the key benefits:**
- **One login, many services**: Create a user account once, use it everywhere on the network
- **Centralized management**: Manage thousands of users/computers from one place
- **Security**: Control who can access what, enforce password policies, audit activity
- **Group Policy**: Push settings, software, and scripts to all computers automatically

Although, the term **active directory** often refer to windows since it runs on a windows server, it uses open protocols ([LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol), [Kerberos](https://en.wikipedia.org/wiki/Kerberos_(protocol))...).
So there are open-source alternatives like [Samba AD DC](https://samba.tranquil.it/doc/fr/index.html) or [FreeIPA](https://www.freeipa.org/page/Main_Page) that could serve as an active directory without using windows.



### Requirement
In this project, you will install and configure the computer infrastructure for "Domolia," a company that specializes in selling home automation tools.
The company is divided into two buildings:
	• A workshop, managed by a supervisor, with several workers.
	• An office, where the company manager is located.
The company requires **two Microsoft Server installations**, one in each building, along with a **Windows workstation** that will connect to the respective building’s server.

###### Forest creation
In this part, you have to install and configure the **server** located in the **administration** building.
The server must have the **Active Directory Domain Controller service** installed and configured.
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

Finish installing your 4 VM and connect to the windows server office (this may take some time). If you want, you can create partitions but it's ok if you don't. The reason we may want to create partitions would be if the files on one of our windows server get to big, where there are no removing file policy. The disk may become saturated meaning the windows server os may no longer work since they are on the same partitions. But for this project this is not really necessary. Make sure to create a network that will link them all together. With virtualbox, go to settings>networks and create a new NAT network by clicking to file>host network manager and create a new network.
Then click on adaptater 2, enable and attached to "host only adaptater" and choose the same network name for the 4 vm.

Log in (go to input to send the ctrl+alt+sup signal) the windows manager application will appear.

From then, lets configure our forest !

##### But wait, what do we mean ? a forest ?

In Active Directory, a **forest** is the highest level of organization — it's the security and administrative boundary that contains everything in your AD infrastructure. Think of it like this:
- A **forest** is like a company
- **Domains** are like departments within that company
- **Organizational Units (OUs)** are like teams within those departments
- **Users and computers** are the actual people and equipment

When you create a forest, you're creating:
1. The **root domain** (the first domain, which becomes the forest name)
2. The **schema** (the rulebook defining what types of objects can exist: users, computers, printers, etc.)
3. The **configuration container** (settings shared across all domains in the forest)
4. **Trust relationships** (automatic two-way trusts between all domains in the forest)


**Why is it called a "forest"?** Because it can contain multiple **trees** (domain hierarchies), and trees contain **branches** (child domains). But for most organizations, you only need one tree with one domain.

To make it more concrete, we can view it if a company is based on multiple country for exemple, US and France.

The forest equal the company
	The tree or domain equal France (country)
		The branches or child domain may equal to a city
			The Organizational Units (OUs) equal to teams within those cities
				and for last we may have users and computers within those teams



The physcal architecture of the ad relies on multiple domaine controlers (dc) that syncronize data between them ensuring information consistancy. 
They handle the comuncations between domain and user.

###### Forest Architecture Options

When designing your Active Directory, you need to choose an architecture. Here are the main options:

**Option 1: Single-Domain Forest**
```
Forest: domolia.local
└── Domain: domolia.local
    ├── DC1-ADMIN (10.0.1.10) - Administration Building
    ├── DC2-WORKSHOP (10.0.2.10) - Workshop Building
    ├── OU: Administration
    │   └── User: admin.user
    ├── OU: Workshop
    │   └── User: workshop.user
    └── OU: Global Groups
        ├── GG_Admin_RW 
        ├── GG_Generic_RW
        └── GG_Projects_RW
```

**Characteristics:**
- One domain = one security boundary
- All users see each other in the Global Address List
- Simplest to manage and backup
- Multiple Domain Controllers (DCs) provide redundancy and load balancing
- Both DCs replicate the same database — if one fails, the other continues

**When to use:** Small to medium businesses (under 10,000 users), single organization, no need to delegate different IT teams, perfect for our setup


**Option 2: Multi-Domain Forest** 

```
Forest: domolia.local
├── Root Domain: domolia.local
│   └── DC1-ADMIN (HQ)
│       └── OU: Administration
└── Child Domain: workshop.domolia.local
    └── DC2-WORKSHOP
        └── OU: Workshop
```

**Characteristics:**
- Each domain has its own security boundary
- Users in workshop.domolia.local have separate passwords/policies from domolia.local
- Automatic two-way trusts between domains (users can access resources across domains)
- More complex replication (schema + configuration replicate forest-wide, but user data stays per-domain)

**When to use:** Large enterprises, separate IT teams per location, different password policies needed, political/organizational boundaries

**Option 3: Multi-Tree Forest**
```
Forest: corp.local
├── Tree 1: domolia.local
│   └── DC: HQ servers
└── Tree 2: partner-company.com (acquired company)
    └── DC: Partner servers
```

**Characteristics:**
- Different namespace trees in the same forest
- Useful after company mergers/acquisitions
- All trees share schema and configuration
- Very complex — avoid unless absolutely necessary

---

#### What We're Building: Single-Domain Forest

For Domolia, we'll use **Option 1** because:
- Small company (two buildings, few users)
- No need for separate IT administration
- Simpler disaster recovery

**Our Architecture:**
- **Forest root domain:** domolia.local
- **Domain Controllers:** 2 (one per building for redundancy)
- **Sites:** We can define two sites (Administration and Workshop) 
- **Replication:** Automatic between both DCs — any change on DC1 syncs to DC2 and vice versa

---

#### Step-by-Step: Creating the Forest on Windows Server 2025

1. **Open Server Manager** (will opens automatically on login)

2. **Add the AD DS Role:**
   - Click **Manage** (top-right) → **Add Roles and Features**
   - Click **Next** until you reach **Server Roles**
   - Check ☑ **Active Directory Domain Services**
   - A popup appears → Click **Add Features**
   - Click **Next** → **Next** → **Install**
   - Wait for installation (takes 2-3 minutes)
   - Click **Close** when done

3. **Promote to Domain Controller:**
   - You'll see a yellow warning flag (⚠️) at the top-right in Server Manager
   - Click it → Click **Promote this server to a domain controller**
   
4. **Deployment Configuration:**
   - Select ⦿ **Add a new forest**
   - **Root domain name:** `domolia.local`
     - `.local` is standard for internal domains (not accessible from internet)
   - Click **Next**

5. **Domain Controller Options:**
   - **Forest functional level:** Windows Server 2016 or higher (use highest available)
   - **Domain functional level:** Windows Server 2016 or higher
   - Keep ☑ **Domain Name System (DNS) server** checked (required)
   - Keep ☑ **Global Catalog (GC)** checked (required for first DC)
   - **DSRM Password:** Enter a strong password (used for disaster recovery mode)
     - ⚠️ **WRITE THIS DOWN** — you'll need it if AD fails
   - Click **Next**

6. **DNS Options:**
   - Warning about DNS delegation — **ignore this** (normal for new forests)
   - Click **Next**

7. **Additional Options:**
   - **NetBIOS domain name:** DOMOLIA (auto-filled, uppercase version)
   - DOMOLIA\Administrator
   - Click **Next**

8. **Paths:**
   - Accept defaults (C:\Windows\NTDS for database, C:\Windows\SYSVOL for shared files)
   - Click **Next**

9. **Review Options:**
   - Review your settings
   - Click **Next**

10. **Prerequisites Check:**
    - Wait for validation (takes 1-2 minutes)
    - Click **Install**

11. **Installation:**
    - Takes 5-10 minutes
    - Server will **automatically reboot** when done
    - ⚠️ **Do not close or interrupt**

12. **After Reboot:**
    - Log in with: **DOMOLIA\Administrator** 
    - 🎉 **Your forest is created!**


#### Verifying Your Forest

After reboot, verify everything works:

**1. Check DNS:**
```powershell
nslookup domolia.local
```
Should return your DC's IP

**2. Check Domain Controller:**
```powershell
dcdiag /v
```
Should show mostly green — some warnings are OK, no red errors

**3. Check Active Directory:**
- Open **Server Manager** → **Tools** → **Active Directory Users and Computers**
- You should see your domain: `domolia.local`
- Expand it — you'll see default OUs (Computers, Users, Domain Controllers)

**4. Check Replication (after adding second DC):**
```powershell
repadmin /replsummary
```
Should show successful replication between DCs

---

#### Connecting Windows 11 Workstation to the Domain

Once your forest is created, join the Windows 11 workstations:

**On the Windows 11 PC:**
1. **Set DNS Server:**
   - Settings → Network & Internet → Ethernet/Wi-Fi → Properties
   - DNS server: (your DC's IP)
   - Click **Save**

2. **Join Domain:**
   - Settings → System → About → **Advanced system settings**
   - Click **Computer Name** tab → **Change**
   - Select ⦿ **Domain**
   - Enter: `domolia.local`
   - Click **OK**
   - Enter credentials: `Administrator` / password
   - Domain: `DOMOLIA`
   - Click **OK** → Restart when prompted

3. **Log in with Domain Account:**
   - At login screen, click **Other user**
   - Username: `DOMOLIA\admin.user`
   - Password: (the password you set in AD)

---

###### Now le'ts configure the Domain controller 

**Step 1: Configure the first Domain Controller (Administration Building)**

Before promotion:
- Set static IP: 10.0.1.10, subnet 255.255.255.0, gateway 10.0.1.1
- Set hostname: DC1-ADMIN
- Set DNS to 127.0.0.1 (will point to itself after AD install)
- Verify time sync; install updates

1) Manage > Add Roles and Features > Role-based > AD DS (include management tools)
2) After install, click "Promote this server to a domain controller"
3) Select "Add a new forest"
   - Root domain name: **domolia.local**
   - Forest/domain functional level: Windows Server 2025 (or highest available)
   - Check "Domain Name System (DNS) server"
   - Set DSRM password (write it down securely!)
   - NetBIOS domain name: DOMOLIA (auto-filled)
   - Accept default paths; click Install (server will reboot)

After reboot, verify:
- Run `dcdiag /v` — all tests should pass (some warnings are OK)
- Open Active Directory Users and Computers — see domolia.local
- Open DNS Manager — see forward lookup zone for domolia.local
- Check Event Viewer > Windows Logs > Directory Service for errors

**Step 2: Configure the second Domain Controller (Workshop Building)**

Before promotion:
- Set static IP: 10.0.2.10, subnet 255.255.255.0, gateway 10.0.2.1
- Set hostname: DC2-WORKSHOP
- Set DNS to **10.0.1.10** (first DC's IP)
- Join the server to the **domolia.local** domain first
  - System Properties > Computer Name > Change > Domain: domolia.local
  - Use Domain Admin credentials; reboot

1) Manage > Add Roles and Features > Role-based > AD DS (include management tools)
2) After install, click "Promote this server to a domain controller"
3) Select "Add a domain controller to an existing domain"
   - Domain: domolia.local
   - Supply Domain Admin credentials
   - Check "Domain Name System (DNS) server" and "Global Catalog"
   - Set DSRM password
   - Click Install (server will reboot)

After reboot, verify:
- Both DCs show in Active Directory Sites and Services
- Run `repadmin /replsummary` on either DC — replication should be healthy
- Both DCs should have identical user/OU structures

---

###### Let's create the appropriate folders now

**Following Option A layout:** We have one domain (domolia.local) with two DCs. We'll create shares on each DC.

**On DC1-ADMIN (Administration Building) — 10.0.1.10:**

1) Create folders:
   ```powershell
   New-Item -Path "C:\Shares\Administration" -ItemType Directory
   New-Item -Path "C:\Shares\Generic" -ItemType Directory
   ```

2) Share them:
   - Right-click each folder > Properties > Sharing > Advanced Sharing
   - Share name: **Administration** and **Generic**
   - Share permissions: Everyone = Read (we'll control via NTFS)

3) Set NTFS permissions (after creating groups in next section):
   - C:\Shares\Administration: NTFS > Security > Edit > Add "DOMOLIA\GG_Admin_RW" with Modify
   - C:\Shares\Generic: NTFS > Security > Edit > Add "DOMOLIA\GG_Generic_RW" with Modify

**On DC2-WORKSHOP (Workshop Building) — 10.0.2.10:**

1) Create folder:
   ```powershell
   New-Item -Path "C:\Shares\Projects" -ItemType Directory
   ```

2) Share it:
   - Right-click > Properties > Sharing > Advanced Sharing
   - Share name: **Projects**
   - Share permissions: Everyone = Read

3) Set NTFS permissions:
   - C:\Shares\Projects: NTFS > Security > Edit > Add "DOMOLIA\GG_Projects_RW" with Modify



###### User account creation

Since we have a single domain (domolia.local), all users and groups are in one place.

**Step 1: Create Organizational Units (OUs)**

In Active Directory Users and Computers:
1) Right-click domolia.local > New > Organizational Unit
   - Name: **Administration** (uncheck "Protect from accidental deletion" for lab)
2) Create OU: **Workshop**
3) Create OU: **Groups**

**Step 2: Create Security Groups**

In the **Groups** OU, create three Global security groups:
- **GG_Admin_RW** — for Administration share access
- **GG_Generic_RW** — for Generic share access (all users)
- **GG_Projects_RW** — for Projects share access


**Step 3: Create User Accounts**

**Administration user:**
- OU: Administration
- Username: admin.user (or alice.manager)
- Member of: GG_Admin_RW, GG_Generic_RW


**Workshop user:**
- OU: Workshop
- Username: workshop.user (or bob.worker)
- Member of: GG_Projects_RW, GG_Generic_RW


**Step 4: Apply NTFS Permissions**

Now go back and set the NTFS permissions on shares (as mentioned in previous section):
- C:\Shares\Administration → GG_Admin_RW (Modify)
- C:\Shares\Generic → GG_Generic_RW (Modify)
- C:\Shares\Projects → GG_Projects_RW (Modify)

**Step 5: Test with Windows 11 Clients**

1) Join both Windows 11 clients to **domolia.local**:
   - Settings > System > About > Rename this PC (advanced) > Domain: domolia.local
   - Use Domain Admin credentials; reboot

2) Log in to the Administration client as **DOMOLIA\admin.user**:
   - Verify access to \DC1-ADMIN\Administration (Read/Write)
   - Verify access to \DC1-ADMIN\Generic (Read/Write)
   - Should NOT have write access to \DC2-WORKSHOP\Projects

3) Log in to the Workshop client as **DOMOLIA\workshop.user**:
   - Verify access to \DC2-WORKSHOP\Projects (Read/Write)
   - Verify access to \DC1-ADMIN\Generic (Read/Write)
   - Should NOT have write access to \DC1-ADMIN\Administration


That's it !
That was the first project of the windows branch, next to go [Automatic Directory]. Let's learn some powershell scripting !


### Resources
• https://learn.microsoft.com/en-us/training/paths/administer-active-directory-domain-services/
• https://learn.microsoft.com/fr-fr/windows-server/identity/identity-and-access
• [Step by stp blog on how to configure an AD](https://www.transip.eu/knowledgebase/configuring-an-active-directory-in-windows-server-2019-or-2022)
• https://www.techtarget.com/searchwindowsserver/definition/Active-Directory-forest-AD-forest
• https://medium.com/@ademolaivamos7/building-my-homelab-part-1-setting-up-windows-server-2022-in-virtualbox-db09dfe55c4d
• https://youtu.be/85-bp7XxWDQ?si=h2vBlj2WXVXqjS1U
• https://youtu.be/7xOUsirYLYU?si=dGb7gVPXpzg-4N_q
• https://youtube.com/playlist?list=PLQ6jKtBHSpE8C6zLCPDbLjqX4PyC0-qKe&si=edEjfQw_OEdIvLdW
• https://youtu.be/ADakXsa8ry8?si=LPoj8pBEMbREDG1H
