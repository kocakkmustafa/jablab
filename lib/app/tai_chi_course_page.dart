import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tai_chi_course.dart';
import 'yang16_written_course_page.dart';
import 'ui_language.dart';

String _text(BuildContext context, TaiChiCopy copy) =>
    UiLanguage.isTurkish(context) ? copy.tr : copy.en;
String _label(BuildContext context, String en, String tr) =>
    UiLanguage.text(context, en: en, tr: tr);

class TaiChiCourseEntryCard extends StatelessWidget {
  const TaiChiCourseEntryCard({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const Key('open-tai-chi-course'),
      title: Text(_label(context, 'Tai Chi foundations', 'Tai Chi temelleri')),
      subtitle: Text(
        _label(
          context,
          '14 written lessons · original practice, not a traditional form',
          '14 yazılı ders · özgün çalışma, geleneksel form değil',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpen,
    ),
  );
}

class TaiChiCoursePage extends StatefulWidget {
  const TaiChiCoursePage({
    super.key,
    required this.loader,
    this.accountUserId,
    this.resourceAdmission,
    this.onOpenYang16WrittenCourse,
  });
  final Future<TaiChiCourse> Function() loader;
  final VoidCallback? onOpenYang16WrittenCourse;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;
  @override
  State<TaiChiCoursePage> createState() => _TaiChiCoursePageState();
}

class _TaiChiCoursePageState extends State<TaiChiCoursePage> {
  TaiChiCourse? _course;
  bool _failed = false;
  bool _retired = false;
  int _generation = 0;
  Route<void>? _overview;
  Route<void>? _lesson;
  NavigatorState? _navigator;
  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(covariant TaiChiCoursePage oldWidget) {
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

  Future<void> _open(TaiChiLesson lesson) async {
    if (_retired ||
        _lesson != null ||
        widget.resourceAdmission?.value == false) {
      return;
    }
    final route = MaterialPageRoute<void>(
      builder: (_) => TaiChiLessonPage(
        lesson: lesson,
        course: _course!,
        admitted: () => !_retired && widget.resourceAdmission?.value != false,
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
    widget.accountUserId?.removeListener(_retire);
    widget.resourceAdmission?.removeListener(_admissionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _label(context, 'Tai Chi foundations', 'Tai Chi temelleri'),
        ),
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
                    key: const Key('tai-chi-retry'),
                    onPressed: _load,
                    child: Text(_label(context, 'Retry', 'Yeniden dene')),
                  ),
                ],
              ),
            )
          : course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('tai-chi-course-list'),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _text(context, course.title),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(_text(context, course.scope)),
                Text(_text(context, course.endpoint)),
                Text(_text(context, course.safety)),
                Text(
                  _label(
                    context,
                    'Per-visit self-checks are not saved and do not certify technique.',
                    'Bu ziyaretteki öz kontroller kaydedilmez ve tekniği onaylamaz.',
                  ),
                ),
                if (widget.onOpenYang16WrittenCourse != null)
                  Yang16WrittenEntryCard(onOpen: () {
                    final lifecycle = WidgetsBinding.instance.lifecycleState;
                    if (mounted && !_retired && _overview?.isCurrent == true &&
                        widget.resourceAdmission?.value != false &&
                        (lifecycle == null || lifecycle == AppLifecycleState.resumed)) {
                      widget.onOpenYang16WrittenCourse?.call();
                    }
                  }),
                for (final lesson in course.lessons)
                  ListTile(
                    key: Key('tai-chi-lesson-${lesson.number}'),
                    title: Text(
                      '${lesson.number}. ${_text(context, lesson.title)}',
                    ),
                    subtitle: Text(_text(context, lesson.objective)),
                    onTap: () => _open(lesson),
                  ),
                Text(
                  _label(context, 'Teaching references', 'Öğretim kaynakları'),
                ),
                for (final source in course.sources)
                  Text('${source.title}\n${source.url}'),
              ],
            ),
    );
  }
}

class TaiChiLessonPage extends StatefulWidget {
  const TaiChiLessonPage({
    super.key,
    required this.lesson,
    required this.course,
    required this.admitted,
  });
  final TaiChiLesson lesson;
  final TaiChiCourse course;
  final bool Function() admitted;
  @override
  State<TaiChiLessonPage> createState() => _TaiChiLessonPageState();
}

