import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val isReleaseBuild = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else if (isReleaseBuild) {
    throw GradleException("android/key.properties is missing. Required for release builds.")
}

android {
    namespace = "com.bhushanraut.wordspark"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.bhushanraut.wordspark"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Debug AdMob App ID
        manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            if (isReleaseBuild) {
                val storeFilePath = keystoreProperties["storeFile"] as String? ?: throw GradleException("storeFile is missing in key.properties")
                val keystoreFile = file(storeFilePath)
                if (!keystoreFile.exists()) {
                    throw GradleException("The configured keystore file does not exist: " + storeFilePath)
                }
                val storePwd = keystoreProperties["storePassword"] as String? ?: ""
                val keyPwd = keystoreProperties["keyPassword"] as String? ?: ""
                val keyAl = keystoreProperties["keyAlias"] as String? ?: ""

                if (storePwd.isEmpty()) throw GradleException("storePassword is empty in key.properties")
                if (keyPwd.isEmpty()) throw GradleException("keyPassword is empty in key.properties")
                if (keyAl.isEmpty()) throw GradleException("keyAlias is empty in key.properties")

                storeFile = keystoreFile
                storePassword = storePwd
                keyAlias = keyAl
                keyPassword = keyPwd
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Release AdMob App ID
            manifestPlaceholders["adMobAppId"] = "ca-app-pub-4413496842954832~2239872257"
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

dependencies {
    implementation("androidx.work:work-runtime:2.9.0")
}
