import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content_repository.dart';
import 'design_tokens.dart';
import 'solo_boxing_course.dart';
import 'solo_boxing_progress.dart';
import 'ui_language.dart';

String _copy(BuildContext context, CourseCopy value) =>
    value.inLanguage(turkish: UiLanguage.isTurkish(context));

/// A visible route to the complete course from both the first-run catalogue
/// and an existing legacy course. Its promise is a learning path, not a score.
class SoloCourseEntryCard extends StatelessWidget {
  const SoloCourseEntryCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => GlassPanel(
    tier: GlassTier.observation,
    padding: const EdgeInsets.all(18),
    child: InkWell(
      key: const Key('open-solo-boxing-course'),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            UiLanguage.text(
              context,
              en: 'SOLO BOXING PATH',
              tr: 'SOLO BOKS YOLU',
            ),
            style: JText.body.copyWith(
              color: JColors.cool,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            UiLanguage.text(
              context,
              en: '39 lessons · from stance to your own round',
              tr: '39 ders · duruştan kendi rauntuna',
            ),
            style: JText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            UiLanguage.text(
              context,
              en: 'Non-contact practice with a clear next step and saved self-reported progress.',
              tr: 'Temassız çalışma, belirgin sıradaki adım ve kaydedilen öz beyan ilerlemesi.',
            ),
            style: JText.bodyMuted,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                UiLanguage.text(context, en: 'Open course', tr: 'Kursu aç'),
                style: JText.body.copyWith(color: JColors.cool),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 18, color: JColors.cool),
            ],
          ),
        ],
      ),
    ),
  );
}

class SoloBoxingCoursePage extends StatefulWidget {
  const SoloBoxingCoursePage({
    super.key,
    required this.repository,
    this.accountUserId,
  });

  final ContentRepository repository;
  final ValueListenable<String?>? accountUserId;

  @override
  State<SoloBoxingCoursePage> createState() => _SoloBoxingCoursePageState();
}

