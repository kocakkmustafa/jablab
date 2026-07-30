/// Uygulamanın PİNLİ poz modeli beyanı (J-072, sözleşme §6 + M-L-01).
///
/// **Neden bir sabit değil de kendi dosyası:** bu üç değer birbirine bağlı ve
/// üçü birlikte doğru olmak zorunda — asset yolu (hangi dosya yüklenecek),
/// `modelId` (her zarfa damgalanan kimlik) ve SHA-256 (dosyanın gerçekten o
/// dosya olduğunun kanıtı). Biri kayarsa diğerleri onu örter.
///
/// ⚠️ [modelId] REFERANSLARI ÜRETEN MODELİN KİMLİĞİDİR. Hasat fixture'ları
/// `modelVersion: pose_landmarker_full/float16/1` taşıyor; jab eklem tablosu
/// (J-061) o modelin ürettiği açılardan türetildi. Başka bir bundle ile
/// koşmak, tabloyu artık ait olmadığı bir modele uygulamak olur — sessizce
/// yanlış hüküm sınıfı. Bu yüzden kimlik ELDE TUTULUR ve zarfa damgalanır:
/// çekirdek `provenance`ta görür, bir model takası bir seansı sessizce
/// yeniden yorumlayamaz.
///
/// ⚠️ `latest` YASAK. Ölçüldü (M-L-01): `full` varyantında `/float16/latest/`
/// ile `/float16/1/` FARKLI — aynı boyut (9 398 198), farklı hash. Boyut
/// değişmediği için fark gözden kaçar. Sürüm segmenti bu yüzden pinli.
library;

final class PoseModelPin {
  const PoseModelPin._();

  /// Flutter asset yolu. Dosya git'te DEĞİL (aile kuralı: `.task` ikilileri
  /// izlenmez) — `tool/fetch_pose_model.sh` indirir/kopyalar ve SHA doğrular.
  static const String assetPath =
      'assets/models/pose_landmarker_full.v1.task';

  /// Zarfa damgalanan kimlik. Hasat fixture'larının `modelVersion` alanıyla
  /// BİREBİR aynı olmak zorunda — `model_pin_test` bunu zorluyor.
  static const String modelId = 'pose_landmarker_full/float16/1';

  /// MODELS.md'deki kanonik hash (varyant `full`, sürüm `1`).
  static const String sha256 =
      '5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1';

  /// Pinli sürüm segmenti. `latest` buraya YAZILAMAZ (testle zorlanıyor).
  static const String versionSegment = '1';
}
