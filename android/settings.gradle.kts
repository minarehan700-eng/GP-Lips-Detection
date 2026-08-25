pluginManagement {
    // Where is the Flutter SDK on THIS computer?
    //
    // `android/local.properties` holds the answer, but that file is deliberately
    // not in version control (it describes one machine) and it is only written
    // the first time the Flutter tool runs. An IDE that syncs Gradle as soon as
    // the folder is opened therefore gets here before the file exists.
    //
    // So: read the file when it is there, fall back to the FLUTTER_ROOT
    // environment variable when it is not, and if neither works, fail with a
    // message that says what to do instead of a "file not found" stack trace.
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localProperties = file("local.properties")
            if (localProperties.exists()) {
                localProperties.inputStream().use { properties.load(it) }
            }

            properties.getProperty("flutter.sdk")
                ?: System.getenv("FLUTTER_ROOT")
                ?: error(
                    "Flutter SDK not found.\n\n" +
                        "Fix: open a terminal in the project root (the folder holding " +
                        "pubspec.yaml) and run\n\n" +
                        "    flutter pub get\n\n" +
                        "That writes android/local.properties, which this file reads. " +
                        "Alternatively, set the FLUTTER_ROOT environment variable to your " +
                        "Flutter installation folder.",
                )
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
