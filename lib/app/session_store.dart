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

  /// **Okunamayan kayıt sayısı** — J-092, M-F-209'un JabLab deltası.
  ///
  /// Neden arayüzde ve neden VARSAYILANI YOK: bu depo bozuk satırı bilerek
  /// ATLIYOR ([JsonlSessionStore._readAll]) ve atlamak DOĞRU karar — tek bozuk
  /// satır yüzünden aylarca birikmiş geçmişi okunamaz ilan etmek, veriyi
  /// kaybetmekle aynı sonucu verir. Ama atlamayı SESSİZ yapmak, "az yaptın"
  /// diyen bir yalan üretir: 50 satırın 40'ı atlanınca özet "10 seans" der ve
  /// bunu gerçekten 10 seans yapılmış gibi aynı güvenle söyler.
  ///
  /// Varsayılan `0` vermek, veri kaybedebilen bir uygulamanın soruyu hiç
  /// cevaplamadan sessiz kalmasına izin verirdi. "Kaç tanesini kaybettin?"
  /// **kaçınılmaz** olmak zorunda — o yüzden zorunlu üye.
  Future<int> unreadableRecords();
}

/// Kaydedilmiş seansların OLGU özeti (F-4/J-066).
///
/// Hüküm YOK: burada "iyi/kötü" diyen tek alan bile bulunmaz. Alanların
/// hepsi kameradan bağımsız ölçülebilen şeyler — bu yüzden K8 kilidi
/// bunları kapatmaz (K8 SKORU kapatır, olguyu değil).
final class RecordedSummary {
  const RecordedSummary({
    required this.sessions,
    required this.completed,
    required this.workedSeconds,
    this.unreadableRecords = 0,
  });

  final int sessions;
  final int completed;
  final int workedSeconds;

  /// Okunamadığı için bu özetin DIŞINDA kalan kayıt sayısı (J-092).
  ///
  /// Sıfırdan büyükse aşağıdaki üç sayının hepsi **alt sınırdır**, ölçüm
  /// değil. Bunu söylemeden göstermek, eksik bir toplamı tam bir toplam
  /// gibi sunmak olur.
  final int unreadableRecords;

  /// Özet EKSİK mi? "Hiç yapmadın" ile "bilmiyorum" arasındaki üçüncü hâl:
  /// *biraz biliyorum, ne kadarını bilmediğimi de biliyorum.*
  bool get isPartial => unreadableRecords > 0;

  int get stoppedEarly => sessions - completed;

  /// İnsan-okur süre. Saniye GÖSTERİLMEZ: bir antrenman süresinde saniye
  /// hassasiyeti bilgi taşımaz, yalnız kesinlik izlenimi verir.
  String get workedLabel {
    final int m = workedSeconds ~/ 60;
    if (m < 60) return '$m min';
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  static Future<RecordedSummary> from(SessionStore store) async {
    final List<SessionRecord> all = await store.recent();
    int worked = 0;
    int done = 0;
    for (final SessionRecord r in all) {
      worked += r.workedSeconds;
      if (r.isComplete) done++;
    }
    return RecordedSummary(
      sessions: all.length,
      completed: done,
      workedSeconds: worked,
      unreadableRecords: await store.unreadableRecords(),
    );
  }
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
    final List<SessionRecord> all = (await _readAll()).records;
    all.sort((SessionRecord a, SessionRecord b) =>
        b.completedAt.compareTo(a.completedAt));
    if (limit == null || limit >= all.length) return all;
    return all.sublist(0, limit);
  }

  @override
  Future<int> workedSecondsFor(String lessonId) async {
    int total = 0;
    for (final SessionRecord r in (await _readAll()).records) {
      if (r.lessonId == lessonId) total += r.workedSeconds;
    }
    return total;
  }

  @override
  Future<int> unreadableRecords() async => (await _readAll()).unreadable;

  /// Kayıtlar VE atlananların sayısı — ikisi AYNI okumadan gelmek zorunda.
  ///
  /// Ayrı ayrı okusaydım (bir tarama kayıt için, bir tarama sayaç için) iki
  /// tarama arasında dosyaya yazılan bir seans, "3 kayıt + 1 kayıp" gibi
  /// birbirini tutmayan bir çift üretebilirdi. Beyan, beyan ettiği sayıyla
  /// aynı anda ölçülmüş olmalı.
  Future<({List<SessionRecord> records, int unreadable})> _readAll() async {
    // DEĞİŞTİRİLEBİLİR liste dönmek zorunlu: `recent()` sonucu yerinde
    // sıralıyor. `const []` dönmek boş-geçmiş yolunu — yani İLK AÇILIŞI —
    // çökertiyordu; testin yakaladığı gerçek kusur.
    if (!await _file.exists()) {
      return (records: <SessionRecord>[], unreadable: 0);
    }
    final List<SessionRecord> out = <SessionRecord>[];
    int skipped = 0;
    for (final String raw in (await _file.readAsString()).split('\n')) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      // BOZUK SATIR TÜM GEÇMİŞİ SİLMEZ. Yarım yazılmış ya da gelecekten
      // gelen bir satır yüzünden kullanıcının aylarca birikmiş kaydını
      // okunamaz ilan etmek, veriyi kaybetmekle aynı sonucu verir —
      // o satır atlanır, gerisi okunur.
      //
      // ⚠️ AMA SESSİZ ATLAMAZ (J-092). Atlananlar sayılıyor ve yüzeye kadar
      // taşınıyor: dayanıklılık kararı doğru, dayanıklılığı gizlemek yanlış.
      // Sessiz hâlinde 50 satırın 40'ı bozulunca özet "10 seans" der ve bunu
      // gerçekten 10 seans yapılmış gibi aynı güvenle söylerdi.
      try {
        final Map<String, dynamic> j =
            (jsonDecode(line) as Map).cast<String, dynamic>();
        final int v = (j['v'] as num?)?.toInt() ?? 0;
        // Sürüm uyuşmazlığı da bir KAYIPTIR: satır sağlam olabilir ama bu
        // sürüm onu okuyamıyor — kullanıcı açısından sonuç aynı, eksik özet.
        if (v != schemaVersion) {
          skipped++;
          continue;
        }
        out.add(SessionRecord.fromJson(j));
      } on Object catch (_) {
        skipped++;
        continue;
      }
    }
    return (records: out, unreadable: skipped);
  }
}
