// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

fun localProperties(): Properties {
    val localPropertiesFile = rootProject.file("local.properties")
    val properties = Properties()
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
    }
    return properties
}

val flutterVersionCode = localProperties().getProperty("flutter.versionCode")
val flutterVersionName = localProperties().getProperty("flutter.versionName")

android {
    namespace = "com.example.ai_scan"
    compileSdk = 36

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.ai_scan"
        minSdk = 24
        targetSdk = 35
        versionCode = flutterVersionCode?.toInt() ?: 1
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }

    aaptOptions {
        noCompress("tflite")
    }

    // ★重要: 重複ファイルの解決策を追加
    packaging {
        jniLibs {
            // ネイティブライブラリが重複した場合、最初に見つかったものを優先する
            pickFirsts.add("lib/arm64-v8a/libtensorflowlite_jni.so")
            pickFirsts.add("lib/armeabi-v7a/libtensorflowlite_jni.so")
            pickFirsts.add("lib/x86/libtensorflowlite_jni.so")
            pickFirsts.add("lib/x86_64/libtensorflowlite_jni.so")
        }
        resources {
            excludes.add("/META-INF/{AL2.0,LGPL2.1}")
        }
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("com.google.android.material:material:1.11.0")

    // ML Kit
    implementation("com.google.mlkit:text-recognition-japanese:16.0.0")

    // ★修正: LiteRT (旧 TFLite) を採用し、古い org.tensorflow は削除
    implementation("com.google.ai.edge.litert:litert:1.4.0")
    // GPUを使用する場合は以下も追加（今回はコメントアウト）
    // implementation("com.google.ai.edge.litert:litert-gpu:1.4.0")

    // OpenCV
    implementation("org.opencv:opencv:4.12.0")

    // CameraX
    val cameraxVersion = "1.5.2"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
    implementation("androidx.camera:camera-view:$cameraxVersion")
    implementation("androidx.camera:camera-extensions:$cameraxVersion")

    implementation("com.google.guava:guava:31.1-android")
    implementation("androidx.concurrent:concurrent-futures:1.1.0")

    // ML KitのText Recognition
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.0")
}