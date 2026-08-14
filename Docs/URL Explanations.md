# URL Explanations

Valid Redirect URIs:
 http://localhost:8080/login/saml2/sso/keycloak

Master SAML Processing URL:
 http://localhost:8080/login/saml2/sso/keycloak

Both settings point to Spring Security’s **SAML Assertion Consumer Service (ACS)** endpoint:

`http://localhost:8080/login/saml2/sso/keycloak`

But they have slightly different meanings in Keycloak.

### Master SAML Processing URL

This tells Keycloak:

> “After I authenticate the user, where should I send the SAML Response?”

In your setup:

```text
Browser
   │
   │ GET /private
   ▼
Spring Boot
   │
   │ AuthnRequest
   ▼
Keycloak
   │
   │ User logs in
   │ john / password
   │
   │ creates SAML Response
   ▼
POST http://localhost:8080/login/saml2/sso/keycloak
   │
   ▼
Spring Security
```

So:

```text
Master SAML Processing URL
=
http://localhost:8080/login/saml2/sso/keycloak
```

is essentially your application's **ACS URL**.

Spring Security listens there for the SAML response from Keycloak.

The `keycloak` at the end comes from your Spring registration ID:

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
```

So:

```text
registration ID = keycloak
                  ↓
/login/saml2/sso/keycloak
```

### Valid Redirect URIs

This is primarily a **security allowlist**.

It tells Keycloak:

> “These are the locations to which this SAML client is allowed to have authentication results sent.”

You configure:

```text
Valid Redirect URIs:

http://localhost:8080/login/saml2/sso/keycloak
```

If an incoming SAML `AuthnRequest` asks Keycloak to send the result somewhere else, such as:

```text
http://evil-site.example/steal-saml-response
```

Keycloak should not accept that as a valid destination for this client.

So you can think of the difference as:

| Setting                        | Purpose                                                         |
| ------------------------------ | --------------------------------------------------------------- |
| **Master SAML Processing URL** | Where Keycloak should normally send the SAML response           |
| **Valid Redirect URIs**        | Which response/redirect destinations Keycloak is allowed to use |

For a simple application with one ACS endpoint, it is completely normal for them to be identical:

```text
Valid Redirect URIs:
http://localhost:8080/login/saml2/sso/keycloak

Master SAML Processing URL:
http://localhost:8080/login/saml2/sso/keycloak
```

The flow becomes:

```text
Spring Boot                          Keycloak
    │                                  │
    │ AuthnRequest                     │
    │--------------------------------->│
    │                                  │
    │     AssertionConsumerServiceURL  │
    │     =                            │
    │     http://localhost:8080/       │
    │     login/saml2/sso/keycloak     │
    │                                  │
    │                           authenticate john
    │                                  │
    │           SAML Response          │
    │<---------------------------------│
    │                                  │
    ▼
/login/saml2/sso/keycloak
    │
    ▼
Spring Security validates response
    │
    ▼
User is authenticated
```

One terminology detail is useful: although Keycloak calls the field **Master SAML Processing URL**, when talking to SAML administrators you will usually hear this Spring endpoint called the **ACS URL (Assertion Consumer Service URL)**. That is the term worth remembering.

# Spring Security Default ACS (Assertion Comsumer Service) URL Pattern

Spring Security has a **default ACS URL pattern**, so normally you don't invent it yourself.

For your project, the ACS URL is:

```text
http://localhost:8080/login/saml2/sso/keycloak
```

It comes from three pieces:

```text
http://localhost:8080
        +
/login/saml2/sso/
        +
keycloak
```

The last part, `keycloak`, is your **registration ID** from `application.yml`:

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            entity-id: spring-saml-demo
            assertingparty:
              metadata-uri: http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

So:

```text
registrationId
    =
keycloak

       ↓

Default Spring ACS path
/login/saml2/sso/{registrationId}

       ↓

/login/saml2/sso/keycloak
```

With your server running on port 8080:

```text
http://localhost:8080/login/saml2/sso/keycloak
```

### The best way to verify it

Rather than calculating it manually, look at the **Spring Service Provider metadata**:

```text
http://localhost:8080/saml2/metadata/keycloak
```

Assuming you've enabled:

```java
.saml2Metadata(withDefaults())
```

you'll see XML containing something similar to:

```xml
<AssertionConsumerService
    Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    Location="http://localhost:8080/login/saml2/sso/keycloak"
    index="0"/>
