import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)

    val requiredSigningProperties = listOf(
        "storePassword",
        "keyPassword",
        "keyAlias",
        "storeFile",
    )
    val missingSigningProperties = requiredSigningProperties.filter {
        signingProperties.getProperty(it).isNullOrBlank()
    }
    require(missingSigningProperties.isEmpty()) {
        "Missing ${missingSigningProperties.joinToString()} in android/key.properties."
    }

    val keystoreFile = rootProject.file(signingProperties.getProperty("storeFile"))
    require(keystoreFile.isFile) {
        "Android signing keystore not found: ${keystoreFile.path}"
    }
}

val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseBuildRequested && !signingPropertiesFile.isFile) {
    error(
        "Release builds require android/key.properties and the GitHub Actions " +
            "upload keystore. See docs/WYDANIA.md.",
    )
}

android {
    namespace = "thr3atb3ar.moesync"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "thr3atb3ar.moesync"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (signingPropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (signingPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
