import 'package:flutter/material.dart';

/// Canlı seansta ekranın söyleyebileceği üç şey.
///
/// Üçüncüsü ürünün karakteri: **"göremiyorum" ayrı bir durumdur**, sessizlik
/// değil. Sessiz kalmak kullanıcıya "her şey yolunda" der; oysa analiz hiç
/// çalışmıyordur.
enum LiveState {
  /// Analiz çalışıyor, düzeltilecek bir şey yok.
  clean,

  /// Tek bir düzeltme veriliyor.
  correcting,

  /// Hüküm verilemiyor (kadraj/güven/yapısal) — sebebi SÖYLENİR.
  noVerdict,
}

/// Canlı seans yüzeyi — ürünün yıldızı (standart §3).
///
/// İlkeler burada widget seviyesinde tutulur:
/// - **Aynı anda TEK düzeltme.** Liste göstermek, telefonu uzağa koymuş bir
///   kullanıcı için gürültüdür ve hiçbirini uygulayamaz.
/// - **Ses birincil, metin minimal.** Ekran teyit içindir, okumak için değil.
/// - **"Göremiyorum" gizlenmez.** Analiz duruyorsa ekran bunu söyler.
class LiveCoachSurface extends StatelessWidget {
  const LiveCoachSurface({
    super.key,
    required this.state,
    required this.eventCount,
    this.cue,
    this.narration,
    this.noVerdictReason,
    this.preview,
  });

  final LiveState state;

  /// Sayılan olay adedi (yumruk, tekrar, adım…). Alan-bağımsız.
  ///
  /// **`null` = HENÜZ SAYILMIYOR** ve bu ayrım J-096'da simülatörde
  /// bulundu: analiz hiç başlamamışken (izin reddi, kamera açılamadı, ilk
  /// kare gelmedi) ekranda kocaman bir **0** duruyordu — yani "sıfır yumruk
  /// attın". Oysa hiçbir şey ÖLÇÜLMEDİ. J-092'nin ("hiç yapmadın ≠
  /// bilmiyorum") canlı ekrandaki birebir tekrarı.
  ///
  /// Koşan bir seansta geçici olarak hüküm verilemiyorsa sayı YİNE gösterilir
  /// — o sayı gerçek: "3 attın, şimdi göremiyorum". İkisi farklı hâller ve
  /// tek bir `int` ikisini de anlatamıyordu.
  final int? eventCount;

  /// Tek cümlelik düzeltme metni — **HÜKÜM** yuvası.
  final String? cue;

  /// Zamanlama/ritim anlatısı ("yarıladın", "on saniye").
  ///
  /// Hükümden AYRI yuvada durur ve hüküm susturulmuşken bile konuşabilir:
  /// süre saymak poza bakmayı gerektirmez. Aynı yuvayı paylaşsalardı,
  /// "göremiyorum" durumundaki kullanıcı ekranda beliren "yarıladın"ı
  /// sistemin kendisini yargıladığı sanırdı.
  final String? narration;

  /// Hüküm verilemiyorsa kullanıcıya söylenecek sebep.
  final String? noVerdictReason;

