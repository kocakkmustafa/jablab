import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart' show BodyOrientation;
import 'package:permission_handler/permission_handler.dart';

import 'pose_model.dart';
import 'content_repository.dart';
import 'camera_capture_coordinator.dart';

/// KAMERA KÖPRÜSÜ **DEV HARNESS** — kullanıcı ekranı DEĞİL (J-072).
///
/// Sözleşme §7.8 "ön-izleme yüzeyi bağlanmadan app'e UI entegrasyonu
/// başlamaz" der ve bu **KULLANICI-UI'ını** bloklar: kullanıcı kendini
/// göremeden hiçbir app "kamera çalışıyor" DEMEZ. Bu ekran o iddiayı
/// kurmuyor — tam tersini yapıyor: köprünün ÖLÇÜMLERİNİ ham hâlde gösteriyor
/// ki canlılık listesi (§7.3-7.6) sayılarla kapanabilsin.
///
/// Bu yüzden burada bilinçli olarak YOK:
///  * ön-izleme dokusu (kullanıcı kendini görmüyor — §7.8 açık kalemi),
///  * hiçbir teknik HÜKÜM (gard/duruş/tempo) — köprü kanıtı ile koçluk
///    iddiası aynı ekranda durursa ikincisi birincisinden meşruiyet çalar,
///  * cila. Sayılar okunabilir olsun diye monospace ve iri.
///
/// Ekranın kendisi `kDebugMode` dışında AÇILMAZ (aşağıdaki [isAvailable]) —
/// yayına giden bir derlemede bir dev-harness'ın erişilebilir kalması,
/// "kamera var" izlenimini kullanıcıya sızdırmanın en kolay yolu olurdu.
class CameraHarnessScreen extends StatefulWidget {
  const CameraHarnessScreen({
    super.key,
    this.controller,
    this.requestPermission,
    this.modelPath,
  });

  /// Testte enjekte edilir; üretimde gerçek plugin kanalı kullanılır.
  final MotionCameraController? controller;
  final Future<PermissionStatus> Function()? requestPermission;
  final Future<String> Function()? modelPath;

  /// Yalnız debug derlemede. Release'de ekran YOK.
  static bool get isAvailable => kDebugMode;

  @override
  State<CameraHarnessScreen> createState() => _CameraHarnessScreenState();
}

class _CameraHarnessScreenState extends State<CameraHarnessScreen> {
  late final MotionCameraController _camera =
      widget.controller ?? MotionCameraController();
  final ThroughputMonitor _monitor = ThroughputMonitor();