```

The important part is:

```xml
<AssertionConsumerService
    Location="http://localhost:8080/login/saml2/sso/keycloak"
/>
```

That `Location` is the ACS URL you should give Keycloak.

So when configuring Keycloak, I recommend this workflow:

```text
1. Configure Spring
       ↓
2. Start Spring Boot
       ↓
3. Open Spring SP metadata
   /saml2/metadata/keycloak
       ↓
4. Find <AssertionConsumerService>
       ↓
5. Copy its Location
       ↓
6. Put that URL into Keycloak
```

For your current project, you should therefore see:

```text
Spring SP Entity ID:
spring-saml-demo

Spring ACS:
http://localhost:8080/login/saml2/sso/keycloak

Spring SP Metadata:
http://localhost:8080/saml2/metadata/keycloak

Keycloak IdP Metadata:
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

One important distinction: **don't try to open the ACS URL directly in the browser to test it**. The ACS is primarily a POST endpoint where Keycloak sends a `SAMLResponse`. Opening it with a normal browser GET isn't a valid SAML login test.

To start authentication, use:

```text
http://localhost:8080/saml2/authenticate/keycloak
```

Then Keycloak eventually POSTs the response to the ACS:

```text
http://localhost:8080/login/saml2/sso/keycloak
```

So remember the two URLs this way:

```text
/saml2/authenticate/keycloak
        ↑
Spring → Keycloak
"Please log me in"


/login/saml2/sso/keycloak
        ↑
Keycloak → Spring
"Here is the authenticated user"
```

 **`/saml2/authenticate/{registrationId}` is Spring Security's default URL for initiating SAML authentication.**

For your configuration:

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            ...
```

the registration ID is:

```text
keycloak
```

Therefore Spring Security automatically provides:

```text
/saml2/authenticate/keycloak
```

and with your application at port 8080:

```text
http://localhost:8080/saml2/authenticate/keycloak
```

### What happens when you access it?

When the browser requests:

```text
GET /saml2/authenticate/keycloak
```

Spring Security essentially does this:

```text
Browser
   │
   │ GET /saml2/authenticate/keycloak
   ▼
Spring Security
   │
   │ Find registration:
   │ "keycloak"
   │
   │ Create SAML <AuthnRequest>
   │
   │ Encode request
   │
   ▼
HTTP redirect
   │
   ▼
Keycloak SAML endpoint
   │
   ▼
Keycloak login page
```

You **do not need to create a controller** for:

```java
@GetMapping("/saml2/authenticate/keycloak")
```

Spring Security handles it internally when you configure:

```java
.saml2Login(withDefaults())
```

### Where does the default come from?

Spring Security's default authentication-request URI template is:

```text
/saml2/authenticate/{registrationId}
```

So if you had multiple IdPs:

```yaml
registration:
  keycloak:
    ...

  okta:
    ...

  azure:
    ...
```

Spring would provide:

```text
/saml2/authenticate/keycloak

/saml2/authenticate/okta

/saml2/authenticate/azure
```

Each one starts authentication using that particular `RelyingPartyRegistration`.

### Don't confuse the two Spring SAML endpoints

These two URLs have opposite purposes:

```text
START login
────────────────────────────────────────────
/saml2/authenticate/keycloak

Browser → Spring → Keycloak

Spring generates AuthnRequest


FINISH login / ACS
────────────────────────────────────────────
/login/saml2/sso/keycloak

Keycloak → Spring

Spring receives SAMLResponse
```

So the complete flow is:

```text
          (1)
Browser
   │
   │ GET
   ▼
/saml2/authenticate/keycloak
   │
   ▼
Spring Security
   │
   │ AuthnRequest
   ▼
Keycloak
   │
   │ john / password
   │
   │ SAMLResponse
   ▼
/login/saml2/sso/keycloak
   │
   │
   ▼
Spring Security
   │
   ▼
