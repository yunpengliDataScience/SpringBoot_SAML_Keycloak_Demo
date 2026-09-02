how to configure using smart card authentication in keycloak

Configuring smart card authentication (such as PIV or DoD CAC cards) in Keycloak relies on X.509 Client Certificate Authentication via Mutual TLS (mTLS). The smart card holds the user's private key and X.509 certificate, which Keycloak validates against a trusted certificate chain and maps to a user profile. [1, 2, 3, 4, 5]

The configuration process involves configuring the network/server layer for mTLS, setting up the truststore, and designing the authentication flow in Keycloak. [3, 6]

---

## Step 1: Configure the Truststore & Enable mTLS

Keycloak must be configured to request and trust the certificate authority (CA) that issued your smart cards. [5]

1. Obtain the CA Chains: Download the Root and Intermediate CA certificates for your smart cards (e.g., DoD CA chain).

2. Create a Truststore: Import these certificates into a Java Keystore (JKS) or PKCS12 file using `keytool`:
   
   ```bash
   keytool -importcert -trustcacerts -file rootCA.crt -keystore keycloak-truststore.p12 -storetype PKCS12 -alias rootCA
   ```

3. Configure Keycloak to Use the Truststore: When running Keycloak, use the following startup flags to point to your truststore and enable mTLS client certificate parsing:
   
   ```bash
   bin/kc.sh start \  --https-client-auth=request \  --https-trust-store-file=/path/to/keycloak-truststore.p12 \  --https-trust-store-password=your_password
   ```
   
   *Note: Setting `--https-client-auth=request` makes certificate presentation optional, allowing users without smart cards to still use standard username/password logins.* [1, 2, 3, 7, 8]

*(If you are running a reverse proxy like Nginx, Apache, or an AWS ALB in front of Keycloak, you must configure mTLS at the proxy layer instead and pass the client certificate to Keycloak via HTTP headers like `X-Client-Cert`).* [9, 10]

---

## Step 2: Configure the X.509 Authentication Flow

Once Keycloak can read the certificate, you must build an authentication flow that processes it. [1, 8]

1. Log into the Keycloak Admin Console.

2. Select your Realm.

3. Click on Authentication from the left menu.

4. Click Create flow (or duplicate the existing `Browser` flow) and name it something like `SmartCard Browser Flow`.

5. Inside your new flow, add a Sub-flow or individual executions:
   
   - Add Cookie (Set to *Alternative* or *Required*).
   - Add X509/Validate Username Form (Set to *Alternative* if you want to fall back to passwords, or *Required* if smart cards are mandatory). [6, 11]

6. Move the X509/Validate Username Form execution up so it executes alongside or before standard login forms.

7. Click Bind flow at the top right and set it as the new Browser flow for the realm.

---

## Step 3: Map Certificate Attributes to Users

You must instruct Keycloak on how to extract a unique identifier from the smart card certificate to match it against a user in your database. [2, 12]

1. Click the gear icon (Configure) next to the X509/Validate Username Form provider inside your authentication flow.

2. Adjust the following critical settings based on your smart card architecture:
   
   - User Identity Source: Define where Keycloak looks for the user identity. Common settings for CAC/PIV include:
     
     - `Subject's Alternative Name E-mail` (Common for standard emails embedded in the cert).
     - `Subject's Common Name (CN)`.
     - `Match Issuer and Subject DN` (The most secure option if accepting federal cards from multiple CAs).
   
   - A regular expression to extract user identity: If you need to parse out a specific ID (like a DOD ID number or EDIPI from the CN), use regex (e.g., `(.*)` to match everything).
   
   - User Mapping Method:
     
     - Select `Custom Attribute Search` if matching a specific field like a unique card ID mapped to a custom attribute on Keycloak user accounts.
     - Select `Username Search` or `Email Search` if the certificate directly yields the user's standard account username or email.
   
   - Bypass identity confirmation: Set to ON if you want the user to log in automatically as soon as they select their certificate PIN. Set to OFF if you want them to click a confirmation button first. [2, 4, 6, 7, 12, 13]

3. Click Save.

---

## Step 4: Test the Configuration

1. Clear your browser cache or open an Incognito/Private window.
2. Insert your smart card into the reader.
3. Navigate to your Keycloak Realm login page using the HTTPS port.
4. Your browser should prompt you to select a client certificate. Select your smart card certificate and input your PIN.
5. Keycloak should read the certificate, extract the user identity, and log you into the account automatically. [6, 13]

To help narrow down any potential hurdles, please let me know:

- Is Keycloak exposed directly to the internet, or is it behind a reverse proxy/load balancer (e.g., Nginx, AWS ALB, Traefik)?
- What specific unique identifier on the smart card (like an Email, UPN, or Employee ID number) do you plan to use for matching accounts?
- What Keycloak version and deployment environment (Docker, Kubernetes, bare-metal) are you using?

[1] [https://www.reddit.com](https://www.reddit.com/r/KeyCloak/comments/1ccxaaz/guide_for_keycloak_cac_card_x509_auth/)

[2] [https://groups.google.com](https://groups.google.com/g/keycloak-user/c/AC4-PH2rqqI)

[3] [https://www.keycloak.org](https://www.keycloak.org/server/mutual-tls)

[4] [https://forum.keycloak.org](https://forum.keycloak.org/t/x509-authentication-with-piv-cards/27517)

[5] [https://thalesdocs.com](https://thalesdocs.com/sas/3.22/agents/keycloak/integrations_using_keycloak/index.html)

[6] [https://medium.com](https://medium.com/@sangeethapl.sai/keycloak-x509-certificate-based-login-e9101f4a9922)

[7] [https://www.jelly.dev](https://www.jelly.dev/posts/keycloak-x509-authentication/)

[8] [https://aimen-brain.medium.com](https://aimen-brain.medium.com/authenticating-with-keycloak-using-x-509-certificates-docker-compose-d25f075aa4a)

[9] [https://groups.google.com](https://groups.google.com/g/keycloak-user/c/AC4-PH2rqqI/m/C4uQIlZuAgAJ)

[10] [https://forum.keycloak.org](https://forum.keycloak.org/t/x-509-smartcard-authentication-ask-for-certificate-only-on-authentication/24846)

[11] [https://www.youtube.com](https://www.youtube.com/watch?v=yLCBMQIqwAc&t=446)

[12] [https://stackoverflow.com](https://stackoverflow.com/questions/60225436/keycloak-x509-client-authentication-configuration)

[13] [https://www.youtube.com](https://www.youtube.com/watch?v=yq1hzNs1JQU)
