import 'technique_capability_panel.dart';
import 'course_scope_note.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'karate_course.dart';
import 'self_guided_practice.dart';
import 'self_guided_practice_panel.dart';
import 'taikyoku_shodan_course_page.dart';
import 'ui_language.dart';

String _text(BuildContext context, KarateCopy copy) =>
    UiLanguage.text(context, en: copy.en, tr: copy.tr);
String _label(
  BuildContext context,
  String en,
  String tr, {
  Map<String, Object> args = const {},
}) => UiLanguage.format(context, en: en, tr: tr, args: args);

class KarateCourseEntryCard extends StatelessWidget {
  const KarateCourseEntryCard({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const Key('open-karate-course'),
      title: Text(_label(context, 'Karate A', 'Karate A')),
      subtitle: Text(
        _label(
          context,
          '16 lessons · written review and optional beginner tasks',
          '16 ders · yazılı inceleme ve isteğe bağlı başlangıç görevleri',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpen,
    ),
  );
}

class KarateLessonPage extends StatefulWidget {
  const KarateLessonPage({
    super.key,
    required this.lesson,
    required this.course,
    required this.admitted,
    required this.priorWritten,
    required this.onWritten,
    required this.onInvalidate,
    required this.onReset,
  });
  final KarateLesson lesson;
  final KarateCourse course;
  final bool Function() admitted, priorWritten;
  final VoidCallback onWritten, onInvalidate, onReset;
  @override
  State<KarateLessonPage> createState() => _KarateLessonPageState();
}

enum _WrittenObservation { unreviewed, uncertain, compared }

class _KarateLessonPageState extends State<KarateLessonPage>
    with WidgetsBindingObserver {
  final TextEditingController _ownAnswer = TextEditingController();
  final TextEditingController _correction = TextEditingController();
  bool _answerVisible = false;
  bool _readingVisible = true;
  _WrittenObservation _observation = _WrittenObservation.unreviewed;
  bool _reported = false;
  PracticeAttempt _practiceAttempt = PracticeAttempt.unrecorded;
  int _practiceEpoch = 0;
  bool _practiceEnded = false;
  bool _practiceForeground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  bool get _canReport =>
      mounted &&
      _practiceForeground &&
      widget.admitted() &&
      _answerVisible &&
      _correction.text.trim().isNotEmpty &&
      _observation == _WrittenObservation.compared &&
      widget.priorWritten() &&
      !_reported;
  @override
  void initState() {
    super.initState();
    _readingVisible = widget.lesson.number != 16;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant KarateLessonPage oldWidget) {
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
    _ownAnswer.dispose();
    _correction.dispose();
    super.dispose();
  }

  void _reset() {
    if (!mounted) return;
    _practiceEpoch++;
    _practiceEnded = false;
    _ownAnswer.clear();
    _correction.clear();
    setState(() {
      _answerVisible = false;
      _observation = _WrittenObservation.unreviewed;
      _reported = false;
      _practiceAttempt = PracticeAttempt.unrecorded;
    });
    widget.onReset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _practiceForeground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      _reset();
    } else {
      _practiceEpoch++;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final practice = l.selfPractice;
    final practiceEpoch = _practiceEpoch;
    bool visitCurrent() =>
        mounted &&
        practiceEpoch == _practiceEpoch &&
        identical(l, widget.lesson) &&
        identical(practice, widget.lesson.selfPractice) &&
        _practiceForeground &&
        widget.admitted();
    bool practiceCurrent() =>
        visitCurrent() && _readingVisible && !_practiceEnded;
    return Scaffold(
      appBar: AppBar(
        title: Text(_text(context, l.title)),
        actions: [
          IconButton(
            key: const Key('karate-stop-top'),
            tooltip: _label(
              context,
              'Stop and clear this visit',
              'Dur ve bu ziyareti temizle',
            ),
            onPressed: () {
              if (widget.admitted()) _reset();
            },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TechniqueCapabilityPanel(courseId: 'jablab.karate_a', lessonId: l.id),
          Text(
            _label(
              context,
              'Written review and published optional beginner tasks are separate. No checkbox, written answer or self-report validates personal technique or suitability.',
              'Yazılı inceleme ve yayımlanan isteğe bağlı başlangıç görevleri ayrıdır. Kutucuk, yazılı yanıt veya öz beyan kişisel tekniği ya da uygunluğu doğrulamaz.',
            ),
            key: const Key('karate-physical-blocked'),
          ),
          Text(_text(context, widget.course.shared['stop']!)),
          TextButton(
            key: const Key('karate-toggle-reading'),
            onPressed: () {
              if (widget.admitted()) {
                setState(() {
                  _practiceEpoch++;
                  _readingVisible = !_readingVisible;
                });
              }
            },
            child: Text(
              _label(
                context,
                _readingVisible
                    ? 'Hide reading to recall independently'
                    : 'Show reading',
                _readingVisible
                    ? 'Bağımsız hatırlamak için okumayı gizle'
                    : 'Okumayı göster',
              ),
            ),
          ),
          if (_readingVisible) ...[
            for (final copy in widget.course.shared.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_text(context, copy)),
              ),
            Text(_text(context, l.teaching), key: const Key('karate-teaching')),
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
            if (l.number == 15)
              for (final row in widget.course.sequenceRows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_text(context, row)),
                  ),
                ),
          ],
          Text(
            _label(
              context,
              l.physicalPrerequisiteIds.isEmpty
                  ? 'Written progress and optional task reports remain separate.'
                  : 'Unverified personal technique records: {value1}',
              l.physicalPrerequisiteIds.isEmpty
                  ? 'Yazılı ilerleme ve isteğe bağlı görev beyanları ayrı kalır.'
                  : 'Doğrulanmamış kişisel teknik kayıtları: {value1}',
              args: {'value1': l.physicalPrerequisiteIds.join(', ')},
            ),
            key: const Key('karate-physical-prerequisites'),
          ),
          Text(
            _text(context, l.writtenTask),
            key: const Key('karate-written-task'),
          ),
          Text(_text(context, l.question)),
          TextField(
            key: const Key('karate-own-answer'),
            controller: _ownAnswer,
            minLines: 3,
            maxLines: null,
            decoration: InputDecoration(
              labelText: _label(
                context,
                'Your independent answer and uncertainty (unsaved)',
                'Bağımsız yanıtın ve belirsizlik (kaydedilmez)',
              ),
            ),
            onChanged: (_) {
              if (widget.admitted()) {
                _correction.clear();
                widget.onInvalidate();
                setState(() {
                  _answerVisible = false;
                  _observation = _WrittenObservation.unreviewed;
                  _reported = false;
                });
              }
            },
          ),
          TextButton(
            key: const Key('karate-reveal-answer'),
            onPressed: _ownAnswer.text.trim().isNotEmpty
                ? () {
                    if (widget.admitted()) {
                      setState(() {
                        _answerVisible = !_answerVisible;
                        if (!_answerVisible) {
                          _observation = _WrittenObservation.unreviewed;
                        }
                      });
                    }
                  }
                : null,
            child: Text(
              _label(
                context,
                _answerVisible
                    ? 'Hide answer'
                    : 'Reveal after writing your own answer',
                _answerVisible
                    ? 'Yanıtı gizle'
                    : 'Kendi yanıtını yazdıktan sonra yanıtı aç',
              ),
            ),
          ),
          if (_answerVisible) ...[
            Text(_text(context, l.answer), key: const Key('karate-answer')),
            Text(
              _text(context, l.correction),
              key: const Key('karate-correction-guidance'),
            ),
            Text(
              _text(context, l.retest),
              key: const Key('karate-retest-guidance'),
            ),
            TextField(
              key: const Key('karate-own-correction'),
              controller: _correction,
              minLines: 2,
              maxLines: null,
              decoration: InputDecoration(
                labelText: _label(
                  context,
                  'Write one correction or an unresolved question (unsaved)',
                  'Bir düzeltme veya çözülmemiş soru yaz (kaydedilmez)',
                ),
              ),
              onChanged: (_) {
                if (!widget.admitted()) return;
                widget.onInvalidate();
                setState(() {
                  _observation = _WrittenObservation.unreviewed;
                  _reported = false;
                });
              },
            ),
          ],
          Text(
            _label(
              context,
              'Written retesting remains separate from optional self-practice. Neither a written answer nor comfort validates technique; stop rather than retry when a stop symptom appears.',
              'Yazılı tekrar isteğe bağlı öz çalışmadan ayrıdır. Yazılı yanıt veya rahatlık tekniği doğrulamaz; durma belirtisinde yeniden denemek yerine dur.',
            ),
          ),
          RadioGroup<_WrittenObservation>(
            key: const Key('karate-observation-group'),
            groupValue: _observation,
            onChanged: (value) {
              if (!widget.admitted() || !_answerVisible || value == null) {
                return;
              }
              widget.onInvalidate();
              setState(() {
                _observation = value;
                _reported = false;
              });
            },
            child: Column(
              children: [
                for (final observation in _WrittenObservation.values)
                  RadioListTile<_WrittenObservation>(
                    key: Key(
                      observation == _WrittenObservation.compared
                          ? 'karate-compared'
                          : 'karate-observation-${observation.name}',
                    ),
                    value: observation,
                    enabled: _answerVisible,
                    title: Text(
                      _label(
                        context,
                        switch (observation) {
                          _WrittenObservation.unreviewed => 'Review pending',
                          _WrittenObservation.uncertain =>
                            'Uncertain; keep written review open',
                          _WrittenObservation.compared =>
                            'I compared my writing; this is my report',
                        },
                        switch (observation) {
                          _WrittenObservation.unreviewed => 'İnceleme bekliyor',
                          _WrittenObservation.uncertain =>
                            'Belirsiz; yazılı inceleme açık kalsın',
                          _WrittenObservation.compared =>
                            'Yazımı karşılaştırdım; bu benim beyanım',
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!widget.priorWritten())
            Text(
              _label(
                context,
                'You may read this lesson now. Report the previous written review first to follow the course sequence.',
                'Bu dersi şimdi okuyabilirsin. Kurs sırası için önce önceki yazılı incelemeyi beyan et.',
              ),
            ),
          TextButton(
            key: const Key('karate-report-written'),
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
          TextButton(
            key: const Key('karate-stop'),
            onPressed: () {
              if (widget.admitted()) _reset();
            },
            child: Text(
              _label(
                context,
                'Stop / break · clear this visit’s unsaved written reviews',
                'Dur / ara ver · bu ziyaretin kaydedilmemiş yazılı incelemelerini temizle',
              ),
            ),
          ),
          for (final id in l.sourceIds)
            Text(widget.course.sources.firstWhere((s) => s.id == id).title),
        ],
      ),
    );
  }
}

class KarateCoursePage extends StatefulWidget {
  const KarateCoursePage({
    super.key,
    required this.loader,
    this.accountUserId,
    this.resourceAdmission,
    this.onOpenTaikyokuCourse,
  });
  final Future<KarateCourse> Function() loader;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;
  final VoidCallback? onOpenTaikyokuCourse;
  @override
  State<KarateCoursePage> createState() => _KarateCoursePageState();
}

class _KarateCoursePageState extends State<KarateCoursePage>
    with WidgetsBindingObserver {
  final Set<String> _written = <String>{};
  KarateCourse? _course;
  bool _failed = false;
  bool _retired = false;
  int _generation = 0;
  Route<void>? _overview;
  Route<void>? _lesson;
  NavigatorState? _navigator;
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
  void didUpdateWidget(covariant KarateCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId ||
        oldWidget.resourceAdmission != widget.resourceAdmission) {
      oldWidget.accountUserId?.removeListener(_retire);
      oldWidget.resourceAdmission?.removeListener(_admissionChanged);
      widget.accountUserId?.addListener(_retire);
      widget.resourceAdmission?.addListener(_admissionChanged);
      _retire();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(_written.clear);
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
    if (_retired || widget.resourceAdmission?.value == false) return;
    final generation = ++_generation;
    setState(() {
      _course = null;
      _failed = false;
    });
    try {
      final course = await widget.loader();
      if (!mounted || _retired || generation != _generation) return;
      setState(() {
        _course = course;
      });
    } catch (_) {
      if (!mounted || _retired || generation != _generation) return;
      setState(() {
        _failed = true;
      });
    }
  }

  Future<void> _open(KarateLesson lesson) async {
    final course = _course;
    if (_retired ||
        course == null ||
        _lesson != null ||
        widget.resourceAdmission?.value == false) {
      return;
    }
    final route = MaterialPageRoute<void>(
      builder: (_) => _retired || widget.resourceAdmission?.value == false
          ? const SizedBox.shrink()
          : KarateLessonPage(
              lesson: lesson,
              course: course,
              admitted: () =>
                  !_retired && widget.resourceAdmission?.value != false,
              priorWritten: () =>
                  lesson.prerequisiteIds.every(_written.contains),
              onWritten: () {
                if (mounted &&
                    !_retired &&
                    widget.resourceAdmission?.value != false &&
                    lesson.prerequisiteIds.every(_written.contains)) {
                  setState(() {
                    _written.add(lesson.id);
                  });
                }
              },
              onInvalidate: () {
                if (mounted && !_retired) {
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
                if (mounted && !_retired) setState(_written.clear);
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
      appBar: AppBar(title: Text(_label(context, 'Karate A', 'Karate A'))),
      body: _retired
          ? const SizedBox.shrink()
          : _failed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(
                      context,
                      'Course could not load.',
                      'Kurs yüklenemedi.',
                    ),
                  ),
                  TextButton(
                    key: const Key('karate-retry'),
                    onPressed: _load,
                    child: Text(_label(context, 'Retry', 'Yeniden dene')),
                  ),
                ],
              ),
            )
          : course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('karate-course-list'),
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.onOpenTaikyokuCourse != null)
                  TaikyokuCourseEntryCard(
                    onOpen: () {
                      if (!_retired &&
                          widget.resourceAdmission?.value != false &&
                          _overview?.isCurrent == true &&
                          (WidgetsBinding.instance.lifecycleState == null ||
                              WidgetsBinding.instance.lifecycleState ==
                                  AppLifecycleState.resumed)) {
                        widget.onOpenTaikyokuCourse!();
                      }
                    },
                  ),
                Text(
                  _text(context, course.title),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const CourseScopeNote(CourseScope.karate),
                for (final copy in course.shared.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_text(context, copy)),
                  ),
                Text(
                  _label(
                    context,
                    'Primary references supply context. The short preparations and KA-P1 are original adaptations with no physical acceptance.',
                    'Birincil kaynaklar bağlam sağlar. Kısa hazırlıklar ve KA-P1 fiziksel kabulü olmayan özgün uyarlamalardır.',
                  ),
                ),
                Text(
                  _label(
                    context,
                    'Each lesson identifies any source-reviewed optional task and a smaller or written alternative. Individual physical validation remains absent.',
                    'Her ders kaynak incelemesine dayanan isteğe bağlı görevini ve daha küçük veya yazılı alternatifini belirtir. Kişisel fiziksel doğrulama yoktur.',
                  ),
                  key: const Key('karate-readiness'),
                ),
                Text(
                  _label(
                    context,
                    '{value1}/16 written reviews reported this visit; optional attempts do not change this count.',
                    'Bu ziyarette {value1}/16 yazılı inceleme beyanı; isteğe bağlı denemeler bu sayıyı değiştirmez.',
                    args: {'value1': _written.length},
                  ),
                  key: const Key('karate-written-progress'),
                ),
                if (_written.length == course.lessons.length)
                  Text(
                    _label(
                      context,
                      'Written review completed by self-report this visit. Optional task reports do not establish physical completion, correct technique, a kata pass or rank.',
                      'Bu ziyaretin yazılı incelemesi öz beyanla tamamlandı. İsteğe bağlı görev beyanları fiziksel tamamlanma, doğru teknik, kata başarısı veya derece oluşturmaz.',
                    ),
                    key: const Key('karate-written-completion'),
                  ),
                Text(
                  _label(
                    context,
                    'Per-visit self-checks are not saved and do not certify technique.',
                    'Bu ziyaretteki öz kontroller kaydedilmez ve tekniği onaylamaz.',
                  ),
                ),
                for (final lesson in course.lessons)
                  ListTile(
                    key: Key('karate-lesson-${lesson.number}'),
                    title: Text(
                      '${lesson.number}. ${_text(context, lesson.title)}',
                    ),
                    subtitle: Text(
                      _label(
                        context,
                        _written.contains(lesson.id)
                            ? 'Written review reported'
                            : 'Read and write your own answer',
                        _written.contains(lesson.id)
                            ? 'Yazılı inceleme beyan edildi'
                            : 'Oku ve kendi yanıtını yaz',
                      ),
                    ),
                    onTap: () => _open(lesson),
                  ),
                Text(
                  _label(context, 'Teaching references', 'Öğretim kaynakları'),
                ),
                for (final source in course.sources)
                  Text(
                    '${source.title}\n${source.url}\n${_label(context, 'Reference scope in original English:', 'Kaynak kapsamı özgün İngilizce kayıtla:')}\n${source.support}\n${source.limit}',
                  ),
              ],
            ),
    );
  }
}
