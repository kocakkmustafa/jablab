import 'package:flutter/material.dart';

import 'honesty_box.dart';
import 'shell_models.dart';

/// Kütüphane → Öğe → Kurs → Ders sayfa şablonları (standart §2).
///
/// Kapsamın TAMAMI baştan görünür ("yakında" rozetiyle) — dar app algısı
/// yaratılmaz — ama **açılmamış öğede kurs listelenmez**. Bu kural burada
/// widget seviyesinde de tutulur: `_CourseList` yalnız `ItemStatus.live`
/// öğelerde çağrılır ve boş kurs render edilmez.
class LibraryPage extends StatelessWidget {
  const LibraryPage({
    super.key,
    required this.library,
    required this.onOpenItem,
    required this.onOpenWhyNot,
  });

  final ShellLibrary library;
  final void Function(ShellItem) onOpenItem;
  final VoidCallback onOpenWhyNot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(library.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...library.items.map((ShellItem i) => _ItemCard(
              item: i,
              onTap: () => onOpenItem(i),
            )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('why-not-button'),
          onPressed: onOpenWhyNot,
          icon: const Icon(Icons.help_outline),
          label: const Text("Why isn't my art here?"),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});

  final ShellItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool live = item.status == ItemStatus.live;
    return Card(
      child: ListTile(
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
            ? const Icon(Icons.chevron_right)
            : Chip(
                key: Key('soon-${item.id}'),
                label: Text(item.waveLabel.isEmpty
                    ? 'Soon'
                    : 'Soon · ${item.waveLabel}'),
              ),
        onTap: onTap,
      ),
    );
  }
}

class ItemPage extends StatelessWidget {
  const ItemPage({super.key, required this.item, required this.onOpenCourse});

  final ShellItem item;
  final void Function(ShellCourse) onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool live = item.status == ItemStatus.live;
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          if (item.blurb.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(item.blurb, style: theme.textTheme.bodyMedium),
          ],
          HonestyBox(measured: item.measured, notMeasured: item.notMeasured),
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
                  child: Text('• $n', style: theme.textTheme.bodySmall),
                )),
          ],
        ],
      ),
    );
  }
}

class CoursePage extends StatelessWidget {
  const CoursePage({super.key, required this.course, required this.onStart});

  final ShellCourse course;
  final void Function(ShellLesson) onStart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (course.goal.isNotEmpty)
            Text(course.goal, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          // Kilitli ders LİSTEDE KALIR ama açılmaz. Gizlemek kapsamı
          // saklardı; açmak ölçemediğimiz bir beceriye seans vermek olurdu.
          // Üçüncü yol: göster, açma, SEBEBİNİ yaz.
          ...course.lessons.map((ShellLesson l) => Card(
                child: ListTile(
                  key: Key('lesson-${l.id}'),
                  enabled: !l.isLocked,
                  leading: Icon(l.isLocked
                      ? Icons.lock_outline
                      : Icons.play_circle_outline),
                  title: Text(l.title),
                  subtitle: l.isLocked
                      ? Text(l.lockedReason!,
                          key: Key('locked-why-${l.id}'),
                          style: theme.textTheme.bodySmall)
                      : (l.subtitle.isEmpty ? null : Text(l.subtitle)),
                  isThreeLine: l.isLocked,
                  trailing:
                      l.minutes == 0 ? null : Text('${l.minutes} min'),
                  onTap: l.isLocked ? null : () => onStart(l),
                ),
              )),
        ],
      ),
    );
  }
}

class WhyNotPage extends StatelessWidget {
  const WhyNotPage({super.key, required this.library});

  final ShellLibrary library;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Why isn't my art here?")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(library.whyNotIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          ...library.exclusions.map((ShellExclusion e) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(e.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(e.reason, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
