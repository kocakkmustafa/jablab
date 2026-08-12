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

android {
    namespace = "com.yulalab.jablab"
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
        applicationId = "com.yulalab.jablab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
            // ⚠️ `null` BİLEREK: debug'a düşmüyoruz. Anahtar yoksa imza YOK,
            // ve aşağıdaki kapı release görevini zaten başlatmıyor.
            signingConfig = if (hasKeystore) signingConfigs.getByName("release") else null
        }
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
                """.trimMargin()
            )
        }
    }
}

flutter {
    source = "../.."
}
