import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// "Karşılama görüldü mü" — TEK bitlik kalıcılık (J-106).
///
/// ## Neden ayrı bir dosya, neden `SessionStore` değil
///
/// `sessions.jsonl` bir ANTRENMAN kaydıdır ve kullanıcının kendi verisidir;
/// oraya bir UI bayrağı yazmak iki farklı ömrü aynı dosyaya bağlardı. Kayıt
/// dosyası bir gün taşınır/temizlenir/dışa aktarılırsa karşılama ekranının
/// geri gelmesi ya da gelmemesi tamamen alakasız bir kararın yan etkisi
/// olurdu.
///
/// ## Hata hâlinde ne olur — ve neden bu yön
///
/// Okuma başarısızsa **karşılama GÖSTERİLİR** (`false` dönülür), yazma
/// başarısızsa hata **yutulur**. İki yön de bilinçli:
///
/// * Okuma hatasında "görülmüş" varsaymak, ilk kez açan kullanıcıyı
///   dürüstlük ön-beyanını HİÇ görmeden ürünün içine bırakırdı — bu ürünün
///   en önemli ekranını bir I/O kazasına bağlamak olurdu.
/// * Yazma hatasında patlamak, kullanıcıyı bir bayrak yüzünden uygulamadan
///   etmek olurdu. Maliyeti: karşılama bir daha görünür. Katlanılır.
///
/// Yani belirsizlikte **fazla göstermeye** düşüyoruz, az göstermeye değil.
/// Sessizce atlamak bu ürün için en pahalı yön.
class OnboardingStore {
  const OnboardingStore({this.fileOverride, this.seenOverride});

  /// Testler için: `path_provider` widget testinde çalışmaz ve gerçek
  /// dosya sistemine yazmak testleri birbirine bağlardı.
  final File? fileOverride;

  /// Testler için: bayrağı dosya sistemine HİÇ dokunmadan kurar.
  ///
  /// `fileOverride` bir dosya İSTER; karşılamayı umursamayan onlarca
  /// uygulama-testinin her birine geçici dizin kurdurmak, ilgisiz bir
  /// kurulumu her yere yaymak olurdu. Bu alan üretimde `null` ve
  /// `storeOverride`/`loadStringOverride` ile aynı emsalde: dikiş TEK
  /// yerde okunuyor.
  final bool? seenOverride;

  static const String fileName = 'onboarding_seen';

  Future<File> _file() async {
    final File? injected = fileOverride;
    if (injected != null) return injected;
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<bool> seen() async {
    final bool? forced = seenOverride;
    if (forced != null) return forced;
    try {
      return (await _file()).existsSync();
    } on Object catch (_) {
      return false;
    }
  }

  /// ⚠️ Yazma **SENKRON**. Tek baytlık, kurulum başına BİR KEZ çalışan bir
  /// dosya için asenkron yazmanın kazandırdığı hiçbir şey yok; kaybettirdiği
  /// şey belirlilik: asenkron sürümde "Start"a basmakla bayrağın diske
  /// inmesi arasında bir pencere kalıyordu ve o pencerede uygulama
  /// öldürülürse karşılama geri geliyordu. (Testte de aynı pencere bir yarış
  /// olarak GÖRÜLDÜ — testi beklemeye zorlamak yerine pencereyi kapatmak
  /// doğru olan: hatayı düzeltmek değil, hatanın imkânsız olduğu yapıyı
  /// seçmek.) Dizin oluşturma da senkron, aynı gerekçe.
  Future<void> markSeen() async {
    if (seenOverride != null) return;
    try {
      final File f = await _file();
      f.parent.createSync(recursive: true);
      f.writeAsStringSync('1');
    } on Object catch (_) {
      // Bilerek yutuluyor — sınıf dokümanındaki gerekçe.
    }
  }
}
