import 'package:flutter/material.dart';
import 'package:motion_core/motion_core.dart' show Lm, PoseLandmark;

import '../shell_candidate/live_surface.dart' show LiveState;
import 'design_tokens.dart';
import 'live_honesty.dart';
import 'ui_language.dart';

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
    required this.analysisRunning,
    this.skeleton,
    this.bucket = LiveHonestyBucket.none,
    this.canvasAppearance,
  });

  /// Analiz GERÇEKTEN koşuyor mu (J-250).
  ///
  /// ## Neden var: yer tutucunun cümlesi KOŞULSUZDU, doğruluğu KOŞULLU
  ///
  /// Altyazı sabitti: *"Camera preview is left out on purpose — **analysis
  /// runs without it**"*. Bu cümle yalnız `LiveJabRunning` dalında doğru.
  /// Diğer ÜÇ dalda ekran onu yine basıyordu ve **yanlıştı**:
  ///  * kamera arızası (izin reddi / açılamama / kurulum hatası),
  ///  * kamerasız ders (`liveJab == null`) — analiz hiç yok,
  ///  * *"Getting the camera ready…"* — analiz henüz başlamadı.
  ///
  /// Simülatörde yürünürken **aynı ekranda** şu ikisi yan yana ölçüldü:
  /// *"analysis runs without it"* ve *"Nothing is analysed without it"*.
  /// İkisi de tek başına savunulabilir (*"it"* birinde ÖNİZLEME, diğerinde
  /// KAMERA), ama kullanıcı ikisini birlikte okur — J-094'ün sınıfı:
  /// *gövde "materyal yok" derken sekme "Watch" diyordu.*
  ///
  /// **`required` ve varsayılansız BİLEREK:** varsayılan `true` eski yalanı
  /// sessizce sürdürürdü, varsayılan `false` yeni çağrı yerlerinde doğru
  /// cümleyi sessizce düşürürdü. Zorunlu alan, her çağıranı **hangi hâlde
  /// olduğunu SÖYLEMEYE** mecbur eder — derleyici dört yeri de yakaladı.
  final bool analysisRunning;

  /// SORUMLULUK KOVASI (J-110). Donmuş `LiveCoachSurface`in ikonu sabit
  /// (`visibility_off_outlined`) ve değiştirilemiyor; ikon ekseni bu yüzden
  /// BURADAN taşınıyor — bu yuva app'in kendi mülkü.
  final LiveHonestyBucket bucket;

  /// Explicit paired image-canvas role. Null keeps a dark image canvas in
  /// both app themes; no mutable global theme or anatomical mirroring.
  final JCameraCanvasAppearance? canvasAppearance;

  final LiveState state;

  /// `null` yalnız kimse hiç bulunamadığında (bkz. alan dokümanı
  /// `LiveJabRunning.skeleton`) — o zaman yalnız yer tutucu görünür.
  final List<PoseLandmark>? skeleton;

  @override
  Widget build(BuildContext context) {
    final appearance = canvasAppearance ?? JCameraCanvasAppearance.dark;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _CameraPlaceholder(appearance: appearance),
        if (skeleton != null)
          CustomPaint(
            key: const Key('skeleton-overlay'),
            painter: _SkeletonPainter(skeleton!, state, observationColor: appearance.observation),
          ),
        // Foreground caption/scrim is painted after the skeleton.
        _CameraCaption(appearance: appearance, bucket: bucket, analysisRunning: analysisRunning),
      ],
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.appearance});
  final JCameraCanvasAppearance appearance;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[appearance.gradientTop, appearance.background],
      ),
    ),
    child: const SizedBox.expand(),
  );
}

class _CameraCaption extends StatelessWidget {
  const _CameraCaption({required this.appearance, required this.bucket, required this.analysisRunning});
  final JCameraCanvasAppearance appearance;
  final LiveHonestyBucket bucket;
  final bool analysisRunning;
  @override
  Widget build(BuildContext context) => Center(
      // Foreground scrim retains alpha .81 as a draft design input.
      // Historic ratios do not replace a new skeleton-overlap render check.
      child: DecoratedBox(
        key: const Key('camera-caption-scrim'),
        decoration: BoxDecoration(
          color: appearance.captionScrim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(bucket.icon, size: 28, color: switch (bucket) {
                LiveHonestyBucket.yours => appearance.observation,
                LiveHonestyBucket.ours => appearance.neutralIcon,
                LiveHonestyBucket.none => appearance.noAnalysisIcon,
              }),
              const SizedBox(height: 8),
              Text(
                // İKİNCİ YARI KOŞULLU (J-250). Analiz koşmuyorken *"analysis
                // runs without it"* basmak, ekranın hemen altındaki arıza
                // cümlesiyle ÇELİŞİR ve yanlıştır. Sorumluluğu üstlenen ilk
                // yarı ("left out on purpose") her hâlde doğru ve KALIYOR —
                // önizlemenin yokluğu bir tercih, bir arıza değil.
                //
                // Analiz koşmuyorken SEBEP burada tekrarlanmıyor: onu
                // `LiveCoachSurface.noVerdictReason` zaten söylüyor ve iki
                // yüzeyin aynı sebebi iki farklı cümleyle anlatması
                // J-047'nin elle-kopyalanmış listesi sınıfına girerdi.
                UiLanguage.text(
                  context,
                  en: (analysisRunning
                      ? 'Camera preview is left out on purpose — analysis runs '
                            'without it'
                      : 'Camera preview is left out on purpose'),
                  tr: (analysisRunning
                      ? 'Kamera önizlemesi bilerek gösterilmiyor; analiz onsuz çalışıyor.'
                      : 'Kamera önizlemesi bilerek gösterilmiyor.'),
                ),
                key: const Key('camera-preview-placeholder'),
                textAlign: TextAlign.center,
                // ⚠️ `ink4` idi ve ÖLÇÜLDÜ: 1,80:1 — WCAG AA normal metin
                // eşiğinin (4,5) çok altında. Bu altyazı kameranın NEDEN
                // görünmediğini açıklıyor, yani en çok iskelet çizilirken
                // gerekiyor; okunamaz olması onu hiç yazmamakla aynı şey.
                style: appearance.captionStyle,
              ),
            ],
          ),
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
  _SkeletonPainter(this.landmarks, this.state, {required this.observationColor});

  final List<PoseLandmark> landmarks;
  final LiveState state;
  final Color observationColor;

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
        bone..color = observationColor.withValues(alpha: a2 * .55),
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
        joint..color = observationColor.withValues(alpha: _alpha(i) * sceneAlpha),
      );
    }

    // Kafa: omuz orta noktasına tek çizgi + baş için biraz büyük nokta —
    // ayrı bir "yüz" çizimi yok, yalnız gövdenin nereye baktığını okunur
    // kılan bir referans.
    final Offset shoulderMid = Offset.lerp(
      _xy(Lm.leftShoulder, size),
      _xy(Lm.rightShoulder, size),
      .5,
    )!;
    final double headAlpha = _alpha(_headPoint) * sceneAlpha;
    canvas.drawLine(
      shoulderMid,
      _xy(_headPoint, size),
      bone..color = observationColor.withValues(alpha: headAlpha * .55),
    );
    canvas.drawCircle(
      _xy(_headPoint, size),
      6,
      joint..color = observationColor.withValues(alpha: headAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) =>
      oldDelegate.landmarks != landmarks || oldDelegate.state != state ||
      oldDelegate.observationColor != observationColor;
}
