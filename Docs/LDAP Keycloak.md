Yes. In Keycloak, Active Directory is usually configured through **User Federation → LDAP**. Keycloak has a built-in LDAP/AD provider, so your Spring Boot application can keep using SAML exactly as it does now while Keycloak authenticates users against AD. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

For your setup, the architecture would be:

```text
Spring Boot
http://localhost:9091
      │
      │ SAML
      ▼
Keycloak
Realm: MySecurityRealm
https://localhost:9991
      │
      │ LDAP / LDAPS
      ▼
Microsoft Active Directory
      │
      ├── john
      ├── mary
      └── AD groups
```

In Keycloak Admin Console, select:

```text
Realm:
MySecurityRealm

→ User Federation
→ Add LDAP providers
```

Then configure the LDAP provider approximately like this for a typical AD domain such as `mycompany.local`:

```text
Vendor:
Active Directory

Connection URL:
ldap://adserver.mycompany.local:389
```

For encrypted LDAP, which is preferable outside a lab:

```text
ldaps://adserver.mycompany.local:636
```

Then configure the bind account. For example:

```text
Bind DN:
CN=keycloak-service,CN=Users,DC=mycompany,DC=local

Bind Credential:
********
```

The bind account is simply an AD account Keycloak uses to search the directory. It normally does **not** need to be a Domain Administrator.

For the directory tree, you might use:

```text
Users DN:
CN=Users,DC=mycompany,DC=local
```

or, if your organization stores users under an OU:

```text
OU=Employees,DC=mycompany,DC=local
```

For Active Directory, typical LDAP attribute settings are:

```text
Username LDAP attribute:
sAMAccountName

RDN LDAP attribute:
cn

UUID LDAP attribute:
objectGUID

User Object Classes:
person, organizationalPerson, user
```

If users log in as:

```text
john
```

then `sAMAccountName` is usually the right username attribute.

If instead you want them to log in using:

```text
john@mycompany.com
```

you may prefer:

```text
userPrincipalName
```

depending on your AD design.

After entering the connection settings, use Keycloak's buttons such as:

```text
Test connection
```

and:

```text
Test authentication
```

The first verifies that Keycloak can reach the domain controller. The second verifies that the bind DN and password work.

Once those succeed, save the provider.

For your first setup, I would enable:

```text
Import Users:
ON
```

That means Keycloak imports an AD user's profile into Keycloak the first time the user is found or logs in, while the password continues to be validated against AD. Keycloak can also synchronize users periodically. The Keycloak documentation recommends doing an initial **Synchronize all users**, then using periodic changed-user synchronization if needed. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

After saving, you'll see synchronization controls such as:

```text
Synchronize all users

Synchronize changed users
```

Run:

```text
Synchronize all users
```

Then look at:

```text
Users
```

and you should start seeing AD users.

Keycloak automatically creates several LDAP mappers. For Active Directory you'll commonly see mappings equivalent to:

```text
AD attribute       Keycloak attribute
----------------------------------------
sAMAccountName  →  username
givenName       →  firstName
sn              →  lastName
mail            →  email
```

Keycloak supports additional LDAP mappers, including group mapping and an AD-specific user account mapper. The Microsoft AD mapper can interpret attributes such as `userAccountControl` and `pwdLastSet`, for example to reflect disabled accounts or expired-password conditions. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

This is useful for your Spring SAML project because your flow then becomes:

```text
Browser
   │
   ▼
Spring Boot
   │
   │ AuthnRequest
   ▼
Keycloak
   │
   │ username/password
   ▼
Active Directory
   │
   │ validate credentials
   ▼
Keycloak
   │
   │ SAMLResponse
   ▼
Spring Boot
```

Spring does **not** need to know anything about LDAP or Active Directory. It still just trusts Keycloak:

```text
Spring Security
      │
      │ SAML
      ▼
Keycloak
```

and Keycloak handles:

```text
Keycloak
      │
      │ LDAP
      ▼
Active Directory
```

That separation is one of the main advantages of using Keycloak.

Since you're also experimenting with **smart-card authentication**, AD can fit into that same design very nicely:

```text
Smart Card
    │
    │ X.509
    ▼
Keycloak
    │
    │ certificate identifies user
    ▼
Active Directory
    │
    │ locate user's directory account
    ▼
Keycloak
    │
    │ SAMLResponse
    ▼
Spring Boot
```

Keycloak even provides an LDAP **Certificate Mapper** specifically for combining X.509 authentication with LDAP-backed users. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

A realistic configuration for you would therefore be:

```text
Keycloak Realm:
MySecurityRealm

User Federation:
Corporate-AD
    Vendor = Active Directory
    URL = ldaps://domain-controller:636
    Users DN = OU=Users,DC=company,DC=com
    Username = sAMAccountName

Authentication:
Browser flow
    ├── Cookie
    ├── X509/Validate Username Form
    └── Username Password Form

Client:
SpringBoot_SAML_App
```

That gives you both possibilities:

```text
smart card → AD user → SAML
```

and, if you keep fallback enabled:

```text
AD username/password → SAML
```

One recommendation: keep a **local Keycloak administrator account** that is not stored in AD. Keycloak's documentation specifically recommends this because if AD/LDAP becomes unavailable, you still need a way to administer the realm. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

If you give me your AD details in a non-sensitive form, for example:

```text
Domain:
example.local

Domain controller:
dc01.example.local

Users OU:
OU=Employees,DC=example,DC=local
```

I can show you the **exact Keycloak field-by-field values** to enter for your `MySecurityRealm`.
