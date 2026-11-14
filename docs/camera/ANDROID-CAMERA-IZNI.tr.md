# Android CAMERA izni: kamera açılınca geri ekleme (JAB-P1-02)

Durum: kamera özelliği KAPALI (`jablabCameraCoachingAvailable = motionCameraCoachingAvailable = false`). Uygulama Android'de CAMERA izni istemez.

## Neden `tools:node="remove"`

`motion_camera` eklentisi (`packages/motion_camera/android/src/main/AndroidManifest.xml`, Core `5b15308`) kendi bildiriminde `android.permission.CAMERA` ve `android.hardware.camera` ekler. Yalnız uygulama bildiriminden satırı silmek yetmez: birleşik bildirimde eklenti satırları geri gelir (ölçüldü: sil-yalnız hâlinde CAMERA birleşikte kalıyor). Bu yüzden `android/app/src/main/AndroidManifest.xml` satırları `tools:node="remove"` ile bildirir.

Koruma testi: `test/android_manifest_camera_off_test.dart`.

## Kamera açılırken yapılacaklar

1. `android/app/src/main/AndroidManifest.xml` içinde şu üç `tools:node="remove"` satırını SİL (veya aşağıdakilerle değiştir); `xmlns:tools` kalabilir:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

   `required="false"`: kamerasız cihaz kurulumu engellenmez (Fitness hattı kamerasız çalışır).
2. `test/android_manifest_camera_off_test.dart` dosyasını kamera açık sözleşmesine göre güncelle (CAMERA artık beklenir).
3. `tool/prepare_store_packet.py` `native_identity` izin kümesi `{INTERNET, CAMERA}` bekler; kamera kapalıyken `{INTERNET}` olmalı, açılınca geri `{INTERNET, CAMERA}`.
4. Play Data Safety ve App Review notunu kamera açık hâline göre güncelle.

## iOS

`ios/Runner/Info.plist` `NSCameraUsageDescription` (satır 55-56) bu işte DEĞİŞMEDİ: "Camera coaching is disabled…" metni duruyor.
