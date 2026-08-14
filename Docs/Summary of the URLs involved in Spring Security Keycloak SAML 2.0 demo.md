# Summary of the **important URLs involved in your Spring Security ↔ Keycloak SAML 2.0 demo**.

## Overall architecture

```text
                     SAML 2.0

     Spring Boot                       Keycloak
   Service Provider                 Identity Provider
        (SP)                             (IdP)
         │                                 │
         │                                 │
         ├────── AuthnRequest ────────────►│
         │                                 │
         │          User Login             │
         │                                 │
         │◄────── SAMLResponse ────────────┤
         │                                 │
         ▼
   Authenticated User
```

Your servers are:

```text
Spring Boot:  http://localhost:8080
Keycloak:     http://localhost:8081
```

And your Spring registration ID is:

```yaml
registration:
  keycloak:
```

Therefore `{registrationId}` = `keycloak`.

---

## 1. Spring: Start SAML Login

```text
http://localhost:8080/saml2/authenticate/keycloak
```

General Spring Security pattern:

```text
/saml2/authenticate/{registrationId}
```

### Purpose

This is where the **browser starts SAML authentication**.

For example, your HTML contains:

```html
<a href="/saml2/authenticate/keycloak">
    Login with Keycloak
</a>
```

The flow is:

```text
Browser
   │
   │ GET
   ▼
/saml2/authenticate/keycloak
   │
   ▼
Spring Security
   │
   │ Creates <AuthnRequest>
   │
   ▼
Redirect to Keycloak
```

Spring Security handles this endpoint. You do **not** create a controller for it.

---

## 2. Keycloak: SAML SSO Endpoint

The browser is redirected to Keycloak's SAML endpoint:

```text
http://localhost:8081/realms/saml-demo/protocol/saml
```

General Keycloak pattern:

```text
/realms/{realm}/protocol/saml
```

For your realm:

```text
realm = saml-demo
```

therefore:

```text
http://localhost:8081/realms/saml-demo/protocol/saml
```

### Purpose

Keycloak receives Spring's:

```xml
<AuthnRequest>
```

and authenticates the user.

For example:

```text
john
password
```

The interaction is:

```text
Spring
   │
   │ AuthnRequest
   ▼
Keycloak SAML endpoint
   │
   ▼
Keycloak Login Page
   │
   │ john/password
   ▼
Authentication successful
```

Normally you don't hard-code this URL into your Spring application because Spring discovers it from **Keycloak's IdP metadata**.

---

## 3. Spring: ACS URL

After successful authentication, Keycloak sends the SAML response to:

```text
http://localhost:8080/login/saml2/sso/keycloak
```

General Spring Security pattern:

```text
/login/saml2/sso/{registrationId}
```

This is called the:

**ACS — Assertion Consumer Service URL**

### Purpose

It receives:

```xml
<SAMLResponse>
    <Assertion>
       ...
    </Assertion>
</SAMLResponse>
```

from Keycloak.

```text
Keycloak
    │
    │ POST SAMLResponse
    ▼
http://localhost:8080/login/saml2/sso/keycloak
    │
    ▼
Spring Security
    │
    ├── Verify signature
    ├── Verify issuer
    ├── Verify audience
    ├── Verify expiration
    ├── Read NameID
    ├── Read attributes
    │
    ▼
Authenticated
```

This is the URL you configure in Keycloak as:

```text
Valid Redirect URIs:

http://localhost:8080/login/saml2/sso/keycloak
```

and:

```text
Master SAML Processing URL:

http://localhost:8080/login/saml2/sso/keycloak
```

---

## 4. Spring: Service Provider Metadata

```text
http://localhost:8080/saml2/metadata/keycloak
```

General pattern:

```text
/saml2/metadata/{registrationId}
```

You enable this in Spring Security with:

```java
.saml2Metadata(withDefaults())
```

### Purpose

This URL tells other SAML systems:

> Here is information about my Spring Boot Service Provider.

The XML contains information such as:

