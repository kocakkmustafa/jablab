/// PROVA İÇERİĞİ YUVASI — `teach_material.dart`ın kardeşi (J-247).
///
/// ## Neden var: aşama, dersin adını bile anmıyordu
///
/// `rehearse` ("Try it") aşaması bugüne kadar **tek bir sabit cümleydi** ve
/// widget'ı `const _Rehearse()` idi — yani **ders girdisi HİÇ YOKTU**. 19
/// dersin 19'unda da ekranda aynı şey yazıyordu:
///
/// > *"Go slow. One thing at a time, no clock."*
///
/// Cümle yanlış değil; **eksik**. Kullanıcı 12 dakikalık bir dersin prova
/// aşamasında duruyor ve ekran ona *neyi* yavaş yapacağını söylemiyor —
/// oysa aynı dersin `techniques` alanı (`jab · cross`) zaten yazılı ve
/// aynı ekranın liste görünümünde alt başlık olarak GÖSTERİLİYOR.
///
/// Bu, J-094'ün ("watch first" denip izlenecek bir şey olmaması) ve
/// J-118'in (biçim vardı, üreticisi yoktu) aynı sınıfı: **ekran, elindeki
/// içerikten TÜRETMİYOR.** Çözüm de aynı sınıftan — cevabı içerikte bırak,
/// ekranı ondan türet.
///
/// ## İÇERİK İCAT EDİLMEDİ — sınır bilerek dar
///
/// Buradaki hiçbir varyant yeni antrenman metni UYDURMUYOR. Gösterilen
/// her dizge `library.json`da **zaten yazılı** (`techniques`,
/// `combinations`). Tekrar sayısı, tempo, süre gibi alanlar YOK — ve
/// olmadıkları için yazılmadılar: onları burada üretmek, ölçülmemiş bir
/// antrenman reçetesini ürünün ağzından söyletmek olurdu (J-044'ün 17 ölü
/// alanı ve J-047'nin elle yazılmış listesi tam bu şekilde doğmuştu).
///
/// ⛔ **Kurucu kapısı:** aşamanın GÖRSEL dili (kart mı, liste mi, sayaç mı)
/// tasarım yönüdür ve burada değişmedi — mevcut düzen korunuyor, yalnız
/// içerik kanalı açıldı.
library;

/// Bir dersin prova materyali. **İki hâl var ve YOKLUK bir hâldir**, bir
/// eksiklik değil — o yüzden gerekçesini taşımak zorunda.
sealed class RehearseMaterial {
  const RehearseMaterial();
}

/// Prova edilecek ADLANDIRILMIŞ bir teknik YOK — ve bu ekranda SÖYLENİR.
///
/// 19 dersin 4'ü bu hâlde ve hiçbiri bir kusur değil: kurulum
/// (`foundations.camera`), duruş (`foundations.stance`) ve savunma /
/// ayak-işi dersleri tek tek "teknik" listelemiyor, çünkü çalıştıkları şey
/// bir yumruk değil bir ŞEKİL.
///
/// [reason] gösterilecek cümlenin kaynağı: sessizce geçmek, boşluğun bir
/// cümle kurmasına izin vermek olur ("herhalde bir şey kaçırdım") ve o
/// cümle yanlıştır.
final class RehearseMaterialNone extends RehearseMaterial {
  const RehearseMaterialNone({required this.reason});

  final String reason;
}

/// Prova edilecek teknikler — hepsi içerikten, hiçbiri türetilmemiş.
///
/// [combinations] BOŞ OLABİLİR ve bu ayrı bir hâl değil: bir dersin
/// kombinasyonu yoksa o bölüm hiç çizilmez. Boşluğu "kombinasyon yok" diye
/// duyurmak gürültü olurdu — kullanıcı zaten tek teknik çalıştığını görüyor.
final class RehearseMaterialDrill extends RehearseMaterial {
  const RehearseMaterialDrill({
    required this.techniques,
    this.combinations = const <String>[],
  });

  /// EN AZ BİR eleman taşır — boşsa çağıran [RehearseMaterialNone] üretir.
  /// Boş listeyle bu varyantı kurmak, "teknik var" diyen bir hâlde hiçbir
  /// teknik göstermemek olurdu (sessiz yarı-hâl).
  final List<String> techniques;

  final List<String> combinations;
}
