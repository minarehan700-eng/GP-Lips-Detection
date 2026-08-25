#!/usr/bin/env bash
# ============================================================================
#  Lips Offline - one-time setup for macOS and Linux
#
#  Run this ONCE after unpacking the project, before opening VS Code:
#
#      chmod +x setup_macos_linux.sh
#      ./setup_macos_linux.sh
#
#  It prepares what Gradle needs and what is deliberately NOT in the archive,
#  because it describes one computer rather than the app:
#
#    1. android/local.properties  - where Flutter and the Android SDK live
#    2. neutralises the Windows-only lines in android/gradle.properties
#
#  Nothing here changes the application.
# ============================================================================
set -u
cd "$(dirname "$0")"

echo
echo "=========================================================="
echo "  Lips Offline - setup"
echo "  $(pwd)"
echo "=========================================================="
echo

# ------------------------------------------------------------------ 1. Flutter
if ! command -v flutter >/dev/null 2>&1; then
    echo "[X] Flutter is not on your PATH."
    echo
    echo "    Install Flutter, or add its bin folder to PATH, then run this again."
    echo "    Check with:  flutter --version"
    exit 1
fi
echo "[1/5] Flutter found."
flutter --version 2>/dev/null | head -n 1 | sed 's/^/      /'

# --------------------------------------------- 2. packages + local.properties
echo
echo "[2/5] Downloading packages (this also writes android/local.properties)..."
if ! flutter pub get; then
    echo
    echo "[X] 'flutter pub get' failed. Read the message above and fix that first."
    exit 1
fi
if [ -f android/local.properties ]; then
    echo "      android/local.properties created."
else
    echo "[X] android/local.properties was still not created. Stopping."
    exit 1
fi

# -------------------------------------------------------------- 3. Android SDK
echo
echo "[3/5] Locating the Android SDK..."
SDKDIR=""
for candidate in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" \
                 "$HOME/Library/Android/sdk" "$HOME/Android/Sdk"; do
    if [ -n "$candidate" ] && [ -d "$candidate" ]; then SDKDIR="$candidate"; break; fi
done

if [ -z "$SDKDIR" ]; then
    echo "      [!] Android SDK not found automatically."
    echo "          Open Android Studio once (it installs the SDK), then re-run this."
    echo "          Continuing anyway - 'flutter run' can often still find it."
elif grep -q '^sdk.dir=' android/local.properties 2>/dev/null; then
    echo "      sdk.dir already present."
else
    echo "sdk.dir=$SDKDIR" >> android/local.properties
    echo "      sdk.dir added: $SDKDIR"
fi

# --------------------------------------- 4. machine-specific gradle.properties
echo
echo "[4/5] Checking the machine-specific lines in android/gradle.properties..."
GP="android/gradle.properties"
if [ ! -f "$GP" ]; then
    echo "      [!] $GP is missing - skipping."
else
    [ -f "$GP.backup" ] || cp "$GP" "$GP.backup"
    # Those two settings point at a Windows JDK and a Windows truststore. Neither
    # path can exist here, so both are commented out rather than deleted.
    python3 - "$GP" <<'PY' 2>/dev/null || sed -i.tmp \
        -e 's|^\([[:space:]]*org\.gradle\.java\.home[[:space:]]*=\)|# disabled by setup (Windows-only path): \1|' \
        -e 's|^\([[:space:]]*systemProp\.javax\.net\.ssl\.trustStore\)|# disabled by setup (Windows-only path): \1|' \
        "$GP" && rm -f "$GP.tmp"
import re, sys
p = sys.argv[1]
out = []
for line in open(p).read().split('\n'):
    if re.match(r'^\s*org\.gradle\.java\.home\s*=', line) or \
       re.match(r'^\s*systemProp\.javax\.net\.ssl\.trustStore', line):
        out.append('# disabled by setup (Windows-only path): ' + line)
    else:
        out.append(line)
open(p, 'w').write('\n'.join(out))
PY
    echo "      Windows-only lines commented out (backup: $GP.backup)."
    echo "      If Gradle complains about the Java version, run:"
    echo "          flutter config --jdk-dir \"<path to a JDK 17>\""
fi

# ------------------------------------------------------------------ 5. doctor
echo
echo "[5/5] Environment check..."
flutter doctor

echo
echo "=========================================================="
echo "  Setup finished."
echo
echo "  Next:  flutter devices        (is your phone listed?)"
echo "         flutter run            (install and start the app)"
echo "         flutter build apk --release"
echo "=========================================================="
echo
