import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// DÜRÜST HÂLLERİN SORUMLULUK EKSENİ (J-110, koordinatör hükmü 2026-08-07).
///
/// ## Ölçülen sorun
///
/// Canlı yüzeyde **11+ ayrı dürüst hâl** var (5 kurulum-hatası sınıfı ·
/// kamerasız ders · başlangıç · kimse-yok · okuma-bozuk · kadraj-dışı ·
/// düşük-güven · gövde-okunamıyor) ve hepsi TEK görselden geçiyordu: aynı
/// ikon, aynı renk, aynı tipografi. Ayrışan tek şey cümleydi.
///
/// Telefon 2-3 m uzakta (UI-BRIEF'in 1 numaralı kısıtı: uzaktan-okunurluk).
/// Kullanıcının okuduğu **ilk şey renk, ikinci şey ikon, cümle üçüncü.**
/// Yani J-103'te metinde ayırdığımız *"sen kadrajda değilsin"* ile
/// *"benim okumam bozuk"* farkı **kullanıcıya ulaşmıyordu** — düzeltmenin
/// görsel karşılığı hiç yapılmamıştı.
///
/// ## Neden 11 değil 3
///
/// 11 hâle 11 görsel icat etmek **eşik icadının görsel kardeşi** olurdu:
/// ayrımın kendisi uydurma olurdu. Bu üç kova İCAT DEĞİL TÜRETİM — 11 hâlin
/// her biri zaten *"eylem kimde"* sorusuna bir cevap taşıyor; burada
/// yapılan tek şey o ekseni görünür kılmak.
///
/// ## `colorScheme.error` KALDIRILDI
///
/// Donmuş `LiveCoachSurface` "göremiyorum" ikonunu `colorScheme.error` ile
/// çiziyordu ve bu HER hâle basılıyordu. **"Kimse yok" bir hata değildir** —
/// kırmızı, kullanıcıya yanlış bir şey yaptığını söyler. Sınıfı yanlış
/// yazmanın renkle yapılmış hâli; J-103'ün düzelttiği yanlış-yönlendirmenin
/// ta kendisi.
///
/// Donmuş widget'a DOKUNULMADAN çözülüyor: `themeFor` `colorScheme.error`ü
/// kovanın rengine eşliyor ve yüzey `Theme(data:, child:)` ile sarılıyor —
/// J-100'ün `jablabSessionTheme` deseninin aynısı.
enum LiveHonestyBucket {
  /// **EYLEM SENDE.** Kullanıcının yapabileceği bir şey var: kadraja gir,
  /// gövdeni göster, daha net dur. Sakin ve okunur — bu bir uyarı değil,
  /// bir yönlendirme.
  yours,

  /// **EYLEM BİZDE.** Okuma bozuk, kamera açılamadı, kurulum düştü.
  /// Kullanıcıya yapması gereken bir şey söylenmiyor çünkü yok. Kırmızı
  /// OLMAZ: kusur onda değil.
  ours,

  /// **ANALİZ HİÇ YOK.** İzin verilmedi, ders kamerasız, ya da henüz ilk
  /// kare gelmedi. Ortada ne düzeltilecek bir şey var ne bozulan bir şey —
  /// en sessiz hâl.
  none;

  Color get accent => switch (this) {
        // Gözlem tonu (Tier 2): "bak" diyor, "hata" demiyor.
        LiveHonestyBucket.yours => JColors.cool,
        // Nötr-parlak: görünür ama yönlendirmiyor — söyleyecek bir eylem yok.
        LiveHonestyBucket.ours => JColors.ink2,
        // Sönük ama GÖRÜNÜR. ⚠️ Burada `ink4` yazıyordu ve ÖLÇÜLDÜ:
        // zemine karşı kontrastı **1,80:1**, WCAG 2.2 SC 1.4.11'in
        // metin-dışı eşiğinin (3,0) altında — yani "analiz hiç yok" ikonu
        // pratikte görünmüyordu. Ve bu hâl izin reddi ile kamerasız dersin
        // hâli, yani en sık görülecek olanlardan biri: **görünmeyen bir
        // dürüst hâl, susmakla aynı şeydir.** `ink3` 3,51:1 veriyor.
        LiveHonestyBucket.none => JColors.ink3,
      };

  /// Önizleme yuvasının ikonu. Donmuş yüzeyin ikonu DEĞİŞTİRİLEMİYOR
  /// (`visibility_off_outlined` orada sabit); ikon ekseni bu yüzden app'in
  /// KENDİ yuvasından (`SkeletonPreview`) taşınıyor.
  IconData get icon => switch (this) {
        LiveHonestyBucket.yours => Icons.center_focus_strong_outlined,
        LiveHonestyBucket.ours => Icons.sync_problem_outlined,
        LiveHonestyBucket.none => Icons.videocam_off_outlined,
      };

  /// Donmuş yüzeyi giydiren tema. **YALNIZ `error` eşleniyor** — o alan
  /// yüzeyin "göremiyorum" ikonunun okuduğu tek renk. Kullanılmayan bir
  /// `ColorScheme` girişi icat edilmedi (`jablabSessionTheme`in kuralı).
  /// ⚠️ **RENK TEK BAŞINA AYRIMI TAŞIMIYOR — ölçüldü ve beyan ediliyor.**
  ///
  /// Üçünün de zemine karşı kontrastı WCAG 2.2 SC 1.4.11'i (metin-dışı,
  /// 3,0:1) geçiyor: `yours` 10,80 · `ours` 7,61 · `none` 3,51. Yani
  /// **görünürlük** ölçülü ve kapıda (`live_honesty_bucket_test`).
  ///
  /// ⚠️ Bu oranlar ZEMİNE karşı. Önizleme yuvasında iskelet metnin/ikonun
  /// üstünden geçebiliyor ve orada efektif zemin farklı — o durum artık
  /// kapsam DIŞI değil, **scrim'li zemine göre ayrıca ölçülüyor** (J-117).
  /// Kapsam beyanının kendisi bayatlayabilir: scrim eklendiği an eski
  /// "kapsam dışı" cümlesi yanlışa döndü ve güncellendi.
  ///
  /// Ama en önemli ayrım — *eylem sende* ile *eylem bizde* — renk olarak
  /// **en zayıf** olanı: `yours`↔`ours` luminans oranı 1,42:1. Bu bir kusur
  /// DEĞİL, bir sınır: WCAG kontrastı bir LUMINANS ölçüsüdür ve *"bu iki
  /// renk birbirinden ayırt edilebilir mi"* sorusunu ölçmez (mavi-gri ile
  /// nötr gri aynı parlaklıkta olup gözle apaçık farklı olabilir). Onu
  /// kontrast oranıyla ölçmeye kalkmak, bir standardı ölçmediği şey için
  /// kullanmak olurdu.
  ///
  /// **Bu yüzden ayrımın asıl yükünü İKON taşıyor**, renk değil — ve ikonun
  /// 2-3 m'den okunup okunmadığı ancak GÖZLE doğrulanır. O doğrulama
  /// yapılmadı (sim erişimi kurucu onayı bekliyor); bu paragraf onun yerine
  /// geçmez, borcu adıyla tutar.
  ThemeData themeFor(ThemeData base) => base.copyWith(
        colorScheme: base.colorScheme.copyWith(error: accent),
      );
}
