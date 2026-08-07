import 'package:flutter/material.dart';

import '../shell_candidate/honesty_box.dart';
import '../shell_candidate/shell_models.dart';
import 'design_tokens.dart';

/// Sayfa A — Disiplin & Kurs Seçimi (design: `docs/design/DESIGN-PANEL-PROMPT.md`
/// §2). Bu app'in giriş yüzeyi; hiç kurs başlatılmamışsa uygulamayı ilk
/// karşılayan sayfa da budur (Hüküm 3, koordinatör 2026-08-06).
///
/// Seçilen disiplinin kursları AYNI SAYFADA açılır — kurucu direktifi "az
/// sayfa": eskiden ayrı bir push olan Öğe sayfası burada satır-içi genişleme
/// oldu. `lib/shell_candidate/` DONDURULMUŞ envanterine yeni bileşen olarak
/// EKLENMEDİ (bkz. `shell_candidate/README.md`) — bu yüzden bu widget
/// bilerek `lib/app/` altında yaşıyor; yalnız zaten var olan, domain-bağımsız
/// `HonestyBox`u değiştirmeden reuse ediyor.
///
/// Görsel giydirme design turu Parça 4 (2026-08-06/07, SON parça) —
/// `design_tokens.dart` tokenlarıyla, Ayarlar/Sayfa B ile AYNI dilde.
/// `HonestyBox` frozen olduğu için (yalnız bu dosyanın reuse ettiği tek
/// paylaşılan bileşen) yerel bir `Theme(data:, child:)` sarmalıyla besleniyor
/// — Parça 2'nin `jablabSessionTheme` deseninin küçük ölçekli tekrarı.
/// "Soon" rozeti ve "Neden yok?" bağlantısı Ayarlar'ın "FREE PLAN" rozeti/
/// "why-not-link" satırıyla BİREBİR aynı görsel kalıptan — aynı kavram iki
/// ekranda iki farklı dil konuşmasın diye.
class SelectPage extends StatefulWidget {
  const SelectPage({
    super.key,
    required this.library,
    required this.onOpenCourse,
    required this.onOpenWhyNot,
    required this.onOpenSettings,
    this.historyUnavailable,
    this.onRetryHistory,
  });

  final ShellLibrary library;
  final void Function(ShellCourse) onOpenCourse;
  final VoidCallback onOpenWhyNot;
  final VoidCallback onOpenSettings;

