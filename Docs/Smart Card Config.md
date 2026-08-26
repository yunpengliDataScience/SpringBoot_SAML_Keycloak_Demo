For a smart-card login, the clean architecture is:

```text
Smart Card
   │
   │ X.509 client certificate
   ▼
Browser
   │
   │ mutual TLS / client certificate
   ▼
Keycloak
   │
   │ authenticates certificate
   │ maps certificate → Keycloak user
   ▼
SAML Response
   │
   ▼
Spring Boot
```

The important point is: **Spring Boot does not normally authenticate the smart card directly** in this design. Keycloak performs the smart-card/X.509 authentication, then Spring continues to receive a normal SAML assertion. Spring Security stays your SAML Service Provider. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

For your current configuration, that means:

```text
Spring Boot:
http://localhost:9091

Keycloak:
https://localhost:9991

Realm:
MySecurityRealm

SAML Client:
SpringBoot_SAML_App
```

The major change is that Keycloak must use **HTTPS**, because browser smart-card authentication relies on TLS client certificates. Plain HTTP cannot carry a TLS client certificate.

### 1. Configure Keycloak HTTPS and trust the smart-card CA

Your smart-card certificate is normally issued by an organization/enterprise CA. Keycloak must trust that CA.

Conceptually:

```text
Smart card certificate
        │
        │ issued by
        ▼
Organization CA
        │
        │ trusted by
        ▼
Keycloak truststore
```

For a direct Keycloak connection, you would start Keycloak with its HTTPS server certificate plus a truststore containing the CA certificates that issued the user smart cards. Keycloak supports requiring client authentication with:

```text
--https-client-auth=required
```

and a truststore via:

```text
--https-trust-store-file=...
```

Keycloak's documentation describes client-certificate authentication at the TLS layer and its X.509 certificate lookup support. ([Keycloak](https://www.keycloak.org/server/haproxy-reencrypt?utm_source=chatgpt.com "HAProxy with TLS re-encrypt - Keycloak"))

A conceptual Windows startup looks like:

```bat
call "%KEYCLOAK_HOME%\bin\kc.bat" start ^
  --https-port=9991 ^
  --https-certificate-file=C:\certs\keycloak.crt ^
  --https-certificate-key-file=C:\certs\keycloak.key ^
  --https-client-auth=required ^
  --https-trust-store-file=C:\certs\smartcard-truststore.p12
```

You would no longer use:

```text
http://localhost:9991
```

but:

```text
https://localhost:9991
```

### 2. Configure an X.509 authentication flow in Keycloak

In:

```text
MySecurityRealm
→ Authentication
→ Flows
```

duplicate the built-in **Browser** flow.

For example name it:

```text
Smart Card Browser
```

Then add the execution:

```text
X509/Validate Username Form
```

Keycloak's documented procedure is to duplicate the Browser flow, add `X509/Validate Username Form`, place it above Browser Forms, and set it as `ALTERNATIVE` if you want certificate authentication alongside another login mechanism. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

A flow allowing smart card or password might look like:

```text
Smart Card Browser
│
├── Cookie                         ALTERNATIVE
│
├── X509/Validate Username Form    ALTERNATIVE
│
└── Browser Forms                  ALTERNATIVE
      └── Username Password Form
```

That means:

> Use an existing Keycloak session if available; otherwise try the smart card; otherwise fall back to username/password.

If you want **smart card only**, you can make the X.509 path required and remove or disable the password path.

For a first test, I recommend keeping password fallback until the certificate flow works.

### 3. Configure how the certificate maps to a Keycloak user

Keycloak has to answer:

> This certificate belongs to which Keycloak user?

It supports several identity sources, including Subject DN, email in the certificate, Subject Alternative Name email, UPN, Common Name, serial number, certificate thumbprint, and others. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

Suppose your smart card certificate contains:

```text
Subject:
CN=John Smith,
OU=Employees,
O=Example Corp,
E=john@example.com
```

You could configure:

```text
User Identity Source:
Subject's email

User Mapping Method:
Username or Email
```

Then if Keycloak has:

```text
User:
john

Email:
john@example.com
```

Keycloak can map:

```text
smart card certificate
email = john@example.com
       │
       ▼
Keycloak user
john
```

Another common enterprise approach is using a certificate UPN such as:

```text
john@example.com
```

from the Subject Alternative Name.

For federal/PIV/CAC-style smart cards, mapping by UPN, subject DN, or a stable certificate-related attribute is often more appropriate than simply using CN.

### 4. Consider bypassing the confirmation screen

By default, after finding the certificate, Keycloak may show a page asking the user to confirm the identified account.

The X.509 authenticator has a setting:

```text
Bypass identity confirmation
```

If enabled, Keycloak signs the mapped user in immediately after successful certificate authentication. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

For true seamless SSO, you'd commonly want:

```text
Bypass identity confirmation = ON
```

after you've validated that your mapping is reliable.

Then the experience becomes:

```text
User inserts smart card
       │
       ▼
Open Spring application
       │
       ▼
Redirect to Keycloak
       │
       ▼
Browser presents certificate
       │
       ▼
Keycloak validates certificate
       │
       ▼
Keycloak maps cert → john
       │
       ▼
No username/password
       │
       ▼
SAMLResponse
       │
       ▼
Spring logged in
```

### 5. Bind your new browser flow

After creating and configuring the flow:

