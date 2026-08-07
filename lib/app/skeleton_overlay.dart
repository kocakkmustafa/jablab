import 'package:flutter/material.dart';
import 'package:motion_core/motion_core.dart' show Lm, PoseLandmark;

import '../shell_candidate/live_surface.dart' show LiveState;
import 'design_tokens.dart';
import 'live_honesty.dart';

/// Canlı seansın önizleme yuvası — `LiveCoachSurface.preview`e verilir.
///
/// İki KATMAN, iki AYRI dürüstlük beyanı taşıyor ve karıştırılmamalı:
///
/// 1. **Kamera GÖRÜNTÜSÜ** — bilinçli ertelendi, bkz. tek satırlık işaretçi:
///    PLACEHOLDER(asset): kamera akışının gerçek görüntüsü (Texture tabanlı önizleme) — unblocked by: Texture-based preview (registrar.textures), deliberately deferred, docs/70-KAMERA-KOPRUSU-SOZLESMESI.md
///    Bu katman İCAT EDİLMEDİ; ekran bunu SAKLAMIYOR — koyu bir dolgu +
///    açık bir cümle, sahte bir "analiz ediliyor" animasyonu DEĞİL.
///
///    **SINIRIN SINIFI: ERTELENMİŞ** (M-F-287 · imkânsız / ertelenmiş /
///    ölçülmemiş üçlüsü). Gravita aynı çekirdek kısıtını aynı sınıfa
///    koydu — aynı `motion_camera` pini, aynı `registrar.textures` yolu,
///    aynı karar; iki hattın farklı sınıflandırması, tek bir kısıtın iki
///    farklı şeymiş gibi okunmasına yol açardı.
///
///    Sınıf ayrımı boş bir titizlik değil, kullanıcı cümlesini belirliyor:
///    *imkânsız* olsaydı "bir kamera bunu göremez" derdik (kapsam-dışı
///    listesinin dili); *ölçülmemiş* olsaydı "bilmiyoruz" derdik.
///    **Ertelenmiş** = yapılabilir, biz yapmadık — o yüzden yüzeydeki
///    cümle sorumluluğu ÜSTLENİYOR ("left out on purpose") ve bir tarih
///    VERMİYOR. "not built yet" ikisini birden kaçırıyordu: hem sorumluluk
///    almıyor hem bir zaman taahhüdü veriyordu (M-F-186, Ostinato hükmü
///    2026-08-07: *"gerekçenin varlığı 'yet'i affetmiyor"*).
/// 2. **İskelet çizimi** — PLACEHOLDER DEĞİL. Motorun zaten ürettiği gerçek
///    [PoseLandmark] koordinatlarından çiziliyor (bkz.
///    `LiveJabController._onEnvelope`, `LiveJabRunning.skeleton`). Kamera
///    görüntüsü yokken bile "ne gördüğümü çiziyorum" doğru bir cümle —
///    motor kişiyi görüyor, yalnız o görüntüyü EKRANA basmıyoruz.
class SkeletonPreview extends StatelessWidget {
  const SkeletonPreview({
    super.key,
    required this.state,
    this.skeleton,
    this.bucket = LiveHonestyBucket.none,
  });

  /// SORUMLULUK KOVASI (J-110). Donmuş `LiveCoachSurface`in ikonu sabit
  /// (`visibility_off_outlined`) ve değiştirilemiyor; ikon ekseni bu yüzden
  /// BURADAN taşınıyor — bu yuva app'in kendi mülkü.
  final LiveHonestyBucket bucket;

  final LiveState state;

  /// `null` yalnız kimse hiç bulunamadığında (bkz. alan dokümanı
  /// `LiveJabRunning.skeleton`) — o zaman yalnız yer tutucu görünür.
  final List<PoseLandmark>? skeleton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _CameraPlaceholder(bucket: bucket),
        if (skeleton != null)
          CustomPaint(
            key: const Key('skeleton-overlay'),
            painter: _SkeletonPainter(skeleton!, state),
          ),
      ],
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.bucket});

  final LiveHonestyBucket bucket;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              JColors.deep.withValues(alpha: .55),
              JColors.ground,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(bucket.icon, size: 28, color: bucket.accent),
              const SizedBox(height: 8),
              Text(
                'Camera preview is left out on purpose — analysis runs '
                'without it',
                key: const Key('camera-preview-placeholder'),
                textAlign: TextAlign.center,
                // ⚠️ `ink4` idi ve ÖLÇÜLDÜ: 1,80:1 — WCAG AA normal metin
                // eşiğinin (4,5) çok altında. Bu altyazı kameranın NEDEN
                // görünmediğini açıklıyor, yani en çok iskelet çizilirken
                // gerekiyor; okunamaz olması onu hiç yazmamakla aynı şey.
                style: JText.mono.copyWith(fontSize: 11, color: JColors.ink2),
              ),
            ],
          ),
        ),
      );
}

