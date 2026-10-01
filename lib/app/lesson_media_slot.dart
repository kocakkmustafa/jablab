import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:video_player/video_player.dart';

import 'design_tokens.dart';
import 'lesson_media_catalog.dart';
import 'solo_boxing_course.dart';
import 'ui_language.dart';

const Duration _nativeRetireDeadline = Duration(seconds: 2);
bool _nativePlaybackUnconfirmed = false;
Completer<void>? _nativeSlotOwner;

Future<bool> _takeNativeSlot() async {
  while (!_nativePlaybackUnconfirmed) {
    final owner = _nativeSlotOwner;
    if (owner == null) {
      _nativeSlotOwner = Completer<void>();
      return true;
    }
    await owner.future;
  }
  return false;
}

void _releaseNativeSlot() {
  final owner = _nativeSlotOwner;
  _nativeSlotOwner = null;
  owner?.complete();
}

/// Keeps the native controller behind an interface so lifecycle and mute
/// ordering can be tested without a native player in widget tests.
abstract interface class LessonPlaybackPort {
  ValueListenable<Duration> get position;
  double get aspectRatio;
  Widget buildVideo();
  Future<Duration?> initializeMuted();
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

typedef LessonPlaybackPortFactory = LessonPlaybackPort Function(String asset);

final class _AssetVideoPlaybackPort implements LessonPlaybackPort {
  _AssetVideoPlaybackPort(String asset)
    : _controller = VideoPlayerController.asset(
        asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

  final VideoPlayerController _controller;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  bool _disposed = false;

  @override
  ValueListenable<Duration> get position => _position;

  @override
  double get aspectRatio => _controller.value.aspectRatio > 0
      ? _controller.value.aspectRatio
      : 16 / 9;

  @override
  Widget buildVideo() => VideoPlayer(_controller);

  void _onTick() {
    if (!_disposed) _position.value = _controller.value.position;
  }

  @override
  Future<Duration?> initializeMuted() async {
    if (_disposed) return null;
    await _controller.initialize();
    if (_disposed) return null;
    // The controller is never played until this call has completed.
    await _controller.setVolume(0);
    if (_disposed) return null;
    _controller.addListener(_onTick);
    return _controller.value.duration;
  }

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_onTick);
    try {
      await _controller.dispose();
    } finally {
      _position.dispose();
    }
  }
}

/// A lesson demo is independent of the learner's self-report progress.
/// Production passes an empty catalogue, so it creates no native controller.
class LessonMediaSlot extends StatefulWidget {
  const LessonMediaSlot({
    required this.catalog,
    required this.bundle,
    required this.course,
    required this.lesson,
    required this.sceneId,
    required this.variantStem,
    required this.locale,
    this.accountUserId,
    this.portFactory,
    super.key,
  });

  LessonMediaSlot.empty({
    required this.course,
    required this.lesson,
    required this.locale,
    this.accountUserId,
    super.key,
  }) : catalog = const LessonMediaCatalog.empty(),
       bundle = rootBundle,
       sceneId = null,
       variantStem = null,
       portFactory = null;

  final LessonMediaCatalog catalog;
  final AssetBundle bundle;
  final SoloBoxingCourse course;
  final SoloLesson lesson;
  final String? sceneId, variantStem;
  final String locale;
  final ValueListenable<String?>? accountUserId;
  final LessonPlaybackPortFactory? portFactory;

  @override
  State<LessonMediaSlot> createState() => _LessonMediaSlotState();
}

