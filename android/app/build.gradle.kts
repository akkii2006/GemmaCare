plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.example.gemma_care"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {

        jvmTarget = "17"
    }

    defaultConfig {

        applicationId = "com.example.gemma_care"

        minSdk = 34

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {

        release {

            signingConfig =
                signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {

        resources {

            excludes +=
                "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {

    source = "../.."
}

dependencies {

    // LiteRT-LM Android runtime
    implementation(
        "com.google.ai.edge.litertlm:litertlm-android:0.11.0"
    )

    // Kotlin coroutines
    implementation(
        "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
    )

    // Kotlin stdlib
    implementation(
        "org.jetbrains.kotlin:kotlin-stdlib:2.0.21"
    )

    // AndroidX core
    implementation(
        "androidx.core:core-ktx:1.13.1"
    )

    // Lifecycle runtime
    implementation(
        "androidx.lifecycle:lifecycle-runtime-ktx:2.8.4"
    )
}