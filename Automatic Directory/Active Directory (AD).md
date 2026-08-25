---
Categories:
Tags:
  - Notes-Taking/InWritting
Source(s):
  - "[[Active Directory (AD)#Resources]]"
Start_Date: 
Edit_Date: 
Related:
---



## What is Active Directory?

### Definition

**Active Directory (AD)** is a distributed directory service that provides **centralized identity, authentication, authorization, and resource management** for Windows-based networks, built on [[LDAP]], [[Kerberos (protocol)]], and [[DNS]].

It acts as the **authoritative source of truth** for *who* users and machines are and *what* they are allowed to do.

---

## Active Directory Conceptual Graph (Explained)

```
Active Directory
│
├── Protocols
│   ├── LDAP
│   ├── Kerberos
│   └── DNS
│
├── Logical Structure
│   ├── Forest
│   ├── Domain
│   ├── OU (Organizational Unit)
│   └── Objects
│
├── Physical Structure
│   ├── Domain Controllers
│   ├── Replication
│   └── Sites
│
├── Security Model
│   ├── Users
│   ├── Groups
│   ├── SIDs
│   └── ACLs
│
└── Client Interaction
    ├── Domain Join
    ├── Authentication
    └── Resource Access
```

### How to Read This Graph (Important)

This is **not a hierarchy of importance**.
It is a **layered dependency graph**.

Think in layers:

1. **Protocols** – *How AD communicates*
2. **Logical Structure** – *How identity is organized*
3. **Physical Structure** – *Where authority lives*
4. **Security Model** – *How access decisions are made*
5. **Client Interaction** – *How users experience AD*

Each layer depends on the ones above it.

---

### Protocols (Foundation Layer)

* [[LDAP]] → Directory queries (read/write objects)
* [[Kerberos (protocol)]] → Authentication (prove identity)
* [[DNS]] → Service discovery (find domain controllers)

> Without protocols, AD cannot be contacted or trusted.

---

### Logical Structure (Identity Modeling Layer)

* **Forest** → Ultimate trust + schema boundary
* **Domain** → Security and policy boundary
* **OU** → Administrative grouping (not security boundary)
* **Objects** → Users, computers, groups, printers, etc.

> This layer answers: *How is identity conceptually organized?*

---

### Physical Structure (Authority Layer)

* **Domain Controllers** → Servers that enforce AD
* **Replication** → Keeps DCs consistent
* **Sites** → Optimize replication and authentication by network topology

> This layer answers: *Where does AD actually run?*

---

### Security Model (Decision Layer)

* **Users / Groups** → Who
* **SIDs** → Immutable identities
* **ACLs** → What is allowed

> This layer answers: *Who can do what?*

---

### Client Interaction (Experience Layer)

* **Domain Join** → Establish trust
* **Authentication** → Prove identity
* **Resource Access** → Enforce permissions

> This layer answers: *What does the user experience?*

---

## Forest, Domain, Domain Controller (Core Concepts)

### Forest

A **forest** is the **top-level security boundary** in Active Directory.
It defines:

* A **shared schema**
* A **shared configuration**
* **Automatic, transitive trust** between domains

A forest is the **maximum scope of implicit trust**.

---

### Domain

A **domain** is a **security and policy boundary**.
It:
* Has its own directory database
* Applies authentication and authorization rules
* Uses a DNS namespace

Domains share schema within a forest but **enforce policies independently**.

---

### Domain Controller

A **domain controller (DC)** is an **active authority**, not a backup.

It:

* Authenticates users and computers
* Issues authorization tokens
* Stores and replicates directory data

Multiple DCs form a **multi-master system**.

---

## My Definition

**Active Directory** is a centralized identity infrastructure that defines trust, authority, and access across an organization.

* **Forest** → The maximum trust boundary
* **Domain** → A security and policy boundary
* **Domain Controller** → The authority that enforces identity and access

---

## Why is Active Directory important?

* Eliminates local user silos
* Enforces consistent security
* Enables scalability and fault tolerance
* Separates **identity** from **devices**

Without AD:

* Each computer becomes its own security authority
* Permissions cannot scale
* Central policy enforcement is impossible

---

## Why should I learn Active Directory?

* It underpins enterprise Windows networks
* It teaches **IAM**, **RBAC**, and **trust modeling**
* Cloud identity systems inherit its logic
* It builds intuition for distributed authority systems

---

## When will I need Active Directory?

* Enterprise networks
* Hybrid cloud environments
* Security engineering
* Identity troubleshooting
* Multi-site organizations

---

## How does Active Directory work?

### Authentication and Authorization Flow

```
User logs in →
  Domain Controller authenticates →
    Security token issued →
      Resource checks ACL →
        Access granted or denied
```

### Discovery Flow

```
Client →
  DNS SRV lookup →
    Domain Controller found →
      Kerberos authentication begins
```

DNS provides **service discovery**, not just name resolution.

---

## In Summary

Active Directory is a **distributed identity system** built on strict separation of concerns:

| Component | Purpose                      |
| --------- | ---------------------------- |
| Forest    | Trust + schema boundary      |
| Domain    | Security and policy boundary |
| DC        | Authentication authority     |
| DNS       | Discovery                    |
| Kerberos  | Authentication               |
| LDAP      | Directory access             |

---

## Understanding Questions — Answered
### Why is identity management separate from file storage?
Because identity must remain consistent even if resources move, change servers, or go offline.

### What breaks if each computer manages its own users?
* No centralized revocation
* No consistent permissions
* No scalability
* Massive security risk

### Why can’t AD just use IP addresses?
* IPs change
* AD needs to discover *services*, not machines
* Kerberos requires DNS for trust establishment

### What happens if two DCs exist but DNS points to only one?
* Authentication still works (partially)
* Load balancing fails
* Failover becomes unreliable
* Replication issues may go unnoticed

### Can you be authenticated but unauthorized?
Yes. Authentication proves *who you are*; authorization decides *what you can access*.

### Why are permissions not checked during login?
Because permissions depend on **which resource is accessed**, not just who logs in.

### NTFS vs Share Permissions (Conceptual)
* **Share permissions** → Network-level gate
* **NTFS permissions** → File-system-level control
  Effective permission = **most restrictive combination**

### What does transitive trust mean?
Trust automatically extends through domain relationships inside a forest.

### Why does a forest have a schema?
The schema ensures **object consistency** across all domains.

### What is the Global Catalog?
A partial replica of all objects across domains, enabling **fast cross-domain searches**.


## Flashcards (Refined)

* **AD** → Distributed identity infrastructure
* **Forest** → Ultimate trust + schema boundary
* **Domain** → Security boundary
* **OU** → Administrative grouping
* **DC** → Authentication authority
* **LDAP** → Directory access
* **Kerberos** → Authentication protocol
* **DNS** → Service discovery
* **SID** → Immutable identity
* **ACL** → Permission list
* **Token** → Authorization proof
* **Global Catalog** → Cross-domain lookup accelerator


## Other Notes

> [!IMPORTANT]
> Active Directory is fundamentally about **authority and trust**, not convenience.

> [!WARNING]
> DNS misconfiguration is the leading cause of AD failures.

> [!CAUTION]
> Treating DCs as backups leads to authentication outages.

## Resources
* [https://en.wikipedia.org/wiki/Active_Directory](https://en.wikipedia.org/wiki/Active_Directory)
