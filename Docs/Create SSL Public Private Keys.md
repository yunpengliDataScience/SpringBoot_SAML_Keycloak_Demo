

`keycloak.crt` and `keycloak.key` are the **TLS server certificate and matching private key for the Keycloak HTTPS server**. They are not normally files that Keycloak generates for you automatically.

For your local Windows demo, the easiest approach is to create a **self-signed certificate with OpenSSL**. For production, you would normally obtain a certificate from your organization's CA or another trusted CA. Keycloak supports a PEM certificate plus PEM private key through `--https-certificate-file` and `--https-certificate-key-file`. ([Keycloak](https://www.keycloak.org/server/enabletls?utm_source=chatgpt.com "Configuring TLS - Keycloak"))

### 1. Create the certificate and key

If OpenSSL is installed, create a directory such as:

```bat
mkdir C:\keycloak-certs
cd C:\keycloak-certs
```

Then run:

```bat
openssl req ^
  -newkey rsa:2048 ^
  -nodes ^
  -keyout keycloak.key ^
  -x509 ^
  -days 365 ^
  -out keycloak.crt ^
  -subj "/CN=localhost"
```

This produces:

```text
C:\keycloak-certs\
    keycloak.crt
    keycloak.key
```

The relationship is:

```text
keycloak.key
    │
    │ Private key
    │ KEEP SECRET
    │
    └──────┐
           │ matching pair
    ┌──────┘
    │
keycloak.crt
    │
    │ Public certificate
    │ Can be distributed
    ▼

Keycloak HTTPS server
```