Authenticated
```

So yes: **both important URLs are Spring Security defaults**:

| Purpose                     | Default                                |
| --------------------------- | -------------------------------------- |
| Start SAML login            | `/saml2/authenticate/{registrationId}` |
| ACS / receive SAML response | `/login/saml2/sso/{registrationId}`    |

In your case `{registrationId}` is `keycloak`, which is why both URLs end with `/keycloak`.

------------------------

# Metadata URLs

Yes. Spring Security also provides default URLs for **Service Provider (SP) metadata**, but metadata is a little different from the login and ACS endpoints.

For your registration:

```yaml
spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
```

the `registrationId` is:

```text
keycloak
```

With Spring Security 6.5 and:

```java
.saml2Metadata(withDefaults())
```

the main metadata URL is:

```text
http://localhost:8080/saml2/metadata/keycloak
```

Spring Security also supports the older/alternative form:

```text
http://localhost:8080/saml2/service-provider-metadata/keycloak
```

I recommend using:

```text
http://localhost:8080/saml2/metadata/keycloak
```

### What is this metadata URL for?

Unlike:

```text
/saml2/authenticate/keycloak
```

which **performs an action** (starts login), the metadata URL **describes your Spring application as a SAML Service Provider**.

When you open:

```text
http://localhost:8080/saml2/metadata/keycloak
```

Spring generates XML approximately like:

```xml
<EntityDescriptor
    entityID="spring-saml-demo">

    <SPSSODescriptor
        protocolSupportEnumeration=
            "urn:oasis:names:tc:SAML:2.0:protocol">

        <KeyDescriptor use="signing">
            ...
            Spring's public certificate
            ...
        </KeyDescriptor>

        <AssertionConsumerService
            Binding=
                "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
            Location=
                "http://localhost:8080/login/saml2/sso/keycloak"
            index="0"/>

    </SPSSODescriptor>

</EntityDescriptor>
```

This tells Keycloak things like:

```text
Who is this Service Provider?
        ↓
entityID = spring-saml-demo

Where should SAMLResponse be sent?
        ↓
ACS = /login/saml2/sso/keycloak

What certificate does the SP use?
        ↓
<KeyDescriptor>...
```

### There are actually two metadata sides

This is important in your project:

```text
                 METADATA

Spring Boot                         Keycloak
Service Provider                    Identity Provider
     │                                    │
     │                                    │
SP Metadata                         IdP Metadata
     │                                    │
     ▼                                    ▼

http://localhost:8080/             http://localhost:8081/
saml2/metadata/keycloak            realms/saml-demo/
                                   protocol/saml/descriptor
```

They serve different purposes.

**Spring SP metadata** tells Keycloak about Spring:

```text
Spring SP Metadata
      ↓
Keycloak learns:
  • Spring entity ID
  • Spring ACS URL
  • Spring signing certificate
  • supported bindings
```

**Keycloak IdP metadata** tells Spring about Keycloak:

```text
Keycloak IdP Metadata
      ↓
Spring learns:
  • Keycloak entity ID
  • Keycloak SSO URL
  • Keycloak signing certificate
  • supported bindings
```

That's why your `application.yml` contains:

```yaml
assertingparty:
  metadata-uri:
    http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

You're telling Spring:

> Go to this Keycloak metadata URL to learn how to communicate with and trust Keycloak.

### Your four important URLs

For your project, I'd memorize these:

| Purpose                         | URL                                                               |
| ------------------------------- | ----------------------------------------------------------------- |
| **Start SAML login**            | `http://localhost:8080/saml2/authenticate/keycloak`               |
| **ACS — receive SAML response** | `http://localhost:8080/login/saml2/sso/keycloak`                  |
| **Spring SP metadata**          | `http://localhost:8080/saml2/metadata/keycloak`                   |
| **Keycloak IdP metadata**       | `http://localhost:8081/realms/saml-demo/protocol/saml/descriptor` |

And their directions are:

```text
LOGIN
Spring ── AuthnRequest ──► Keycloak

ACS
Spring ◄── SAMLResponse ── Keycloak


METADATA

Spring SP metadata
Spring ──────────────────► Keycloak
"Here is information about me"


Keycloak IdP metadata
Spring ◄────────────────── Keycloak
"Here is information about me"
```

One final difference: `/saml2/authenticate/{registrationId}`, `/login/saml2/sso/{registrationId}`, and `/saml2/metadata/{registrationId}` are **Spring Security endpoints**. The Keycloak `/realms/{realm}/protocol/saml/descriptor` URL is a **Keycloak endpoint**, not a Spring Security URL.
