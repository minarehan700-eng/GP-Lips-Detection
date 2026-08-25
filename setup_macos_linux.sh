#!/usr/bin/env bash
# ============================================================================
#  Lips Offline - one-time setup for macOS and Linux
#
#  Run this ONCE after unpacking the project, before opening VS Code:
#
#      chmod +x setup_macos_linux.sh
#      ./setup_macos_linux.sh
#
#  It prepares what the build needs and what is deliberately NOT in the
#  archive, because it describes one computer rather than the app:
#
#    1. android/local.properties  - where Flutter and the Android SDK live
#    2. the JDK the Android build runs on (Gradle needs 17 or newer)
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

# ----------------------------------------------------------- 4. a JDK 17+
#
# Gradle 8.14 and the Android Gradle Plugin refuse to run on Java 8, which is
# still what `java` on PATH points at on many machines:
#
#     Dependency requires at least JVM runtime version 11.
#     This build uses a Java 8 JVM.
#
# The JDK bundled with Android Studio is always new enough, so it is tried
# first. Whatever is found is handed to the Flutter tool, which then passes it
# to Gradle on every build. Nothing is written into android/gradle.properties:
# that file is shared with everyone and must stay free of local paths.
echo
echo "[4/5] Looking for a JDK 17 or newer for the Android build..."

jdk_major() {
    # Prints the major version of the JDK rooted at $1, or nothing at all.
    # Java 8 reports itself as 1.8.0_x, so it comes out as 1 and is rejected.
    #
    # The version line is picked out of the whole output rather than from the
    # first line: when JAVA_TOOL_OPTIONS or _JAVA_OPTIONS is set - antivirus,
    # a corporate proxy and some IDEs all do it - the JVM prints a "Picked up
    # ..." notice ahead of the version, and reading only line one finds it
    # instead of the version.
    [ -x "$1/bin/java" ] || return 1
    "$1/bin/java" -version 2>&1 |
        sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -n 1
}

JDKDIR=""
for candidate in \
        "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
        "$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
        "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home" \
        "/opt/android-studio/jbr" \
        "$HOME/android-studio/jbr" \
        "/usr/local/android-studio/jbr" \
        "${JAVA_HOME:-}" \
        "/usr/lib/jvm/java-21-openjdk-amd64" \
        "/usr/lib/jvm/java-17-openjdk-amd64" ; do
    [ -n "$candidate" ] || continue
    major="$(jdk_major "$candidate" 2>/dev/null || true)"
    if [ -n "$major" ] && [ "$major" -ge 17 ] 2>/dev/null; then
        JDKDIR="$candidate"
        break
    fi
done

# macOS keeps a registry of installed JDKs; ask it as a last resort.
if [ -z "$JDKDIR" ] && [ -x /usr/libexec/java_home ]; then
    JDKDIR="$(/usr/libexec/java_home -v 17+ 2>/dev/null || true)"
fi

if [ -z "$JDKDIR" ]; then
    echo "      [!] No JDK 17 or newer found."
    echo
    echo "          Install Android Studio (it bundles one), or a JDK 17 from"
    echo "          https://adoptium.net, then run:"
    echo
    echo "              flutter config --jdk-dir \"<path to that JDK>\""
    echo
    echo "          Without this the Android build stops with"
    echo "          \"Dependency requires at least JVM runtime version 11\"."
else
    echo "      Using: $JDKDIR  (Java $(jdk_major "$JDKDIR"))"
    flutter config --jdk-dir "$JDKDIR" >/dev/null 2>&1 &&
        echo "      Registered with Flutter." ||
        echo "      [!] 'flutter config --jdk-dir' failed - run it by hand."
fi

# A daemon started under the old JDK keeps serving the old error, so retire it.
if pkill -f GradleDaemon >/dev/null 2>&1; then
    echo "      Stopped a Gradle daemon left over from an earlier JDK."
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
