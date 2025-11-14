import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val storeFilePath = keystoreProperties.getProperty("storeFile")
val storePassword = keystoreProperties.getProperty("storePassword")
val keyAlias = keystoreProperties.getProperty("keyAlias")
val keyPassword = keystoreProperties.getProperty("keyPassword")
val hasReleaseSigning = listOf(storeFilePath, storePassword, keyAlias, keyPassword).all { !it.isNullOrBlank() }

android {
    namespace = "com.phonebuddy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.phonebuddy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(storeFilePath!!)
                storePassword = storePassword!!
                keyAlias = keyAlias!!
                keyPassword = keyPassword!!
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // FCM dependency for messaging service
    implementation("com.google.firebase:firebase-messaging:24.0.1")
    // Firestore dependency for background updates
    implementation("com.google.firebase:firebase-firestore:25.0.0")
}

flutter {
    source = "../.."
}
