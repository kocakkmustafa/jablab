/// ÖĞRETİCİ İÇERİK YUVASI — UI-BRIEF §4/2'nin kod tarafı (J-094).
///
/// ## Neden var: ekran olmayan bir şeyi yapmamızı söylüyordu
///
/// `teach` aşaması bugüne kadar şunu yazıyordu: *"Nothing is being analysed
/// yet — **watch first**."* İzlenecek hiçbir şey YOK. `Lesson` modelinde
/// materyal alanı hiç bulunmuyor; ekranda ders adı, alt başlık ve bu cümle
/// var, o kadar. Yani kullanıcıya **yapamayacağı bir eylem** söyleniyordu.
///
/// Kusur J-047'nin aynı sınıfı: ekran, içerikten TÜRETİLMEYEN bir cümle
/// taşıyordu. Orada "lead hip puanlanmıyor" elle yazılmış ve config'le
/// çelişmişti; burada "önce izle" elle yazılmış ve hiçbir içerikle
/// desteklenmiyordu. Çözüm de aynı sınıftan: cevabı TEK bir yere koy, ekranı
/// ondan türet.
///
/// ## Bu dosya tasarımın YERİNE GEÇMEZ
///
/// Sınıf-C kaleminin comp gerektiren kısmı (video/çizim/animasyon nasıl
/// görünecek) tasarımcıya ait ve burada **icat edilmedi**. Bugün dürüstçe
/// taahhüt edebildiğimiz tek biçim METİN; zengin biçimler geldiğinde bu
/// hiyerarşiye yeni bir varyant eklenir ve `switch` derleyici tarafından
/// kırılır — sessizce eski davranışa düşmez.
///
/// Var olmayan alanları şimdiden yazmak (videoUrl, posterImage, duration…)
/// tasarımın kararını kodun tahminiyle doldurmak olurdu; o alanlar sonra
/// "vardı ama kimse okumuyordu" kutusuna düşerdi (J-044'ün 17 okunmayan
/// alanı tam böyle birikmişti).
library;

/// Bir dersin anlatım materyali. **İki hâl var ve YOKLUK bir hâldir**, bir
/// eksiklik değil — o yüzden gerekçesini taşımak zorunda.
sealed class TeachMaterial {
  const TeachMaterial();
}

/// Materyal YOK — ve bu ekranda SÖYLENİR.
///
/// [reason] kullanıcıya gösterilecek cümlenin kaynağı: yokluğu belirtmeden
/// geçmek, sessizliğin bir cümle kurmasına izin vermek olur ve o cümle
/// ("herhalde ben bir şey kaçırdım") yanlıştır.
final class TeachMaterialNone extends TeachMaterial {
  const TeachMaterialNone({required this.reason});

  final String reason;
}

/// Metin anlatımı — bugün dürüstçe render edebildiğimiz TEK biçim.
///
/// Zengin biçimler (video, çizim, adım-adım animasyon) comp bekliyor ve
/// AYRI birer varyant olacak: onları buraya opsiyonel alan olarak eklemek,
/// "video yoksa null" gibi sessiz bir yarı-hâl üretirdi.
final class TeachMaterialText extends TeachMaterial {
  const TeachMaterialText({required this.body});

  final String body;
}
