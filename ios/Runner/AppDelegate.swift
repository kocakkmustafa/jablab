import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // JAB-P0-002: cihaz-günü canlılık probu için termal-durum köprüsü.
    // motion_camera/motion_core PİNLİ paketlerinden BAĞIMSIZ, app-özel,
    // ayrı bir kanal — kamera zarfı ham piksel taşımıyor (frame_envelope.
    // dart doğrulandı, blur-bucket bulgusuyla aynı ölçüm), termal ise
    // kameradan tamamen bağımsız bir OS sorgusu. Yalnız OKUR.
    let thermalChannel = FlutterMethodChannel(
      name: "com.yulalab.jablab/thermal",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    thermalChannel.setMethodCallHandler { call, result in
      guard call.method == "getThermalState" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let state: String
      switch ProcessInfo.processInfo.thermalState {
      case .nominal: state = "nominal"
      case .fair: state = "fair"
      case .serious: state = "serious"
      case .critical: state = "critical"
      @unknown default: state = "critical"  // yeni bir Apple kademesi — İYİMSER tahmin etme
      }
      result(["platform": "ios", "raw": state])
    }
  }
}
