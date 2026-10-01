@file:Suppress("DEPRECATION")

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ANDROID RELEASE İMZASI — sessiz debug-imzası KALDIRILDI (J-215).
//
// ## Ne vardı, neden kusurdu
//
// Flutter şablonu `release { signingConfig = signingConfigs.getByName("debug") }`
// bırakıyor. Bu, `flutter build appbundle` komutunu ÇALIŞTIRIR ve **debug
// anahtarıyla imzalanmış** bir artefakt üretir — Play bunu REDDEDER. Kusurun
// sınıfı bu üründe tanıdık: **sessiz-hiçlik.** Komut başarılı görünür, dosya
// oluşur, ve yanlış olduğu ancak Play'e yüklendiğinde anlaşılır.
//
// Aile taraması (koordinatör): **5/5 hat** aynı şablon satırında, hiçbirinde
// `key.properties`/keystore/`signingConfigs` yok. Pozitif kontrol: aynı desen,
// imzası olduğu BİLİNEN LifeOS'ta isabet etti — yani beş sıfır doğrulanmış.
//
// ## Bu dosyanın YAPTIĞI ve YAPMADIĞI
//
// * ⛔ **Keystore ÜRETMEZ.** İmza kimliği kurucunun kalemidir ve bir SIRDIR;
//   yeri `~/.secrets/yula/`, workspace'e ASLA girmez.
// * ✅ **Yokluğu GÜRÜLTÜLÜ yapar.** `key.properties` yoksa release görevleri
//   *başlamadan* adıyla durur. Bugün sessizce üretilip Play'de reddedilecek
//   bir artefaktı, yerelde ve gerekçesiyle durduruyoruz.
// * ✅ **Debug'a DOKUNMAZ.** `flutter run`/`flutter test`/commit kapısı
//   etkilenmez — kapı yalnız release görev grafiğinde ateşlenir.
val keystorePropsFile: File = rootProject.file("key.properties")
val hasKeystore: Boolean = keystorePropsFile.exists()
val keystoreProps = Properties().apply {
    if (hasKeystore) FileInputStream(keystorePropsFile).use { load(it) }
}

// JAB-P0-004 — CI KAÇIŞ KAPISI (Gravita'nın kendi build.gradle.kts'i bu
// deponun mekanizmasını "JabLab: key.properties yoksa signingConfig=null,
// debug'a DÜŞMEZ" diye kaynak gösterip Lissom'un `-PallowDebugSigning`
// bayrağıyla BİRLEŞTİRMİŞTİ — burada o birleşimin JabLab tarafı tamamlanıyor
// (icat değil, aile-doğrulanmış desen). CI'ın gerçek keystore'u YOK ve
// OLMAMALI (sır, kurucuda) ama Step 3'ün "Android release build" kanıtı
// istediği şey RELEASE KOD YOLUNUN derlendiği, Play'e yüklenebilir bir
// artefakt DEĞİL — bayrak bilerek AÇIK bir karar gerektirir, sessiz
// varsayılan değildir.
val allowDebugSigning: Boolean =
    (project.findProperty("allowDebugSigning") as String?) == "true"

android {
    namespace = "com.yulalab.jablab"
    compileSdk = 37
    buildToolsVersion = "37.0.0"
    ndkVersion = "30.0.16248370"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yulalab.jablab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Yalnız gerçek anahtar VARSA tanımlanır. Boş/yer-tutucu bir release
        // config tanımlamak, olmayan bir imzayı VARMIŞ gibi gösterirdi.
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
                storeFile = keystoreProps.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // ⚠️ Üç hâl, `when` ile AÇIKÇA ayrılmış (bir `if/else` zinciri
            // "bayrak sessizce debug'a düştü" ihtimalini gizlerdi):
            //   1) gerçek anahtar VAR → onunla imzala (üretim yolu).
            //   2) anahtar YOK ama `-PallowDebugSigning=true` AÇIKÇA verildi
            //      → debug anahtarıyla imzala (yalnız CI/yerel kod-yolu
            //      kanıtı; aşağıdaki kapı bunu GÜRÜLTÜLÜ uyarır, Play'e
            //      yüklenebilir bir artefakt DEĞİLDİR).
            //   3) ikisi de yok → `null`, aşağıdaki kapı release görev
            //      grafiğini GradleException ile durdurur (J-215, DEĞİŞMEDİ).
            signingConfig = when {
                hasKeystore -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// ⛔ KAPI — release, imzasız SESSİZCE üretilemez.
//
// `taskGraph.whenReady` seçildi çünkü yapılandırma anında fırlatmak DEBUG'ı da
// kırardı; kusur yalnız release yolunda ve kapı da yalnız orada ötmeli.
if (!hasKeystore) {
    gradle.taskGraph.whenReady {
        val releaseTasks = allTasks.filter { task ->
            task.name.contains("Release") &&
                listOf("assemble", "bundle", "package", "install").any { task.name.startsWith(it) }
        }
        if (releaseTasks.isNotEmpty()) {
            // ⚠️ İKİ YÖNDE ölçülür (Gravita'nın bulduğu tuzak, `test/
            // android_signing_test.dart`ta adıyla korunuyor): bayrak
            // VERİLMEDİĞİNDE hâlâ ÖTMELİ (aşağıda), VERİLDİĞİNDE ise SUSUP
            // yalnız uyarı basmalı — bir kapı, kendi kaçış bayrağını
            // ENGELLERSE o bayrak hiç var olmamış demektir.
            if (allowDebugSigning) {
                logger.warn(
                    "⚠️  ANDROID RELEASE DEBUG ANAHTARIYLA İMZALANIYOR " +
                        "(-PallowDebugSigning=true, JAB-P0-004). Bu artefakt " +
                        "yalnız RELEASE KOD YOLUNUN derlendiğini kanıtlar — " +
                        "Play'e YÜKLENEMEZ, yerel/CI denemesi içindir."
                )
                return@whenReady
            }
            throw GradleException(
                """
                |
                |╔══════════════════════════════════════════════════════════════╗
                |║  ANDROID RELEASE İMZASI YOK — build DURDURULDU (J-215)        ║
                |╚══════════════════════════════════════════════════════════════╝
                |
                |İstenen görev: ${releaseTasks.joinToString(", ") { it.name }}
                |
                |NEDEN DURDU: `android/key.properties` yok. Flutter şablonu bu
                |durumda release'i DEBUG anahtarıyla imzalar; o artefakt derlenir,
                |dosya oluşur ve Play tarafından REDDEDİLİR. Sessizce yanlış bir
                |şey üretmektense burada, adıyla duruyoruz.
                |
                |NE GEREKİYOR (kurucu kalemi — imza kimliği bir SIRDIR):
                |  1. Keystore kurucuda üretilir/saklanır: ~/.secrets/yula/
                |     ⛔ Keystore ve parolalar bu depoya ASLA girmez.
                |  2. `android/key.properties` (git-dışı, .gitignore'da):
                |       storeFile=/Users/<sen>/.secrets/yula/jablab-release.jks
                |       storePassword=...
                |       keyAlias=...
                |       keyPassword=...
                |
                |Debug etkilenmedi: `flutter run`, `flutter test` ve commit kapısı
                |bu kapıya hiç çarpmaz.
                |
                |Yalnız RELEASE KOD YOLUNUN derlendiğini (imzalı yayın DEĞİL)
                |kanıtlamak için: ./gradlew :app:assembleRelease -PallowDebugSigning=true
                """.trimMargin()
            )
        }
    }
}

flutter {
    source = "../.."
}
