import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fala.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fala.app"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // Phase 3 (plans/12_abi_split): flutter_gemma 0.13.6 bundles native libs for engine
    // paths this app never uses. It runs only the LiteRT-LM path (ModelType.qwen3 /
    // ModelFileType.litertlm) with no embeddings/RAG and no MediaPipe .task/.bin models,
    // so the MediaPipe, image-generator and RAG .so files are dead weight (~116 MB/ABI).
    // Keep liblitertlm_jni.so (our engine) and libsqlite3.so (may have other consumers).
    // Re-verify this list on flutter_gemma upgrades.
    packaging {
        jniLibs {
            excludes += listOf(
                // 32-bit v7a guard: --target-platform (see docs/build-and-release.md) drops v7a
                // from split builds, but a plain `flutter build apk`/`appbundle` without the flag
                // would still package flutter_gemma's AAR v7a libs; this exclude makes that safe.
                "lib/armeabi-v7a/**",
                "**/libllm_inference_engine_jni.so",              // MediaPipe LLM (tasks-genai), .task/.bin only
                "**/libmediapipe_tasks_vision_jni.so",            // vision tasks
                "**/libmediapipe_tasks_vision_image_generator_jni.so", // image generation
                "**/libimagegenerator_gpu.so",                    // image generation GPU
                "**/libgemma_embedding_model_jni.so",             // RAG embedding (localagents-rag)
                "**/libgecko_embedding_model_jni.so",             // RAG embedding (localagents-rag)
                "**/libtext_chunker_jni.so",                      // RAG text chunking
                "**/libsqlite_vector_store_jni.so",               // RAG vector store
            )
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
