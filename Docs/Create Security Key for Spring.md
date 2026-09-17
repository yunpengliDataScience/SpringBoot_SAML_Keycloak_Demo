The information you’re about to submit is not secureBecause this form is being submitted using a connection that’s not secure, your information will be visible to others. When my application try to http://10.86.44.244:9092/login/saml2/sso/keycloak



This error occurs because of an HTTPS-to-HTTP mismatch during the SAML login loop.

Your Keycloak server is running on HTTPS (`https://10.86.44.244:9991`), but your Spring Boot application is running on HTTP (`http://10.86.44.244:9092`).

When Keycloak successfully authenticates a user, it sends a browser redirect containing the user's secure credentials back to your Spring Boot application. Because Keycloak is forcing the browser to send data from a secure HTTPS environment to an insecure HTTP endpoint (`/login/saml2/sso/keycloak`), your web browser (Chrome or Edge) intervenes and displays "The information you’re about to submit is not secure" to prevent credential leakage.

---

## How to Fix It

To fix this, you must tell Spring Boot to use the exact same certificate you created for Keycloak so both servers communicate over HTTPS.

## Step 1: Convert your OpenSSL Certificate to a PKCS12 Keystore

Spring Boot cannot read raw `.crt` and `.key` files natively; it requires a Java-compatible keystore format. Run this single-line OpenSSL command in your terminal to package them together:

```cmd
%OPEN_SSL_HOME%\openssl pkcs12 -export -in keycloak.crt -inkey keycloak.key -out springboot.p12 -name springboot -passout pass:springbootpass
```

This creates a new file called `springboot.p12` with the password `springbootpass`.

## Step 2: Add the Keystore to Spring Boot

1. Copy the newly created `springboot.p12` file.
2. Paste it into your Spring Boot application's `src/main/resources/` directory.

## Step 3: Configure `application.properties` or `application.yml`

Open your Spring Boot configuration file and add the following lines to enable HTTPS:

```properties
# Change your application to run over secure HTTPSserver.ssl.key-store=classpath:springboot.p12server.ssl.key-store-type=PKCS12server.ssl.key-store-password=springbootpassserver.ssl.key-alias=springboot
```

## Step 4: Update the Client Configuration in Keycloak

Because your Spring Boot application is now secure, you must update the URLs inside your Keycloak Admin Console:

1. Log into Keycloak and go to your Clients menu.
2. Select SpringBoot_SAML_App1.
3. Change all occurrences of `http://10.86.44.244:9092...` to `https://10.86.44.244:9092...` (specifically the Valid Redirect URIs and the Master SAML Processing URL).

---

## What to Expect Next

Once both servers are running on matching HTTPS channels, restart your Spring Boot application. When you navigate to `https://10.86.44.244:9092`, the application will redirect to Keycloak and process the authentication smoothly without any browser security warnings.

Let me know:

- Did enabling HTTPS in Spring Boot resolve the insecure form submission error?
- Are you ready to generate the user's client X.509 certificate so we can test the fallback authentication flow?
