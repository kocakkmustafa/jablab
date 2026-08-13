import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';

import 'content_failure.dart';
import 'session_narrator.dart';
import 'session_store.dart';
import 'pose_model.dart';
import 'rehearse_material.dart';
import 'teach_material.dart';
import 'package:jablab_engine/jablab_engine.dart';

import '../shell_candidate/shell_models.dart';

/// İçeriği asset'lerden yükler ve kabuğun nötr modellerine çevirir.
///
/// **Çeviri katmanı bilinçli:** kabuk `Discipline`/`RuleSet` gibi alan
/// tiplerini görmez (bkz. `shell_candidate/README.md` sözleşmesi), yoksa
/// `motion_shell`'e terfi ettiğinde boks kural motorunu da beraberinde
/// taşırdı. Alan → kabuk dönüşümü **yalnız burada** olur.
final class ContentRepository {
  const ContentRepository({this.storeOverride, this.loadStringOverride});

  /// Asset okuma dikişi — YALNIZ test için, `storeOverride` ile aynı gerekçe.
  ///
  /// Neden var: dürüst hata ekranının (J-079) uçtan uca sınanması "bozuk bir
  /// içerik güncellemesi cihaza ulaştı" hâlini kurmayı gerektiriyor.
  /// Alternatif olarak `flutter/assets` kanalı taklit edilmişti ve **çalışmadı
  /// — ölçüldü:** kanal yalnız bizim üç asset'imizi değil, framework'ün
  /// istediği her şeyi (font/manifest) taşıyor; hepsini dosyadan servis
  /// etmeye çalışan taklit, uygulamayı sonsuz yükleme hâlinde bırakıyordu.
  /// Bu dikiş üretimde `null` ve tek bir yerde okunuyor ([_loadString]).
  final Future<String> Function(String assetKey)? loadStringOverride;

  Future<String> _loadString(String key) =>
      loadStringOverride?.call(key) ?? rootBundle.loadString(key);

  /// Denetim/testte gerçek dosya sistemine gitmeden depo enjekte etmek için
  /// (J-070). Üretimde `null` — `openStore()` o zaman gerçek JSONL deposunu
  /// açar. Bu alan olmadan uçtan-uca ship denetimi kaydı DOĞRULAYAMAZ:
  /// `path_provider` widget testinde çalışmaz ve seans akışı kayıtsız koşar,
  /// yani denetim en kritik bacağı ölçmeden "geçti" derdi.
  final SessionStore? storeOverride;

  static const String libraryAsset = 'assets/content/library.json';
  static const String boxingRuleSetAsset = 'assets/rulesets/boxing@1.0.0.json';

  static const String cuesAsset = 'assets/content/cues.en.json';

  /// İLERLEME KAPILARI (J-208). **Bu asset 2026-08-12'ye kadar üretimde HİÇ
  /// YÜKLENMİYORDU** — paketleniyordu ama onu okuyan tek şey testlerdi, yani
  /// 16 kapı bir içerik beyanıydı, bir ürün davranışı değil (J-207). Kapı
  /// sisteminin eksik TÜKETİCİSİ buradan başlıyor.
  static const String curriculumAsset = 'assets/content/curriculum.json';

  /// Eklem anahtarı → kullanıcıya gösterilen ad. `RuleSet.stanceCoachedOnlyJoints`
  /// bu sözlükten okunmadan ürüne çıkamaz (bkz. [coachedNotScoredLabels]) —
  /// bir eklem kovası değişince (M-F-51 türü yeniden hesap) metnin eski
  /// kovayı anlatmaya devam etmesini engelleyen tek şey bu zorunluluk.
  static const Map<String, String> _jointLabels = <String, String>{
    'lead_hip': 'Lead hip position',
    'lead_knee': 'Lead knee position',
    'rear_knee': 'Rear knee position',
    'lead_thigh': 'Lead thigh placement',
    'rear_shin': 'Rear shin angle',
    'lead_shoulder': 'Lead shoulder position',
    'lead_shin': 'Lead shin angle',
    'rear_shoulder': 'Rear shoulder position',
    'rear_hip': 'Rear hip position',
    'rear_thigh': 'Rear thigh placement',
    'lead_elbow': 'Lead elbow angle',
    'rear_elbow': 'Rear elbow angle',
    'lead_upper_arm': 'Lead upper arm angle',
    'rear_upper_arm': 'Rear upper arm angle',
    'lead_forearm': 'Lead guard hand position',
    'rear_forearm': 'Rear guard hand position',
    'trunk_tilt': 'Torso lean',
  };

