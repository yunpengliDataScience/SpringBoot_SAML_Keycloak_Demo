REM ----------------------------------------------------------------------------------------------------------------------------
REM Generate public/private keys using OpenSSL.
REM Download OpenSSL at:
REM https://kb.firedaemon.com/support/solutions/articles/4000121705-openssl-binary-distributions-for-microsoft-windows#ZIP-File
REM -----------------------------------------------------------------------------------------------------------------------------

set OPENSSL_HOME=C:\tools\openssl-4.0.1
set OPENSSL_CONF=%OPENSSL_HOME%\ssl\openssl.cnf
set PATH=%OPENSSL_HOME%\x64\bin;%PATH%

cd .\keycloak-certs

%OPEN_SSL_HOME%\openssl req ^
  -newkey rsa:2048 ^
  -nodes ^
  -keyout keycloak.key ^
  -x509 ^
  -days 365 ^
  -out keycloak.crt ^
  -subj "/CN=localhost"