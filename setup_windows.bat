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

rem ------------------------------------------------------------ 4. a JDK 17+
rem
rem  Gradle 8.14 and the Android Gradle Plugin refuse to run on Java 8, which
rem  is still what "java" on PATH points at on many Windows machines:
rem
rem      Dependency requires at least JVM runtime version 11.
rem      This build uses a Java 8 JVM.
rem
rem  The JDK bundled with Android Studio ("jbr") is always new enough, so the
rem  known install locations are checked directly - no version parsing needed.
rem  Whatever is found is handed to the Flutter tool, which then passes it to
rem  Gradle on every build. Nothing is written into android\gradle.properties:
rem  that file is shared with everyone and must stay free of paths that exist
rem  on one computer only.
echo.
echo [4/5] Looking for a JDK 17 or newer for the Android build...

set "JDKDIR="
for %%J in (
    "%ProgramFiles%\Android\Android Studio\jbr"
    "%ProgramFiles%\Android\Android Studio Preview\jbr"
    "%LOCALAPPDATA%\Programs\Android Studio\jbr"
) do (
    if not defined JDKDIR if exist "%%~J\bin\java.exe" set "JDKDIR=%%~J"
)

rem  JAVA_HOME is a fallback, and only when it is clearly not a Java 8 install
rem  - a Java 8 JAVA_HOME is exactly what produces the error above. These lines
rem  are deliberately NOT wrapped in parentheses: JAVA_HOME often contains a
rem  path like "C:\Program Files (x86)\...", and an unquoted closing bracket
rem  inside a parenthesised block ends the block early.
if defined JDKDIR goto :jdk_done
if not defined JAVA_HOME goto :jdk_done
if not exist "%JAVA_HOME%\bin\java.exe" goto :jdk_done
echo "%JAVA_HOME%" | findstr /i /c:"1.8" /c:"jdk8" /c:"jre8" >nul
if errorlevel 1 set "JDKDIR=%JAVA_HOME%"
:jdk_done

if not defined JDKDIR (
    echo       [!] No JDK 17 or newer found.
    echo.
    echo           Install Android Studio ^(it bundles one^), or a JDK 17 from
    echo           https://adoptium.net, then run:
    echo.
    echo               flutter config --jdk-dir "^<path to that JDK^>"
    echo.
    echo           Without this the Android build stops with
    echo           "Dependency requires at least JVM runtime version 11".
) else (
    echo       Using: !JDKDIR!
    call flutter config --jdk-dir "!JDKDIR!" >nul 2>&1
    if errorlevel 1 (
        echo       [!] "flutter config --jdk-dir" failed - run it by hand.
    ) else (
        echo       Registered with Flutter.
    )
)

rem  A Gradle daemon started under the old JDK stays alive and keeps repeating
rem  the old error after the JDK is corrected. Only daemons are ended here -
rem  matching on the command line rather than on "java.exe", so unrelated Java
rem  programs the user has open are left alone.
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_Process -Filter \"Name='java.exe'\" |" ^
  "Where-Object { $_.CommandLine -like '*GradleDaemon*' } |" ^
  "ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1

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