  /// Seans özetinin "coached but not scored" listesi — config'in
  /// `stanceCoachedOnlyJoints`'inden TÜRETİLİR, elle kopyalanmaz (J-033/
  /// rule 9). Beyansız eklem sessizce atlanmaz: sözlükte karşılığı olmayan
  /// bir anahtar, kovalar arasında bir eklem taşındığında fark edilmeden
  /// metnin bayatlamasını önlemek için burada FIRLATIR.
  List<String> coachedNotScoredLabels(RuleSet boxing) =>
      _labelsFor(boxing.stanceCoachedOnlyJoints);

  /// Jab'ın "coached but not scored" listesi (J-061). Duruştan AYRI tutulur
  /// çünkü kovalar farklı: jab'da öncü kol da koçlanan tarafta — tekniğin
  /// kendisi ölçülüyor ama eğitmen uzlaşısı olmadığı için yargılanmıyor.
  List<String> jabCoachedNotScoredLabels(RuleSet boxing) =>
      _labelsFor(boxing.jabCoachedOnlyJoints);

  /// Ekranda gösterilecek BANT haritası — kural setinin
  /// `trackedComponents`ından TÜRETİLİR, elle yazılmaz (J-144).
  ///
  /// Önce iki ekran kendi üçlüsünü elle yazıyordu ve ikisi FARKLIYDI:
  /// özet `Stance·Balance·Footwork`, Sayfa B `Guard discipline·Punch
  /// mechanics·Balance`. Üstelik `Guard discipline` **puanlanmayan** bir
  /// bileşendi ve *"kalibrasyon gelene kadar bant"* başlığının altında
  /// duruyordu — **karşılıksız bir vaat**, çünkü o bileşen kalibrasyonla
  /// değil eğitmen uzlaşmazlığıyla kapalı.
  ///
  /// Değer `—`: K8 kalibrasyon kapısı geçilmeden sayı yok.
  Map<String, String> gradedBands(RuleSet boxing) => <String, String>{
        for (final TrackedComponent c in boxing.gradedComponents)
          c.displayName: '—',
      };

  List<String> _labelsFor(List<String> keys) => keys.map((String key) {
        final String? label = _jointLabels[key];
        if (label == null) {
          throw StateError('coachedOnlyJoints eklemi "$key" için etiket yok — '
              'ContentRepository._jointLabels güncellenmeli');
        }
        return label;
      }).toList(growable: false);

  /// Seans geçmişi deposunu açar (J-064).
  ///
  /// `path_provider` yalnız uygulama-özel dizini bulmak için; depolama
  /// biçiminin kendisi uygulamada (append-only JSONL). Üçüncü-taraf DB
  /// bilerek yok — sorgu ihtiyacı ÖLÇÜLDÜĞÜNDE gelir.
  Future<SessionStore> openStore() async {
    final SessionStore? injected = storeOverride;
    if (injected != null) return injected;
    final Directory dir = await getApplicationSupportDirectory();
    return JsonlSessionStore(File('${dir.path}/sessions.jsonl'));
  }

  /// Bir dersin tur planını alan kütüphanesinden arar (J-063).
  ///
  /// Kabuk modeli planı taşımaz — kabukta "round" alan sözlüğüdür ve
  /// `shell_candidate/README.md` sözleşmesi onu yasaklıyor. Çeviri katmanının
  /// işi tam bu: kabuk nötr kalır, plan app tarafında çözülür.
  RoundPlan? roundPlanFor(Library lib, String lessonId) =>
      _lessonFor(lib, lessonId)?.roundPlan;

  /// Aralık planı (J-068) — aynı çeviri katmanı, aynı sebep.
  IntervalPlan? intervalPlanFor(Library lib, String lessonId) =>
      _lessonFor(lib, lessonId)?.intervalPlan;

  /// Ders KAMERA hattını açar mı — İÇERİKTEN (J-096).
  bool usesCamera(Library lib, String lessonId) =>
      _lessonFor(lib, lessonId)?.usesCamera ?? false;

