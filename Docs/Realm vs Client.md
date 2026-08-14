# Realm vs Client

In Keycloak, **Realm** and **Client** represent two very different levels of configuration.

For your Spring Security SAML project, think of it like this:

```text
Keycloak
│
├── Realm: master
│
│   └── Keycloak administration
│
└── Realm: saml-demo
    │
    ├── Users
    │   ├── john
    │   ├── mary
    │   └── ...
    │
    ├── Roles
    │
    └── Clients
        │
        └── spring-saml-demo
              │
              └── represents your Spring Boot application
```

### Realm

A **Realm** is an isolated security domain inside Keycloak.

Your realm is:

```text
saml-demo
```

It contains and manages things such as users, credentials, roles, groups, authentication policies, and clients.

So when you create:

```text
Realm: saml-demo

User:
    john
    password
```

`john` belongs to the `saml-demo` realm.

That's why your Keycloak URLs contain the realm name:

```text
http://localhost:8081/realms/saml-demo/...
                              ^^^^^^^^^
                                 realm
```

For example, the IdP metadata URL is:

```text
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

A different realm would be a different authentication domain. For example:

```text
Keycloak
│
├── Realm: employees
│     ├── john
│     ├── mary
│     └── employee applications
│
└── Realm: customers
      ├── customer1
      ├── customer2
      └── customer applications
```

Users and configuration are generally isolated between these realms.

### Client

A **Client** represents an application or service that uses Keycloak for authentication.

In your case:

```text
Client:
spring-saml-demo
```

represents:

```text
Your Spring Boot application
http://localhost:8080
```

Since you're using SAML:

```text
Spring Boot                      Keycloak
    │                               │
    │                               │
    │       represented by          │
    ├──────────────────────────────►│
    │                               │
    │                         Client
    │                    spring-saml-demo
```

The Keycloak client tells Keycloak things such as:

```text
What application is this?
        ↓
Client ID / Entity ID
spring-saml-demo


What protocol does it use?
        ↓
SAML


Where can I send the SAMLResponse?
        ↓
http://localhost:8080/login/saml2/sso/keycloak


Does this application sign AuthnRequests?
        ↓
Signature configuration


What certificate belongs to this application?
        ↓
Spring SP certificate
```

So the **client is Keycloak's representation of your Spring application**.

### How they fit together in your project

Your structure is:

```text
Keycloak
│
└── Realm
    saml-demo
       │
       ├── User
       │     john
       │
       │     password
       │
       └── Client
             spring-saml-demo
                   │
                   │ represents
                   ▼
             Spring Boot
             localhost:8080
```

When `john` logs into your Spring application:

```text
1. Browser
      │
      ▼
   Spring Boot

2. Spring:
   "Authenticate using Keycloak"

      │ AuthnRequest
      ▼

3. Keycloak realm:
   saml-demo

      │
      ├── Which application?
      │
      └── Client: spring-saml-demo

4. Keycloak:
   "Who is the user?"

      │
      └── User: john

5. john enters password

6. Keycloak authenticates john

7. Keycloak creates SAMLResponse

      │
      ▼

8. Spring ACS
   /login/saml2/sso/keycloak
```

The distinction worth remembering is:

| Keycloak concept | Represents                          | In your project    |
| ---------------- | ----------------------------------- | ------------------ |
| **Realm**        | Security/user domain                | `saml-demo`        |
| **Client**       | Application using Keycloak          | `spring-saml-demo` |
| **User**         | Person/account being authenticated  | `john`             |
| **Protocol**     | How client and Keycloak communicate | SAML 2.0           |

One terminology trap: **Keycloak "Client" does not mean the user's browser.** In Keycloak terminology, your Spring Boot application is the client. In SAML terminology, that same application is the **Service Provider (SP)** or **Relying Party (RP)**.

So all three refer to the same application from different viewpoints:

```text
Your Spring Boot application

Spring Security calls it:
    Relying Party (RP)

SAML calls it:
    Service Provider (SP)

Keycloak calls it:
    Client
```

That mapping is especially useful when reading Spring Security and Keycloak documentation side-by-side.

----------------------------------------------------------

# Applications (Service Providers) are Clients under the same Realm



You make the second Spring Boot application another **SAML client / Service Provider** in the **same Keycloak realm**.

Then SSO works because both applications trust the same Keycloak IdP, and the browser already has a Keycloak login session.

Suppose you have:

```text
App 1:
http://localhost:8080
Client ID / Entity ID:
spring-app-1

App 2:
http://localhost:8082
Client ID / Entity ID:
spring-app-2

Keycloak:
http://localhost:8081

Realm:
saml-demo
```

In Keycloak, the structure becomes:

```text
Keycloak
└── Realm: saml-demo
    ├── User: john
    │
    ├── Client: spring-app-1
    │      └── represents Spring Boot App 1
    │
    └── Client: spring-app-2
           └── represents Spring Boot App 2
```

Each Spring application has its **own SAML client configuration**, but both point to the same Keycloak realm.

For App 1:

```yaml
server:
  port: 8080

spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            entity-id: spring-app-1
            assertingparty:
              metadata-uri: http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

For App 2:

```yaml
server:
  port: 8082

spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            entity-id: spring-app-2
            assertingparty:
              metadata-uri: http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

Then create two SAML clients in Keycloak.

For App 1:

```text
Client ID:
spring-app-1

Valid Redirect URI:
http://localhost:8080/login/saml2/sso/keycloak

