import 'technique_capability_panel.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart';

import 'content_failure.dart';
import 'content_failure_screen.dart';
import 'content_repository.dart';
import 'design_tokens.dart';
import 'lesson_media_slot.dart';
import 'solo_boxing_course.dart';
import 'solo_boxing_progress.dart';
import 'ui_language.dart';

String _copy(BuildContext context, CourseCopy value) =>
    UiLanguage.text(context, en: value.en, tr: value.tr);

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
            style: JText.of(context).body.copyWith(
              color: JColors.of(context).observation,
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
            style: JText.of(context).body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            UiLanguage.text(
              context,
              en: 'Non-contact practice with a clear next step and saved self-reported progress.',
              tr: 'Temassız çalışma, belirgin sıradaki adım ve kaydedilen öz beyan ilerlemesi.',
            ),
            style: JText.of(context).bodyMuted,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                UiLanguage.text(context, en: 'Open course', tr: 'Kursu aç'),
                style: JText.of(
                  context,
                ).body.copyWith(color: JColors.of(context).observation),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: JColors.of(context).observation,
              ),
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
    this.resourceAdmission,
  });

  final ContentRepository repository;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;

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
  bool _progressUnavailable = false;
  ContentFailure? _contentFailure;
  int _generation = 0;
  ModalRoute<void>? _ownerRoute;
  NavigatorState? _ownerNavigator;

  @override
  void initState() {
    super.initState();
    widget.accountUserId?.addListener(_load);
    widget.resourceAdmission?.addListener(_admissionChanged);
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownerRoute = ModalRoute.of<void>(context);
    _ownerNavigator = Navigator.of(context);
    if (widget.resourceAdmission?.value == false) _admissionChanged();
  }

  @override
  void didUpdateWidget(covariant SoloBoxingCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceAdmission != widget.resourceAdmission) {
      oldWidget.resourceAdmission?.removeListener(_admissionChanged);
      widget.resourceAdmission?.addListener(_admissionChanged);
      _admissionChanged();
    }
    if (oldWidget.accountUserId != widget.accountUserId) {
      oldWidget.accountUserId?.removeListener(_load);
      widget.accountUserId?.addListener(_load);
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    widget.accountUserId?.removeListener(_load);
    widget.resourceAdmission?.removeListener(_admissionChanged);
    super.dispose();
  }

  void _admissionChanged() {
    if (widget.resourceAdmission?.value != false) return;
    _generation++;
    _store = null;
    _removeRetiredRoute(_ownerRoute, _ownerNavigator);
  }

  Future<void> _load() async {
    if (widget.resourceAdmission?.value == false) return;
    final int generation = ++_generation;
    final String? account = widget.accountUserId?.value;
    if (mounted) {
      setState(() {
        _progress = null; // previous account must disappear immediately
        _store = null;
        _loading = true;
        _opening = false;
        _failed = false;
        _progressUnavailable = false;
        _contentFailure = null;
      });
    }
    try {
      final SoloBoxingCourse course =
          _course ?? await widget.repository.loadSoloBoxingCourse();
      SoloCourseProgressStore? store;
      SoloCourseProgress? progress;
      try {
        store = await widget.repository.openSoloProgressStore(
          accountUserId: account,
        );
        progress = await store.load();
      } on Object {
        // Content remains readable. Unknown progress is never an empty journal.
      }
      if (!mounted ||
          generation != _generation ||
          widget.resourceAdmission?.value == false) {
        return;
      }
      setState(() {
        _course = course;
        _store = store;
        _progress = progress;
        _progressUnavailable = progress == null;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted ||
          generation != _generation ||
          widget.resourceAdmission?.value == false) {
        return;
      }
      setState(() {
        _progress = null;
        _loading = false;
        _failed = true;
        if (error is ContentException) {
          _contentFailure = ContentFailure.from(error);
        }
      });
    }
  }

  Future<void> _openLesson(SoloLesson lesson) async {
    final SoloBoxingCourse? course = _course;
    final SoloCourseProgressStore? store = _store;
    if (_opening ||
        course == null ||
        widget.resourceAdmission?.value == false) {
      return;
    }
    final String? account = widget.accountUserId?.value;
    final ownerNotifier = widget.accountUserId;
    final admissionNotifier = widget.resourceAdmission;
    final int generation = _generation;
    bool current() =>
        mounted &&
        generation == _generation &&
        identical(ownerNotifier, widget.accountUserId) &&
        identical(admissionNotifier, widget.resourceAdmission) &&
        account == widget.accountUserId?.value &&
        widget.resourceAdmission?.value != false;
    setState(() => _opening = true);
    try {
      SoloLessonProgress? initialProgress;
      bool readOnly = _progressUnavailable || store == null;
      if (!readOnly) {
        try {
          final SoloCourseProgress viewed = await store.markViewed(
            course,
            lesson,
          );
          if (!current()) return;
          setState(() => _progress = viewed);
          initialProgress = viewed.forLesson(lesson, course.version);
        } on Object {
          if (!current()) return;
          readOnly = true;
          setState(() {
            _progress = null;
            _progressUnavailable = true;
          });
        }
      }
      if (!mounted || !current()) return;
      final navigator = Navigator.of(context);
      late final MaterialPageRoute<void> route;
      route = MaterialPageRoute<void>(
        builder: (_) {
          if (!current()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (route.isActive) navigator.removeRoute(route);
            });
            WidgetsBinding.instance.ensureVisualUpdate();
            return const SizedBox.shrink();
          }
          return SoloBoxingLessonPage(
            course: course,
            lesson: lesson,
            store: store,
            accountUserId: ownerNotifier,
            resourceAdmission: admissionNotifier,
            accountAtOpen: account,
            initialProgress: initialProgress,
            readOnly: readOnly,
          );
        },
      );
      await navigator.push<void>(route);
      if (current()) {
        await _load();
      }
    } on Object {
      if (mounted && current()) {
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
    final ContentFailure? contentFailure = _contentFailure;
    if (contentFailure != null) {
      return ContentFailureScreen(
        failure: contentFailure,
        onRetry: _load,
        onExit: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
      );
    }
    final SoloBoxingCourse? course = _course;
    final SoloCourseProgress? progress = _progress;
    return Scaffold(
      backgroundColor: JColors.of(context).ground,
      appBar: AppBar(
        backgroundColor: JColors.of(context).ground,
        foregroundColor: JColors.of(context).ink,
        title: Text(
          UiLanguage.text(
            context,
            en: 'Solo boxing course',
            tr: 'Solo boks kursu',
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: JColors.of(context).observation,
              ),
            )
          : _failed || course == null
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
                      style: JText.of(context).body,
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
    SoloCourseProgress? progress,
  ) {
    final int? done = progress?.completedCount(course);
    final SoloLesson? next = progress?.nextLesson(course);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      children: <Widget>[
        Text(
          _copy(context, course.title),
          style: JText.of(context).pageTitle.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 12),
        Text(_copy(context, course.goal), style: JText.of(context).bodyMuted),
        const SizedBox(height: 18),
        GlassPanel(
          tier: GlassTier.observation,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (done == null) ...<Widget>[
                const _SoloReadOnlyNotice(),
                TextButton(
                  key: const Key('solo-progress-retry'),
                  onPressed: _load,
                  child: Text(
                    UiLanguage.text(
                      context,
                      en: 'Try again',
                      tr: 'Yeniden dene',
                    ),
                  ),
                ),
              ] else ...<Widget>[
                Text(
                  UiLanguage.format(
                    context,
                    en: '{value1} / 39 self-reported complete',
                    tr: '{value1} / 39 öz beyanla tamamlandı',
                    args: {'value1': done},
                  ),
                  key: const Key('solo-course-progress'),
                  style: JText.of(
                    context,
                  ).body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: done / course.lessons.length,
                  backgroundColor: JColors.of(context).outline,
                  color: JColors.of(context).observation,
                ),
                const SizedBox(height: 9),
              ],
              Text(
                UiLanguage.text(
                  context,
                  en: 'Reading, practice and self-report are recorded separately. No camera score or skill certification.',
                  tr: 'Okuma, çalışma ve öz beyan ayrı kaydedilir. Kamera puanı veya beceri belgesi yok.',
                ),
                style: JText.of(context).bodyMuted,
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
                    style: JText.of(
                      context,
                    ).body.copyWith(color: JColors.of(context).observation),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _copy(context, next.title),
                    style: JText.of(
                      context,
                    ).body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _copy(context, next.objective),
                    style: JText.of(context).bodyMuted,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Text(
            _copy(context, course.healthNotice),
            style: JText.of(context).bodyMuted,
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
    SoloCourseProgress? progress,
  ) {
    final int? completed = progress == null
        ? null
        : module.lessons
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
          iconColor: JColors.of(context).observation,
          collapsedIconColor: JColors.of(context).observation,
          title: Text(
            _copy(context, module.title),
            style: JText.of(context).body.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            UiLanguage.format(
              context,
              en: completed == null
                  ? 'Progress unavailable · read only'
                  : '{value1} / {value2} self-reported complete',
              tr: completed == null
                  ? 'İlerleme okunamıyor · salt okunur'
                  : '{value1} / {value2} öz beyan tamamlandı',
              args: {
                if (completed != null) 'value1': completed,
                'value2': module.lessons.length,
              },
            ),
            style: JText.of(context).bodyMuted,
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                _copy(context, module.intro),
                style: JText.of(context).bodyMuted,
              ),
            ),
            for (int i = 0; i < module.lessons.length; i++)
              ListTile(
                key: Key('solo-lesson-${module.lessons[i].id}'),
                onTap: _opening ? null : () => _openLesson(module.lessons[i]),
                leading: Icon(
                  progress == null
                      ? Icons.help_outline
                      : progress
                                .forLesson(module.lessons[i], course.version)
                                ?.state ==
                            SoloLessonState.selfReportedComplete
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: JColors.of(context).observation,
                ),
                title: Text(
                  _copy(context, module.lessons[i].title),
                  style: JText.of(context).body.copyWith(fontSize: 15),
                ),
                subtitle: Text(
                  _copy(context, module.lessons[i].objective),
                  style: JText.of(context).bodyMuted,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: JColors.of(context).observation,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SoloReadOnlyNotice extends StatelessWidget {
  const _SoloReadOnlyNotice();

  @override
  Widget build(BuildContext context) => Text(
    UiLanguage.text(
      context,
      en: 'Progress could not be verified. You can read the lessons, but progress totals and saving are unavailable. This screen does not reset your files. Reopen the course to try again.',
      tr: 'İlerleme doğrulanamadı. Dersleri okuyabilirsin; ilerleme toplamları ve kayıt kullanılamıyor. Bu ekran dosyalarını sıfırlamaz. Yeniden denemek için kursu yeniden aç.',
    ),
    key: const Key('solo-progress-unavailable'),
    style: JText.of(context).bodyMuted,
  );
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
    this.resourceAdmission,
    this.preparationClock,
    this.readOnly = false,
  });

  final SoloBoxingCourse course;
  final SoloLesson lesson;
  final SoloCourseProgressStore? store;
  final bool readOnly;
  final SoloLessonProgress? initialProgress;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;
  final String? accountAtOpen;

  /// Optional clock for deterministic date-boundary tests; never persisted.
  final DateTime Function()? preparationClock;

  @override
  State<SoloBoxingLessonPage> createState() => _SoloBoxingLessonPageState();
}

class _SoloBoxingLessonPageState extends State<SoloBoxingLessonPage>
    with WidgetsBindingObserver {
  late SoloLessonProgress? _progress;
  late List<bool> _checks;
  bool _saving = false;
  late bool _readOnly;
  bool _ownerRetired = false;
  ModalRoute<void>? _ownerRoute;
  NavigatorState? _ownerNavigator;
  DateTime? _preparedAt;
  Timer? _preparationExpiry;
  bool _foreground = true;
  bool _practisedThisSession = false;
  int _sessionEpoch = 0;
  DateTime get _now =>
      (widget.preparationClock?.call() ?? DateTime.now()).toLocal();
  bool get _sessionPrepared {
    final prepared = _preparedAt;
    final now = _now;
    return _foreground &&
        prepared != null &&
        prepared.year == now.year &&
        prepared.month == now.month &&
        prepared.day == now.day;
  }

  bool get _preparationBlocked => _needsSessionPreparation && !_sessionPrepared;
  bool get _needsSessionPreparation =>
      widget.lesson.id != 'boxing.start.space' &&
      widget.lesson.id != 'boxing.start.breath';

  String _specificPreparation(BuildContext context) {
    final module = widget.lesson.id.split('.')[1];
    return switch (module) {
      'footwork' => UiLanguage.text(
        context,
        en: 'Rehearse your stance and small steps at walking pace before changing direction.',
        tr: 'Yön değiştirmeden önce duruşunu ve küçük adımları yürüyüş hızında prova et.',
      ),
      'straights' => UiLanguage.text(
        context,
        en: 'Recall stance and guard, then extend and return a few easy straight punches into open air.',
        tr: 'Duruş ve gardı hatırla; ardından boşluğa birkaç rahat düz yumruk uzatıp geri çek.',
      ),
      'defence' => UiLanguage.text(
        context,
        en: 'Rehearse small supported weight shifts and your known guard before the defence task.',
        tr: 'Savunma görevinden önce küçük destekli ağırlık geçişlerini ve bildiğin gardı prova et.',
      ),
      'curves' => UiLanguage.text(
        context,
        en: 'Move shoulders and elbows gently; rehearse a small, slow arc into open air without impact.',
        tr: 'Omuz ve dirsekleri rahatça hareket ettir; temas olmadan küçük, yavaş bir kavis prova et.',
      ),
      _ => UiLanguage.text(
        context,
        en: 'Rehearse familiar stance, a small step and known punches slowly before the new sequence.',
        tr: 'Yeni diziden önce bildiğin duruşu, küçük adımı ve tanıdık yumrukları yavaşça prova et.',
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _readOnly = widget.readOnly || widget.store == null;
    _progress = _readOnly ? null : widget.initialProgress;
    _checks = List<bool>.filled(widget.lesson.selfChecks.length, false);
    widget.accountUserId?.addListener(_accountChanged);
    widget.resourceAdmission?.addListener(_accountChanged);
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownerRoute = ModalRoute.of<void>(context);
    _ownerNavigator = Navigator.of(context);
    _accountChanged();
  }

  @override
  void didUpdateWidget(covariant SoloBoxingLessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readOnly || widget.store == null) {
      _readOnly = true;
      _progress = null;
    }
    if (identical(oldWidget.accountUserId, widget.accountUserId) &&
        identical(oldWidget.resourceAdmission, widget.resourceAdmission) &&
        identical(oldWidget.store, widget.store) &&
        oldWidget.accountAtOpen == widget.accountAtOpen) {
      return;
    }
    oldWidget.accountUserId?.removeListener(_accountChanged);
    oldWidget.resourceAdmission?.removeListener(_accountChanged);
    widget.accountUserId?.addListener(_accountChanged);
    widget.resourceAdmission?.addListener(_accountChanged);
    _ownerRetired = true;
    _resetPreparation();
    _removeRetiredRoute(_ownerRoute, _ownerNavigator);
  }

  @override
  void dispose() {
    _preparationExpiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.accountUserId?.removeListener(_accountChanged);
    widget.resourceAdmission?.removeListener(_accountChanged);
    super.dispose();
  }

  void _accountChanged() {
    if ((widget.accountUserId?.value != widget.accountAtOpen ||
            widget.resourceAdmission?.value == false) &&
        mounted) {
      _ownerRetired = true;
      _resetPreparation();
      _removeRetiredRoute(_ownerRoute, _ownerNavigator);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _resetPreparation();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _resetPreparation() {
    _preparationExpiry?.cancel();
    _preparationExpiry = null;
    _sessionEpoch++;
    if (!mounted) return;
    setState(() {
      _preparedAt = null;
      _practisedThisSession = false;
      _checks = List<bool>.filled(widget.lesson.selfChecks.length, false);
    });
  }

  void _acknowledgePreparation(bool value) {
    _resetPreparation();
    if (!value || !_foreground) return;
    final now = _now;
    setState(() => _preparedAt = now);
    // Calendar invalidation is not a physiological warm-up duration claim.
    _preparationExpiry = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      _resetPreparation,
    );
  }

  Future<void> _save({required bool complete}) async {
    final SoloCourseProgressStore? store = widget.store;
    if (_readOnly ||
        store == null ||
        _ownerRetired ||
        _saving ||
        widget.accountUserId?.value != widget.accountAtOpen ||
        widget.resourceAdmission?.value == false ||
        _preparationBlocked ||
        (complete && _needsSessionPreparation && !_practisedThisSession)) {
      return;
    }
    setState(() => _saving = true);
    final sessionEpoch = _sessionEpoch;
    try {
      final SoloCourseProgress updated = complete
          ? await store.markCompleted(
              widget.course,
              widget.lesson,
              selfChecksConfirmed: _checks.every((bool value) => value),
            )
          : await store.markPractised(widget.course, widget.lesson);
      if (!mounted ||
          widget.accountUserId?.value != widget.accountAtOpen ||
          widget.resourceAdmission?.value == false) {
        return;
      }
      setState(() {
        _progress = updated.forLesson(widget.lesson, widget.course.version);
        if (!complete && sessionEpoch == _sessionEpoch && _sessionPrepared) {
          _practisedThisSession = true;
        }
        _saving = false;
      });
    } on Object {
      if (!mounted) return;
      if (widget.accountUserId?.value != widget.accountAtOpen ||
          widget.resourceAdmission?.value == false) {
        return;
      }
      setState(() {
        _saving = false;
        _readOnly = true;
        _progress = null;
      });
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
    if (_ownerRetired || widget.resourceAdmission?.value == false) {
      return const SizedBox.shrink();
    }
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
      backgroundColor: JColors.of(context).ground,
      appBar: AppBar(
        backgroundColor: JColors.of(context).ground,
        foregroundColor: JColors.of(context).ink,
        title: Text(_copy(context, lesson.title)),
      ),
      body: ListView(
        key: const Key('solo-lesson-list'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: <Widget>[
          if (_readOnly) const _SoloReadOnlyNotice(),
          TechniqueCapabilityPanel(
            courseId: widget.course.id,
            lessonId: lesson.id,
          ),
          Text(
            _copy(context, lesson.title),
            style: JText.of(context).pageTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 10),
          Text(
            _copy(context, lesson.objective),
            style: JText.of(context).bodyMuted,
          ),
          const SizedBox(height: 10),
          Text(
            UiLanguage.format(
              context,
              en: '{value1} min suggested · self-report only',
              tr: '{value1} dk öneri · yalnız öz beyan',
              args: {'value1': lesson.minutes},
            ),
            style: JText.of(
              context,
            ).body.copyWith(color: JColors.of(context).observation),
          ),
          LessonMediaSlot.empty(
            course: widget.course,
            lesson: lesson,
            locale: UiLanguage.tag(context),
            accountUserId: widget.accountUserId,
          ),
          if (prerequisites.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              UiLanguage.format(
                context,
                en: 'Builds on: {value1}',
                tr: 'Ön çalışma: {value1}',
                args: {
                  'value1': prerequisites
                      .map((SoloLesson item) => _copy(context, item.title))
                      .join(", "),
                },
              ),
              style: JText.of(context).bodyMuted,
            ),
          ],
          if (_needsSessionPreparation) ...<Widget>[
            const SizedBox(height: 12),
            _section(
              context,
              UiLanguage.text(
                context,
                en: 'PREPARE THIS SESSION',
                tr: 'BU OTURUMA HAZIRLAN',
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    UiLanguage.text(
                      context,
                      en: 'Clear your space. Begin with comfortable walking in place and gentle joint movement, then gradually rehearse familiar boxing movements at low effort without tiring yourself. Take the preparation time you need; a short lesson or reading this card does not establish readiness. You may read without performing the movement.',
                      tr: 'Alanı boşalt. Yerinde rahat yürüyüş ve nazik eklem hareketleriyle başla; ardından tanıdık boks hareketlerini yorulmadan düşük eforla kademeli prova et. Hazırlığa gereken zamanı ayır; kısa bir ders veya bu kartı okumak hazır oluşunu göstermez. Hareketi yapmadan okuyabilirsin.',
                    ),
                    style: JText.of(context).body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _specificPreparation(context),
                    style: JText.of(context).body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UiLanguage.text(
                      context,
                      en: 'After practice, step and breathe more slowly; stop for pain, dizziness or feeling unwell.',
                      tr: 'Çalışma sonunda adımı ve nefesi yavaşlat; ağrı, baş dönmesi veya kötü hissetmede dur.',
                    ),
                    style: JText.of(context).bodyMuted,
                  ),
                  CheckboxListTile(
                    key: const Key('solo-session-prepared'),
                    contentPadding: EdgeInsets.zero,
                    value: _sessionPrepared,
                    onChanged: _saving || !_foreground
                        ? null
                        : (value) => _acknowledgePreparation(value ?? false),
                    title: Text(
                      UiLanguage.text(
                        context,
                        en: 'I prepared for this session · self-report, not a readiness check',
                        tr: 'Bu oturuma hazırlandım · öz beyan, hazır oluş kontrolü değil',
                      ),
                      style: JText.of(context).bodyMuted,
                    ),
                  ),
                  if (_sessionPrepared)
                    TextButton(
                      key: const Key('solo-session-break'),
                      onPressed: _resetPreparation,
                      child: Text(
                        UiLanguage.text(
                          context,
                          en: 'After a break · prepare again',
                          tr: 'Moladan sonra · yeniden hazırlan',
                        ),
                      ),
                    ),
                ],
              ),
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
                          style: JText.of(context).body.copyWith(
                            color: JColors.of(context).observation,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _copy(context, lesson.steps[i]),
                            style: JText.of(context).body,
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
            _preparationBlocked
                ? Text(
                    UiLanguage.text(
                      context,
                      en: 'Prepare above before physical practice. You can read the lesson without trying the movements; this does not record physical practice.',
                      tr: 'Fiziksel çalışmadan önce yukarıdaki hazırlığı yap. Hareketleri denemeden dersi okuyabilirsin; bu, fiziksel pratik olarak kaydedilmez.',
                    ),
                    key: const Key('solo-preparation-required'),
                    style: JText.of(context).body,
                  )
                : Text(
                    _copy(context, lesson.practice),
                    style: JText.of(context).body,
                  ),
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
                    activeColor: JColors.of(context).observation,
                    checkColor: JColors.of(context).ground,
                    title: Text(
                      _copy(context, lesson.selfChecks[i]),
                      style: JText.of(context).body.copyWith(fontSize: 15),
                    ),
                    onChanged: _readOnly || _saving || _preparationBlocked
                        ? null
                        : (bool? value) =>
                              setState(() => _checks[i] = value ?? false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'ADAPT', tr: 'UYARLA'),
            Text(
              _copy(context, lesson.adaptation),
              style: JText.of(context).body,
            ),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            UiLanguage.text(context, en: 'STOP SIGNAL', tr: 'DURMA İŞARETİ'),
            Text(
              _copy(context, lesson.stopSignal),
              style: JText.of(context).body,
            ),
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
            onPressed: _readOnly || _saving || _preparationBlocked
                ? null
                : () => _save(complete: false),
            child: Text(
              UiLanguage.format(
                context,
                en: practised
                    ? 'Practise again · {value1} recorded'
                    : 'I practised this',
                tr: practised
                    ? 'Yeniden çalış · {value1} kayıt'
                    : 'Bunu çalıştım',
                args: {if (practised) 'value1': _progress!.practiceCount},
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('solo-mark-complete'),
            onPressed:
                _readOnly ||
                    _saving ||
                    _preparationBlocked ||
                    (_needsSessionPreparation && !_practisedThisSession) ||
                    !practised ||
                    !_checks.every((bool value) => value)
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
            style: JText.of(context).bodyMuted,
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
              style: JText.of(context).body.copyWith(
                color: JColors.of(context).observation,
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
                style: JText.of(context).body.copyWith(fontSize: 14),
              ),
              SelectableText(
                source.url.toString(),
                style: JText.of(context).bodyMuted.copyWith(fontSize: 12),
              ),
              if (source.supports case final support?)
                Text(
                  '${UiLanguage.text(context, en: 'Supports only:', tr: 'Yalnız destekler:')} ${_copy(context, support)}',
                  key: Key('boxing.sourceScope.${source.id}'),
                  style: JText.of(context).bodyMuted.copyWith(fontSize: 12),
                ),
              if (source.doesNotSupport case final limit?)
                Text(
                  '${UiLanguage.text(context, en: 'Does not establish:', tr: 'Kanıtlamaz:')} ${_copy(context, limit)}',
                  key: Key('boxing.sourceLimit.${source.id}'),
                  style: JText.of(context).bodyMuted.copyWith(fontSize: 12),
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
          icon: Icon(Icons.copy, color: JColors.of(context).observation),
        ),
      ],
    ),
  );
}

/// Remove only the retired training route, even when another route covers it.
void _removeRetiredRoute(ModalRoute<void>? route, NavigatorState? navigator) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (navigator != null &&
        navigator.mounted &&
        route != null &&
        route.isActive &&
        !route.isFirst) {
      navigator.removeRoute(route);
    }
  });
  WidgetsBinding.instance.ensureVisualUpdate();
}