  /// Geçmiş TAMAMEN okunamadıysa (hangi dersin/kursun "güncel" olduğu bile
  /// bilinemiyor — bu yüzden Sayfa B'ye değil buraya düşülüyor) gösterilecek
  /// beyan. `null` ise hiçbir şey basılmaz.
  ///
  /// **Bu alan olmadan J-092 kusuru burada YENİDEN doğardı:** kurs
  /// çözülemiyorsa giriş Sayfa A'ya düşer (Hüküm 3) — ama "kurs yok" ile
  /// "kursu SÖYLEYEMİYORUM" aynı şey değildir. Bu alan yokken ikisi de aynı
  /// boş seçim ekranına dönüşüyordu: "bilmiyorum" sessizce "hiç yapmadın"a
  /// dönüşmüş oluyordu — tam da doc-75/J-092'nin yasakladığı karışıklık.
  final String? historyUnavailable;
  final VoidCallback? onRetryHistory;

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: JColors.ground,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[const Color(0xFF170809), JColors.ground],
              stops: const <double>[0, .42],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.library.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JText.pageTitle.copyWith(fontSize: 22, letterSpacing: -.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlassIconButton(
                      key: const Key('settings-button'),
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onTap: widget.onOpenSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (widget.historyUnavailable != null) ...<Widget>[
                  // Tier 2-d: "hangi kurs güncel" bile bilinemiyor — bu TAM
                  // OLARAK `UnknownGlassPanel`in rezerve ettiği "bilmiyorum"
                  // (Sayfa B'nin aynı beyanla AYNI tier'ı kullanmasıyla
                  // tutarlı, bkz. course_page.dart).
                  UnknownGlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Where you left off',
                            key: const Key('recorded-heading'),
                            style: JText.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(widget.historyUnavailable!,
                            key: const Key('recorded-unavailable'),
                            style: JText.bodyMuted),
                        if (widget.onRetryHistory != null) ...<Widget>[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            key: const Key('retry-history'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: JColors.ink,
                              side: BorderSide(color: JColors.border),
                            ),
                            onPressed: widget.onRetryHistory,
                            child: const Text('Try again'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...widget.library.items.map((ShellItem i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ItemBlock(
                        item: i,
                        expanded: _expandedId == i.id,
                        onTap: () => setState(
                            () => _expandedId = _expandedId == i.id ? null : i.id),
                        onOpenCourse: widget.onOpenCourse,
                      ),
                    )),
                const SizedBox(height: 6),
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    key: const Key('why-not-button'),
                    onTap: widget.onOpenWhyNot,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.help_outline, color: JColors.ember, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text("Why isn't my art here?",
                              style: JText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        Icon(Icons.chevron_right, color: JColors.ember, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ItemBlock extends StatelessWidget {
  const _ItemBlock({
    required this.item,
    required this.expanded,
    required this.onTap,
    required this.onOpenCourse,
  });

  final ShellItem item;
  final bool expanded;
  final VoidCallback onTap;
  final void Function(ShellCourse) onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final bool live = item.status == ItemStatus.live;
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            key: Key('item-${item.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.title,
                            style: JText.body.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                          live
                              ? '${item.courses.length} course${item.courses.length == 1 ? '' : 's'}'
                              : item.blurb,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: JText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (live)
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        color: JColors.ink3)
                  else
                    // `waveLabel` BİLEREK GEÇİLMİYOR (J-150, koordinatör
                    // hükmü 10:12). Değerler `W1`→`W4` idi ve iki kusur
                    // taşıyorlardı: kullanıcıya **hiçbir şey ifade
                    // etmiyorlar** (bilgi değeri sıfır) ama `W1→W4` bir
                    // **SIRA** kuruyor (vaat değeri pozitif). Sıfır bilgi +
                    // pozitif vaat = kaldırılır.
                    _SoonBadge(key: Key('soon-${item.id}')),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!live)
                    UnknownGlassPanel(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 14,
                      child: Text(
                        // J-150 ③: eski metin *"We list it so you can see
                        // where this is going"* diyordu — **cümlesel** bir
                        // vaat, ve kapının kelime listesinde yok. Yani aynı
                        // kartta İKİ ayrı vaat vardı: biri şemada (`W1`),
                        // biri cümlede. Yeni metin NEDEN listelediğimizi
                        // söylüyor (kapsamı görünür kılmak), NEREYE gittiğini
                        // değil.
                        'Not open. We list it so you can see the whole scope '
                        'of what this app covers — there are no placeholder '
                        'lessons behind this page.',
                        key: const Key('coming-soon-note'),
                        style: JText.bodyMuted,
                      ),
                    ),
                  if (item.blurb.isNotEmpty && live) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(item.blurb, style: JText.body.copyWith(color: JColors.ink2, fontSize: 14)),
                  ],
                  // `HonestyBox` frozen (shell_candidate) — `Theme.of(context)`
                  // üzerinden besleniyor, JColors'ı doğrudan okuyamıyor.
                  //
                  // KAPALI DİSİPLİNDE ÇİZİLMİYOR (J-137, koordinatör hükmü
                  // 08:47). Ölçüldü (gerçek render): kapalı bir kartta
                  // kullanıcı aynı olguyu DÖRT kez görüyordu — `NOT OPEN`
                  // rozeti · "Not open · W1. We list it so…" notu · kutunun
                  // ÖLÇÜLENLER tarafı ("This section is not open.") ·
                  // ÖLÇÜLMEYENLER tarafı ("This discipline is not open").
                  // Son ikisi ölçüm cümlesi DEĞİL: **kapalı olmak bir ölçüm
                  // sınırı değildir.**
                  //
                  // Kap ölçüm beyanı içindir; ölçüm yoksa kap yanlıştır.
                  // Tutarlılık uğruna boş kap doldurmak sahte dolulukdur ve
                  // tautoloji yazardan değil ORADAN doğuyor.
                  //
                  // Alternatif ("açılınca ölçemeyeceklerimizi yaz") REDDEDİLDİ:
                  // kapalı disiplinin gerçek ölçüm sınırı YOK — hiç ölçmüyor.
                  // Var olmayan bir motorun sınırını iddia etmek, tautolojiden
                  // daha pahalı bir yanlış olurdu.
                  //
                  // Bilgi kaybı yok: gerekçe altbaşlıkta (render ile
                  // doğrulandı), durum rozette ve notta.
                  if (live)
                    Theme(
                      data: _honestyBoxTheme,
                      child: HonestyBox(
                          measured: item.measured, notMeasured: item.notMeasured),
                    ),
                  if (live) ...<Widget>[
                    const SizedBox(height: 6),
                    Text('Courses', style: JText.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...item.courses
                        .where((ShellCourse c) => c.lessons.isNotEmpty)
                        .map((ShellCourse c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassPanel(
                                tier: GlassTier.observation,
                                padding: const EdgeInsets.all(14),
                                child: InkWell(
                                  key: Key('course-${c.id}'),
                                  onTap: () => onOpenCourse(c),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(c.title,
                                                style: JText.body.copyWith(fontWeight: FontWeight.w600)),
                                            if (c.goal.isNotEmpty) ...<Widget>[
                                              const SizedBox(height: 3),
                                              Text(c.goal,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: JText.bodyMuted.copyWith(fontSize: 12.5)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('${c.lessons.length} lessons',
                                          style: JText.mono.copyWith(color: JColors.cool2)),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                  ],
                  if (item.pendingNotes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text('Not open in this section',
                        style: JText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    ...item.pendingNotes.map((String n) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $n', style: JText.bodyMuted),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Açık değil" rozeti — Ayarlar'ın "FREE PLAN" rozetiyle BİREBİR aynı kalıp
/// (settings_page.dart) — aynı görsel dil, iki ayrı icat değil.
///
/// ⚠️ Metin **"SOON" DEĞİL** (2026-08-07). Rozet bir kelimeyle konuşuyor ve
/// o kelime en yoğun beyandır: "SOON" tek başına bir takvim sözü verir ve
/// arkasında hiçbir tarih yok. Kartın altındaki cümle zaten *neden* açık
/// olmadığını isimli teknik gerekçesiyle söylüyor — rozetin işi o gerekçeyi
/// tekrarlamak değil, DURUMU adlandırmak. `NOT OPEN` durum; `SOON` vaat.
///
/// Sınıf ve widget ANAHTARI (`soon-<id>`) bilerek DEĞİŞMEDİ: anahtarlar
/// kullanıcıya görünmez ve testlerin tutunduğu yüzeydir; görünmeyen bir adı
/// değiştirmek görünen bir kusuru düzeltmez, yalnız gürültü üretir.
/// Kapalı disiplin rozeti — **durum**, sıra DEĞİL.
///
/// Eskiden `NOT OPEN · W1` yazıyordu. `wave` alanı içerikte DURUYOR (meşru
/// iç planlama verisi) ama **yüzeye çıkmıyor**: `W1`/`W2`/`W3`/`W4` bir
/// numaralandırma ve numaralandırma bir **sıra**, sıra da bir **vaat**
/// (J-150). Vaat dili kapısı bunu göremedi çünkü kapı **kelimelere**
/// bakıyor (`yet`·`soon`·`will`) ve burada vaat **şemadaydı** — kelime
/// taraması bu sınıfa **tanımı gereği** kör.
///
/// ⚠️ Ve *"W1 ne demek"i açıklamak* bir çözüm DEĞİL: örtük yol haritası
/// vaadini **açık** hâle getirirdi.
class _SoonBadge extends StatelessWidget {
  const _SoonBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: JColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'NOT OPEN',
          // ⚠️ `ink3` idi ve ÖLÇÜLDÜ: 10 puntoda zemine karşı **3,51:1**,
          // WCAG 2.2 AA normal-metin eşiği 4,5. J-108'de bu rozetin
          // SÖZCÜĞÜNÜ düzelttim (`SOON` → `NOT OPEN`) ve KONTRASTINI hiç
          // ölçmedim; kontrast kapısı da onu göremedi çünkü token
          // VARSAYILANLARINI ölçüyor, yerinde `copyWith(color:)` ile
          // geçilenleri değil (J-126). Rozet 7 kapalı disiplin kartında var.
          style: JText.label.copyWith(color: JColors.ink2, letterSpacing: 1),
        ),
      );
}

/// `HonestyBox`un okuduğu tek yüzey (`Card`+`titleSmall`/`bodySmall`) —
/// design_tokens.dart'ın kendi `jablabSessionTheme`iyle AYNI eşleme deseni,
/// yalnız bu sayfanın frozen tek bileşenine ölçekli.
final ThemeData _honestyBoxTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  cardColor: const Color(0x13E4ECF3),
  cardTheme: const CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  iconTheme: IconThemeData(color: JColors.ink3),
  textTheme: TextTheme(
    titleSmall: JText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
    bodySmall: JText.bodyMuted,
  ),
);
