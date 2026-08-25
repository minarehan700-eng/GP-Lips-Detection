@echo off
setlocal enabledelayedexpansion
rem ===========================================================================
rem  Lips Offline - one-time setup for Windows
rem
rem  Run this ONCE after unzipping the project, before opening VS Code.
rem  It prepares the three things Gradle needs and that are NOT in the ZIP,
rem  because they describe one computer rather than the app:
rem
rem    1. android\local.properties     - where Flutter and the Android SDK live
rem    2. the JDK path in gradle.properties
rem    3. the SSL truststore path in gradle.properties
rem
rem  Nothing here changes the application. It only points the build at the
rem  tools installed on THIS machine.
rem ===========================================================================

cd /d "%~dp0"
echo.
echo ==========================================================
echo   Lips Offline - setup
echo   %CD%
echo ==========================================================
echo.

rem ---------------------------------------------------------------- 1. Flutter
where flutter >nul 2>&1
if errorlevel 1 (
    echo [X] Flutter is not on your PATH.
    echo.
    echo     Install Flutter, or add its bin folder to PATH, then run this again.
    echo     Check with:  flutter --version
    echo.
    pause
    exit /b 1
)
echo [1/5] Flutter found.
for /f "delims=" %%v in ('flutter --version 2^>nul ^| findstr /b /c:"Flutter"') do echo       %%v

rem ------------------------------------------------- 2. packages + local.properties
echo.
echo [2/5] Downloading packages ^(this also writes android\local.properties^)...
call flutter pub get
if errorlevel 1 (
    echo.
    echo [X] "flutter pub get" failed. Read the message above and fix that first.
    pause
    exit /b 1
)
if exist "android\local.properties" (
    echo       android\local.properties created.
) else (
    echo [X] android\local.properties was still not created. Stopping.
    pause
    exit /b 1
)

rem ------------------------------------------------------------ 3. Android SDK
echo.
echo [3/5] Locating the Android SDK...
set "SDKDIR="
if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%" set "SDKDIR=%ANDROID_SDK_ROOT%"
if not defined SDKDIR if defined ANDROID_HOME if exist "%ANDROID_HOME%" set "SDKDIR=%ANDROID_HOME%"
if not defined SDKDIR if exist "%LOCALAPPDATA%\Android\Sdk" set "SDKDIR=%LOCALAPPDATA%\Android\Sdk"
if not defined SDKDIR if exist "%USERPROFILE%\AppData\Local\Android\Sdk" set "SDKDIR=%USERPROFILE%\AppData\Local\Android\Sdk"

if not defined SDKDIR (
    echo       [!] Android SDK not found automatically.
    echo           Open Android Studio once ^(it installs the SDK^), then re-run this.
    echo           Continuing anyway - "flutter run" can often still find it.
) else (
    findstr /b /c:"sdk.dir=" "android\local.properties" >nul 2>&1
    if errorlevel 1 (
        set "ESCAPED=!SDKDIR:\=\\!"
        >>"android\local.properties" echo sdk.dir=!ESCAPED!
        echo       sdk.dir added: !SDKDIR!
    ) else (
        echo       sdk.dir already present.
    )
)

rem ------------------------------------------- 4. machine-specific gradle lines
echo.
echo [4/5] Checking the machine-specific lines in android\gradle.properties...
set "GP=android\gradle.properties"
if not exist "%GP%" (
    echo       [!] %GP% is missing - skipping.
    goto :doctor
)

set "JDKOK=0"
set "TSOK=0"
if exist "C:\Program Files\Android\Android Studio\jbr" set "JDKOK=1"
if exist "%USERPROFILE%\.gradle\ssl-truststore.jks" set "TSOK=1"

rem The rewrite is done in PowerShell rather than batch string surgery, so that
rem the file's blank lines, comments and backslash escaping survive untouched.
rem A backup is written first and only lines whose target does not exist on this
rem machine are commented out.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%GP%';" ^
  "$jdk=[bool]%JDKOK%; $ts=[bool]%TSOK%;" ^
  "if (-not (Test-Path \"$p.backup\")) { Copy-Item $p \"$p.backup\" };" ^
  "$out = Get-Content $p | ForEach-Object {" ^
  "  if ((-not $jdk) -and ($_ -match '^\s*org\.gradle\.java\.home\s*=')) { '# disabled by setup_windows.bat (folder not found on this machine): ' + $_ }" ^
  "  elseif ((-not $ts) -and ($_ -match '^\s*systemProp\.javax\.net\.ssl\.trustStore')) { '# disabled by setup_windows.bat (file not found on this machine): ' + $_ }" ^
  "  else { $_ } };" ^
  "Set-Content -Path $p -Value $out -Encoding ASCII"
if errorlevel 1 echo       [!] Could not rewrite %GP% - edit it by hand if the build complains.

if "%JDKOK%"=="1" (
    echo       JDK path OK    : C:\Program Files\Android\Android Studio\jbr
) else (
    echo       JDK path missing - the org.gradle.java.home line was commented out.
    echo       Gradle will use your default Java. If the build complains about the
    echo       Java version, run:  flutter config --jdk-dir "<path to a JDK 17>"
)
if "%TSOK%"=="1" (
    echo       Truststore OK  : %USERPROFILE%\.gradle\ssl-truststore.jks
) else (
    echo       Truststore missing - those two lines were commented out.
    echo       Only needed if antivirus intercepts HTTPS. If downloads fail with an
    echo       SSL / certificate error, see the README troubleshooting section.
)

:doctor
rem ----------------------------------------------------------------- 5. doctor
echo.
echo [5/5] Environment check...
call flutter doctor

echo.
echo ==========================================================
echo   Setup finished.
echo.
echo   Next:  flutter devices        ^(is your phone listed?^)
echo          flutter run            ^(install and start the app^)
echo          flutter build apk --release
echo ==========================================================
echo.
pause