class _TaiChiLessonPageState extends State<TaiChiLessonPage>
    with WidgetsBindingObserver {
  bool _answerVisible = false;
  bool _prepared = false;
  bool _attempted = false;
  String _selfCheck = 'unattempted';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _rest() {
    if (!mounted) return;
    setState(() {
      _prepared = false;
      _attempted = false;
      _selfCheck = 'unattempted';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _rest();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(title: Text(_text(context, lesson.title))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_text(context, lesson.objective)),
          Text(_text(context, widget.course.safety)),
          Text(_text(context, lesson.preparation)),
          Text(_text(context, lesson.instructions)),
          for (final row in lesson.practiceRows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_label(context, 'Count', 'Sayım')}: ${_text(context, row.count)}',
                    ),
                    Text(
                      '${_label(context, 'Direction', 'Yön')}: ${_text(context, row.direction)}',
                    ),
                    Text(
                      '${_label(context, 'Support', 'Destek')}: ${_text(context, row.support)}',
                    ),
                    Text(_text(context, row.instruction)),
                  ],
                ),
              ),
            ),
          CheckboxListTile(
            key: const Key('tai-chi-prepared'),
            value: _prepared,
            title: Text(
              _label(
                context,
                'I checked the space and chosen support.',
                'Alanı ve seçtiğim desteği kontrol ettim.',
              ),
            ),
            onChanged: (value) {
              if (widget.admitted()) {
                setState(() {
                  _prepared = value ?? false;
                  if (!_prepared) {
                    _attempted = false;
                    _selfCheck = 'unattempted';
                  }
                });
              }
            },
          ),
          CheckboxListTile(
            key: const Key('tai-chi-attempted'),
            value: _attempted,
            title: Text(
              _label(
                context,
                'I optionally attempted the practice; this is my report.',
                'İsteğe bağlı çalışmayı denedim; bu benim beyanım.',
              ),
            ),
            onChanged: _prepared
                ? (value) {
                    if (widget.admitted()) {
                      setState(() {
                        _attempted = value ?? false;
                        if (!_attempted) _selfCheck = 'unattempted';
                      });
                    }
                  }
                : null,
          ),
          TextButton(
            key: const Key('tai-chi-take-break'),
            onPressed: () {
              if (widget.admitted()) _rest();
            },
            child: Text(
              _label(
                context,
                'Take a break · check support again before practice',
                'Ara ver · çalışmadan önce desteği yeniden kontrol et',
              ),
            ),
          ),
          Text(_text(context, lesson.selfCheck)),
          RadioGroup<String>(
            key: const Key('tai-chi-self-check-group'),
            groupValue: _selfCheck,
            onChanged: (value) {
              if (value != null &&
                  widget.admitted() &&
                  (value == 'unattempted' || _attempted)) {
                setState(() {
                  _selfCheck = value;
                });
              }
            },
            child: Column(
              children: [
                for (final choice in [
                  'unattempted',
                  'uncertain',
                  'needsCorrection',
                  'observed',
                ])
                  RadioListTile<String>(
                    key: Key('tai-chi-check-$choice'),
                    value: choice,
                    enabled: choice == 'unattempted' || _attempted,
                    title: Text(
                      _label(
                        context,
                        {
                          'unattempted': 'Not attempted',
                          'uncertain': 'Uncertain',
                          'needsCorrection': 'Needs correction',
                          'observed': 'I noticed the stated cues',
                        }[choice]!,
                        {
                          'unattempted': 'Denenmedi',
                          'uncertain': 'Emin değilim',
                          'needsCorrection': 'Düzeltme gerekiyor',
                          'observed': 'Belirtilen ipuçlarını fark ettim',
                        }[choice]!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(_text(context, lesson.correction)),
          Text(_text(context, lesson.retest)),
          Text(_text(context, lesson.question)),
          TextButton(
            key: const Key('tai-chi-reveal-answer'),
            onPressed: () {
              if (widget.admitted()) {
                setState(() {
                  _answerVisible = !_answerVisible;
                });
              }
            },
            child: Text(
              _label(
                context,
                _answerVisible ? 'Hide answer' : 'Reveal answer',
                _answerVisible ? 'Yanıtı gizle' : 'Yanıtı göster',
              ),
            ),
          ),
          if (_answerVisible)
            Text(
              _text(context, lesson.answer),
              key: const Key('tai-chi-answer'),
            ),
          for (final id in lesson.sourceIds)
            Text(widget.course.sources.firstWhere((s) => s.id == id).title),
        ],
      ),
    );
  }
}
