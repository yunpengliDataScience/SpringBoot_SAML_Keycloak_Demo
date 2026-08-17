# Spring Boot SAML 2.0 + Standalone Keycloak Demo

A complete local demo in which:

- **Spring Boot** is the SAML 2.0 Service Provider (SP / Relying Party).
- **Keycloak** is the SAML 2.0 Identity Provider (IdP / Asserting Party).
- **No Docker or container runtime is required.**

## Software

- Java 17+ for the Spring Boot application
- Maven 3.6+
- Spring Boot 3.5.16
- Spring Security SAML2 Service Provider
- Standalone Keycloak 26.7.1 ZIP distribution: [Downloads - Keycloak](https://www.keycloak.org/downloads)

> Keycloak's current standalone getting-started guide may require a newer JDK than the Spring application. If your existing Java is too old for Keycloak, install a supported JDK and point Keycloak at it with `JAVA_HOME`. The Spring application itself only requires Java 17+.

## Architecture

```text
Browser
   |
   | GET /private
   v
Spring Boot SP :8080
   |
   | SAML AuthnRequest
   v
Keycloak IdP :8081
   |
   | User signs in
   | Signed SAML Response
   v
POST http://localhost:8080/login/saml2/sso/keycloak
   |
   v
Spring Security validates the response
and creates an authenticated HTTP session
```

# 1. Download and extract Keycloak

Download the **Keycloak Server ZIP** from the official Keycloak downloads page ([Downloads - Keycloak](https://www.keycloak.org/downloads)) and extract it somewhere on your computer.

Example Windows location:

```text
C:\tools\keycloak-26.7.1
```

Example Linux/macOS location:

```text
$HOME/tools/keycloak-26.7.1
```

The extracted directory should contain:

```text
keycloak-26.7.1/
├── bin/
│   ├── kc.bat
│   └── kc.sh
├── conf/
├── lib/
└── ...
```

# 2. Start standalone Keycloak on port 8081

This project includes convenience scripts. They intentionally start Keycloak in **development mode** and bootstrap the demo administrator as `admin / admin`.

## Windows Command Prompt

From the project directory:

```bat
set KEYCLOAK_HOME=C:\tools\keycloak-26.7.1
scripts\start-keycloak.bat
```

## Windows PowerShell

```powershell
$env:KEYCLOAK_HOME = "C:\tools\keycloak-26.7.1"
.\scripts\start-keycloak.bat
```

## Linux/macOS

```bash
export KEYCLOAK_HOME=$HOME/tools/keycloak-26.7.1
./scripts/start-keycloak.sh
```

The scripts execute the equivalent of:

### Windows

```bat
%KEYCLOAK_HOME%\bin\kc.bat start-dev ^
  --http-port=8081 ^
  --bootstrap-admin-username=admin ^
  --bootstrap-admin-password=admin
```

### Linux/macOS

```bash
$KEYCLOAK_HOME/bin/kc.sh start-dev \
  --http-port=8081 \
  --bootstrap-admin-username=admin \
  --bootstrap-admin-password=admin
```

Keycloak should now be available at:

```text
http://localhost:8081
```

Admin credentials for this demo:

```text
username: admin
password: admin
```

> These credentials and `start-dev` are only for local development/testing.

## If the bootstrap admin options do not create an administrator

This normally means the Keycloak data directory was already initialized. Open Keycloak and use the administrator that already exists, or use Keycloak's supported admin recovery/bootstrap procedure. For a brand-new extracted instance, the startup options above create the temporary bootstrap administrator on first startup.

# 3. Create the SAML realm

Open:

```text
http://localhost:8081
```

Log into **Administration Console** with `admin / admin`.

Then:

1. Open **Manage realms**.
2. Click **Create realm**.
3. Realm name: `saml-demo`
4. Click **Create**.

The SAML IdP metadata URL is now:

```text
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

The Spring application reads this metadata to discover Keycloak's issuer, SSO endpoints, bindings, and signing certificate.

# 4. Create a Keycloak test user

Inside the `saml-demo` realm:

1. Go to **Users**.
2. Click **Create new user**.
3. Username: `john`
4. Email: `john@example.com`
5. First name: `John`
6. Last name: `Smith`
7. Click **Create**.
8. Open **Credentials**.
9. Set password to `password`.
10. Set **Temporary** to **Off**.

Test login:

```text
john / password
```

# 5. Start the Spring Boot application

Open a second terminal in this project directory. Keep Keycloak running in the first terminal.

Run:

```bash
mvn spring-boot:run
```

Spring Boot starts at:

```text
http://localhost:8080
```

Important: Keycloak must be running and the `saml-demo` realm must already exist before Spring starts, because Spring loads the IdP metadata from:

```text
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

# 6. Verify Spring's Service Provider metadata

Open:

```text
http://localhost:8080/saml2/service-provider-metadata/keycloak
```

This XML describes the Spring application to Keycloak.

Important values are:

```text
SP Entity ID:
  spring-saml-demo

Assertion Consumer Service (ACS):
  http://localhost:8080/login/saml2/sso/keycloak
```

# 7. Create the SAML client in Keycloak

In the Keycloak Admin Console, make sure you are in realm:

```text
saml-demo
```

Then:

1. Open **Clients**.
2. Click **Create client**.
3. Client type/protocol: **SAML**.
4. Client ID: `spring-saml-demo`
5. Create/save the client.

The Keycloak Client ID must match Spring's SP Entity ID:

```yaml
entity-id: spring-saml-demo
```

Configure the SAML client approximately as follows:

```text
Client ID:
  spring-saml-demo

Root URL:
    http://localhost:8080
Home URL:
    http://localhost:8080

Valid Redirect URIs:
  http://localhost:8080/login/saml2/sso/keycloak

Master SAML Processing URL:
  http://localhost:8080/login/saml2/sso/keycloak

Client signature required:
  Off

Sign documents:
  On

Sign assertions:
  On

Encrypt assertions:
  Off

Keys:
    Off
```

The exact placement/names of some settings can vary slightly between Keycloak UI versions.

## Alternative: import the Spring SP metadata

Once Spring is running, open/save:

```text
http://localhost:8080/saml2/service-provider-metadata/keycloak
```

You can import that SAML Entity Descriptor into Keycloak instead of manually typing the SP metadata values. This often prevents ACS/entity-ID mistakes.

# 8. Test SAML login

Open:

```text
http://localhost:8080
```

Click **Login with Keycloak**, or open directly:

```text
http://localhost:8080/saml2/authenticate/keycloak
```

The browser flow should be:

```text
Spring Boot
    |
    | SAML AuthnRequest
    v
Keycloak login page
    |
    | john / password
    v
Keycloak
    |
    | signed SAML Response
    v
Spring ACS
http://localhost:8080/login/saml2/sso/keycloak
    |
    v
Authenticated Spring Security session
```

Then test:

```text
http://localhost:8080/private
```

and:

```text
http://localhost:8080/user
```

# Important endpoints

| Purpose               | URL                                                               |
| --------------------- | ----------------------------------------------------------------- |
| Spring application    | `http://localhost:8080`                                           |
| Protected page        | `http://localhost:8080/private`                                   |
| SAML user information | `http://localhost:8080/user`                                      |
| Start SAML login      | `http://localhost:8080/saml2/authenticate/keycloak`               |
| Spring ACS            | `http://localhost:8080/login/saml2/sso/keycloak`                  |
| Spring SP metadata    | `http://localhost:8080/saml2/service-provider-metadata/keycloak`  |
| Keycloak              | `http://localhost:8081`                                           |
| Keycloak IdP metadata | `http://localhost:8081/realms/saml-demo/protocol/saml/descriptor` |

# Spring SAML configuration

The key configuration is in:

```text
src/main/resources/application.yml
```

```yaml
server:
  port: 8080

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

Terminology:

```text
Spring Security term     SAML term             Component
-----------------------------------------------------------
Relying Party            Service Provider      Spring Boot
Asserting Party          Identity Provider     Keycloak
```

# Project structure

```text
spring-saml-keycloak/
├── pom.xml
├── README.md
├── scripts/
│   ├── start-keycloak.bat
│   └── start-keycloak.sh
└── src/
    ├── main/
    │   ├── java/com/example/samldemo/
    │   │   ├── SamlDemoApplication.java
    │   │   ├── config/SecurityConfig.java
    │   │   └── controller/HomeController.java
    │   └── resources/application.yml
    └── test/
        └── java/com/example/samldemo/SamlDemoApplicationTests.java
```

# SAML attributes

The `/user` endpoint displays the `Saml2AuthenticatedPrincipal` and its attributes.

Keycloak can send fields such as:

```text
email
firstName
lastName
roles
```

using SAML protocol mappers.

Spring can read an attribute with:

```java
String email = principal.getFirstAttribute("email");
```

and all attributes with:

```java
principal.getAttributes()
```

# Troubleshooting

## Spring startup fails with connection refused

Confirm Keycloak is running at:

```text
http://localhost:8081
```

Then confirm this URL returns XML:

```text
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

If it returns `404`, create the `saml-demo` realm first.

## Keycloak starts on port 8080 instead of 8081

Use:

```text
--http-port=8081
```

or use the included startup script.

Spring intentionally uses port `8080`, while Keycloak uses `8081`.

## Invalid destination / invalid recipient

The ACS must match exactly:

```text
http://localhost:8080/login/saml2/sso/keycloak
```

## Invalid audience

The Keycloak SAML client ID and Spring entity ID must match:

```text
spring-saml-demo
```

## Signature validation errors

Make sure Spring is reading metadata from the same Keycloak realm that is issuing the SAML response:

```text
http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

For this basic demo, leave **Client signature required** off. Keycloak can still sign its SAML response/assertion so Spring can verify the IdP.

## Port already in use

Spring uses `8080`; Keycloak uses `8081`.

To change Keycloak's port, you must also update `application.yml` and any Keycloak client URLs accordingly.

# Production note

This setup is intentionally development-oriented. For production, do not use `start-dev`, demo passwords, HTTP, or the embedded development database. Configure TLS, a production database, secure administrator credentials, hostname/proxy settings, certificate/key management, and appropriate SAML signing/encryption requirements.

----------------------------------------------

# Enable Signed AuthnRequest and Public/Private Key

To enable signed `AuthnRequest`s, Spring Boot needs its **own private key + X.509 certificate**, and Keycloak needs the matching **public certificate** so it can verify Spring’s signature. Spring Security signs `AuthnRequest`s by default when the asserting party requires it. ([Home](https://docs.spring.io/spring-security/reference/servlet/saml2/login/authentication-requests.html?utm_source=chatgpt.com "Producing <saml2:AuthnRequest>s"))

The cleanest setup is:

```text
Spring Boot
  ├─ sp-private-key.pem     ← keep secret
  └─ sp-certificate.crt     ← public

Keycloak
  └─ imports/trusts sp-certificate.crt
```

First generate a key pair. With OpenSSL:

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout sp-private-key.pem \
  -out sp-certificate.crt \
  -days 3650 \
  -nodes \
  -subj "/CN=spring-saml-demo"
```

Put both files under:

```text
src/main/resources/saml/
```

so you have:

```text
src/main/resources/saml/sp-private-key.pem
src/main/resources/saml/sp-certificate.crt
```

Then configure them in `application.yml`. Spring Boot supports signing credentials under the relying-party registration:

```yaml
server:
  port: 8080

spring:
  security:
    saml2:
      relyingparty:
        registration:
          keycloak:

            entity-id: spring-saml-demo

            signing:
              credentials:
                - private-key-location: classpath:saml/sp-private-key.pem
                  certificate-location: classpath:saml/sp-certificate.crt

            assertingparty:
              metadata-uri: http://localhost:8081/realms/saml-demo/protocol/saml/descriptor
```

Now remove this override:

```java
metadata.wantAuthnRequestsSigned(false)
```

You no longer need it.

Your Java security configuration can remain very small:

```java
package com.example.samldemo.config;

import static org.springframework.security.config.Customizer.withDefaults;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

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
}
```

Then in Keycloak, go to:

```text
Realm: saml-demo
→ Clients
→ spring-saml-demo
→ Keys
```

Enable:

```text
Client Signature Required = ON
```

When enabled, Keycloak expects documents from the SAML client to be signed and validates them. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/index.html?utm_source=chatgpt.com "Server Administration Guide"))

You also need to give Keycloak Spring’s public certificate:

```text
sp-certificate.crt
```

Depending on your Keycloak version/UI, this is done in the SAML client's **Keys / Signature and Encryption** area by importing the client certificate, or by configuring Keycloak to retrieve the SP certificate from its metadata URL. Keycloak documents both approaches. ([Keycloak](https://www.keycloak.org/docs/latest/server_admin/index.html?utm_source=chatgpt.com "Server Administration Guide"))

Do **not** give Keycloak:

```text
sp-private-key.pem
```

Only Spring should have that.

The final flow becomes:

```text
Spring Boot
    |
    | AuthnRequest
    |
    | sign with
    | sp-private-key.pem
    v
Signed AuthnRequest
    |
    v
Keycloak
    |
    | verify with
    | sp-certificate.crt
    |
    v
Accept request
```

Spring Security uses the configured signing credential specifically for signing messages like `<AuthnRequest>`. ([Home](https://docs.spring.io/spring-security/site/docs/5.4.2/reference/html5/?utm_source=chatgpt.com "Spring Security Reference"))

After restarting Spring Boot, open:

```text
http://localhost:8080/saml2/metadata/keycloak
```

Your metadata should now contain a certificate section similar to:

```xml
<KeyDescriptor use="signing">
    <KeyInfo>
        <X509Data>
            <X509Certificate>
                ...
            </X509Certificate>
        </X509Data>
    </KeyInfo>
</KeyDescriptor>
```

That certificate is Spring telling Keycloak:

> This is my public key. Use it to verify requests that I sign.

Then test:

```text
http://localhost:8080/saml2/authenticate/keycloak
```

At that point your previous:

```text
Failed to resolve any signing credential
```

should disappear, because Spring now has an actual signing private key/certificate available.