```text
Authentication
→ Flows
→ Smart Card Browser
→ Action
→ Bind flow
```

Bind it as the realm's:

```text
Browser flow
```

Now SAML authentication requests coming from `SpringBoot_SAML_App` will use this browser authentication flow.

### 6. Your Spring Boot configuration changes very little

Your Spring application still uses SAML:

```yaml
server:
  port: 9091

spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:
            entity-id: SpringBoot_SAML_App

            assertingparty:
              metadata-uri:
                https://localhost:9991/realms/MySecurityRealm/protocol/saml/descriptor
```

Notice the change from:

```text
http://localhost:9991
```

to:

```text
https://localhost:9991
```

Your Spring Security code can remain:

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http)
        throws Exception {

    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers(
                "/",
                "/error",
                "/saml2/metadata/**"
            ).permitAll()
            .anyRequest().authenticated()
        )

        .saml2Login(withDefaults())

        .saml2Metadata(withDefaults());

    return http.build();
}
```

Spring does not need something like:

```java
.x509(...)
```

for this architecture, because **Keycloak is doing X.509 authentication**.

Spring only receives:

```text
SAMLResponse
```

and processes it normally. ([Home](https://docs.spring.io/spring-security/reference/servlet/saml2/login/authentication.html?utm_source=chatgpt.com "Authenticating <saml2:Response>s :: Spring Security"))

### 7. What changes in the authentication sequence?

Your current flow is:

```text
Browser
   │
   ▼
Spring
   │
   │ AuthnRequest
   ▼
Keycloak
   │
   ▼
Username/password
   │
   ▼
Keycloak
   │
   │ SAMLResponse
   ▼
Spring
```

Smart-card flow becomes:

```text
Browser
   │
   ▼
Spring :9091
   │
   │ AuthnRequest
   ▼
Keycloak :9991
   │
   │ TLS CertificateRequest
   ▼
Browser / Smart Card
   │
   │ client certificate
   │
   │ user may enter smart-card PIN
   ▼
Keycloak
   │
   ├── validate certificate chain
   ├── check expiration
   ├── optionally check CRL / OCSP
   ├── extract certificate identity
   └── map identity → Keycloak user
   │
   │ SAMLResponse
   ▼
Spring ACS
/login/saml2/sso/keycloak
   │
   ▼
Authenticated Spring session
```

The smart-card **PIN is not the same as a Keycloak password**.

Typically the PIN unlocks use of the private key stored on the smart card:

```text
Smart Card
│
├── Certificate          public
│
└── Private key          never leaves card
        │
        │ unlocked by PIN
        ▼
TLS client authentication
```

Keycloak never needs the user's private key.

### 8. SSO still works across multiple Spring applications

Suppose you have:

```text
Spring App 1
Spring App 2
       │
       └────── same Keycloak MySecurityRealm
```

The first application causes the smart-card authentication:

```text
App 1
  ↓
Keycloak
  ↓
smart card
  ↓
Keycloak session established
```

Then the second application redirects to Keycloak:

```text
App 2
  ↓
Keycloak
  ↓
existing Keycloak SSO session
  ↓
immediate SAMLResponse
  ↓
App 2 authenticated
```

So the user doesn't have to type username/password, and normally won't need to repeat certificate selection/PIN while the relevant browser/smart-card session remains usable.

### 9. If Keycloak is behind a reverse proxy

This becomes particularly important for smart cards.

The most secure setup is:

```text
Browser
    │
    │ TLS + client cert
    ▼
Keycloak
```

If you're using a proxy:

```text
Browser
    │
    │ TLS + smart card cert
    ▼
NGINX / Apache / HAProxy
    │
    ▼
Keycloak
```

the proxy may terminate TLS, which means Keycloak cannot directly see the browser certificate.

In that case the proxy has to securely forward certificate information, and Keycloak needs the appropriate `x509cert-lookup` provider. Keycloak has providers for NGINX, Apache, HAProxy, Traefik, Envoy, and RFC 9440-compatible proxies. ([Keycloak](https://www.keycloak.org/server/reverseproxy?utm_source=chatgpt.com "Configuring a reverse proxy - Keycloak"))

Keycloak specifically warns that forwarding certificates through HTTP headers is security-sensitive. If possible, TLS passthrough is preferred for X.509 authentication because it prevents forged certificate headers. ([Keycloak](https://www.keycloak.org/server/reverseproxy?utm_source=chatgpt.com "Configuring a reverse proxy - Keycloak"))

### 10. Recommended configuration for your demo

I would build it in two stages:

```text
Stage 1

Smart card / certificate
        OR
username/password
```

Use:

```text
X509/Validate Username Form    ALTERNATIVE
Browser Forms                  ALTERNATIVE
```

Verify that your smart card maps correctly to your `john` or enterprise user.

Then move to:

```text
Stage 2

Smart card only
```

with:

```text
X509/Validate Username Form    REQUIRED
```

and remove the password fallback if that's your security requirement.

Also enable the checks appropriate for your PKI, such as expiration, KeyUsage/ExtendedKeyUsage, and potentially CRL or OCSP revocation checking. Keycloak's X.509 authenticator supports those validations. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/?utm_source=chatgpt.com "Server Administration Guide"))

For your existing Spring SAML project, **almost all of the work is on the Keycloak/TLS side; Spring remains essentially unchanged**.
