import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Tamamlanmış bir seansın kaydı (J-064).
///
/// **Neden bu kadar az alan var:** kaydedilen her alan, sonradan bir ürün
/// yüzeyinin ona dayanmasına davetiye. Bugün yalnız Fitness'ın vaadini
/// ("çalıştığını kaydet") karşılayacak kadarı var: hangi ders, ne zaman, kaç
/// tur, ne kadar ÇALIŞMA. Hüküm/skor alanı **bilerek yok** — kamera köprüsü
/// yokken sıfır sayı kaydetmek, yarın "ilerleme" grafiğinde sıfırlar çizmek
/// olurdu.
final class SessionRecord {
  const SessionRecord({
    required this.lessonId,
    required this.completedAt,
    required this.workedSeconds,
    required this.roundsCompleted,
    required this.plannedRounds,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        lessonId: j['lessonId'] as String,
        completedAt: DateTime.parse(j['completedAt'] as String),
        workedSeconds: (j['workedSeconds'] as num).toInt(),
        roundsCompleted: (j['roundsCompleted'] as num).toInt(),
        plannedRounds: (j['plannedRounds'] as num).toInt(),
      );

  final String lessonId;
  final DateTime completedAt;

  /// Fiilen ÇALIŞILAN saniye — dinlenme HARİÇ. İlerleme kapıları
  /// (`curriculum.json` `sessionMinutes`) çalışma süresini sayıyor; burada
  /// dinlenmeyi de toplasak kullanıcı kapıyı hak etmeden geçerdi.
  final int workedSeconds;

  /// Yarıda bırakılan seans da kaydedilir — "bıraktı" bir veridir, silinmesi
  /// gereken bir utanç değil. [plannedRounds] ile birlikte tamamlanma oranı
  /// okunabilir kalır.
  final int roundsCompleted;
  final int plannedRounds;

  bool get isComplete => roundsCompleted >= plannedRounds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lessonId': lessonId,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'workedSeconds': workedSeconds,
        'roundsCompleted': roundsCompleted,
        'plannedRounds': plannedRounds,
      };
}

/// Seans geçmişi deposu — **arayüz kasıtlı olarak dar** (M-F: üçler kuralı).
///
/// Kalıcılık Fitness vaadinin VERİ KATMANI, opsiyonel bir özellik değil:
/// "10 dakika çalıştın" tek oturum içinde söylenebilir ama yarın
/// hatırlanmazsa vaat yarım kalır.
///
/// Bu arayüzün var olma sebebi ikinci app: aynı ihtiyaç Gravita/Ostinato'da
/// doğduğunda uygulama `motion_core`a kaldırılır, tüketiciler değişmez.
/// O yüzden burada tek bir boks terimi yok.
abstract interface class SessionStore {
  Future<void> append(SessionRecord record);

  /// En yeni ÖNCE. [limit] verilmezse tümü.
  Future<List<SessionRecord>> recent({int? limit});

  /// Bir dersin toplam çalışma süresi — ilerleme kapısı bunu sorar.
  Future<int> workedSecondsFor(String lessonId);
}

/// Append-only JSONL deposu (koordinatör hükmü: 3. taraf DB YOK).
///
/// **Neden JSONL ve neden append-only:** seans kaydı bir OLAY akışıdır, sorgu
/// yükü yok — bugün ihtiyaç "sona ekle, baştan oku". Bir DB (sqflite/Hive)
/// bu iş için şema göçü, sorgu katmanı ve bir platform bağımlılığı getirirdi;
/// sorgu ihtiyacı ÖLÇÜLDÜĞÜNDE gelir. (Hive'ın aile-gotcha'sı ayrıca kayıtlı:
/// yanlış cipher'da fırlatmaz, içeriği SESSİZCE siler.)
///
/// **Her satır kendi şema sürümünü taşır.** Dosya düzeyinde tek sürüm
/// yazmak, eski satırların hangi kurala göre yazıldığını okunamaz kılar —
/// göç günü tüm dosyayı yeniden yazmak ya da tahmin etmek gerekirdi.
///
/// **Atomiklik:** ekleme geçici dosyaya yazılıp `rename` ile yerine konur.
/// Doğrudan `append` sırasında süreç ölürse (mobilde işletim sistemi
/// uygulamayı her an öldürebilir) dosyanın sonunda YARIM bir satır kalır ve
/// sonraki okuma o satırda patlar. `rename` POSIX'te atomiktir: ya eski
/// dosya ya yeni dosya görünür, arası yok.
final class JsonlSessionStore implements SessionStore {
  JsonlSessionStore(this._file);

  /// Bugünkü satır şeması. Yeni alan eklenince ARTIRILIR; okuma tarafı
  /// bilmediği bir sürümü ATLAR (patlamaz) — ileri uyumluluk, çünkü
  /// kullanıcı uygulamayı geri de kurabilir.
  static const int schemaVersion = 1;

  final File _file;

  @override
  Future<void> append(SessionRecord record) async {
    final String line = jsonEncode(<String, dynamic>{
      'v': schemaVersion,
      ...record.toJson(),
    });

    final String existing =
        await _file.exists() ? await _file.readAsString() : '';
    final String next = existing.isEmpty ? '$line\n' : '$existing$line\n';

    final File tmp = File('${_file.path}.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(next, flush: true);
    await tmp.rename(_file.path);
  }

  @override
  Future<List<SessionRecord>> recent({int? limit}) async {
    final List<SessionRecord> all = await _readAll();
    all.sort((SessionRecord a, SessionRecord b) =>
        b.completedAt.compareTo(a.completedAt));
    if (limit == null || limit >= all.length) return all;
    return all.sublist(0, limit);
  }

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int total = 0;
    for (final SessionRecord r in await _readAll()) {
      if (r.lessonId == lessonId) total += r.workedSeconds;
    }
    return total;
  }

  Future<List<SessionRecord>> _readAll() async {
    // DEĞİŞTİRİLEBİLİR liste dönmek zorunlu: `recent()` sonucu yerinde
    // sıralıyor. `const []` dönmek boş-geçmiş yolunu — yani İLK AÇILIŞI —
    // çökertiyordu; testin yakaladığı gerçek kusur.
    if (!await _file.exists()) return <SessionRecord>[];
    final List<SessionRecord> out = <SessionRecord>[];
    for (final String raw in (await _file.readAsString()).split('\n')) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      // BOZUK SATIR TÜM GEÇMİŞİ SİLMEZ. Yarım yazılmış ya da gelecekten
      // gelen bir satır yüzünden kullanıcının aylarca birikmiş kaydını
      // okunamaz ilan etmek, veriyi kaybetmekle aynı sonucu verir —
      // o satır atlanır, gerisi okunur.
      try {
        final Map<String, dynamic> j =
            (jsonDecode(line) as Map).cast<String, dynamic>();
        final int v = (j['v'] as num?)?.toInt() ?? 0;
        if (v != schemaVersion) continue;
        out.add(SessionRecord.fromJson(j));
      } on Object catch (_) {
        continue;
      }
    }
    return out;
  }
}