class _SoloBoxingCoursePageState extends State<SoloBoxingCoursePage> {
  SoloBoxingCourse? _course;
  SoloCourseProgress? _progress;
  SoloCourseProgressStore? _store;
  bool _loading = true;
  bool _opening = false;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.accountUserId?.addListener(_load);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant SoloBoxingCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId) {
      oldWidget.accountUserId?.removeListener(_load);
      widget.accountUserId?.addListener(_load);
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    widget.accountUserId?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final int generation = ++_generation;
    final String? account = widget.accountUserId?.value;
    if (mounted) {
      setState(() {
        _progress = null; // previous account must disappear immediately
        _store = null;
        _loading = true;
        _opening = false;
        _failed = false;
      });
    }
    try {
      final SoloBoxingCourse course =
          _course ?? await widget.repository.loadSoloBoxingCourse();
      final SoloCourseProgressStore store = await widget.repository
          .openSoloProgressStore(accountUserId: account);
      final SoloCourseProgress progress = await store.load();
      if (!mounted || generation != _generation) return;
      setState(() {
        _course = course;
        _store = store;
        _progress = progress;
        _loading = false;
      });
    } on Object {
      if (!mounted || generation != _generation) return;
      setState(() {
        _progress = null;
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _openLesson(SoloLesson lesson) async {
    final SoloBoxingCourse? course = _course;
    final SoloCourseProgressStore? store = _store;
    if (_opening || course == null || store == null) return;
    final String? account = widget.accountUserId?.value;
    setState(() => _opening = true);
    try {
      final SoloCourseProgress viewed = await store.markViewed(course, lesson);
      if (!mounted || account != widget.accountUserId?.value) return;
      setState(() => _progress = viewed);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SoloBoxingLessonPage(
            course: course,
            lesson: lesson,
            store: store,
            accountUserId: widget.accountUserId,
            accountAtOpen: account,
            initialProgress: viewed.forLesson(lesson, course.version),
          ),
        ),
      );
      if (mounted && account == widget.accountUserId?.value) {
        setState(() => _opening = false);
        final SoloCourseProgress latest = await store.load();
        if (mounted && account == widget.accountUserId?.value) {
          setState(() => _progress = latest);
        }
      }
    } on Object {
      if (mounted) {
        setState(() => _opening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UiLanguage.text(
                context,
                en: 'Progress could not be saved. Try again.',
                tr: 'İlerleme kaydedilemedi. Yeniden dene.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SoloBoxingCourse? course = _course;
    final SoloCourseProgress? progress = _progress;
    return Scaffold(
      backgroundColor: JColors.ground,
      appBar: AppBar(
        backgroundColor: JColors.ground,
        foregroundColor: JColors.ink,
        title: Text(
          UiLanguage.text(
            context,
            en: 'Solo boxing course',
            tr: 'Solo boks kursu',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: JColors.cool))
          : _failed || course == null || progress == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      UiLanguage.text(
                        context,
                        en: 'Course or progress could not be read. No progress total is shown.',
                        tr: 'Kurs veya ilerleme okunamadı. İlerleme toplamı gösterilmiyor.',
                      ),
                      textAlign: TextAlign.center,
                      style: JText.body,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(
                        UiLanguage.text(
                          context,
                          en: 'Try again',
                          tr: 'Yeniden dene',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _courseBody(context, course, progress),
    );
  }

  Widget _courseBody(
    BuildContext context,
    SoloBoxingCourse course,
    SoloCourseProgress progress,
  ) {
    final int done = progress.completedCount(course);
    final SoloLesson? next = progress.nextLesson(course);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      children: <Widget>[
        Text(
          _copy(context, course.title),
          style: JText.pageTitle.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 12),
        Text(_copy(context, course.goal), style: JText.bodyMuted),
        const SizedBox(height: 18),
        GlassPanel(
          tier: GlassTier.observation,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UiLanguage.text(
                  context,
                  en: '$done / 39 self-reported complete',
                  tr: '$done / 39 öz beyanla tamamlandı',
                ),
                key: const Key('solo-course-progress'),
                style: JText.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 9),
              LinearProgressIndicator(
                value: done / course.lessons.length,
                backgroundColor: JColors.border,
                color: JColors.cool,
              ),
              const SizedBox(height: 9),
              Text(
                UiLanguage.text(
                  context,
                  en: 'Reading, practice and self-report are recorded separately. No camera score or skill certification.',
                  tr: 'Okuma, çalışma ve öz beyan ayrı kaydedilir. Kamera puanı veya beceri belgesi yok.',
                ),
                style: JText.bodyMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (next != null)
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              key: const Key('solo-next-lesson'),
              onTap: _opening ? null : () => _openLesson(next),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    UiLanguage.text(context, en: 'UP NEXT', tr: 'SIRADAKİ'),
                    style: JText.body.copyWith(color: JColors.cool),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _copy(context, next.title),
                    style: JText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(_copy(context, next.objective), style: JText.bodyMuted),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Text(
            _copy(context, course.healthNotice),
            style: JText.bodyMuted,
          ),
        ),
        const SizedBox(height: 20),
        for (final SoloModule module in course.modules)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _moduleTile(context, course, module, progress),
          ),
      ],
    );
  }

  Widget _moduleTile(
    BuildContext context,
    SoloBoxingCourse course,
    SoloModule module,
    SoloCourseProgress progress,
  ) {
    final int completed = module.lessons
        .where(
          (SoloLesson lesson) =>
              progress.forLesson(lesson, course.version)?.state ==
              SoloLessonState.selfReportedComplete,
        )
        .length;
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          key: PageStorageKey<String>(module.id),
          initiallyExpanded: module == course.modules.first,
          iconColor: JColors.cool,
          collapsedIconColor: JColors.cool,
          title: Text(
            _copy(context, module.title),
            style: JText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            UiLanguage.text(
              context,
              en: '$completed / ${module.lessons.length} self-reported complete',
              tr: '$completed / ${module.lessons.length} öz beyan tamamlandı',
            ),
            style: JText.bodyMuted,
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(_copy(context, module.intro), style: JText.bodyMuted),
            ),
            for (int i = 0; i < module.lessons.length; i++)
              ListTile(
                key: Key('solo-lesson-${module.lessons[i].id}'),
                onTap: _opening ? null : () => _openLesson(module.lessons[i]),
                leading: Icon(
                  progress
                              .forLesson(module.lessons[i], course.version)
                              ?.state ==
                          SoloLessonState.selfReportedComplete
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: JColors.cool,
                ),
                title: Text(
                  _copy(context, module.lessons[i].title),
                  style: JText.body.copyWith(fontSize: 15),
                ),
                subtitle: Text(
                  _copy(context, module.lessons[i].objective),
                  style: JText.bodyMuted,
                ),
                trailing: const Icon(Icons.chevron_right, color: JColors.cool),
              ),
          ],
        ),
      ),
    );
  }
}

class SoloBoxingLessonPage extends StatefulWidget {
  const SoloBoxingLessonPage({
    super.key,
    required this.course,
    required this.lesson,
    required this.store,
    required this.initialProgress,
    required this.accountAtOpen,
    this.accountUserId,
  });

  final SoloBoxingCourse course;
  final SoloLesson lesson;
  final SoloCourseProgressStore store;
  final SoloLessonProgress? initialProgress;
  final ValueListenable<String?>? accountUserId;
  final String? accountAtOpen;

  @override
  State<SoloBoxingLessonPage> createState() => _SoloBoxingLessonPageState();
}

class _SoloBoxingLessonPageState extends State<SoloBoxingLessonPage> {
  late SoloLessonProgress? _progress;
  late List<bool> _checks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress;
    _checks = List<bool>.filled(widget.lesson.selfChecks.length, false);
    widget.accountUserId?.addListener(_accountChanged);
  }

  @override
  void dispose() {
    widget.accountUserId?.removeListener(_accountChanged);
    super.dispose();
  }

  void _accountChanged() {
    if (widget.accountUserId?.value != widget.accountAtOpen && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _save({required bool complete}) async {
    if (_saving || widget.accountUserId?.value != widget.accountAtOpen) return;
    setState(() => _saving = true);
    try {
      final SoloCourseProgress updated = complete
          ? await widget.store.markCompleted(
              widget.course,
              widget.lesson,
              selfChecksConfirmed: _checks.every((bool value) => value),
            )
          : await widget.store.markPractised(widget.course, widget.lesson);
      if (!mounted || widget.accountUserId?.value != widget.accountAtOpen) {
        return;
      }
      setState(() {
        _progress = updated.forLesson(widget.lesson, widget.course.version);
        _saving = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UiLanguage.text(
              context,
              en: 'Progress could not be saved. Try again.',
              tr: 'İlerleme kaydedilemedi. Yeniden dene.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SoloLesson lesson = widget.lesson;
    final bool practised =
        _progress != null &&
        _progress!.state.index >= SoloLessonState.practised.index;
    final bool completed =
        _progress?.state == SoloLessonState.selfReportedComplete;
    final List<SoloLesson> prerequisites = widget.course.lessons
        .where((SoloLesson item) => lesson.prerequisites.contains(item.id))
        .toList(growable: false);
    return Scaffold(
      backgroundColor: JColors.ground,
      appBar: AppBar(
        backgroundColor: JColors.ground,
        foregroundColor: JColors.ink,
        title: Text(_copy(context, lesson.title)),
      ),
      body: ListView(
        key: const Key('solo-lesson-list'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: <Widget>[
          Text(
            _copy(context, lesson.title),
            style: JText.pageTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 10),
          Text(_copy(context, lesson.objective), style: JText.bodyMuted),
          const SizedBox(height: 10),
          Text(
            UiLanguage.text(
              context,
              en: '${lesson.minutes} min suggested · self-report only',
              tr: '${lesson.minutes} dk öneri · yalnız öz beyan',
            ),
            style: JText.body.copyWith(color: JColors.cool),
          ),
          if (prerequisites.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              UiLanguage.text(
                context,
                en: 'Builds on: ${prerequisites.map((SoloLesson item) => _copy(context, item.title)).join(", ")}',
                tr: 'Ön çalışma: ${prerequisites.map((SoloLesson item) => _copy(context, item.title)).join(", ")}',
              ),
              style: JText.bodyMuted,
            ),
          ],
          const SizedBox(height: 18),
          _section(
            context,
            UiLanguage.text(context, en: 'LEARN', tr: 'ÖĞREN'),
            Column(
              children: <Widget>[
                for (int i = 0; i < lesson.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: JText.body.copyWith(color: JColors.cool),
                        ),
                        Expanded(
                          child: Text(
                            _copy(context, lesson.steps[i]),
                            style: JText.body,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'PRACTISE', tr: 'ÇALIŞ'),
            Text(_copy(context, lesson.practice), style: JText.body),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'SELF-CHECK', tr: 'ÖZ DENETİM'),
            Column(
              children: <Widget>[
                for (int i = 0; i < lesson.selfChecks.length; i++)
                  CheckboxListTile(
                    key: Key('solo-check-${lesson.id}-$i'),
                    contentPadding: EdgeInsets.zero,
                    value: _checks[i],
                    activeColor: JColors.cool,
                    checkColor: JColors.ground,
                    title: Text(
                      _copy(context, lesson.selfChecks[i]),
                      style: JText.body.copyWith(fontSize: 15),
                    ),
                    onChanged: (bool? value) =>
                        setState(() => _checks[i] = value ?? false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'ADAPT', tr: 'UYARLA'),
            Text(_copy(context, lesson.adaptation), style: JText.body),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'STOP SIGNAL', tr: 'DURMA İŞARETİ'),
            Text(_copy(context, lesson.stopSignal), style: JText.body),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'SOURCES', tr: 'KAYNAKLAR'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final String sourceId in lesson.sourceIds)
                  _sourceRow(
                    context,
                    widget.course.sources.singleWhere(
                      (CourseSource source) => source.id == sourceId,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('solo-mark-practised'),
            onPressed: _saving ? null : () => _save(complete: false),
            child: Text(
              UiLanguage.text(
                context,
                en: practised
                    ? 'Practise again · ${_progress!.practiceCount} recorded'
                    : 'I practised this',
                tr: practised
                    ? 'Yeniden çalış · ${_progress!.practiceCount} kayıt'
                    : 'Bunu çalıştım',
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('solo-mark-complete'),
            onPressed:
                _saving || !practised || !_checks.every((bool value) => value)
                ? null
                : () => _save(complete: true),
            child: Text(
              UiLanguage.text(
                context,
                en: completed
                    ? 'Self-reported complete · review again'
                    : 'Complete by self-report',
                tr: completed
                    ? 'Öz beyanla tamamlandı · yeniden gözden geçir'
                    : 'Öz beyanla tamamla',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            UiLanguage.text(
              context,
              en: 'These buttons record your report. They do not verify technique or medical safety.',
              tr: 'Bu düğmeler beyanını kaydeder. Tekniği veya tıbbi güvenliği doğrulamaz.',
            ),
            style: JText.bodyMuted,
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String label, Widget child) =>
      GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: JText.body.copyWith(
                color: JColors.cool,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Material(type: MaterialType.transparency, child: child),
          ],
        ),
      );

  Widget _sourceRow(BuildContext context, CourseSource source) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${source.publisher}: ${source.title}',
                style: JText.body.copyWith(fontSize: 14),
              ),
              SelectableText(
                source.url.toString(),
                style: JText.bodyMuted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: UiLanguage.text(
            context,
            en: 'Copy source link',
            tr: 'Kaynak bağlantısını kopyala',
          ),
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: source.url.toString())),
          icon: const Icon(Icons.copy, color: JColors.cool),
        ),
      ],
    ),
  );
}
