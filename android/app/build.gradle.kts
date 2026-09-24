plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.carryonapp.app"
    // WHY: flutter_secure_storage 11 ships an AAR built against API 37;
    // the Flutter default (36) fails AAR metadata checks. AGP 9.1.0 allows
    // 37 with an acknowledgment flag in gradle.properties.
    compileSdk = 37
    // WHY: the SDK ships API 37 as the minor-versioned platform
    // "android-37.0"; without the minor, Gradle looks up "android-37".
    compileSdkMinor = 0
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Same id the Ionic build shipped under.
        applicationId = "com.CarryOnApp.App"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// Firebase (push topics) needs the google-services plugin, which in turn
// needs android/app/google-services.json from the Firebase console for the
// `com.CarryOnApp.App` Android app. Apply it only when the file is present
// so a checkout without it still builds; push is then disabled at runtime.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
