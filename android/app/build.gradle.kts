import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Ключ подписи релиза. В репозитории его нет и быть не должно:
// - локально лежит в ~/.splitly/key.properties (рядом с upload-keystore.jks);
// - в CI workflow собирает android/key.properties из секретов репозитория.
val keyProperties = listOf(rootProject.file("key.properties"), File(System.getProperty("user.home"), ".splitly/key.properties"))
    .firstOrNull { it.exists() }
    ?.let { file -> Properties().apply { file.inputStream().use { load(it) } } }

android {
    namespace = "dev.toniess.splitly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.toniess.splitly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties != null) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// Без ключа релиз не собираем вовсе: APK, подписанный debug-ключом, Google Play
// не примет, а пользователь потом не сможет обновиться поверх него. Проверка
// на самих задачах, а не при конфигурации — иначе без ключа не собрался бы и debug.
if (keyProperties == null) {
    tasks.configureEach {
        if (name == "bundleRelease" || name == "assembleRelease") {
            doFirst { throw GradleException("Нет ключа подписи релиза: см. раздел «Релиз» в README") }
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
