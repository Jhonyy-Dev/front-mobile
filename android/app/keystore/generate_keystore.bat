@echo off
echo Generando keystore para Trust Country...

REM Buscar keytool en el JDK de Flutter
for /f "tokens=*" %%a in ('where flutter') do set FLUTTER_PATH=%%a
set FLUTTER_JDK_PATH=%FLUTTER_PATH%\..\cache\jdk

REM Verificar si existe el directorio
if not exist "%FLUTTER_JDK_PATH%" (
  echo No se pudo encontrar el JDK de Flutter.
  echo Intenta ejecutar manualmente el comando:
  echo keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass trustcountry123 -keypass trustcountry123 -dname "CN=Trust Country, OU=Mobile Development, O=Trust Country Inc, L=City, S=State, C=US"
  exit /b 1
)

REM Generar el keystore
"%FLUTTER_JDK_PATH%\bin\keytool" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass trustcountry123 -keypass trustcountry123 -dname "CN=Trust Country, OU=Mobile Development, O=Trust Country Inc, L=City, S=State, C=US"

echo Keystore generado correctamente en: %CD%\upload-keystore.jks
echo Configuración de firma completada.
