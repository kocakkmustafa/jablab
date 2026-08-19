package com.yulalab.jablab

import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val THERMAL_CHANNEL = "com.yulalab.jablab/thermal"

class MainActivity : FlutterActivity() {
    // JAB-P0-002: cihaz-günü canlılık probu için termal-durum köprüsü.
    // motion_camera/motion_core PİNLİ paketlerinden BAĞIMSIZ, app-özel,
    // ayrı bir kanal — bkz. AppDelegate.swift'teki aynı gerekçe. Yalnız
    // OKUR, izin istemez.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THERMAL_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "getThermalState") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // PowerManager.getCurrentThermalStatus() API 29 (Android 10)
                // ile geldi — altında YOK, sessizce 0/nominal UYDURULMAZ:
                // Dart tarafı (ThermalReading._androidTier) `raw:null`ı
                // "critical'a yuvarla AMA measured=false" diye ayrı işler
                // (H-31 sınıfı: yarım kanıt tam ölçüm gibi taşınmaz).
                val raw: Int? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    (getSystemService(POWER_SERVICE) as? PowerManager)?.currentThermalStatus
                } else {
                    null
                }
                result.success(mapOf("platform" to "android", "raw" to raw))
            }
    }
}
