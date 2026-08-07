import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/jablab_app.dart';

/// PORTRE KİLİDİ (J-109, koordinatör hükmü 2026-08-07).
///
/// ## Gerekçe — ve gerekçe OLMAYAN şey
///
/// Kilit **"yatayda bozulur" diye konmadı**: o bir hipotezdi ve ölçülmedi.
/// Cihaz döndürüldüğünde landmark'ların cihaz yönüne göre normalize edilip
/// edilmediği bilinmiyor — `motion_camera` dokümanı *"capture size after
/// sensor-rotation normalization"* diyor ama o SENSÖR montajı, cihaz yönü
/// değil; native taraf okunmadı. Doğru olsa bile ölçülmemiş bir gerekçeyle
/// alınan karar, yanlış gerekçeyle alınmış karardır.
///
/// **Gerçek gerekçe:** yatay yüzey hiç tasarlanmadı ve hiç ölçülmedi. 375pt
/// taşma kapısı YALNIZ portre ölçüyor (375×812); yatayda (812×375) canlı
/// yüzeyin `Expanded(preview) + sabit metin bloğu` düzeni hiçbir testten
/// geçmedi. Ölçülmemiş bir yüzeyi kullanıcıya açmak M-F-277'nin tersidir.
/// Kilit ucuz ve geri alınabilir; yatayı açık bırakmak değil.
///
/// ## Neden ÜÇ yerde birden
///
/// Flutter çağrısı tek başına yeterli değil: platform manifest'i hâlâ üç
/// yönü ilan ediyorsa iOS açılışta kısa bir yatay kare çizebiliyor ve
/// Android yapılandırma değişikliğini uygulamaya taşıyor. Beyanın üçünde de
/// aynı olması, "kilit var" cümlesinin her katmanda doğru olması demek.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp]);
  runApp(const JabLabApp());
}
