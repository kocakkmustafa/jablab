import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jablab_engine/jablab_engine.dart';

import '../shell_candidate/library_pages.dart';
import '../shell_candidate/shell_models.dart';
import '../shell_candidate/shell_scaffold.dart';
import 'content_repository.dart';
import 'session_narrator.dart';
import 'session_store.dart';
import 'session_screen.dart';

/// JabLab uygulaması — kabuğu içerikle bağlar.
class JabLabApp extends StatelessWidget {
  const JabLabApp({super.key, this.repository = const ContentRepository()});

  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JabLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB3261E), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: _Root(repository: repository),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.repository});

  final ContentRepository repository;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  ShellLibrary? _library;
  CueBook? _cues;
  RuleSet? _boxing;

  /// Alan kütüphanesi de tutulur: kabuk modeli tur planını TAŞIMAZ (kabukta
  /// "round" alan sözlüğüdür, README sözleşmesi) — plan burada, app
  /// katmanında aranıp canlı ekrana verilir.
  Library? _domain;

  /// Seans geçmişi (J-064). Kurulumu async olduğu için `null` başlar; henüz
  /// gelmemişken seans açılırsa akış çalışır, yalnız o seans KAYDEDİLMEZ —
  /// açılışı bloklamak, kayıt için kullanıcıyı bekletmek olurdu.
  SessionStore? _store;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(widget.repository.openStore().then((SessionStore s) {
      if (mounted) setState(() => _store = s);
    }).catchError((Object e) {
      // Kalıcılık kurulamazsa uygulama ÇALIŞMAYA DEVAM EDER, yalnız kayıt
      // tutmaz. Depolama hatası yüzünden antrenmanı engellemek, çözümü
      // sorundan kötü yapardı.
      if (mounted) setState(() => _store = null);
    }));
    Future.wait<Object>(<Future<Object>>[
      widget.repository.load(),
      widget.repository.loadCues(),
    ]).then((List<Object> r) {
      if (!mounted) return;
      final ({dynamic library, dynamic boxing}) content =
          r[0] as ({dynamic library, dynamic boxing});
      setState(() {
        _domain = content.library as Library;
        _library = widget.repository.toShell(content.library);
        _boxing = content.boxing as RuleSet;
        _cues = r[1] as CueBook;
      });
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$_error', key: const Key('content-error')),
          ),
        ),
      );
    }
    final ShellLibrary? lib = _library;
    if (lib == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return ShellScaffold(
      home: _TodayPage(library: lib, onStart: (ShellLesson l) => _openSession(l)),
      library: LibraryPage(
        library: lib,
        onOpenItem: (ShellItem i) => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ItemPage(
              item: i,
              onOpenCourse: (ShellCourse c) => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CoursePage(course: c, onStart: _openSession),
                ),
              ),
            ),
          ),
        ),
        onOpenWhyNot: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => WhyNotPage(library: lib)),
        ),
      ),
      // K8 (M-F-04): kalibrasyon kapısı geçilmeden sayısal skor YOK.
      progress: const ProgressPage(
        bands: <String, String>{
          'Guard discipline': '—',
          'Punch mechanics': '—',
          'Balance': '—',
        },
      ),
      profile: const _ProfilePage(),
    );
  }

  void _openSession(ShellLesson l) => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
            builder: (_) => SessionScreen(
                  lesson: l,
                  cues: _cues!,
                  coachedNotScored:
                      widget.repository.coachedNotScoredLabels(_boxing!),
                  plan: widget.repository.roundPlanFor(_domain!, l.id),
                  store: _store,
                )),
      );
}

class _TodayPage extends StatelessWidget {
  const _TodayPage({required this.library, required this.onStart});

  final ShellLibrary library;
  final void Function(ShellLesson) onStart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Iterable<ShellItem> live =
        library.items.where((ShellItem i) => i.status == ItemStatus.live);
    final ShellCourse? first =
        live.isEmpty || live.first.courses.isEmpty ? null : live.first.courses.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Today',
            key: const Key('today-heading'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (first != null)
          Card(
            child: ListTile(
              key: const Key('continue-course'),
              title: Text(first.title),
              subtitle: Text(first.lessons.first.title),
              trailing: const Icon(Icons.play_arrow),
              // 2-tık kuralı: ana sayfa → derse tek dokunuş.
              onTap: () => onStart(first.lessons.first),
            ),
          ),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const PaywallStub(
            freeUntil:
                'The first assessment and the first course are free — you see '
                'what the coaching is actually like before anything is asked of you.',
          ),
        ],
      );
}
