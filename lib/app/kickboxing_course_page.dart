import 'technique_capability_panel.dart';
import 'course_scope_note.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'kickboxing_course.dart';
import 'ui_language.dart';
import 'self_guided_practice.dart';
import 'self_guided_practice_panel.dart';

String _text(BuildContext context, KickboxingCopy copy) =>
    UiLanguage.text(context, en: copy.en, tr: copy.tr);
String _label(
  BuildContext context,
  String en,
  String tr, {
  Map<String, Object> args = const {},
}) => UiLanguage.format(context, en: en, tr: tr, args: args);

class KickboxingCourseEntryCard extends StatelessWidget {
  const KickboxingCourseEntryCard({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const Key('open-kickboxing-course'),
      title: Text(_label(context, 'Kickboxing A', 'Kickboxing A')),
      subtitle: Text(
        _label(
          context,
          '16 lessons · selected beginner learning and written self-review',
          '16 ders · seçili başlangıç bilgisi ve yazılı öz inceleme',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpen,
    ),
  );
}

class KickboxingLessonPage extends StatefulWidget {
  const KickboxingLessonPage({
    super.key,
    required this.lesson,
    required this.course,
    required this.admitted,
    required this.priorWritten,
    required this.onWritten,
    required this.onInvalidate,
    required this.onReset,
  });
  final KickboxingLesson lesson;
  final KickboxingCourse course;
  final bool Function() admitted, priorWritten;
  final VoidCallback onWritten, onInvalidate, onReset;
  @override
  State<KickboxingLessonPage> createState() => _KickboxingLessonPageState();
}

enum _WrittenObservation { unreviewed, uncertain, compared }

class _KickboxingLessonPageState extends State<KickboxingLessonPage>
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
  bool _foreground = true;

  bool get _canReport =>
      _foreground &&
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
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant KickboxingLessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id) {
      _practiceEpoch++;
      _practiceAttempt = PracticeAttempt.unrecorded;
      _practiceEnded = false;
      _ownAnswer.clear();
      _correction.clear();
      _answerVisible = false;
      _observation = _WrittenObservation.unreviewed;
      _reported = false;
      _readingVisible = widget.lesson.number != 16;
    } else if (oldWidget.lesson.selfGuidedPractice !=
        widget.lesson.selfGuidedPractice) {
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
    _ownAnswer.clear();
    _correction.clear();
    setState(() {
      _answerVisible = false;
      _observation = _WrittenObservation.unreviewed;
      _reported = false;
      _practiceAttempt = PracticeAttempt.unrecorded;
      _practiceEnded = false;
    });
    widget.onReset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _reset();
    } else if (mounted) {
      _practiceEpoch++;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final practice = l.selfGuidedPractice;
    final practiceEpoch = _practiceEpoch;
    bool practiceCurrent() =>
        mounted &&
        _foreground &&
        _readingVisible &&
        !_practiceEnded &&
        practiceEpoch == _practiceEpoch &&
        identical(l, widget.lesson) &&
        identical(practice, widget.lesson.selfGuidedPractice) &&
        widget.admitted();
    return Scaffold(
      appBar: AppBar(
        title: Text(_text(context, l.title)),
        actions: [
          IconButton(
            key: const Key('kickboxing-stop-top'),
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
          Text(
            _label(
              context,
              'Written review and any optional beginner trial are separate. Your physical technique and individual suitability are not verified.',
              'Yazılı inceleme ile varsa isteğe bağlı başlangıç denemesi ayrıdır. Fiziksel tekniğin ve kişisel uygunluğun doğrulanmaz.',
            ),
            key: const Key('kickboxing-physical-blocked'),
          ),
          TechniqueCapabilityPanel(
            courseId: 'jablab.kickboxing_a',
            lessonId: l.id,
          ),
          Text(_text(context, widget.course.safety)),
          TextButton(
            key: const Key('kickboxing-toggle-reading'),
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
            Text(_text(context, widget.course.common)),
            Text(_text(context, widget.course.conventions)),
            for (final row in widget.course.conventionRows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_text(context, row)),
                ),
              ),
            if (l.sourceNote != null) Text(_text(context, l.sourceNote!)),
            if (practice != null)
              SelfGuidedPracticePanel(
                key: ValueKey('practice-${l.id}'),
                practice: practice,
                attempt: _practiceAttempt,
                admitted: practiceCurrent,
                onChanged: (value) {
                  if (!practiceCurrent() ||
                      (value == PracticeAttempt.attempted &&
                          !practice.offersMovement)) {
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
            // The lesson's own teaching (incl. its instructor prerequisite)
            // stays visible next to the optional self-guided panel.
            Text(_text(context, l.instructions)),
            for (final row in l.rows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_text(context, row)),
                ),
              ),
          ],
          Text(_text(context, l.question)),
          TextField(
            key: const Key('kickboxing-own-answer'),
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
            key: const Key('kickboxing-reveal-answer'),
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
            Text(_text(context, l.answer), key: const Key('kickboxing-answer')),
            Text(
              _text(context, l.correction),
              key: const Key('kickboxing-correction-guidance'),
            ),
            TextField(
              key: const Key('kickboxing-own-correction'),
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
              'Written retesting stays separate from any optional trial. Use the smaller or written alternative; a self-report is not a technique grade.',
              'Yazılı tekrar varsa isteğe bağlı denemeden ayrıdır. Daha küçük veya yazılı seçeneği kullan; öz beyan teknik notu değildir.',
            ),
          ),
          RadioGroup<_WrittenObservation>(
            key: const Key('kickboxing-observation-group'),
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
                          ? 'kickboxing-compared'
                          : 'kickboxing-observation-${observation.name}',
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
            key: const Key('kickboxing-report-written'),
            onPressed: _canReport
                ? () {
                    if (!mounted ||
                        !_canReport ||
                        practiceEpoch != _practiceEpoch ||
                        !identical(l, widget.lesson)) {
                      return;
                    }
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
            key: const Key('kickboxing-stop'),
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

class KickboxingCoursePage extends StatefulWidget {
  const KickboxingCoursePage({
    super.key,
    required this.loader,
    this.accountUserId,
    this.resourceAdmission,
  });
  final Future<KickboxingCourse> Function() loader;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;
  @override
  State<KickboxingCoursePage> createState() => _KickboxingCoursePageState();
}

class _KickboxingCoursePageState extends State<KickboxingCoursePage>
    with WidgetsBindingObserver {
  final Set<String> _written = <String>{};
  KickboxingCourse? _course;
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
  void didUpdateWidget(covariant KickboxingCoursePage oldWidget) {
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

  Future<void> _open(KickboxingLesson lesson) async {
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
          : KickboxingLessonPage(
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
      appBar: AppBar(
        title: Text(_label(context, 'Kickboxing A', 'Kickboxing A')),
      ),
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
                    key: const Key('kickboxing-retry'),
                    onPressed: _load,
                    child: Text(_label(context, 'Retry', 'Yeniden dene')),
                  ),
                ],
              ),
            )
          : course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('kickboxing-course-list'),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _text(context, course.title),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const CourseScopeNote(CourseScope.kickboxing),
                Text(_text(context, course.common)),
                Text(_text(context, course.conventions)),
                for (final row in course.conventionRows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_text(context, row)),
                    ),
                  ),
                Text(_text(context, course.review)),
                Text(
                  _label(
                    context,
                    'Physical technique, instructor approval and individual suitability are not verified. A self-report cannot change that.',
                    'Fiziksel teknik, eğitmen onayı ve kişisel uygunluk doğrulanmaz. Öz beyan bunu değiştirmez.',
                  ),
                  key: const Key('kickboxing-readiness'),
                ),
                Text(
                  _label(
                    context,
                    '{value1}/16 written reviews reported this visit; this does not certify physical technique.',
                    'Bu ziyarette {value1}/16 yazılı inceleme beyanı; fiziksel teknik onaylanmaz.',
                    args: {'value1': _written.length},
                  ),
                  key: const Key('kickboxing-written-progress'),
                ),
                if (_written.length == course.lessons.length)
                  Text(
                    _label(
                      context,
                      'Written review completed by self-report this visit. Stance, steps, jab, cross, low front kick and combined blocks remain physically unverified; optional attempts are separate self-reports.',
                      'Bu ziyaretin yazılı incelemesi öz beyanla tamamlandı. Duruş, adımlar, jab, cross, alçak öne tekme ve birleşik bloklar fiziksel olarak doğrulanmadı; isteğe bağlı denemeler ayrı öz beyanlardır.',
                    ),
                    key: const Key('kickboxing-written-completion'),
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
                    key: Key('kickboxing-lesson-${lesson.number}'),
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
