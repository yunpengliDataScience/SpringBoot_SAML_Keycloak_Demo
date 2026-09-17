REM ----------------------------------------------------------------------------------------------------------------------------
REM Generate public/private keys using OpenSSL.
REM Download OpenSSL at:
REM https://kb.firedaemon.com/support/solutions/articles/4000121705-openssl-binary-distributions-for-microsoft-windows#ZIP-File
REM -----------------------------------------------------------------------------------------------------------------------------

REM set OPENSSL_HOME=C:\tools\openssl-4.0.1
set OPENSSL_HOME=C:\Projects\SpringBoot_SAML_Keycloak_Demo\openssl-4.0.1
set OPENSSL_CONF=%OPENSSL_HOME%\ssl\openssl.cnf
set PATH=%OPENSSL_HOME%\x64\bin;%PATH%

cd .\keycloak-certs

REM openssl req ^
REM   -newkey rsa:2048 ^
REM   -nodes ^
REM   -keyout keycloak.key ^
REM   -x509 ^
REM   -days 365 ^
REM   -out keycloak.crt ^
REM   -subj "/CN=localhost"
  
openssl req ^
  -newkey rsa:2048 ^
  -nodes ^
  -keyout keycloak.key ^
  -x509 ^
  -days 3650 ^
  -out keycloak.crt ^
  -subj "/CN=keycloak-dev" ^
  -addext "subjectAltName = DNS:localhost, IP:127.0.0.1, IP:10.86.44.244"



REM Convert OpenSSL Certificate to a PKCS12 Keystore for Spring Boot applications
openssl pkcs12 -export -in keycloak.crt -inkey keycloak.key -out springboot.p12 -name springboot -passout pass:springbootpass

cd ..
