pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter plugin loader (required for Flutter 3.24+)
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Android Gradle Plugin
    id("com.android.application") version "8.7.0" apply false

    // Kotlin plugin (match Gradle + Flutter requirements)
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false

    // Google Services for Firebase
    id("com.google.gms.google-services") version "4.4.4" apply false
}

include(":app")
