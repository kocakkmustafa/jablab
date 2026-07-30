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

/// Ne tür bir başarısızlık — ve bu ayrım kullanıcıya SUNULAN EYLEMİ belirler.
enum ContentFailureKind {
  /// İçerik okunabildi ama KENDİ İÇİNDE tutarsız: kural setinde olmayan bir
  /// tekniğe atıf, gerekçesiz kapsam-dışı madde, boş dürüstlük bloğu…
  ///
  /// Bu bir bizim-hatamız sınıfıdır ve **kasıtlı olarak bloklayıcıdır**:
  /// uygulama, doğruluğuna kefil olamadığı bir kütüphaneyi göstermek yerine
  /// hiç göstermemeyi seçiyor. Tekrar denemek anlamsız — asset aynı.
  integrity,

  /// İçerik OKUNAMADI veya çözümlenemedi: asset yok, JSON bozuk, I/O hatası.
  /// Kurulum bozulmuş olabilir; yeniden kurmak GERÇEKTEN çözebilir.
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
  /// yanlış tarafa düşmek gerekiyorsa, "yeniden kurmayı dene" demek
  /// "bu bizim içerik hatamız" demekten daha az yanlıştır — ikincisi
  /// kullanıcıya bizim adımıza teşhis koyar.
  factory ContentFailure.from(Object error) {
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
