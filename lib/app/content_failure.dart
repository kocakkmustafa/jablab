/// İÇERİK YÜKLEME HATASININ TİPLİ MODELİ (J-079).
///
/// UI-BRIEF §4/3: *"Dürüst hata ekranı — bugün içerik denetimi başarısız
/// olunca ham crash."* Gerçekte tam crash değildi, daha sinsi bir şey vardı:
/// `_Root` hatayı yakalıyor ve ekrana `'$_error'` basıyordu — yani
/// kullanıcı Türkçe bir `StateError` gövdesi ve eklem adları görüyordu.
/// "Çökmüyor" ile "dürüstçe açıklıyor" aynı şey değil.
///
/// **Neden tip, neden string değil:** ekranın davranışı hata sınıfına göre
/// değişmek zorunda (bir bütünlük hatasında "tekrar dene" yalan olur, aynı
/// asset aynı sonucu verir). Bunu hata METNİNDEN çıkarmak ("mesajda
/// 'dürüstlük denetimi' geçiyorsa…") tam o sessiz-kırılma sınıfı olurdu:
/// metin bir gün değişir, sınıflandırma sessizce yanlışa döner ve hiçbir test
/// bunu görmez. O yüzden fırlatan taraf sınıfı KENDİSİ beyan ediyor.
library;

import 'package:motion_content/motion_content.dart';

/// Ne tür bir başarısızlık — ve bu ayrım kullanıcıya SUNULAN EYLEMİ belirler.
enum ContentFailureKind {
  /// Paketlenmiş içerik eksik veya KENDİ İÇİNDE tutarsız: eksik kurs varlığı,
  /// kural setinde olmayan teknik, gerekçesiz kapsam-dışı madde…
  ///
  /// Bu bir bizim-hatamız sınıfıdır ve **kasıtlı olarak bloklayıcıdır**:
  /// uygulama, doğruluğuna kefil olamadığı bir kütüphaneyi göstermek yerine
  /// hiç göstermemeyi seçiyor. Tekrar denemek anlamsız — asset aynı.
  integrity,

  /// Geçici okuma/erişim hatası: zaman aşımı veya I/O. İçeriğin paket içinde
  /// eksik olması bu sınıfa girmez; aynı sürümün tekrar denenmesi onu üretmez.
  unreadable,
}

/// Kütüphane doğrulaması başarısız olduğunda fırlatılan tip.
///
/// [errors] doğrulayıcının kendi satırları — kullanıcıya BİRİNCİL metin
/// olarak gösterilmez, ama gizlenmez de: sahada kurucunun elinde tek teşhis
/// malzemesi bu (bkz. [ContentFailureScreen] "technical detail" bölümü).
final class ContentIntegrityException implements Exception {
  const ContentIntegrityException(this.errors);

  final List<String> errors;

  @override
  String toString() =>
      'ContentIntegrityException(${errors.length} ihlal):\n${errors.join("\n")}';
}

/// Ekranın okuduğu şey. Sınıflandırma BURADA yapılır, ekranda değil — ekran
/// bir hata nesnesini yorumlamaya başlarsa yorum mantığı iki yere dağılır.
final class ContentFailure {
  const ContentFailure({required this.kind, required this.detail});

