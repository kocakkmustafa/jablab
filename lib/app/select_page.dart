import 'package:flutter/material.dart';

import '../shell_candidate/honesty_box.dart';
import '../shell_candidate/shell_models.dart';

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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.title),
        actions: <Widget>[
          IconButton(
            key: const Key('settings-button'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (widget.historyUnavailable != null) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Where you left off',
                        key: const Key('recorded-heading'),
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(widget.historyUnavailable!,
                        key: const Key('recorded-unavailable'),
                        style: theme.textTheme.bodySmall),
                    if (widget.onRetryHistory != null) ...<Widget>[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('retry-history'),
                        onPressed: widget.onRetryHistory,
                        child: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...widget.library.items.map((ShellItem i) => _ItemBlock(
                item: i,
                expanded: _expandedId == i.id,
                onTap: () => setState(
                    () => _expandedId = _expandedId == i.id ? null : i.id),
                onOpenCourse: widget.onOpenCourse,
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('why-not-button'),
            onPressed: widget.onOpenWhyNot,
            icon: const Icon(Icons.help_outline),
            label: const Text("Why isn't my art here?"),
          ),
        ],
      ),
    );
  }
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
    final ThemeData theme = Theme.of(context);
    final bool live = item.status == ItemStatus.live;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            key: Key('item-${item.id}'),
            title: Text(item.title),
            subtitle: Text(
              live
                  ? '${item.courses.length} course${item.courses.length == 1 ? '' : 's'}'
                  : item.blurb,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: live
                ? Icon(expanded ? Icons.expand_less : Icons.expand_more)
                : Chip(
                    key: Key('soon-${item.id}'),
                    label: Text(item.waveLabel.isEmpty
                        ? 'Soon'
                        : 'Soon · ${item.waveLabel}'),
                  ),
            onTap: onTap,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!live)
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Not open yet${item.waveLabel.isEmpty ? '' : ' · ${item.waveLabel}'}. '
                          'We list it so you can see where this is going — '
                          'there are no placeholder lessons behind this page.',
                          key: const Key('coming-soon-note'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  if (item.blurb.isNotEmpty && live) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(item.blurb, style: theme.textTheme.bodyMedium),
                  ],
                  HonestyBox(
                      measured: item.measured, notMeasured: item.notMeasured),
                  if (live) ...<Widget>[
                    Text('Courses', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...item.courses
                        .where((ShellCourse c) => c.lessons.isNotEmpty)
                        .map((ShellCourse c) => Card(
                              child: ListTile(
                                key: Key('course-${c.id}'),
                                title: Text(c.title),
                                subtitle: Text(c.goal),
                                trailing: Text('${c.lessons.length} lessons'),
                                onTap: () => onOpenCourse(c),
                              ),
                            )),
                  ],
                  if (item.pendingNotes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text('Not open yet in this section',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    ...item.pendingNotes.map((String n) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child:
                              Text('• $n', style: theme.textTheme.bodySmall),
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