/// Boks için ilgili 13 nokta + kemik bağlantıları — 33 MediaPipe noktasının
/// TAMAMI değil (yüz-örgüsü/parmak detayı bu ekranın amacına hizmet etmez,
/// `LmRegion.fullBody`nin kendisi zaten motorun ÖLÇTÜĞÜ kümeyle birebir).
const List<(int, int)> _bones = <(int, int)>[
  (Lm.leftShoulder, Lm.rightShoulder),
  (Lm.leftShoulder, Lm.leftElbow),
  (Lm.leftElbow, Lm.leftWrist),
  (Lm.rightShoulder, Lm.rightElbow),
  (Lm.rightElbow, Lm.rightWrist),
  (Lm.leftHip, Lm.rightHip),
  (Lm.leftShoulder, Lm.leftHip),
  (Lm.rightShoulder, Lm.rightHip),
  (Lm.leftHip, Lm.leftKnee),
  (Lm.leftKnee, Lm.leftAnkle),
  (Lm.rightHip, Lm.rightKnee),
  (Lm.rightKnee, Lm.rightAnkle),
];

/// Kafa için tek nokta — omuz orta noktasına bağlanır (ayrı bir kemik listesi
/// gerektirmeyecek kadar basit, [_SkeletonPainter] içinde ele alınıyor).
const int _headPoint = Lm.nose;

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.landmarks, this.state);

  final List<PoseLandmark> landmarks;
  final LiveState state;

  Offset _xy(int i, Size size) =>
      Offset(landmarks[i].x * size.width, landmarks[i].y * size.height);

  /// Güven DÜŞÜKKEN nokta TAMAMEN kaybolmaz, SOLUKLAŞIR — "görmüyorum" ile
  /// "zayıf görüyorum" farklı beyanlar (doc-75/5 ruhu çizime taşınıyor).
  double _alpha(int i) => 0.15 + 0.85 * landmarks[i].visibility.clamp(0, 1);

  @override
  void paint(Canvas canvas, Size size) {
    // Genel opaklık: hüküm SUSARKEN iskelet de biraz siliklaşır — motorun
    // "seni görüyorum ama okuyamıyorum" hâliyle "temiz okuyorum" hâli
    // görsel olarak ayrışsın. Renk AYRI kalıyor (her zaman cool/gözlem
    // tonlu) — kemik çizimi bir HÜKÜM taşımıyor, `cue` metni taşıyor.
    final double sceneAlpha = state == LiveState.noVerdict ? .45 : .85;

    final Paint bone = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final (int a, int b) in _bones) {
      final double a2 = ((_alpha(a) + _alpha(b)) / 2) * sceneAlpha;
      canvas.drawLine(
        _xy(a, size),
        _xy(b, size),
        bone..color = JColors.cool.withValues(alpha: a2 * .55),
      );
    }

    final Paint joint = Paint()..style = PaintingStyle.fill;
    for (final int i in const <int>[
      Lm.leftShoulder,
      Lm.rightShoulder,
      Lm.leftElbow,
      Lm.rightElbow,
      Lm.leftWrist,
      Lm.rightWrist,
      Lm.leftHip,
      Lm.rightHip,
      Lm.leftKnee,
      Lm.rightKnee,
      Lm.leftAnkle,
      Lm.rightAnkle,
    ]) {
      canvas.drawCircle(
        _xy(i, size),
        3.2,
        joint..color = JColors.cool.withValues(alpha: _alpha(i) * sceneAlpha),
      );
    }

    // Kafa: omuz orta noktasına tek çizgi + baş için biraz büyük nokta —
    // ayrı bir "yüz" çizimi yok, yalnız gövdenin nereye baktığını okunur
    // kılan bir referans.
    final Offset shoulderMid = Offset.lerp(
        _xy(Lm.leftShoulder, size), _xy(Lm.rightShoulder, size), .5)!;
    final double headAlpha = _alpha(_headPoint) * sceneAlpha;
    canvas.drawLine(shoulderMid, _xy(_headPoint, size),
        bone..color = JColors.cool.withValues(alpha: headAlpha * .55));
    canvas.drawCircle(_xy(_headPoint, size), 6, joint..color = JColors.cool.withValues(alpha: headAlpha));
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) =>
      oldDelegate.landmarks != landmarks || oldDelegate.state != state;
}