  /// App'e özgü görsel (kamera önizlemesi, iskelet overlay).
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHighest,
            child: preview ??
                const Center(child: Icon(Icons.videocam_outlined, size: 48)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              // SAYI YOKSA YUVA DA YOK. `0` çizmek "sıfır yaptın" demektir
              // ve analiz hiç başlamamışken bu bir ölçüm değil, bir yalandır.
              if (eventCount != null) ...<Widget>[
                Text('$eventCount',
                    key: const Key('event-count'),
                    style: theme.textTheme.displayMedium),
                const SizedBox(height: 12),
              ],
              switch (state) {
                LiveState.correcting => Text(
                    cue ?? '',
                    key: const Key('live-cue'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                LiveState.noVerdict => Column(
                    key: const Key('live-no-verdict'),
                    children: <Widget>[
                      Icon(Icons.visibility_off_outlined,
                          size: 20, color: theme.colorScheme.error),
                      const SizedBox(height: 6),
                      Text(
                        noVerdictReason ?? "I can't see you well enough to judge",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                LiveState.clean => Text('Keep going',
                    key: const Key('live-clean'),
                    style: theme.textTheme.titleMedium),
              },
              // Anlatı HER durumda görünebilir — hüküm susarken bile.
              // Ayrı yuva, ayrı ton: ikincil, sessiz, yargı taşımaz.
              if (narration != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(narration!,
                    key: const Key('live-narration'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Seans özeti — bileşen bantları + ölçülemeyenler.
class SessionSummaryView extends StatelessWidget {
  const SessionSummaryView({
    super.key,
    required this.eventCount,
    required this.bands,
    required this.coachedNotScored,
    this.topIssue,
    this.unitsCompleted = 0,
    this.unitLabel = '',
    this.workedSeconds = 0,
  });

  /// Bu seansta sayılan olay — **`null` = ANALİZ HİÇ KOŞMADI** (J-156).
  ///
  /// Alan önce non-nullable `int` idi ve çağıran taraf sabit `0` geçiyordu:
  /// kullanıcı kaç yumruk atarsa atsın özet **"0 recorded this session"**
  /// diyordu. Çıplak `0`, *"hiç yapmadın"* diye okunur (J-092/J-096) — ve
  /// burada olan daha kötüsüydü: **ölçülmüş bir olgu atılıp yerine yanlışı
  /// gösteriliyordu.**
  ///
  /// ⚠️ DONMUŞ AĞAÇ DEĞİŞİKLİĞİ, koordinatör hükmü 2026-08-07 11:04.
  /// Gerekçe: *"bilinmiyor" ↔ "sıfır"* ayrımı bu dosyada **zaten vardı**
  /// ([LiveCoachSurface.eventCount] `int?`); yeni bir kavram eklenmedi,
  /// **var olan ayrım taşındı** — envanter büyümüyor, TUTARLI hâle geliyor.
  /// Aynı dosyada iki benzer alanın biri `int?` biri `int` olması zaten bir
  /// tutarsızlıktı.
  final int? eventCount;

  /// Bileşen → bant. K8 (M-F-04): kalibrasyon kapısı geçilmeden SAYI yok.
  final Map<String, String> bands;

  /// Koçlanan ama SKORLANMAYAN başlıklar — eğitmenlerin anlaşmadığı yerler.
  /// Kullanıcıya söylenir: neden puan almadığını bilmek hakkı.
  final List<String> coachedNotScored;

  final String? topIssue;

  /// Bu seansta tamamlanan birim sayısı (J-259). `_SessionScreenState`
  /// içinde zaten izleniyor ve diske yazılıyordu
  /// ([SessionRecord.unitsCompleted]) — özete hiç geçmiyordu. Varsayılan
  /// `0` diğer alanlarla tutarlı (canlı aşamaya hiç girilmezse zaten 0'da
  /// kalır — bu ekrana yalnız `live`dan SONRA gelinir).
  final int unitsCompleted;

  /// Birimin ADI — **app'ten TAM ÇÖZÜLMÜŞ hâliyle gelir** (M-F-25 terfi
  /// kapısı, `test/shell_promotion_test.dart`): kabuk klasörü gelecekte
  /// 5 app'e ortak terfi edecek, ve alan kelimesi (`round`/`interval`)
  /// buraya sabit yazılamaz.
  ///
  /// ⚠️ TEKİL/ÇOĞUL DA BURADA KARAR VERİLMEZ — çoğulluk bir SUNUM kuralı
  /// değil bir DİL kuralıdır (İngilizce sayıdan sonra çoğul ister, Türkçe
  /// istemez). Kabuğa "N==1 ise tekil" mantığı koymak, bugün yalnız
  /// İngilizce doğru olan bir kuralı ortak katmana gömerdi — kelimeden
  /// daha tehlikeli bir sızıntı, çünkü kapı onu YAKALAMAZ. Desen
  /// [SessionRecord.unitLabel]den (session_screen.dart) taşındı, icat
  /// edilmedi.
  final String unitLabel;

  /// Bu seansta çalışılan süre, saniye (J-259). Diske zaten yazılıyordu.
  ///
  /// ⚠️ SIFIR İKİ FARKLI OLGUYU ANLATABİLİR (J-257 dersi, burada da
  /// geçerli): `_workedLabel` 0 < sn < 60 durumunu "under a minute" diye
  /// ayırır — 17 saniye çalışan kullanıcı "0 min" GÖRMEMELİ.
  final int workedSeconds;

  /// `RecordedSummary.workedLabel` (session_store.dart) ile AYNI kural —
  /// iki ekran aynı olguyu farklı cümlelerle anlatırsa biri bayatlar.
  /// Burada kopya duruyor çünkü `RecordedSummary` ÇOKLU-seans toplamıdır
  /// (dosyadan okunur); bu tek, henüz kaydedilmemiş seans için o sınıfı
  /// kurmak yanlış soyutlama olurdu.
  String get _workedLabel {
    if (workedSeconds <= 0) return 'no time recorded';
    if (workedSeconds < 60) return 'under a minute';
    final int m = workedSeconds ~/ 60;
    if (m < 60) return '$m min';
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Analiz koşmadıysa SAYI DA CÜMLE DE çizilmiyor. Yalnız sayıyı
        // gizleyip *"recorded this session"* başlığını bırakmak, boş bir
        // iddia bırakırdı.
        if (eventCount != null) ...<Widget>[
          Text('$eventCount',
              key: const Key('summary-count'),
              style: theme.textTheme.displayMedium),
          Text('recorded this session', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
        ],
        // J-259: seans yapısı (tur+süre) `eventCount` (kameranın saydığı
        // yumruk) ile AYNI ŞEY DEĞİL — kamera hiç bağlı olmasa/hüküm
        // veremese bile kullanıcı turu bitirmiş, süre çalışmış olabilir.
        // Ayrı yuva, karıştırılmaz.
        Text(
          '$unitsCompleted $unitLabel • $_workedLabel',
          key: const Key('summary-worked'),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 20),
        if (bands.isNotEmpty) ...<Widget>[
          // J-251: bantlar hep "—" basıyordu, hiçbir açıklama yoktu — oysa
          // hemen altındaki "Coached but not scored" bölümünün gerekçesi
          // VARDI (H-24 dürüstlük asimetrisi: yalnız engellide konuşuyorduk).
          // Metin `course_page.dart`taki `_HonestBands`ten AYNEN alındı
          // (`bands-only-note`) — aynı olgu, tek cümle, iki yerde tutarlı.
          Text(
            'Scores are shown as bands until the thresholds are calibrated '
            'on real recordings. A precise-looking number we cannot back up '
            'would be worse than no number.',
            key: const Key('summary-bands-note'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
        ...bands.entries.map((MapEntry<String, String> e) => ListTile(
              key: Key('summary-band-${e.key}'),
              dense: true,
              title: Text(e.key),
              trailing: Text(e.value, style: theme.textTheme.titleSmall),
            )),
        if (topIssue != null) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('summary-top-issue'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(topIssue!),
            ),
          ),
        ],
        if (coachedNotScored.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Text('Coached but not scored', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Experienced instructors disagree about these, so we point them out '
            'but do not grade them.',
            key: const Key('coached-not-scored-note'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...coachedNotScored.map((String c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $c', style: theme.textTheme.bodySmall),
              )),
        ],
      ],
    );
  }
}
