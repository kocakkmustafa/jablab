import 'technique_capability_panel.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'content_failure.dart';
import 'ui_language.dart';
import 'yang16_written_course.dart';
import 'yang16_preparation_course.dart';
import 'self_guided_practice.dart';
import 'self_guided_practice_panel.dart';

String _label(
  BuildContext context,
  String en,
  String tr, {
  Map<String, Object> args = const {},
}) => UiLanguage.format(context, en: en, tr: tr, args: args);
String _text(BuildContext context, Yang16Copy copy) =>
    UiLanguage.text(context, en: copy.en, tr: copy.tr);
Widget _copy(BuildContext context, Yang16Copy copy, String key) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(_text(context, copy), key: Key(key)),
);
bool _resumed() =>
    WidgetsBinding.instance.lifecycleState == null ||
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

class Yang16WrittenEntryCard extends StatelessWidget {
  const Yang16WrittenEntryCard({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const Key('open-yang16-written-course'),
      title: Text(
        _label(
          context,
          'Yang16 written form order',
          'Yang16 yazılı form sırası',
        ),
      ),
      subtitle: Text(
        _label(
          context,
          'Angela Plarre presentation · written form order only · 18 sections and 6 final targets',
          'Angela Plarre sunumu · yalnız yazılı form sırası · 18 bölüm ve 6 son hedef',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpen,
    ),
  );
}

class Yang16WrittenTargetPage extends StatefulWidget {
  const Yang16WrittenTargetPage({
    super.key,
    required this.course,
    required this.target,
    required this.admitted,
    required this.priorWritten,
    required this.onWritten,
    required this.onInvalidate,
    required this.onReset,
    this.practice,
  });
  final Yang16WrittenCourse course;
  final Yang16Target target;
  final bool Function() admitted, priorWritten;
  final VoidCallback onWritten, onInvalidate, onReset;
  final SelfGuidedPractice? practice;
  @override
  State<Yang16WrittenTargetPage> createState() =>
      _Yang16WrittenTargetPageState();
}

class _Yang16WrittenTargetPageState extends State<Yang16WrittenTargetPage>
    with WidgetsBindingObserver {
  final _initial = TextEditingController();
  final _retest = TextEditingController();
  final _correction = TextEditingController();
  final _supplement = TextEditingController();
  final _facts = <int>{};
  bool _reading = true, _keyVisible = false, _initialRevealed = false;
  bool _correcting = false, _retesting = false, _reported = false;
  bool _supplementVisible = false, _supplementKey = false;
  bool _foreground = _resumed();
  PracticeAttempt _practiceAttempt = PracticeAttempt.unrecorded;
  int _practiceEpoch = 0;
  bool _practiceEnded = false;
  bool get _admitted => mounted && _foreground && widget.admitted();
  bool get _filled {
    final answer = (_retesting ? _retest : _initial).text.trim();
    // An option letter cannot stand in for reconstruction. Fact correctness is
    // still the learner's explicit comparison, never an automatic grade.
    final compact = answer.toLowerCase().replaceAll(RegExp(r'[().:\s]'), '');
    return answer.isNotEmpty && !RegExp(r'^[a-z]$').hasMatch(compact);
  }

  bool get _canCompare => _admitted && !_reading && _filled;
  bool get _canRetest =>
      _admitted &&
      _initialRevealed &&
      _correcting &&
      _correction.text.trim().isNotEmpty;
  bool get _canReport =>
      _canCompare &&
      _keyVisible &&
      (!_correcting || _retesting) &&
      _facts.length == widget.target.facts.length &&
      widget.priorWritten() &&
      !_reported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _practiceEpoch++;
    WidgetsBinding.instance.removeObserver(this);
    for (final c in [_initial, _retest, _correction, _supplement]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clear() {
    _practiceEpoch++;
    _practiceAttempt = PracticeAttempt.unrecorded;
    _practiceEnded = false;
    for (final c in [_initial, _retest, _correction, _supplement]) {
      c.clear();
    }
    _facts.clear();
    _reading = true;
    _keyVisible = false;
    _initialRevealed = false;
    _correcting = false;
    _retesting = false;
    _reported = false;
    _supplementVisible = false;
    _supplementKey = false;
  }

  void _reset() {
    if (!mounted) return;
    setState(_clear);
    widget.onReset();
  }

  @override
  void didUpdateWidget(covariant Yang16WrittenTargetPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.practice != widget.practice) {
      _practiceEpoch++;
      _practiceAttempt = PracticeAttempt.unrecorded;
      _practiceEnded = false;
    }
    if (oldWidget.target != widget.target ||
        oldWidget.course != widget.course) {
      _clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // Clear on interruption and resume: delayed input cannot become fresh work.
    _reset();
  }

  void _answerChanged() {
    if (!_admitted) return;
    widget.onInvalidate();
    setState(() {
      _keyVisible = false;
      _facts.clear();
      _reported = false;
      _supplementVisible = false;
      _supplementKey = false;
      _supplement.clear();
      if (!_retesting) {
        _initialRevealed = false;
        _correcting = false;
        _correction.clear();
        _retest.clear();
      }
    });
  }

  void _startRetest() {
    if (!_canRetest) return;
    widget.onInvalidate();
    setState(() {
      _reading = false;
      _keyVisible = false;
      _retesting = true;
      _facts.clear();
      _reported = false;
      _retest.clear();
      _supplementVisible = false;
      _supplementKey = false;
      _supplement.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final practice = widget.practice;
    final practiceEpoch = _practiceEpoch;
    bool practiceCurrent() =>
        _admitted &&
        _reading &&
        !_practiceEnded &&
        practiceEpoch == _practiceEpoch &&
        identical(widget.target, target) &&
        identical(widget.practice, practice);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48 + 40 * MediaQuery.textScalerOf(context).scale(1),
        title: Text(
          _label(
            context,
            'Written form-order target',
            'Yazılı form sırası hedefi',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('yang16-stop-top'),
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
        key: const Key('yang16-target-body'),
        padding: const EdgeInsets.all(20),
        children: [
          _copy(context, target.title, 'yang16-target-title'),
          TechniqueCapabilityPanel(
            courseId: 'yang16-angela-written-v2',
            lessonId: target.id,
          ),
          Text(
            _label(
              context,
              'Written review and published optional beginner tasks are separate. No checkbox, written answer or self-report validates personal technique or suitability.',
              'Yazılı inceleme ve yayımlanan isteğe bağlı başlangıç görevleri ayrıdır. Kutucuk, yazılı yanıt veya öz beyan kişisel tekniği ya da uygunluğu doğrulamaz.',
            ),
            key: const Key('yang16-physical-blocked'),
          ),
          TextButton(
            key: const Key('yang16-toggle-reading'),
            onPressed: _admitted
                ? () {
                    if (!_admitted) return;
                    final show = !_reading;
                    _practiceEpoch++;
                    _practiceAttempt = PracticeAttempt.unrecorded;
                    _practiceEnded = false;
                    widget.onInvalidate();
                    setState(() {
                      _clear();
                      _reading = show;
                    });
                  }
                : null,
            child: Text(
              _label(
                context,
                _reading
                    ? 'Hide reading and answer independently'
                    : 'Show reading and reset this target',
                _reading
                    ? 'Okumayı gizle ve bağımsız yanıtla'
                    : 'Okumayı göster ve bu hedefi sıfırla',
              ),
            ),
          ),
          if (_reading) ...[
            if (target.isFinal)
              for (var i = 0; i < widget.course.reading.length; i++)
                _copy(
                  context,
                  widget.course.reading[i],
                  'yang16-final-reading-$i',
                ),
            for (var i = 0; i < target.reading.length; i++)
              _copy(context, target.reading[i], 'yang16-reading-$i'),
            for (final b in widget.course.boundariesFor(target)) ...[
              Text('${b.id}: ${b.from} → ${b.to}'),
              _copy(context, b.link, 'yang16-${b.id}-link'),
              _copy(context, b.limit, 'yang16-${b.id}-limit'),
            ],
          ],
          if (_reading && practice != null)
            SelfGuidedPracticePanel(
              practice: practice,
              attempt: _practiceAttempt,
              admitted: practiceCurrent,
              onChanged: (value) {
                if (!practiceCurrent()) return;
                if (value == PracticeAttempt.attempted &&
                    (_practiceEnded || !practice.offersMovement)) {
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
          _copy(context, widget.course.conditions, 'yang16-same-conditions'),
          Text(
            _label(
              context,
              _retesting
                  ? 'Same original question. Reconstruct every fact again; an option letter alone is insufficient.'
                  : 'Write your own complete answer before revealing a key.',
              _retesting
                  ? 'Aynı asıl soru. Her olguyu yeniden kur; yalnız seçenek harfi yeterli değildir.'
                  : 'Anahtarı açmadan önce kendi tam yanıtını yaz.',
            ),
          ),
          _copy(context, target.prompt, 'yang16-original-prompt'),
          if (_retesting && target.responseRequirement != null)
            _copy(
              context,
              target.responseRequirement!,
              'yang16-retest-response-requirement',
            ),
          for (final option in target.options)
            Text(
              '${option.id}: ${_text(context, option.text)}',
              key: Key('yang16-original-option-${option.id}'),
            ),
          TextField(
            key: Key(_retesting ? 'yang16-retest-answer' : 'yang16-own-answer'),
            controller: _retesting ? _retest : _initial,
            enabled: _admitted && !_reading,
            minLines: 2,
            maxLines: null,
            decoration: InputDecoration(
              labelText: _label(
                context,
                _retesting
                    ? 'Your full same-target reconstruction (unsaved)'
                    : 'Your independent full answer (unsaved)',
                _retesting
                    ? 'Aynı hedefi tam yeniden kurman (kaydedilmez)'
                    : 'Bağımsız tam yanıtın (kaydedilmez)',
              ),
            ),
            onChanged: (_) => _answerChanged(),
          ),
          TextButton(
            key: const Key('yang16-compare-answer'),
            onPressed: _canCompare
                ? () {
                    if (!_canCompare) return;
                    widget.onInvalidate();
                    setState(() {
                      _keyVisible = true;
                      _facts.clear();
                      _reported = false;
                      _supplementVisible = false;
                      _supplementKey = false;
                      _supplement.clear();
                      if (!_retesting) _initialRevealed = true;
                    });
                  }
                : null,
            child: Text(
              _label(
                context,
                _retesting
                    ? 'Compare the complete same-target retest'
                    : 'Reveal after your own answer',
                _retesting
                    ? 'Tam aynı hedefli tekrarı karşılaştır'
                    : 'Kendi yanıtından sonra anahtarı aç',
              ),
            ),
          ),
          if (_keyVisible) ...[
            _copy(context, target.answer, 'yang16-full-answer-key'),
            if ((_retesting
                    ? target.retestExplanation
                    : target.initialExplanation) !=
                null)
              _copy(
                context,
                (_retesting
                    ? target.retestExplanation
                    : target.initialExplanation)!,
                'yang16-answer-explanation',
              ),
            _copy(context, widget.course.passCriteria, 'yang16-pass-criteria'),
            Text(
              _label(
                context,
                'Check each fact only if it is correct in your written answer. This is your comparison, not automatic grading.',
                'Her olguyu yalnız yazılı yanıtında doğruysa işaretle. Bu senin karşılaştırmandır, otomatik puanlama değildir.',
              ),
            ),
            for (var i = 0; i < target.facts.length; i++)
              CheckboxListTile(
                key: Key('yang16-fact-$i'),
                value: _facts.contains(i),
                title: Text(_text(context, target.facts[i])),
                onChanged: _canCompare
                    ? (checked) {
                        if (!_canCompare || !_keyVisible) return;
                        widget.onInvalidate();
                        setState(() {
                          if (checked == true) {
                            _facts.add(i);
                          } else {
                            _facts.remove(i);
                          }
                          _reported = false;
                        });
                      }
                    : null,
              ),
            if (_correcting)
              _copy(context, target.correction, 'yang16-authored-correction'),
          ],
          if (_initialRevealed && !_retesting)
            TextButton(
              key: const Key('yang16-needs-correction'),
              onPressed: _admitted
                  ? () {
                      if (!_admitted) return;
                      widget.onInvalidate();
                      setState(() {
                        _correcting = true;
                        _facts.clear();
                        _reported = false;
                      });
                    }
                  : null,
              child: Text(
                _label(
                  context,
                  'My answer is wrong or incomplete: correct the same target',
                  'Yanıtım yanlış veya eksik: aynı hedefi düzelt',
                ),
              ),
            ),
          if (_correcting && !_retesting)
            TextField(
              key: const Key('yang16-own-correction'),
              controller: _correction,
              enabled: _admitted,
              minLines: 2,
              maxLines: null,
              decoration: InputDecoration(
                labelText: _label(
                  context,
                  'Your correction of the original error (unsaved)',
                  'Asıl hataya kendi düzeltmen (kaydedilmez)',
                ),
              ),
              onChanged: (_) {
                if (!_admitted) return;
                widget.onInvalidate();
                setState(() {
                  _facts.clear();
                  _reported = false;
                  _retest.clear();
                });
              },
            ),
          if (_correcting && (!_retesting || _keyVisible))
            TextButton(
              key: const Key('yang16-start-retest'),
              onPressed: _canRetest ? _startRetest : null,
              child: Text(
                _label(
                  context,
                  _retesting
                      ? 'Unresolved: hide keys and retry the same full target'
                      : 'Hide correction and key; retest the same full target',
                  _retesting
                      ? 'Çözülmedi: anahtarları gizle ve aynı tam hedefi yinele'
                      : 'Düzeltme ve anahtarı gizle; aynı tam hedefi tekrar yanıtla',
                ),
              ),
            ),
          if (!widget.priorWritten())
            Text(
              _label(
                context,
                'You may read this target. Resolve and report the preceding written target first.',
                'Bu hedefi okuyabilirsin. Önce önceki yazılı hedefi çöz ve beyan et.',
              ),
            ),
          TextButton(
            key: const Key('yang16-report-written'),
            onPressed: _canReport
                ? () {
                    if (!_canReport) return;
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
                    ? 'Full written target self-report recorded this visit'
                    : 'Self-report all original facts reconstructed',
                _reported
                    ? 'Tam yazılı hedef öz beyanı bu ziyaret için alındı'
                    : 'Bütün asıl olguları yeniden kurduğunu beyan et',
              ),
            ),
          ),
          if (_reported)
            _copy(context, target.completion, 'yang16-target-completion-rule'),
          if (_reported)
            TextButton(
              key: const Key('yang16-open-supplement'),
              onPressed: _admitted
                  ? () {
                      if (!_admitted) return;
                      setState(() {
                        _supplementVisible = !_supplementVisible;
                        _supplement.clear();
                        _supplementKey = false;
                      });
                    }
                  : null,
              child: Text(
                _label(
                  context,
                  'Optional supplementary question',
                  'İsteğe bağlı tamamlayıcı soru',
                ),
              ),
            ),
          if (_reported && _supplementVisible) ...[
            Text(
              _label(
                context,
                'This never resolves or replaces an original target.',
                'Bu soru asıl hedefi çözmez veya onun yerine geçmez.',
              ),
            ),
            _copy(context, target.supplementPrompt, 'yang16-supplement-prompt'),
            for (final o in target.supplementOptions)
              Text('${o.id}: ${_text(context, o.text)}'),
            TextField(
              key: const Key('yang16-supplement-answer'),
              controller: _supplement,
              enabled: _admitted,
              minLines: 2,
              maxLines: null,
              onChanged: (_) {
                if (!_admitted) return;
                setState(() {
                  _supplementKey = false;
                });
              },
            ),
            TextButton(
              key: const Key('yang16-compare-supplement'),
              onPressed: _admitted && _supplement.text.trim().isNotEmpty
                  ? () {
                      if (!_admitted || _supplement.text.trim().isEmpty) return;
                      setState(() {
                        _supplementKey = true;
                      });
                    }
                  : null,
              child: Text(
                _label(
                  context,
                  'Compare optional answer',
                  'İsteğe bağlı yanıtı karşılaştır',
                ),
              ),
            ),
            if (_supplementKey)
              _copy(context, target.supplementAnswer, 'yang16-supplement-key'),
            if (_supplementKey && target.supplementExplanation != null)
              _copy(
                context,
                target.supplementExplanation!,
                'yang16-supplement-explanation',
              ),
          ],
          Text(
            _label(
              context,
              'Answers, corrections and self-reports are unsaved and clear on stop, interruption, owner change or leaving this visit. They do not verify movement.',
              'Yanıtlar, düzeltmeler ve öz beyanlar kaydedilmez; durma, kesinti, sahip değişimi veya ziyaretten çıkışta temizlenir. Hareketi doğrulamaz.',
            ),
          ),
        ],
      ),
    );
  }
}

class Yang16WrittenCoursePage extends StatefulWidget {
  const Yang16WrittenCoursePage({
    super.key,
    required this.loader,
    this.accountUserId,
    this.resourceAdmission,
    this.preparationLoader,
  });
  final Future<Yang16WrittenCourse> Function() loader;
  final Future<Yang16PreparationCourse> Function()? preparationLoader;
  final ValueListenable<String?>? accountUserId;
  final ValueListenable<bool>? resourceAdmission;
  @override
  State<Yang16WrittenCoursePage> createState() =>
      _Yang16WrittenCoursePageState();
}

class _Yang16WrittenCoursePageState extends State<Yang16WrittenCoursePage>
    with WidgetsBindingObserver {
  final _written = <String>{};
  Yang16WrittenCourse? _course;
  final _preparation = ValueNotifier<Yang16PreparationCourse?>(null);
  bool _failed = false, _integrityFailure = false, _retired = false;
  bool _foreground = _resumed();
  int _generation = 0;
  Route<void>? _overview, _target;
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
  void didUpdateWidget(covariant Yang16WrittenCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId ||
        oldWidget.resourceAdmission != widget.resourceAdmission ||
        oldWidget.loader != widget.loader ||
        oldWidget.preparationLoader != widget.preparationLoader) {
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
      if (!_retired && _preparation.value == null) {
        unawaited(_loadPreparation(_generation));
      }
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
    _preparation.value = null;
    if (mounted) {
      setState(() {
        _course = null;
        _written.clear();
      });
    }
    final navigator = _navigator;
    final overview = _overview;
    final target = _target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator == null || !navigator.mounted) return;
      if (target != null && target.isActive) navigator.removeRoute(target);
      if (overview != null && overview.isActive) {
        navigator.removeRoute(overview);
      }
    });
  }

  Future<void> _load() async {
    if (!_admitted) return;
    final generation = ++_generation;
    _preparation.value = null;
    unawaited(_loadPreparation(generation));
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

  Future<void> _loadPreparation(int generation) async {
    final loader = widget.preparationLoader;
    if (loader == null || !_admitted) return;
    try {
      final value = await loader();
      if (!_admitted || generation != _generation) return;
      _preparation.value = value;
    } catch (_) {
      if (!_admitted || generation != _generation) return;
      _preparation.value =
          null; // Keep written study readable; no unreviewed fallback.
    }
  }

  Future<void> _open(Yang16Target target) async {
    final course = _course;
    if (!_admitted ||
        course == null ||
        _target != null ||
        _overview?.isCurrent != true) {
      return;
    }
    late final MaterialPageRoute<void> route;
    bool current() => _admitted && identical(_target, route) && route.isCurrent;
    bool prior() =>
        target.index == 0 ||
        _written.contains(course.targets[target.index - 1].id);
    route = MaterialPageRoute<void>(
      builder: (_) => !current()
          ? const SizedBox.shrink()
          : ValueListenableBuilder<Yang16PreparationCourse?>(
              valueListenable: _preparation,
              builder: (_, preparation, __) => Yang16WrittenTargetPage(
                key: ValueKey(target.id),
                practice: preparation?.forTarget(target.id),
                course: course,
                target: target,
                admitted: current,
                priorWritten: prior,
                onWritten: () {
                  if (current() && prior()) {
                    setState(() {
                      _written.add(target.id);
                    });
                  }
                },
                onInvalidate: () {
                  if (!current()) return;
                  setState(() {
                    for (final later in course.targets.where(
                      (t) => t.index >= target.index,
                    )) {
                      _written.remove(later.id);
                    }
                  });
                },
                onReset: () {
                  if (!_retired && mounted) setState(_written.clear);
                },
              ),
            ),
    );
    _target = route;
    await _navigator!.push(route);
    if (identical(_target, route)) _target = null;
  }

  @override
  void dispose() {
    _retired = true;
    _generation++;
    _written.clear();
    _preparation.dispose();
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
        toolbarHeight: 48 + 40 * MediaQuery.textScalerOf(context).scale(1),
        title: Text(
          _label(context, 'Yang16 written order', 'Yang16 yazılı sıra'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
                        ? 'Reviewed written content could not be verified.'
                        : 'Written course could not load.',
                    _integrityFailure
                        ? 'İncelenmiş yazılı içerik doğrulanamadı.'
                        : 'Yazılı kurs yüklenemedi.',
                  ),
                  key: const Key('yang16-load-failure'),
                ),
                if (!_integrityFailure)
                  TextButton(
                    key: const Key('yang16-retry'),
                    onPressed: _admitted ? _load : null,
                    child: Text(_label(context, 'Retry', 'Yeniden dene')),
                  ),
              ],
            )
          : course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('yang16-course-list'),
              padding: const EdgeInsets.all(20),
              children: [
                _copy(context, course.title, 'yang16-course-title'),
                Text(
                  _label(
                    context,
                    'Angela Plarre presentation · written form order only · 18 sections and 6 final targets',
                    'Angela Plarre sunumu · yalnız yazılı form sırası · 18 bölüm ve 6 son hedef',
                  ),
                  key: const Key('yang16-course-scope'),
                ),
                Text(
                  _label(
                    context,
                    '{value1}/24 full written targets self-reported this visit; optional attempts do not change this count.',
                    'Bu ziyarette {value1}/24 tam yazılı hedef öz beyanı; isteğe bağlı denemeler bu sayıyı değiştirmez.',
                    args: {'value1': _written.length},
                  ),
                  key: const Key('yang16-written-progress'),
                ),
                if (_written.length == 24)
                  Text(
                    _label(
                      context,
                      'Whole-order written reconstruction self-reported. This does not establish physical completion or mastery.',
                      'Tam-sıra yazılı yeniden kurma öz beyanı alındı. Fiziksel tamamlanma veya ustalık doğrulanmaz.',
                    ),
                    key: const Key('yang16-written-completion'),
                  ),
                for (var i = 0; i < course.reading.length; i++)
                  _copy(
                    context,
                    course.reading[i],
                    'yang16-overview-reading-$i',
                  ),
                for (final target in course.targets)
                  ListTile(
                    key: Key('yang16-target-${target.id}'),
                    title: Text(_text(context, target.title)),
                    subtitle: Text(
                      _label(
                        context,
                        _written.contains(target.id)
                            ? 'Full written target self-reported'
                            : 'Read, reconstruct, correct and retest the same target',
                        _written.contains(target.id)
                            ? 'Tam yazılı hedef öz beyanı alındı'
                            : 'Oku, yeniden kur, düzelt ve aynı hedefi tekrar yanıtla',
                      ),
                    ),
                    onTap: _admitted ? () => _open(target) : null,
                  ),
                TextButton(
                  key: const Key('yang16-clear-visit'),
                  onPressed: _admitted
                      ? () {
                          if (_admitted) setState(_written.clear);
                        }
                      : null,
                  child: Text(
                    _label(
                      context,
                      'Stop and clear this visit',
                      'Dur ve bu ziyareti temizle',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
