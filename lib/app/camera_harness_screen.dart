import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart' show BodyOrientation;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pose_model.dart';

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
  const CameraHarnessScreen({super.key, this.controller});

  /// Testte enjekte edilir; üretimde gerçek plugin kanalı kullanılır.
  final MotionCameraController? controller;

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
  int _envelopes = 0;
  int _emptyPasses = 0;
  DateTime? _startedAt;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    if (_session != null) unawaited(_camera.stop().catchError((_) {}));
    super.dispose();
  }

  /// Modeli asset'ten diske çıkarır — MediaPipe bir DOSYA YOLU istiyor,
  /// asset bundle'ı okuyamıyor. SHA doğrulaması `tool/fetch_pose_model.sh`
  /// ve `model_pin_test`te; burada tekrar hash'lemek çıkarma maliyetini
  /// her açılışta ikiye katlardı.
  Future<String> _materializeModel() async {
    final Directory dir = await getApplicationSupportDirectory();
    final File out = File('${dir.path}/${PoseModelPin.assetPath.split('/').last}');
    if (!out.existsSync()) {
      final data = await rootBundle.load(PoseModelPin.assetPath);
      await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return out.path;
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      // İZNİ APP İSTER, PLUGIN İSTEMEZ (sözleşme §1 katman sınırı): plugin
      // `camera-permission-denied` diye isimli bir retle döner ve UX'i
      // buraya bırakır. Bu adım YOKKEN emülatör smoke'u tam bu retle
      // düştü — yani boşluk gerçekti ve cihaz gününde de aynı yerde
      // patlayacaktı.
      final PermissionStatus perm = await Permission.camera.request();
      if (!perm.isGranted) {
        setState(() {
          _error = 'camera permission not granted ($perm) — the bridge '
              'refuses by design; grant it in system settings and retry';
          _starting = false;
        });
        return;
      }
      final String path = await _materializeModel();
      final CameraSessionInfo info = await _camera.start(
        modelPath: path,
        // §6: kimlik REFERANSLARI ÜRETEN modelin kimliği; zarfa damgalanır.
        modelId: PoseModelPin.modelId,
        lens: CameraLens.front,
        initialPlan: PassPlan.uprightOnly,
      );
      _sub = _camera.frames().listen(
        (CameraFrameEnvelope e) {
          _monitor.record(e);
          if (!mounted) return;
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
          if (mounted) setState(() => _error = err);
        },
      );
      if (!mounted) return;
      setState(() {
        _session = info;
        _startedAt = DateTime.now();
        _starting = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _starting = false;
      });
    }
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _camera.stop();
    } on Object catch (_) {
      // stop hatası ölçümü geçersiz kılmaz; ekran ölçümü korur.
    }
    if (mounted) setState(() => _session = null);
  }

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
                onPressed: running || _starting ? null : _start,
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
                child: Text('$_error',
                    key: const Key('harness-error'),
                    style: theme.textTheme.bodyMedium),
              ),
            ),
          _MetricRows(rows: <String, String>{
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
          }),
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
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
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
    final TextStyle? mono = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(fontFamily: 'monospace');
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