class _LessonMediaSlotState extends State<LessonMediaSlot>
    with WidgetsBindingObserver {
  InspectedLessonMedia? _media;
  LessonPlaybackPort? _port;
  int _epoch = 0;
  bool _closed = false;
  bool _accountRevoked = false;
  bool _backgrounded = false;
  bool _starting = false;
  bool _pausing = false;
  bool _playing = false;
  bool _ready = false;
  Future<void> _retiring = Future<void>.value();
  Future<void> _nativeOperation = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.accountUserId?.addListener(_onAccount);
    unawaited(_inspect());
  }

  @override
  void didUpdateWidget(covariant LessonMediaSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId) {
      oldWidget.accountUserId?.removeListener(_onAccount);
      widget.accountUserId?.addListener(_onAccount);
      _accountRevoked = true;
      _close();
    }
    if (oldWidget.course != widget.course ||
        oldWidget.lesson != widget.lesson ||
        oldWidget.locale != widget.locale ||
        oldWidget.catalog != widget.catalog ||
        oldWidget.bundle != widget.bundle ||
        oldWidget.sceneId != widget.sceneId ||
        oldWidget.variantStem != widget.variantStem) {
      _close();
      if (!_accountRevoked && !_backgrounded && !_nativePlaybackUnconfirmed) {
        _closed = false;
        unawaited(_inspect());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _backgrounded = state != AppLifecycleState.resumed;
    if (_backgrounded) {
      _close();
    } else if (_closed && !_accountRevoked && !_nativePlaybackUnconfirmed) {
      _closed = false;
      unawaited(_inspect());
    }
  }

  void _onAccount() {
    _accountRevoked = true;
    _close();
  }

  Future<void> _inspect() async {
    if (_closed ||
        _backgrounded ||
        _accountRevoked ||
        _nativePlaybackUnconfirmed ||
        widget.catalog.isEmpty ||
        widget.sceneId == null ||
        widget.variantStem == null) {
      return;
    }
    final epoch = ++_epoch;
    await _retiring;
    if (!mounted ||
        _closed ||
        _backgrounded ||
        _accountRevoked ||
        _nativePlaybackUnconfirmed ||
        epoch != _epoch) {
      return;
    }
    final inspected = await widget.catalog.inspect(
      bundle: widget.bundle,
      course: widget.course,
      lesson: widget.lesson,
      sceneId: widget.sceneId!,
      variantStem: widget.variantStem!,
    );
    if (mounted &&
        !_closed &&
        !_nativePlaybackUnconfirmed &&
        epoch == _epoch &&
        inspected != null) {
      setState(() => _media = inspected);
    }
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _epoch++;
    final port = _port;
    _port = null;
    _media = null;
    _ready = false;
    _pausing = false;
    _playing = false;
    if (port != null) _queueRetire(port);
    if (mounted) setState(() {});
  }

  void _queueRetire(LessonPlaybackPort port) {
    final pending = _nativeOperation;
    _retiring = _retiring.then((_) async {
      var unconfirmed = false;
      try {
        try {
          await pending.timeout(_nativeRetireDeadline);
        } on Object {
          unconfirmed = true;
        }
        try {
          await port.pause().timeout(_nativeRetireDeadline);
        } on Object {
          unconfirmed = true;
        }
        try {
          await port.dispose().timeout(_nativeRetireDeadline);
        } on Object {
          unconfirmed = true;
        }
      } finally {
        if (unconfirmed) {
          // Timed-out native Futures keep running. No later session may claim
          // playback ownership in this process after uncertain retirement.
          _nativePlaybackUnconfirmed = true;
          if (mounted) {
            setState(() {
              _closed = true;
              _media = null;
              _epoch++;
            });
          }
        }
        _releaseNativeSlot();
      }
    });
    unawaited(_retiring);
  }

  Future<T> _runTrackedNative<T>(Future<T> Function() start) {
    // Reserve the wait marker before calling the port. A synchronous account
    // or lifecycle callback can retire this slot from inside that call.
    final settled = Completer<void>();
    _nativeOperation = Future.wait<void>([
      _nativeOperation,
      settled.future,
    ]).then<void>((_) {});
    try {
      final operation = start();
      operation.then<void>(
        (_) => settled.complete(),
        onError: (Object _, StackTrace __) => settled.complete(),
      );
      return operation;
    } catch (_) {
      settled.complete();
      rethrow;
    }
  }

  Future<void> _start() async {
    final media = _media;
    if (_closed ||
        _starting ||
        _pausing ||
        _nativePlaybackUnconfirmed ||
        media == null) {
      return;
    }
    final epoch = _epoch;
    _starting = true;
    LessonPlaybackPort? port = _port;
    var tookSlot = false;
    try {
      await _retiring;
      if (!mounted ||
          _closed ||
          _nativePlaybackUnconfirmed ||
          epoch != _epoch) {
        return;
      }
      if (port == null) {
        if (!await _takeNativeSlot()) return;
        tookSlot = true;
        if (!mounted ||
            _closed ||
            _nativePlaybackUnconfirmed ||
            epoch != _epoch) {
          _releaseNativeSlot();
          tookSlot = false;
          return;
        }
        port = (widget.portFactory ?? _AssetVideoPlaybackPort.new)(media.path);
        _port = port;
        tookSlot = false;
        if (!mounted ||
            _closed ||
            _nativePlaybackUnconfirmed ||
            epoch != _epoch) {
          _port = null;
          _queueRetire(port);
          return;
        }
        final initialization = _runTrackedNative(port.initializeMuted);
        final duration = await initialization;
        if (!mounted || _closed || epoch != _epoch) return;
        if (duration != media.duration) {
          _close();
          return;
        }
        setState(() => _ready = true);
      }
      if (_closed || epoch != _epoch) return;
      final playback = _runTrackedNative(port.play);
      await playback;
      if (mounted && !_closed && epoch == _epoch) {
        setState(() => _playing = true);
      }
    } catch (_) {
      if (tookSlot) _releaseNativeSlot();
      // A native playback failure never removes the written lesson.
      if (mounted && epoch == _epoch) _close();
    } finally {
      _starting = false;
    }
  }

  Future<void> _pause() async {
    final port = _port;
    if (port == null || _closed || _pausing || _nativePlaybackUnconfirmed) {
      return;
    }
    final epoch = _epoch;
    setState(() => _pausing = true);
    try {
      final pause = _runTrackedNative(port.pause);
      await pause;
    } catch (_) {
      if (mounted && !_closed && epoch == _epoch && identical(_port, port)) {
        _close();
      }
      return;
    }
    if (mounted && !_closed && epoch == _epoch && identical(_port, port)) {
      setState(() {
        _pausing = false;
        _playing = false;
      });
    }
  }

  @override
  void dispose() {
    widget.accountUserId?.removeListener(_onAccount);
    WidgetsBinding.instance.removeObserver(this);
    _epoch++;
    final port = _port;
    _port = null;
    if (port != null) _queueRetire(port);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = _media;
    if (media == null || _closed || _nativePlaybackUnconfirmed) {
      return const SizedBox.shrink();
    }
    final port = _port;
    final language = widget.locale == 'tr' ? 'tr' : 'en';
    return GlassPanel(
      tier: GlassTier.observation,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiLanguage.text(
                context,
                en: 'DEMONSTRATION · MUTED',
                tr: 'GÖSTERİM · SESSİZ',
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
                en: 'Watch the movement with captions. This does not grade your form or record practice.',
                tr: 'Hareketi altyazıyla izle. Bu gösterim formunu puanlamaz veya çalışma kaydı oluşturmaz.',
              ),
              style: JText.bodyMuted,
            ),
            if (_ready && port != null) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: port.aspectRatio,
                child: port.buildVideo(),
              ),
              ValueListenableBuilder<Duration>(
                valueListenable: port.position,
                builder: (context, position, _) {
                  final cues = media.captions[language]!;
                  final shown = cues.where(
                    (cue) => position >= cue.start && position < cue.end,
                  );
                  return Semantics(
                    liveRegion: true,
                    child: Text(
                      shown.isEmpty ? '' : shown.single.text,
                      key: const Key('solo-media-caption'),
                      style: JText.body,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('solo-media-play-pause'),
              onPressed: _starting || _pausing
                  ? null
                  : (_playing ? _pause : _start),
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              label: Text(
                UiLanguage.text(
                  context,
                  en: _playing ? 'Pause demonstration' : 'Play demonstration',
                  tr: _playing ? 'Gösterimi duraklat' : 'Gösterimi oynat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