Master SAML Processing URL:
http://localhost:8080/login/saml2/sso/keycloak
```

For App 2:

```text
Client ID:
spring-app-2

Valid Redirect URI:
http://localhost:8082/login/saml2/sso/keycloak

Master SAML Processing URL:
http://localhost:8082/login/saml2/sso/keycloak
```

The SSO flow is the important part.

First the user opens App 1:

```text
Browser
   |
   | GET App 1
   v
Spring App 1
   |
   | AuthnRequest
   v
Keycloak
   |
   | No existing Keycloak session
   |
   v
Login page

john / password
   |
   v
Keycloak session created
   |
   | SAMLResponse
   v
Spring App 1

User is logged into App 1
```

At this point there are actually two sessions:

```text
Browser
│
├── Spring App 1 session
│      JSESSIONID
│
└── Keycloak SSO session
       Keycloak cookies
```

Now the user opens App 2:

```text
Browser
   |
   | GET App 2
   v
Spring App 2
   |
   | AuthnRequest
   v
Keycloak
```

But Keycloak sees:

```text
Browser already has
Keycloak SSO session
```

so it does **not** need to show:

```text
username:
password:
```

again.

Instead:

```text
Spring App 2
      |
      | AuthnRequest
      v
Keycloak
      |
      | "This browser already authenticated as john"
      |
      | immediately generates SAMLResponse
      v
Spring App 2 ACS
      |
      v
User logged into App 2
```

That is the **Single Sign-On** part.

So the complete behavior looks like:

```text
                  Keycloak
                 saml-demo
                    │
           ┌────────┴────────┐
           │                 │
           │                 │
        App 1              App 2
     spring-app-1       spring-app-2
     localhost:8080     localhost:8082


FIRST APPLICATION

Browser ───────► App 1
                   │
                   │ AuthnRequest
                   ▼
                Keycloak
                   │
              LOGIN REQUIRED
                   │
             john/password
                   │
                   ▼
             Keycloak session
                   │
                   │ SAMLResponse
                   ▼
                 App 1
                   │
               logged in


SECOND APPLICATION

Browser ───────► App 2
                   │
                   │ AuthnRequest
                   ▼
                Keycloak
                   │
             existing session!
                   │
             NO LOGIN SCREEN
                   │
                   │ SAMLResponse
                   ▼
                 App 2
                   │
               logged in
```

One thing that is easy to misunderstand is that App 1 does **not** share its Spring `JSESSIONID` with App 2.

You don't have:

```text
App 1 Spring session
      ↓
shared with
      ↓
App 2
```

Instead:

```text
App 1                    App 2
  │                        │
  │ own session            │ own session
  │                        │
  └────────┐      ┌────────┘
           │      │
           ▼      ▼
            Keycloak
            SSO session
```

Each application establishes its own local authenticated Spring Security session after receiving its own SAML assertion.

The thing enabling SSO is the **Keycloak browser session**.

For example:

```text
Browser cookies

localhost:8080:
    JSESSIONID=AAA
    → App 1 login session

localhost:8082:
    JSESSIONID=BBB
    → App 2 login session

localhost:8081:
    Keycloak session cookies
    → Central SSO session
```

That's why Keycloak is acting as the central SSO authority.

Also, both applications don't have to use exactly the same user attributes. You can configure different SAML mappings per Keycloak client:

```text
spring-app-1
    ↓
username
email
department


spring-app-2
    ↓
username
email
roles
groups
```

Even though both authenticate the same `john` user.

A good real-world architecture is therefore:

```text
                         Keycloak
                      Corporate Realm
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
   HR Application     Payroll App      Reporting App
    SAML Client        SAML Client       SAML Client
         │                 │                 │
         └─────────────────┴─────────────────┘
                     same SSO session
```

The first application prompts for login. After that, opening the other applications can authenticate transparently through Keycloak.

One additional topic is **Single Logout (SLO)**. SSO and SLO are separate. Logging out of App 1 does not automatically guarantee logout from App 2 unless you configure SAML Single Logout and Keycloak session handling appropriately. That would be the natural next part to add to your demo.



---------------------------------------------------

**Is Client an Application (Service Provider)?**



Exactly. In your **Keycloak + SAML** setup, a Keycloak **Client represents an application**, and in SAML terminology that application is usually the **Service Provider (SP)**.

So for your project:

```text
Keycloak terminology        SAML terminology       Actual system
───────────────────────────────────────────────────────────────
Client                      Service Provider (SP)   Spring Boot App
Identity Provider           IdP                     Keycloak
Realm                       Security domain         saml-demo
User                        Subject                 john
```

For example:

```text
Keycloak
└── Realm: saml-demo
    │
    ├── User: john
    │
    ├── Client: spring-app-1
    │      ↓
    │   Spring Boot App 1
    │   SAML Service Provider
    │
    └── Client: spring-app-2
           ↓
        Spring Boot App 2
        SAML Service Provider
```

So when you create this in Keycloak:

```text
Client ID: spring-app-1
Client type/protocol: SAML
```

you are essentially telling Keycloak:

> "`spring-app-1` is an application that will use me as its SAML Identity Provider."

One small terminology nuance: **"client" is Keycloak's general term**, because Keycloak supports protocols other than SAML, especially OpenID Connect (OIDC). With SAML, the Keycloak client corresponds to an **SP**. With OIDC, the application is normally called an **OIDC Client** or **Relying Party**.

For your current project, it's safe to remember:

**Keycloak Client = Spring application = SAML Service Provider (SP).**
