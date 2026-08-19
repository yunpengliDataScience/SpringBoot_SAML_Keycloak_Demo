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

set KEYCLOAK_HOME=C:\tools\keycloak-26.7.1
set JAVA_HOME=C:\Java\jdk-21

if "%KEYCLOAK_HOME%"=="" (
  echo ERROR: KEYCLOAK_HOME is not set.
  echo Example: set KEYCLOAK_HOME=C:\tools\keycloak-26.7.1
  exit /b 1
)

if not exist "%KEYCLOAK_HOME%\bin\kc.bat" (
  echo ERROR: Cannot find "%KEYCLOAK_HOME%\bin\kc.bat".
  echo Check that KEYCLOAK_HOME points to the extracted Keycloak directory.
  exit /b 1
)

echo Starting Keycloak at http://localhost:9991 ...
echo Demo bootstrap admin: admin / admin

call "%KEYCLOAK_HOME%\bin\kc.bat" start-dev ^
  --http-port=9991 ^
  --bootstrap-admin-username=admin ^
  --bootstrap-admin-password=admin
