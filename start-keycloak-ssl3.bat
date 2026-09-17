@echo off
setlocal

REM ---------------------------------------------------------------------------
REM Starts a locally extracted Keycloak server for this SAML demo.
REM
REM Before running this script, set KEYCLOAK_HOME to your Keycloak directory.
REM Example:
REM   set KEYCLOAK_HOME=C:\tools\keycloak-26.7.1
REM   scripts\start-keycloak.bat
REM ---------------------------------------------------------------------------

REM set KEYCLOAK_HOME=C:\Projects\SpringBoot_SAML_Keycloak_Demo\keycloak-26.7.1
REM set JAVA_HOME=C:\Projects\SpringBoot_SAML_Keycloak_Demo\jdk-21.0.8

:: Get the directory where the script is actually located
set "BASE_DIR=%~dp0"
:: Remove the trailing backslash
set "BASE_DIR=%BASE_DIR:~0,-1%"

set "KEYCLOAK_HOME=%BASE_DIR%\keycloak-26.7.1"
set "JAVA_HOME=%BASE_DIR%\jdk-21.0.8"

echo KEYCLOAK_HOME is set to: %KEYCLOAK_HOME%
echo JAVA_HOME is set to: %JAVA_HOME%

if "%KEYCLOAK_HOME%"=="" (
  echo ERROR: KEYCLOAK_HOME is not set.
  echo Example: set KEYCLOAK_HOME=C:\Projects\SpringBoot_SAML_Keycloak_Demo\keycloak-26.7.1
  exit /b 1
)

if not exist "%KEYCLOAK_HOME%\bin\kc.bat" (
  echo ERROR: Cannot find "%KEYCLOAK_HOME%\bin\kc.bat".
  echo Check that KEYCLOAK_HOME points to the extracted Keycloak directory.
  exit /b 1
)

echo Starting Keycloak at https://localhost:9991 ...
echo Demo bootstrap admin: admin / admin

call "%KEYCLOAK_HOME%\bin\kc.bat" start-dev ^
  --https-port=9991 ^
  --http-host=0.0.0.0 ^
  --https-certificate-file=.\keycloak-certs\keycloak.crt ^
  --https-certificate-key-file=.\keycloak-certs\keycloak.key ^
  --https-client-auth=request ^
  --https-trust-store-file=.\keycloak_truststore.p12 ^
  --https-trust-store-password=changeit ^
  --bootstrap-admin-username=admin ^
  --bootstrap-admin-password=admin