  StreamSubscription<CameraFrameEnvelope>? _sub;
  CameraSessionInfo? _session;
  CameraFrameEnvelope? _last;
  Object? _error;
  bool _starting = false;
  int _generation = 0;
  CameraCaptureLease? _capture;
  int _envelopes = 0;
  int _emptyPasses = 0;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _error = CameraCaptureCoordinator.failure;
    CameraCaptureCoordinator.uncertainty.addListener(_onUncertainty);
  }

  void _onUncertainty() {
    if (mounted) setState(() => _error = CameraCaptureCoordinator.failure);
  }

  @override
  void dispose() {
    _generation++;
    CameraCaptureCoordinator.uncertainty.removeListener(_onUncertainty);
    final capture = _capture;
    _capture = null;
    final closing = capture == null
        ? Future<void>.value()
        : CameraCaptureCoordinator.close(capture);
    final subscription = _sub;
    _sub = null;
    unawaited(
      _closeCapture(closing, subscription).catchError((Object error) {
        CameraCaptureCoordinator.recordUncertainty(error);
      }),
    );
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || _session != null || CameraCaptureCoordinator.isBlocked) {
      return;
    }
    final int generation = ++_generation;
    final capture = _camera.createCaptureLease();
    _capture = capture;
    var started = false;
    bool current() => mounted && generation == _generation;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await CameraCaptureCoordinator.waitForClosure();
      if (!current() || capture.isRetired) return;
      // İZNİ APP İSTER, PLUGIN İSTEMEZ (sözleşme §1 katman sınırı): plugin
      // `camera-permission-denied` diye isimli bir retle döner ve UX'i
      // buraya bırakır. Bu adım YOKKEN emülatör smoke'u tam bu retle
      // düştü — yani boşluk gerçekti ve cihaz gününde de aynı yerde
      // patlayacaktı.
      final PermissionStatus perm =
          await (widget.requestPermission?.call() ??
              Permission.camera.request());
      if (!current()) return;
      if (!perm.isGranted) {
        setState(() {
          _error =
              'camera permission not granted ($perm) — the bridge '
              'refuses by design; grant it in system settings and retry';
          _starting = false;
        });
        return;
      }
      final String path =
          await (widget.modelPath?.call() ??
              const ContentRepository().materializePoseModel());
      if (!current()) return;
      final CameraSessionInfo info = await capture.start(
        modelPath: path,
        // §6: kimlik REFERANSLARI ÜRETEN modelin kimliği; zarfa damgalanır.
        modelId: PoseModelPin.modelId,
        lens: CameraLens.front,
        initialPlan: PassPlan.uprightOnly,
      );
      if (!current()) return;
      _sub = capture.frames().listen(
        (CameraFrameEnvelope e) {
          if (!current()) return;
          _monitor.record(e);
          setState(() {
            _last = e;
            _envelopes += 1;
            // Model kimseyi görmediyse geçiş NULL döner. Bu bir HATA DEĞİL,
            // "hüküm yok" — ayrı sayılıyor ki "akış var ama kimse yok"
            // durumu "akış yok" ile karışmasın.
            if (e.pass(BodyOrientation.upright) == null) _emptyPasses += 1;
          });
        },
        onError: (Object err) {
          if (!current()) return;
          setState(() => _error = err);
          unawaited(_stop());
        },
      );
      if (!current()) return;
      setState(() {
        _session = info;
        _startedAt = DateTime.now();
        _starting = false;
      });
      started = true;
    } on Object catch (e) {
      if (!current()) return;
      setState(() {
        _error = e;
        _starting = false;
      });
    } finally {
      if (!started) {
        if (identical(_capture, capture)) _capture = null;
        try {
          await CameraCaptureCoordinator.close(capture);
        } catch (error) {
          final failure = CameraCaptureCoordinator.recordUncertainty(error);
          if (current()) setState(() => _error = failure);
        }
        if (current()) setState(() => _starting = false);
      }
    }
  }

  Future<void> _stop() async {
    _generation++;
    final capture = _capture;
    _capture = null;
    final closing = capture == null
        ? Future<void>.value()
        : CameraCaptureCoordinator.close(capture);
    final subscription = _sub;
    _sub = null;
    try {
      await _closeCapture(closing, subscription);
    } catch (error) {
      final failure = CameraCaptureCoordinator.recordUncertainty(error);
      if (mounted) setState(() => _error = failure);
    }
    if (mounted) {
      setState(() {
        _session = null;
        _starting = false;
      });
    }
  }

  Future<void> _closeCapture(
    Future<void> closing,
    StreamSubscription<CameraFrameEnvelope>? subscription,
  ) => Future.wait<void>([
    closing,
    if (subscription != null) subscription.cancel(),
  ]);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool running = _session != null;
    final Duration elapsed = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);

    return Scaffold(
      appBar: AppBar(title: const Text('Camera bridge — DEV HARNESS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Developer harness, not a feature. There is no preview here on '
                'purpose: until you can see yourself, this app does not claim '
                'the camera works. Nothing on this screen is a judgement about '
                'how you moved.',
                key: const Key('harness-disclaimer'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilledButton(
                key: const Key('harness-start'),
                onPressed:
                    running || _starting || CameraCaptureCoordinator.isBlocked
                    ? null
                    : _start,
                child: Text(_starting ? 'Starting…' : 'Start'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                key: const Key('harness-stop'),
                onPressed: running ? _stop : null,
                child: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '$_error',
                  key: const Key('harness-error'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          _MetricRows(
            rows: <String, String>{
              // §7.3 — zarf akışı ve süresi
              'session': running ? 'running' : 'stopped',
              'elapsed': '${elapsed.inSeconds} s',
              'envelopes': '$_envelopes',
              // §7.3 — ölçülen oranlar (uydurma yok: null ise "—")
              'judgedRatio': _fmt(_monitor.judgedRatio, digits: 3),
              'judged/s': _fmt(_monitor.judgedPerSecond, digits: 1),
              'captured/s': _fmt(_monitor.capturedPerSecond, digits: 1),
              'meanInferenceUs': _fmt(_monitor.meanInferenceUs, digits: 0),
              // §7.5 — buffer açlığı bu sayının patlaması olarak görünür
              'dropped (session)': '${_monitor.sessionDroppedCount}',
              'dropped (last)': _last == null ? '—' : '${_last!.dropped}',
              // §7.6 — clock domain; "unknown" AYRI bir gözlem
              'clockDomain': _session?.clockDomain.name ?? '—',
              'frame': _last == null
                  ? '—'
                  : '${_last!.size.width}×${_last!.size.height}',
              'modelVersion (envelope)': _last?.modelVersion ?? '—',
              'library': _session?.libraryTag ?? '—',
              'no-person passes': '$_emptyPasses',
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Declared model pin (§6 / M-L-01)\n'
                '  id   : ${PoseModelPin.modelId}\n'
                '  asset: ${PoseModelPin.assetPath}\n'
                '  sha256: ${PoseModelPin.sha256}\n\n'
                'The envelope carries this id. If "modelVersion (envelope)" '
                'ever differs from the id above, a model swap has silently '
                'changed what the joint tables mean — stop and re-measure.',
                key: const Key('harness-model-pin'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ölçülemeyen değer "—" olarak gösterilir, 0 olarak DEĞİL: sıfır bir
  /// ölçümdür, yokluk değil.
  static String _fmt(double? v, {required int digits}) =>
      v == null ? '—' : v.toStringAsFixed(digits);
}

class _MetricRows extends StatelessWidget {
  const _MetricRows({required this.rows});

  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final TextStyle? mono = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace');
    return Column(
      children: <Widget>[
        for (final MapEntry<String, String> e in rows.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            // Değer SARILABİLİR olmak zorunda: zarfın taşıdığı model kimliği
            // uzun bir dize ("mp-android-0.10.29+pose_landmarker_full/
            // float16/1") ve sabit bir Row'da 480 px genişlikte 348 px
            // taşırıyordu — emülatör smoke'unda ölçüldü. Kırpmak yerine
            // sarıyoruz: bu ekranın işi sayıyı TAM göstermek, ve kırpılmış
            // bir model kimliği tam olarak yanlış okunacak şeydir.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 4, child: Text(e.key, style: mono)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Text(
                    e.value,
                    key: Key('metric-${e.key}'),
                    textAlign: TextAlign.right,
                    softWrap: true,
                    style: mono?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
