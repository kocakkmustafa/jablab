/// Kabuğun alan-bağımsız görünüm modelleri.
///
/// Kabuk `jablab_engine`'e BAĞIMLI DEĞİLDİR — olsaydı `motion_shell`'e terfi
/// ettiğinde Ostinato'ya boks kural motorunu da taşırdı. App katmanı kendi
/// alan modelini bu nötr tiplere çevirir; kabuk "disiplin/çalgı/stil" ayrımını
/// bilmez, yalnız **öğe** görür.
library;

enum ItemStatus { live, comingSoon }

/// Kütüphanedeki bir öğe: JabLab'da disiplin, Ostinato'da çalgı,
/// Choreia'da stil, Gravita'da hareket ailesi.
final class ShellItem {
  const ShellItem({
    required this.id,
    required this.title,
    required this.status,
    required this.courses,
    required this.measured,
    required this.notMeasured,
    this.waveLabel = '',
    this.blurb = '',
    this.pendingNotes = const <String>[],
  });

  final String id;
  final String title;
  final ItemStatus status;
  final String waveLabel;
  final String blurb;
  final List<ShellCourse> courses;

  /// Dürüstlük kutusu — standart §2'de her öğe sayfası için ZORUNLU.
  final List<String> measured;
  final List<String> notMeasured;

  /// Öğe içinde henüz açılmamış başlıklar (kurs olarak listelenmez).
  final List<String> pendingNotes;
}

final class ShellCourse {
  const ShellCourse({
    required this.id,
    required this.title,
    required this.lessons,
    this.goal = '',
    this.level = '',
    this.minutes = 0,
  });

  final String id;
  final String title;
  final String goal;
  final String level;
  final int minutes;
  final List<ShellLesson> lessons;
}

final class ShellLesson {
  const ShellLesson({
    required this.id,
    required this.title,
    this.minutes = 0,
    this.subtitle = '',
    this.lockedReason,
  });

  final String id;
  final String title;
  final String subtitle;
  final int minutes;

  /// Doluysa öğe açılamaz ve bu cümle SEBEBİ olarak gösterilir.
  ///
  /// Kabuk için gerekli: bir öğeyi kilitleyip sebebini söylememek, kilidi
  /// pazarlama rozetine çevirir. Sebebi taşımayı zorunlu kılan şey alan
  /// bilgisi değil, ürünün "ölçemediğimizi vaat etmeyiz" sözü.
  final String? lockedReason;

  bool get isLocked => lockedReason != null;
}

/// Kapsam-dışı madde — "Neden yok?" sayfası.
final class ShellExclusion {
  const ShellExclusion(this.title, this.reason);

  final String title;
  final String reason;
}

final class ShellLibrary {
  const ShellLibrary({
    required this.title,
    required this.items,
    required this.exclusions,
    this.whyNotIntro = '',
  });

  final String title;
  final List<ShellItem> items;
  final List<ShellExclusion> exclusions;
  final String whyNotIntro;
}
