plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.remote_control"
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
        applicationId = "com.example.remote_control"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with debug keys per your configuration
            signingConfig = signingConfigs.getByName("debug")
            
            // Rename logic inside Kotlin DSL
            applicationVariants.all {
                val variant = this
                variant.outputs.all {
                    val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
                    val appName = "Remote Control"
                    val buildTypeName = variant.buildType.name
                    val flavorName = if (variant.flavorName.isNullOrEmpty()) "default" else variant.flavorName
                    
                    val newName = if (buildTypeName == "debug") {
                        "app-$flavorName-debug.apk"
                    } else {
                        "${appName}_v${defaultConfig.versionName}_$flavorName.apk"
                    }
                    
                    output.outputFileName = newName
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