```xml
<EntityDescriptor entityID="spring-saml-demo">

    <SPSSODescriptor>

        <KeyDescriptor use="signing">
            ...
        </KeyDescriptor>

        <AssertionConsumerService
            Location=
            "http://localhost:8080/login/saml2/sso/keycloak"/>

    </SPSSODescriptor>

</EntityDescriptor>
```

Keycloak can learn from it:

```text
Spring Entity ID
        ↓
spring-saml-demo

Spring ACS
        ↓
http://localhost:8080/login/saml2/sso/keycloak

Spring certificate
        ↓
<KeyDescriptor>
```

So this URL describes **Spring to Keycloak**.

---

## 5. Keycloak: Identity Provider Metadata

```text
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

General Keycloak pattern:

```text
/realms/{realm}/protocol/saml/descriptor
```

This is the URL you've configured in Spring:

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:

            entity-id: spring-saml-demo

            assertingparty:
              metadata-uri:
                http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

### Purpose

It does the opposite of Spring metadata.

It tells Spring:

> Here is information about the Keycloak Identity Provider.

For example, it contains:

```text
Keycloak Entity ID
Keycloak SSO endpoint
Keycloak signing certificate
supported SAML bindings
```

Conceptually:

```text
Keycloak IdP Metadata
        │
        ▼
Spring learns

"What is Keycloak's Entity ID?"

"Where do I send AuthnRequest?"

"What certificate should I use
to verify Keycloak's signatures?"
```

---

# The five important URLs

For your demo, this is the table I'd keep as a reference:

| URL                                                               | Owned by | Purpose                            |
| ----------------------------------------------------------------- | -------- | ---------------------------------- |
| `http://localhost:8080/saml2/authenticate/keycloak`               | Spring   | Start SAML login                   |
| `http://localhost:8081/realms/saml-demo/protocol/saml`            | Keycloak | Receive AuthnRequest / perform SSO |
| `http://localhost:8080/login/saml2/sso/keycloak`                  | Spring   | ACS: receive SAMLResponse          |
| `http://localhost:8080/saml2/metadata/keycloak`                   | Spring   | Spring SP metadata                 |
| `http://localhost:8081/realms/saml-demo/protocol/saml/descriptor` | Keycloak | Keycloak IdP metadata              |

The easiest way to remember them is:

```text
START LOGIN
Spring
/saml2/authenticate/keycloak

              │
              │ AuthnRequest
              ▼

KEYCLOAK LOGIN
Keycloak
/realms/saml-demo/protocol/saml

              │
              │ SAMLResponse
              ▼

FINISH LOGIN / ACS
Spring
/login/saml2/sso/keycloak
```

And separately:

```text
              METADATA

Spring SP                         Keycloak IdP

/saml2/metadata/keycloak         /realms/saml-demo/
                                 protocol/saml/descriptor

        │                               │
        │ "About Spring"                │ "About Keycloak"
        │                               │
        └──────────── exchange ─────────┘
```

## Which URLs do you configure manually?

This distinction is useful.

**In Spring `application.yml`:**

```yaml
assertingparty:
  metadata-uri:
    http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

Spring reads that metadata and discovers Keycloak's SAML SSO configuration.

**In Keycloak's SAML client:**

```text
Client ID:
spring-saml-demo

Valid Redirect URIs:
http://localhost:8080/login/saml2/sso/keycloak

Master SAML Processing URL:
http://localhost:8080/login/saml2/sso/keycloak
```

Or, instead of manually entering the SP information, you can use Spring's metadata:

```text
http://localhost:8080/saml2/metadata/keycloak
```

to describe the Spring SP.

So conceptually, the two metadata URLs make configuration easier:

```text
Spring needs to know about Keycloak
              │
              ▼
Keycloak IdP Metadata


Keycloak needs to know about Spring
              │
              ▼
Spring SP Metadata
```

And the two most important **runtime** URLs are:

```text
Spring → Keycloak:

/saml2/authenticate/keycloak
          ↓
creates AuthnRequest


Keycloak → Spring:

/login/saml2/sso/keycloak
          ↓
receives SAMLResponse
```

Those four concepts—**Login Initiation, IdP SSO Endpoint, ACS, and SP/IdP Metadata**—cover most of the URLs you'll encounter when debugging this Spring Security + Keycloak SAML setup.