  /// Poz modelini asset'ten diske çıkarır — MediaPipe bir DOSYA YOLU
  /// istiyor, asset bundle'ı okuyamıyor (J-096).
  ///
  /// Dev-harness'tan buraya taşındı: canlı ders ve harness AYNI yolu
  /// kullanmalı, yoksa iki kopya çıkar ve biri güncellenmeyi unutur.
  /// SHA doğrulaması `tool/fetch_pose_model.sh` + `model_pin_test`te;
  /// burada her açılışta yeniden hash'lemek çıkarma maliyetini ikiye
  /// katlardı.
  Future<String> materializePoseModel() async {
    final Directory dir = await getApplicationSupportDirectory();
    final File out =
        File('${dir.path}/${PoseModelPin.assetPath.split('/').last}');
    if (!out.existsSync()) {
      final ByteData data = await rootBundle.load(PoseModelPin.assetPath);
      await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return out.path;
  }

  /// Dersin anlatım materyali (J-094) — **tek karar noktası**.
  ///
  /// Ekran bu soruyu kendisi cevaplamaz. Eskiden cevabı ekranın içinde elle
  /// yazılmış bir cümle veriyordu (*"watch first"*) ve o cümle hiçbir içerik
  /// tarafından desteklenmiyordu; J-047'de aynı sınıftan bir kusur (elle
  /// kopyalanmış `coachedNotScored` listesi) config'le çelişerek yakalanmıştı.
  ///
  /// Bugün **hiçbir derste materyal yok** ve bu bir varsayım değil ölçülebilir
  /// bir olgu: `Lesson` modelinde materyal alanı bulunmuyor. Comp geldiğinde
  /// değişecek TEK yer burası — ekran zaten türetiyor.
  TeachMaterial teachMaterialFor(Library lib, String lessonId) {
    // Ders bulunamazsa da YOKLUK döner, fırlatmaz: seans akışı bir içerik
    // arama hatası yüzünden kesilmemeli — ama sebep AYRI yazılır, yoksa iki
    // farklı durum ("materyal yok" / "ders yok") aynı cümleye düşerdi.
    if (_lessonFor(lib, lessonId) == null) {
      return const TeachMaterialNone(
          reason: 'We could not find this lesson in the library, so there is '
              'nothing to show here.');
    }
    // İÇERİKTEN TÜRETİLİR (J-118). `TeachMaterialText` varyantı J-094'ten
    // beri VARDI ve render ediliyordu — ama hiçbir yer ONU ÜRETMİYORDU,
    // yani 17 canlı dersin 17'sinde de öğretme aşaması boştu. Tanıdık
    // desen: biçimin varlığı üreticisinin varlığı değildir.
    final String? teach = _lessonFor(lib, lessonId)?.teach;
    if (teach != null && teach.trim().isNotEmpty) {
      return TeachMaterialText(body: teach);
    }
    return const TeachMaterialNone(
        reason: 'There is no lesson material to watch or read here — we '
            'have not made it. The session still works: the next step is you '
            'moving, and nothing is scored while you learn the shape.');
  }

  /// Prova aşamasının materyali (J-247) — `teachMaterialFor`un kardeşi.
  ///
  /// Aynı sözleşme: ders bulunamazsa FIRLATMAZ, yokluğu AYRI bir sebeple
  /// döner. İki farklı durumu ("teknik listelenmemiş" / "ders yok") tek
  /// cümleye düşürmek, ekranın onları ayırt etmesini imkânsız kılardı.
  RehearseMaterial rehearseMaterialFor(Library lib, String lessonId) {
    final Lesson? l = _lessonFor(lib, lessonId);
    if (l == null) {
      return const RehearseMaterialNone(
          reason: 'We could not find this lesson in the library, so there is '
              'nothing to name here.');
    }
    // İÇERİKTEN TÜRETİLİR — hiçbir dizge burada UYDURULMUYOR; `techniques`
    // ve `combinations` `library.json`da yazılı ve aynı ders kartının alt
    // başlığında zaten gösteriliyor.
    if (l.techniques.isEmpty) {
      return const RehearseMaterialNone(
          reason: 'This lesson does not drill a named technique — the shape '
              'itself is the work. Move through it slowly and stay in frame.');
    }
    return RehearseMaterialDrill(
      techniques: l.techniques,
      combinations: l.combinations,
    );
  }

  Lesson? _lessonFor(Library lib, String lessonId) {
    for (final Discipline d in lib.disciplines) {
      for (final Course c in d.courses) {
        for (final Lesson l in c.lessons) {
          if (l.id == lessonId) return l;
        }
      }
    }
    return null;
  }

  /// Replik kitabı. Yükleme sırasında eşleme doğrulanır: bir olayın repliği
  /// yoksa [CueBook.fromJson] FIRLATIR. Sessizce boş geçmek, o anı sonsuza
  /// kadar sessiz bırakırdı ve kullanıcı sessizliği "sorun yok" diye okur.
  Future<CueBook> loadCues() async => CueBook.fromJson(
      await _loadString(cuesAsset), jabLabCueMapping);

  /// İlerleme kapıları (J-208) — ham harita olarak.
  ///
  /// `Library`/`RuleSet` gibi tiplenmiş bir modele çevrilmiyor: bu turun
  /// kapsamı **tek bir kapı sınıfı** (olay-sayımı) ve o sınıfı okuyan tek
  /// yer [evaluateEventGate]. Dört sınıfın tamamını taşıyan bir tip
  /// tanımlamak, bugün üçünün üreticisi yokken kullanılmayan üç dal
  /// üretirdi — tam da bu hattın söktüğü ölü-mekanizma sınıfı.
  Future<Map<String, dynamic>> loadCurriculum() async =>
      (jsonDecode(await _loadString(curriculumAsset)) as Map)
          .cast<String, dynamic>();

  Future<({Library library, RuleSet boxing})> load() async {
    final Library lib = Library.fromJson(
        (jsonDecode(await _loadString(libraryAsset)) as Map)
            .cast<String, dynamic>());
    final RuleSet boxing = RuleSet.fromJson(
        (jsonDecode(await _loadString(boxingRuleSetAsset)) as Map)
            .cast<String, dynamic>());

    // Dürüstlük değişmezleri çalışma zamanında da denetlenir: bozuk bir
    // içerik güncellemesi testleri atlayıp cihaza ulaşırsa, uygulama sessizce
    // sahte kurs göstermek yerine burada patlar.
    final List<String> errs = lib.validate(<String, RuleSet>{'boxing': boxing});
    if (errs.isNotEmpty) {
      // TİPLİ fırlatma (J-079): eskiden bu bir `StateError`'dı ve UI katmanı
      // onu `'$e'` diye ekrana basıyordu. Hata ekranının davranışı sınıfa
      // göre değişmek zorunda (bütünlük hatasında "yine dene" yalan olur),
      // ve sınıfı hata METNİNDEN çıkarmak sessizce kırılacak bir bağ olurdu.
      throw ContentIntegrityException(errs);
    }
    return (library: lib, boxing: boxing);
  }

  ShellLibrary toShell(Library lib) => ShellLibrary(
        title: lib.productName,
        whyNotIntro: lib.whyNotIntro,
        items: lib.disciplines.map(_item).toList(growable: false),
        exclusions: lib.excluded
            .map((ExcludedItem e) => ShellExclusion(e.displayName, e.reason))
            .toList(growable: false),
      );

  ShellItem _item(Discipline d) => ShellItem(
        id: d.id,
        title: d.displayName,
        status: d.status == DisciplineStatus.live
            ? ItemStatus.live
            : ItemStatus.comingSoon,
        waveLabel: d.wave,
        blurb: d.blurb,
        measured: d.measured,
        notMeasured: d.notMeasured,
        courses: d.courses
            .map((Course c) => ShellCourse(
                  id: c.id,
                  title: c.displayName,
                  goal: c.goal,
                  level: c.level,
                  minutes: c.estimatedMinutes,
                  lessons: c.lessons
                      .map((Lesson l) => ShellLesson(
                            id: l.id,
                            title: l.displayName,
                            minutes: l.minutes,
                            subtitle: l.techniques.isEmpty
                                ? ''
                                : l.techniques.join(' · '),
                            lockedReason: l.lockedReason,
                          ))
                      .toList(growable: false),
                ))
            .toList(growable: false),
      );
}