Keycloak officially supports this PEM certificate/key arrangement. ([Keycloak](https://www.keycloak.org/server/enabletls?utm_source=chatgpt.com "Configuring TLS - Keycloak"))

### 2. Start your Keycloak on HTTPS port 9991

For your current setup:

```bat
call "%KEYCLOAK_HOME%\bin\kc.bat" start-dev ^
  --https-port=9991 ^
  --https-certificate-file=C:\keycloak-certs\keycloak.crt ^
  --https-certificate-key-file=C:\keycloak-certs\keycloak.key ^
  --bootstrap-admin-username=admin ^
  --bootstrap-admin-password=admin
```

Keycloak's default HTTPS port is 8443, but `--https-port` lets you change it, so your `9991` is fine. ([Keycloak](https://www.keycloak.org/server/enabletls?utm_source=chatgpt.com "Configuring TLS - Keycloak"))

You would then access:

```text
https://localhost:9991
```

instead of:

```text
http://localhost:9991
```

Your metadata URL also changes to:

```text
https://localhost:9991/realms/MySecurityRealm/protocol/saml/descriptor
```

### 3. One problem you'll encounter

Because this is a **self-signed certificate**, Windows, Chrome/Edge, Java, and your Spring application do not automatically trust it.

Your browser will probably show something like:

```text
Your connection is not private

NET::ERR_CERT_AUTHORITY_INVALID
```

This does **not** necessarily mean your Keycloak HTTPS configuration is broken. It means:

> The browser doesn't trust the CA that issued this certificate.

In this case, the certificate issued itself.

For a quick local test you can proceed past the warning where the browser permits it. For a cleaner development environment, you can import the certificate into your Windows trusted certificate store, or better, create a small development CA and use that CA to sign the Keycloak server certificate.

### 4. Spring also needs to trust it

This is particularly important with your configuration.

You currently have something equivalent to:

```java
RelyingPartyRegistrations.fromMetadataLocation(
    "https://localhost:9991/realms/MySecurityRealm/protocol/saml/descriptor"
)
```

Remember what we discussed earlier: Spring accesses this URL **during startup**.

So now:

```text
Spring Boot startup
       │
       │ HTTPS
       ▼
https://localhost:9991
       │
       ▼
Keycloak
       │
       │ presents
       ▼
keycloak.crt
       │
       ▼
Java asks:
"Do I trust this certificate?"
```

If the answer is no, Spring startup can fail with an SSL error such as:

```text
PKIX path building failed
```

or:

```text
unable to find valid certification path
```

For that reason, your Spring JVM also needs to trust the certificate/CA.

Alternatively, for your demo you could use the local metadata approach we discussed:

```java
.fromMetadataLocation(
    "classpath:saml/keycloak-metadata.xml"
)
```

That removes the Spring-startup HTTPS dependency, although the browser still needs to trust Keycloak when actually performing SSO.

### 5. Smart-card authentication needs another certificate relationship

There are actually **two different certificate purposes** here, and this is important.

The files you just generated are:

```text
keycloak.crt
keycloak.key
```

They identify the **Keycloak server**:

```text
Browser
    │
    │ "Prove you are Keycloak"
    ▼
Keycloak
    │
    ├── keycloak.crt
    └── keycloak.key
```

Your smart card has a completely separate certificate and private key:

```text
Keycloak
    │
    │ "Prove who the USER is"
    ▼
Smart Card
    │
    ├── User certificate
    └── User private key
```

So mutual TLS looks like:

```text
                HTTPS / mTLS

Browser                            Keycloak
   │                                  │
   │◄──── keycloak.crt ───────────────┤
   │
   │  Browser verifies Keycloak
   │
   │
   ├──── Smart Card Certificate ─────►│
   │                                  │
   │                         Keycloak verifies
   │                         user's certificate
   │
   ▼                                  ▼

USER CERTIFICATE                SERVER CERTIFICATE
Who are you?                    Which server are you?

Smart card                      keycloak.crt
```

Keycloak therefore needs a **truststore containing the CA that issued your smart-card certificate** in order to validate smart-card client certificates. Keycloak's mTLS documentation specifically requires the relevant CA/certificate chain to be trusted and enables client-certificate handling with `--https-client-auth=request` or `required`. ([Keycloak](https://www.keycloak.org/server/mutual-tls?utm_source=chatgpt.com "Configuring trusted certificates for mTLS - Keycloak"))

### 6. For your first smart-card experiment, use `request`

I would initially start with:

```bat
call "%KEYCLOAK_HOME%\bin\kc.bat" start-dev ^
  --https-port=9991 ^
  --https-certificate-file=C:\keycloak-certs\keycloak.crt ^
  --https-certificate-key-file=C:\keycloak-certs\keycloak.key ^
  --https-client-auth=request ^
  --bootstrap-admin-username=admin ^
  --bootstrap-admin-password=admin
```

Notice:

```text
--https-client-auth=request
```

rather than:

```text
--https-client-auth=required
```

Keycloak defines these differently: `request` accepts connections without a client certificate but validates one when supplied, while `required` rejects a TLS connection if the client doesn't provide an acceptable certificate. ([Keycloak](https://www.keycloak.org/server/mutual-tls?utm_source=chatgpt.com "Configuring trusted certificates for mTLS - Keycloak"))

That makes `request` much easier while you're developing:

```text
request
   │
   ├── Smart card available → certificate can be used
   │
   └── No certificate → Keycloak can still load
```

versus:

```text
required
   │
   ├── valid client certificate → continue
   │
   └── no valid certificate → TLS connection fails
```

Once everything works, you can decide whether `required` is appropriate.

One more thing: for actual smart-card authentication, **generating `keycloak.crt/keycloak.key` is only the server-HTTPS half of the setup**. The next critical step is getting the **CA certificate that issued your smart-card certificate** and configuring that as Keycloak's trust anchor. Keycloak supports either its system truststore or a dedicated mTLS truststore. ([Keycloak](https://www.keycloak.org/server/keycloak-truststore?utm_source=chatgpt.com "Configuring trusted certificates - Keycloak"))

[Keycloak TLS configuration guide](https://www.keycloak.org/server/enabletls?utm_source=chatgpt.com)

[Keycloak mutual TLS configuration guide](https://www.keycloak.org/server/mutual-tls?utm_source=chatgpt.com)