  /// Herhangi bir yakalanmış hatayı sınıflandırır.
  ///
  /// Bilinmeyen bir hata tipi [ContentFailureKind.unreadable] sayılır:
  /// yanlış tarafa düşmek gerekiyorsa, "bir kez yeniden dene" demek
  /// "bu bizim içerik hatamız" demekten daha az yanlıştır — ikincisi
  /// kullanıcıya bizim adımıza kesin teşhis koyar.
  factory ContentFailure.from(Object error) {
    if (error is ContentException) {
      final ContentFailureKind kind = switch (error.error.code) {
        ContentErrorCode.timeout ||
        ContentErrorCode.io => ContentFailureKind.unreadable,
        _ => ContentFailureKind.integrity,
      };
      return ContentFailure(kind: kind, detail: error.error.toString());
    }
    if (error is ContentIntegrityException) {
      return ContentFailure(
        kind: ContentFailureKind.integrity,
        detail: error.errors.join('\n'),
      );
    }
    // Motor tarafı çözümleyicileri (replik eşlemesi, kural seti, eklem
    // etiketleri) tutarsızlığı `StateError`/`ArgumentError` ile bildiriyor.
    // Bunlar da bütünlük sınıfıdır: dosya okunmuş, içeriği tutmuyor.
    if (error is StateError || error is ArgumentError) {
      return ContentFailure(
          kind: ContentFailureKind.integrity, detail: error.toString());
    }
    return ContentFailure(
        kind: ContentFailureKind.unreadable, detail: error.toString());
  }

  final ContentFailureKind kind;

  /// Geliştirici ayrıntısı. Kullanıcıya İKİNCİL olarak, katlanmış hâlde.
  final String detail;
}

/// ⚠️ **EMEKLİ (J-095).** Bu sınıfın yerini `motion_core` 0.11.0'ın
/// `HistoryUnavailable`ı aldı — üç hat aynı semantiğe yakınsadı, sözleşme
/// çekirdeğe terfi etti (M-F-254) ve yerel kopyayı tutmak "aynı kuralın iki
/// yerde yaşaması" olurdu. Aşağıdaki gerekçe TARİHSEL kayıt olarak duruyor:
/// çekirdek tipin neden var olduğunu anlatan ölçülmüş vaka budur.
///
/// ---
///
/// GEÇMİŞ okunamadı — ama İÇERİK sağlam (J-092, aile kuralı M-F-209).
///
/// Emsal Gravita'nın `HistoryFailure`'ı (G-102) ve JabLab burada üçüncü
/// tüketici. Kusurun JabLab'daki hâli aynı sınıftandı: `openStore()`
/// başarısız olunca `_store = null` kalıyor, özet hiç gelmiyor ve ilerleme
/// sayfası "What we recorded" bölümünü **hiç çizmiyordu** — yani ekran, hiç
/// antrenman yapmamış kullanıcınınkiyle BİREBİR AYNI görünüyordu. Sessizlik
/// burada bir cümle kuruyor ve o cümle *"hiç yapmadın"*.
///
/// **Bloklayıcı DEĞİL** ([ContentFailureKind.integrity]'nin aksine): içerik
/// sağlamsa dersler açılabilir, antrenman yapılabilir. Depolama hatası
/// yüzünden antrenmanı engellemek çözümü sorundan kötü yapardı. Ama
/// **beyan edilmek zorunda** ve beyan edilirken **sayı gösterilmez** —
/// bilmediğimizi sıfır yazmayız.
///
/// ## ⭐ JABLAB DELTASI — ikili değil, ÜÇ hâl
///
/// Gravita'da geçmiş ya okunur ya okunmaz: tüm okuma tek `try`/`catch`
/// içinde. JabLab'ın deposu bozuk satırı **bilerek atlıyor** ve atlamak doğru
/// karar (bkz. `session_store.dart`) — bu, Gravita'da KARŞILIĞI OLMAYAN bir
/// üçüncü hâl doğuruyor: *kısmen okundu.* Orada "hiç yapmadın" yalanı vardı,
/// burada bir de **"az yaptın"** yalanı mümkün: özet yine sayı gösterir, ama
/// gösterdiği sayı bir toplam değil bir ALT SINIRDIR.
///
/// Bu yüzden JabLab'ın modeli bu sınıf + [RecordedSummary.unreadableRecords]
/// çiftidir. Sadece bu sınıf terfi ettirilirse (ikili hâliyle) JabLab onu
/// devraldığı gün kırmak zorunda kalır — terfi hakemliği için ölçülmüş fark
/// budur.
// (sınıf gövdesi kaldırıldı — çekirdek `HistoryUnavailable` kullanılıyor)
