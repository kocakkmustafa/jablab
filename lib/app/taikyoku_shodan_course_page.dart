import 'technique_capability_panel.dart';
import 'course_scope_note.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'content_failure.dart';
import 'taikyoku_shodan_course.dart';
import 'self_guided_practice.dart';
import 'self_guided_practice_panel.dart';
import 'ui_language.dart';

String _label(
  BuildContext context,
  String en,
  String tr, {
  Map<String, Object> args = const {},
}) => UiLanguage.format(context, en: en, tr: tr, args: args);
String _text(BuildContext context, TaikyokuCopy copy) =>
    UiLanguage.text(context, en: copy.en, tr: copy.tr);
Widget _copy(BuildContext context, TaikyokuCopy copy, String key) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(_text(context, copy), key: Key(key)),
);
bool _resumed() =>
    WidgetsBinding.instance.lifecycleState == null ||
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

class TaikyokuCourseEntryCard extends StatelessWidget {
  const TaikyokuCourseEntryCard({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const Key('open-taikyoku-course'),
      title: const Text('Taikyoku Shodan'),
      subtitle: Text(
        _label(
          context,
          'Jason Leung reference · 20 counts · written review and optional tasks',
          'Jason Leung referansı · 20 hareket · yazılı inceleme ve isteğe bağlı görevler',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpen,
    ),
  );
}

class TaikyokuLessonPage extends StatefulWidget {
  const TaikyokuLessonPage({
    super.key,
    required this.lesson,
    required this.course,
    required this.admitted,
    required this.priorWritten,
    required this.onWritten,
    required this.onInvalidate,
    required this.onReset,
  });
  final TaikyokuLesson lesson;
  final TaikyokuCourse course;
  final bool Function() admitted, priorWritten;
  final VoidCallback onWritten, onInvalidate, onReset;
  @override
  State<TaikyokuLessonPage> createState() => _TaikyokuLessonPageState();
}

class _TaikyokuLessonPageState extends State<TaikyokuLessonPage>
    with WidgetsBindingObserver {
  final _initial = [TextEditingController(), TextEditingController()];
  final _retest = [TextEditingController(), TextEditingController()];
  final _correction = TextEditingController();
  bool _readingVisible = true;
  bool _answerVisible = false;
  bool _initialRevealed = false;
  bool _retesting = false;
  bool _compared = false;
  bool _reported = false;
  PracticeAttempt _practiceAttempt = PracticeAttempt.unrecorded;
  int _practiceEpoch = 0;
  bool _practiceEnded = false;
  bool _foreground = _resumed();
  bool get _admitted => mounted && _foreground && widget.admitted();
  bool _filled(List<TextEditingController> values) =>
      values.every((v) => v.text.trim().isNotEmpty);
  bool get _canReveal =>
      _admitted && !_readingVisible && !_retesting && _filled(_initial);
  bool get _canRetest =>
      _admitted &&
      _initialRevealed &&
      !_retesting &&
      _correction.text.trim().isNotEmpty;
  bool get _canCompare => _admitted && _retesting && _filled(_retest);
  bool get _canReport =>
      _canCompare &&
      _answerVisible &&
      _compared &&
      _correction.text.trim().isNotEmpty &&
      widget.priorWritten() &&
      !_reported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant TaikyokuLessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lesson, widget.lesson) ||
        !identical(oldWidget.course, widget.course)) {
      _practiceEpoch++;
      _practiceAttempt = PracticeAttempt.unrecorded;
      _practiceEnded = false;
    }
  }

  @override
  void dispose() {
    _practiceEpoch++;
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in [..._initial, ..._retest, _correction]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearReview() {
    _answerVisible = false;
    _initialRevealed = false;
    _retesting = false;
    _compared = false;
    _reported = false;
    _correction.clear();
    for (final controller in _retest) {
      controller.clear();
    }
  }

  void _reset() {
    if (!mounted) return;
    _practiceEpoch++;
    _practiceEnded = false;
    for (final controller in _initial) {
      controller.clear();
    }
    setState(() {
      _clearReview();
      _practiceAttempt = PracticeAttempt.unrecorded;
    });
    widget.onReset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // Also clear on resume so a delayed input event during interruption
    // cannot become a fresh recall answer when admission returns.
    _reset();
    if (mounted) setState(() {});
  }

  void _initialChanged() {
    if (!_admitted) return;
    widget.onInvalidate();
    setState(_clearReview);
  }

  void _correctionChanged() {
    if (!_admitted) return;
    widget.onInvalidate();
    setState(() {
      for (final controller in _retest) {
        controller.clear();
      }
      _retesting = false;
      _compared = false;
      _reported = false;
    });
  }

  void _retestChanged() {
    if (!_admitted) return;
    widget.onInvalidate();
    setState(() {
      _answerVisible = false;
      _compared = false;
      _reported = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final practice = lesson.selfPractice;
    final practiceEpoch = _practiceEpoch;
    bool visitCurrent() =>
        mounted &&
        practiceEpoch == _practiceEpoch &&
        identical(lesson, widget.lesson) &&
        identical(practice, widget.lesson.selfPractice) &&
        _admitted;
    bool practiceCurrent() =>
        visitCurrent() && _readingVisible && !_practiceEnded;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _label(
            context,
            'Lesson {value1}',
            'Ders {value1}',
            args: {'value1': lesson.number},
          ),
        ),
        actions: [
          IconButton(
            key: const Key('taikyoku-stop-top'),
            tooltip: _label(
              context,
              'Stop and clear this visit',
              'Dur ve bu ziyareti temizle',
            ),
            onPressed: () {
              if (_admitted) _reset();
            },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        key: const Key('taikyoku-lesson-body'),
        padding: const EdgeInsets.all(20),
        children: [
          TechniqueCapabilityPanel(
            courseId: 'jablab.taikyoku_shodan_jl',
            lessonId: lesson.id,
          ),
          _copy(context, lesson.title, 'taikyoku-lesson-title'),
          Text(
            _label(
              context,
              'Written recall and optional beginner adaptations are separate. Your technique, personal suitability and full kata performance are not validated.',
              'Yazılı geri çağırma ve isteğe bağlı başlangıç uyarlamaları ayrıdır. Tekniğin, kişisel uygunluğun ve tam kata performansın doğrulanmaz.',
            ),
            key: const Key('taikyoku-physical-blocked'),
          ),
          _copy(context, lesson.objective, 'taikyoku-objective'),
          TextButton(
            key: const Key('taikyoku-toggle-reading'),
            onPressed: () {
              if (!_admitted) return;
              widget.onInvalidate();
              setState(() {
                _practiceEpoch++;
                _readingVisible = !_readingVisible;
                for (final controller in _initial) {
                  controller.clear();
                }
                _clearReview();
              });
            },
            child: Text(
              _label(
                context,
                _readingVisible
                    ? 'Hide reading and recall independently'
                    : 'Show reading',
                _readingVisible
                    ? 'Okumayı gizle ve bağımsız hatırla'
                    : 'Okumayı göster',
              ),
            ),
          ),
          if (_readingVisible) ...[
            SelfGuidedPracticePanel(
              practice: practice,
              attempt: _practiceAttempt,
              admitted: practiceCurrent,
              onChanged: (value) {
                if (!practiceCurrent()) return;
                if (!practice.offersMovement &&
                    value == PracticeAttempt.attempted) {
                  return;
                }
                setState(() {
                  _practiceAttempt = value;
                  if (value == PracticeAttempt.stopped ||
                      value == PracticeAttempt.uncertain) {
                    _practiceEnded = true;
                    _practiceEpoch++;
                  }
                });
              },
            ),
            for (var i = 0; i < lesson.teaching.length; i++)
              _copy(context, lesson.teaching[i], 'taikyoku-teaching-$i'),
            for (final movement in widget.course.movementsFor(lesson)) ...[
              Semantics(
                header: true,
                child: _copy(context, movement.title, '${movement.id}-title'),
              ),
              Text(
                _label(
                  context,
                  'B · sampled position {value1}; this is not a movement-onset time.',
                  'B · {value1} örnek karesi; hareketin başlangıç zamanı değildir.',
                  args: {'value1': movement.evidence.sample},
                ),
              ),
              for (final (sectionKey, sectionCopy, englishLabel, turkishLabel)
                  in [
                    ('start', movement.start, 'Entry', 'Giriş'),
                    ('feet', movement.feet, 'Feet and torso', 'Ayak ve gövde'),
                    ('hands', movement.hands, 'Hand path', 'El yolu'),
                    ('finish', movement.finish, 'Finish', 'Bitiş'),
                    ('next', movement.next, 'Next entry', 'Sonraki giriş'),
                    (
                      'limit',
                      movement.limit,
                      'Visibility limit',
                      'Görünürlük sınırı',
                    ),
                  ]) ...[
                Semantics(
                  header: true,
                  child: Text(_label(context, englishLabel, turkishLabel)),
                ),
                _copy(context, sectionCopy, '${movement.id}-$sectionKey'),
              ],
            ],
          ],
          Text(
            _label(
              context,
              _retesting
                  ? 'Same prompts, side and heading: write the retest with reading and keys hidden.'
                  : 'Write your own recall before revealing a key. Hide the reading first.',
              _retesting
                  ? 'Aynı istem, taraf ve yön: okuma ve anahtarlar gizliyken tekrar yanıtını yaz.'
                  : 'Anahtarı açmadan önce kendi yanıtını yaz. Önce okumayı gizle.',
            ),
          ),
          for (var i = 0; i < lesson.recall.length; i++) ...[
            _copy(
              context,
              lesson.recall[i].prompt,
              '${lesson.recall[i].id}-prompt',
            ),
            for (final choice in lesson.recall[i].choices) ...[
              Text('${choice.id}.'),
              _copy(
                context,
                choice.text,
                '${lesson.recall[i].id}-choice-${choice.id}',
              ),
            ],
            TextField(
              key: Key(
                'taikyoku-${_retesting ? 'retest' : 'own'}-${lesson.recall[i].id}',
              ),
              controller: _retesting ? _retest[i] : _initial[i],
              enabled: _admitted,
              minLines: 2,
              maxLines: null,
              decoration: InputDecoration(
                labelText: _label(
                  context,
                  _retesting
                      ? 'Your retest answer (unsaved)'
                      : 'Your independent answer (unsaved)',
                  _retesting
                      ? 'Tekrar yanıtın (kaydedilmez)'
                      : 'Bağımsız yanıtın (kaydedilmez)',
                ),
              ),
              onChanged: (_) =>
                  _retesting ? _retestChanged() : _initialChanged(),
            ),
          ],
          if (!_retesting)
            TextButton(
              key: const Key('taikyoku-reveal-answer'),
              onPressed: _canReveal
                  ? () {
                      if (!_canReveal) return;
                      setState(() {
                        _answerVisible = true;
                        _initialRevealed = true;
                      });
                    }
                  : null,
              child: Text(
                _label(
                  context,
                  'Reveal after your own answers',
                  'Kendi yanıtlarından sonra anahtarı aç',
                ),
              ),
            ),
          if (_retesting)
            TextButton(
              key: const Key('taikyoku-compare-retest'),
              onPressed: _canCompare
                  ? () {
                      if (!_canCompare) return;
                      setState(() {
                        _answerVisible = true;
                        _compared = false;
                      });
                    }
                  : null,
              child: Text(
                _label(
                  context,
                  'Compare the written retest',
                  'Yazılı tekrarı karşılaştır',
                ),
              ),
            ),
          if (_answerVisible) ...[
            for (final q in lesson.recall)
              Semantics(
                container: true,
                label: _label(
                  context,
                  'Answer key for {value1}',
                  '{value1} yanıt anahtarı',
                  args: {'value1': q.id},
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(
                        context,
                        'Key: {value1}',
                        'Anahtar: {value1}',
                        args: {'value1': q.correctChoiceId},
                      ),
                      key: Key('${q.id}-key'),
                    ),
                    _copy(
                      context,
                      q.correctChoice.text,
                      '${q.id}-correct-answer',
                    ),
                    _copy(context, q.explanation, '${q.id}-explanation'),
                  ],
                ),
              ),
          ],
          if (_initialRevealed && (!_retesting || _answerVisible))
            TextField(
              key: const Key('taikyoku-own-correction'),
              controller: _correction,
              minLines: 2,
              maxLines: null,
              enabled: _admitted,
              decoration: InputDecoration(
                labelText: _label(
                  context,
                  'One correction or unresolved question (unsaved)',
                  'Bir düzeltme veya çözülmemiş soru (kaydedilmez)',
                ),
              ),
              onChanged: (_) => _correctionChanged(),
            ),
          if (!_retesting)
            TextButton(
              key: const Key('taikyoku-start-retest'),
              onPressed: _canRetest
                  ? () {
                      if (!_canRetest) return;
                      widget.onInvalidate();
                      setState(() {
                        _readingVisible = false;
                        _answerVisible = false;
                        _retesting = true;
                        _compared = false;
                        _reported = false;
                        for (final controller in _retest) {
                          controller.clear();
                        }
                      });
                    }
                  : null,
              child: Text(
                _label(
                  context,
                  'Hide the keys and retest the same prompts',
                  'Anahtarları gizle ve aynı istemleri tekrar yanıtla',
                ),
              ),
            ),
          CheckboxListTile(
            key: const Key('taikyoku-compared'),
            value: _compared,
            onChanged: _canCompare && _answerVisible
                ? (value) {
                    if (!_canCompare || !_answerVisible) return;
                    widget.onInvalidate();
                    setState(() {
                      _compared = value == true;
                      _reported = false;
                    });
                  }
                : null,
            title: Text(
              _label(
                context,
                'I compared my written retest; physical details remain open. This is my report.',
                'Yazılı tekrarımı karşılaştırdım; fiziksel ayrıntılar açıktır. Bu benim beyanımdır.',
              ),
            ),
          ),
          if (!widget.priorWritten())
            Text(
              _label(
                context,
                'You may read now. Report the preceding written lesson before reporting this one.',
                'Şimdi okuyabilirsin. Bunu beyan etmeden önce önceki yazılı dersi beyan et.',
              ),
            ),
          TextButton(
            key: const Key('taikyoku-report-written'),
            onPressed: _canReport
                ? () {
                    if (!visitCurrent() || !_canReport) return;
                    widget.onWritten();
                    setState(() {
                      _reported = true;
                    });
                  }
                : null,
            child: Text(
              _label(
                context,
                _reported
                    ? 'Written review reported'
                    : 'Report written review only',
                _reported
                    ? 'Yazılı inceleme beyan edildi'
                    : 'Yalnız yazılı incelemeyi beyan et',
              ),
            ),
          ),
          _copy(
            context,
            lesson.completionMeaning,
            'taikyoku-completion-meaning',
          ),
          Text(
            _label(
              context,
              'Answers, corrections, retests and progress are unsaved and limited to this visit. They do not certify movement.',
              'Yanıt, düzeltme, tekrar ve ilerleme kaydedilmez; bu ziyaretle sınırlıdır. Hareketi onaylamaz.',
            ),
          ),
          TextButton(
            key: const Key('taikyoku-stop'),
            onPressed: () {
              if (_admitted) _reset();
            },
            child: Text(
              _label(
                context,
                'Stop / break and clear this visit',
                'Dur / ara ver ve bu ziyareti temizle',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaikyokuCoursePage extends StatefulWidget {
  const TaikyokuCoursePage({
    super.key,
    required this.loader,
    this.accountUserId,
    this.resourceAdmission,
  });
  final Future<TaikyokuCourse> Function() loader;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;
  @override
  State<TaikyokuCoursePage> createState() => _TaikyokuCoursePageState();
}

class _TaikyokuCoursePageState extends State<TaikyokuCoursePage>
    with WidgetsBindingObserver {
  final _written = <String>{};
  TaikyokuCourse? _course;
  bool _failed = false, _integrityFailure = false, _retired = false;
  bool _foreground = _resumed();
  int _generation = 0;
  Route<void>? _overview, _lesson;
  NavigatorState? _navigator;
  bool get _admitted =>
      mounted &&
      !_retired &&
      _foreground &&
      widget.resourceAdmission?.value != false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.accountUserId?.addListener(_retire);
    widget.resourceAdmission?.addListener(_admissionChanged);
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overview = ModalRoute.of<void>(context);
    _navigator = Navigator.of(context);
    if (widget.resourceAdmission?.value == false) _retire();
  }

  @override
  void didUpdateWidget(covariant TaikyokuCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId ||
        oldWidget.resourceAdmission != widget.resourceAdmission ||
        oldWidget.loader != widget.loader) {
      oldWidget.accountUserId?.removeListener(_retire);
      oldWidget.resourceAdmission?.removeListener(_admissionChanged);
      widget.accountUserId?.addListener(_retire);
      widget.resourceAdmission?.addListener(_admissionChanged);
      _retire();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _generation++;
      if (mounted) setState(_written.clear);
    } else if (!_retired && _course == null) {
      unawaited(_load());
    } else if (mounted) {
      setState(() {});
    }
  }

  void _admissionChanged() {
    if (widget.resourceAdmission?.value == false) _retire();
  }

  void _retire() {
    if (_retired) return;
    _retired = true;
    _generation++;
    if (mounted) {
      setState(() {
        _course = null;
        _written.clear();
      });
    }
    final navigator = _navigator;
    final overview = _overview;
    final lesson = _lesson;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator == null || !navigator.mounted) return;
      if (lesson != null && lesson.isActive) navigator.removeRoute(lesson);
      if (overview != null && overview.isActive) {
        navigator.removeRoute(overview);
      }
    });
  }

  Future<void> _load() async {
    if (!_admitted) return;
    final generation = ++_generation;
    setState(() {
      _course = null;
      _failed = false;
      _integrityFailure = false;
    });
    try {
      final course = await widget.loader();
      if (!_admitted || generation != _generation) return;
      setState(() {
        _course = course;
      });
    } catch (error) {
      if (!_admitted || generation != _generation) return;
      setState(() {
        _failed = true;
        _integrityFailure =
            error is FormatException ||
            ContentFailure.from(error).kind == ContentFailureKind.integrity;
      });
    }
  }

  Future<void> _open(TaikyokuLesson lesson) async {
    final course = _course;
    if (!_admitted ||
        course == null ||
        _lesson != null ||
        _overview?.isCurrent != true) {
      return;
    }
    late final MaterialPageRoute<void> route;
    bool current() => _admitted && identical(_lesson, route) && route.isCurrent;
    bool prior() =>
        lesson.previousLessonId == null ||
        _written.contains(lesson.previousLessonId);
    route = MaterialPageRoute<void>(
      builder: (_) => !current()
          ? const SizedBox.shrink()
          : TaikyokuLessonPage(
              lesson: lesson,
              course: course,
              admitted: current,
              priorWritten: prior,
              onWritten: () {
                if (current() && prior()) {
                  setState(() {
                    _written.add(lesson.id);
                  });
                }
              },
              onInvalidate: () {
                if (current()) {
                  setState(() {
                    for (final next in course.lessons.where(
                      (l) => l.number >= lesson.number,
                    )) {
                      _written.remove(next.id);
                    }
                  });
                }
              },
              onReset: () {
                if (!_retired && mounted) setState(_written.clear);
              },
            ),
    );
    _lesson = route;
    await _navigator!.push(route);
    if (identical(_lesson, route)) _lesson = null;
  }

  @override
  void dispose() {
    _retired = true;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    widget.accountUserId?.removeListener(_retire);
    widget.resourceAdmission?.removeListener(_admissionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      appBar: AppBar(title: const Text('Taikyoku Shodan')),
      body: _retired
          ? const SizedBox.shrink()
          : _failed
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _label(
                    context,
                    _integrityFailure
                        ? 'Course content could not be verified. Written review is unavailable.'
                        : 'Course could not load.',
                    _integrityFailure
                        ? 'Kurs içeriği doğrulanamadı. Yazılı inceleme kullanılamaz.'
                        : 'Kurs yüklenemedi.',
                  ),
                  key: const Key('taikyoku-load-failure'),
                ),
                if (!_integrityFailure)
                  TextButton(
                    key: const Key('taikyoku-retry'),
                    onPressed: _admitted ? _load : null,
                    child: Text(_label(context, 'Retry', 'Yeniden dene')),
                  ),
              ],
            )
          : course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('taikyoku-course-list'),
              padding: const EdgeInsets.all(20),
              children: [
                _copy(context, course.title, 'taikyoku-course-title'),
                const CourseScopeNote(CourseScope.taikyoku),
                Text(
                  _label(
                    context,
                    'Jason Leung reference. A supplies opening/closing; B supplies all 20 counts and observed entries.',
                    'Jason Leung referansı. Açılış/kapanış A’dan; 20 hareket ve gözlenen girişler B’den alınır.',
                  ),
                ),
                Text(
                  _label(
                    context,
                    'Written review and optional source-reviewed beginner tasks are separate. All six individual physical validation records remain open.',
                    'Yazılı inceleme ve kaynak incelemesine dayanan isteğe bağlı başlangıç görevleri ayrıdır. Altı kişisel fiziksel doğrulama kaydı açık kalır.',
                  ),
                  key: const Key('taikyoku-readiness'),
                ),
                Text(
                  _label(
                    context,
                    '{value1}/10 written reviews reported this visit; optional attempts do not change this count.',
                    'Bu ziyarette {value1}/10 yazılı inceleme beyanı; isteğe bağlı denemeler bu sayıyı değiştirmez.',
                    args: {'value1': _written.length},
                  ),
                  key: const Key('taikyoku-written-progress'),
                ),
                if (_written.length == course.lessons.length)
                  Text(
                    _label(
                      context,
                      'Complete written sequence review reported this visit. This does not establish physical completion or mastery.',
                      'Bu ziyarette tam yazılı sıra incelemesi beyan edildi. Fiziksel tamamlanma veya ustalık doğrulanmaz.',
                    ),
                    key: const Key('taikyoku-written-completion'),
                  ),
                Text(
                  _label(
                    context,
                    'These reports are unsaved and clear when you stop, leave this visit, change owner or interrupt the app.',
                    'Bu beyanlar kaydedilmez; durunca, ziyaretten çıkınca, sahip değişince veya uygulama kesilince temizlenir.',
                  ),
                ),
                for (final lesson in course.lessons)
                  ListTile(
                    key: Key('taikyoku-lesson-${lesson.number}'),
                    title: Text(_text(context, lesson.title)),
                    subtitle: Text(
                      _label(
                        context,
                        _written.contains(lesson.id)
                            ? 'Written review reported'
                            : 'Read, recall, correct and retest',
                        _written.contains(lesson.id)
                            ? 'Yazılı inceleme beyan edildi'
                            : 'Oku, hatırla, düzelt ve tekrar yanıtla',
                      ),
                    ),
                    onTap: _admitted ? () => _open(lesson) : null,
                  ),
                ExpansionTile(
                  key: const Key('taikyoku-prerequisites'),
                  title: Text(
                    _label(
                      context,
                      'Open individual physical requirements',
                      'Açık bireysel fiziksel gereksinimler',
                    ),
                  ),
                  children: [
                    for (final requirement in course.requirements)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _copy(
                              context,
                              requirement.title,
                              '${requirement.id}-title',
                            ),
                            _copy(
                              context,
                              requirement.detail,
                              '${requirement.id}-detail',
                            ),
                            Text(
                              _label(
                                context,
                                '{value1}: open',
                                '{value1}: açık',
                                args: {'value1': requirement.id},
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ExpansionTile(
                  key: const Key('taikyoku-source-limits'),
                  title: Text(
                    _label(
                      context,
                      'Reference scope and visibility limits',
                      'Referans kapsamı ve görünürlük sınırları',
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _copy(
                            context,
                            course.commonLimits,
                            'taikyoku-common-limits',
                          ),
                          for (final source in course.sources)
                            Text(
                              '${source.id}: ${source.title}\n${source.url}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
