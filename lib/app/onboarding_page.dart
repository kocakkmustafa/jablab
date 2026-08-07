import 'package:flutter/material.dart';

import '../shell_candidate/shell_models.dart';
import 'design_tokens.dart';

/// KARŞILAMA — ürünün ilk cümlesi ve **dürüstlük ön-beyanı** (J-106).
///
/// ## Neden bu ekran ürünün en zor tasarım problemi
///
/// Bir fitness uygulaması normalde vaatle açılır. JabLab'ın ayırt ediciliği
/// tam tersinde: **ne yapmadığını baştan söylemek.** UI-BRIEF ton kuralı 1
/// bunu şart koşuyor ("ölçmediğini iddia etme") ve §3.1 sırayı da veriyor —
/// dürüstlük ön-beyanı karşılamadan hemen SONRA, kullanıcı ürünün içine
/// girmeden ÖNCE.
///
/// Risk açık: bir ürün kendini kötülemeye başlarsa kimse kalmaz. Bu yüzden
/// üç perde de aynı sesle konuşuyor — **kısıtı bir özür olarak değil, bir
/// KARAR olarak** sunuyor. "Tahmin eden bir sürüm göndermektense onu dışarıda
/// bırakıp nedenini söylüyoruz" cümlesi savunma değil, konumlandırma.
///
/// ## Kapsam-dışı listesi ELLE YAZILMIYOR
///
/// İkinci perde `library.exclusions`ı okuyor — `WhyNotPage`in okuduğu AYNI
/// canlı veri (`library.json → whyNotIncluded`). Buraya iki örnek cümle
/// kopyalamak, listeyi güncelleyen kişinin karşılamayı güncellemeyi
/// unutmasına açık olurdu ve karşılama sessizce bayatlardı — *türetimli
/// listeler elle yazılmaz.* Sayı da (`exclusions.length`) veriden geliyor.
///
/// ## Vaat dili YOK
///
/// Hiçbir perde "yakında", "şimdilik", "yet" demiyor (M-F-186). Üçüncü
/// perdedeki izin cümlesi de bir vaat değil bir OLGU: izni reddeden kullanıcı
/// için bugün çalışan şey saat ve anlatı — bu gerçekten böyle
/// (`SessionScreen` kamerayı opsiyonel alıyor ve kamerasız ders TAM koşuyor).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.library,
    required this.onDone,
    required this.onOpenWhyNot,
  });

  final ShellLibrary library;

  /// Karşılama bitti — çağıran bayrağı yazar ve kabuğa geçer.
  final VoidCallback onDone;

  /// Tam listeyi açar. Karşılamada listenin KENDİSİ gösterilmiyor: üç ekrana
  /// sığmaz ve ilk açılışta okunmaz. Gösterilen şey listenin VARLIĞI ve
  /// sebebi; detay bir dokunuş uzakta ve ürünün içinde de aynı yerde duruyor.
  final VoidCallback onOpenWhyNot;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;

  static const int _steps = 3;

  void _next() {
    if (_step + 1 < _steps) {
      setState(() => _step += 1);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JColors.ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StepDots(step: _step, total: _steps),
              const SizedBox(height: 20),
              // ⚠️ `Expanded` + kaydırma ZORUNLU: 375×812'de (kapı cihazı)
              // ikinci perdenin metni ekranı aşıyor ve bir taşma çizgisi
              // ürünün ilk ekranında görünürdü.
              Expanded(
                child: SingleChildScrollView(
                  child: switch (_step) {
                    0 => _Welcome(key: const Key('onboarding-welcome')),
                    1 => _Honesty(
                        key: const Key('onboarding-honesty'),
                        library: widget.library,
                        onOpenWhyNot: widget.onOpenWhyNot,
                      ),
                    _ => _Setup(key: const Key('onboarding-setup')),
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding-next'),
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: JColors.accent,
                    foregroundColor: JColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_step + 1 < _steps ? 'Next' : 'Start',
                      style: JText.body.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ① Vaat — TEK cümle. Ne olduğu, ve neye ihtiyaç duymadığı.
class _Welcome extends StatelessWidget {
  const _Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('THE CORNER', style: JText.label),
        const SizedBox(height: 10),
        Text('Boxing practice\nyou can do alone.', style: JText.pageTitle),
        const SizedBox(height: 18),
        Text(
          'Put your phone down, step back, and work. No bag, no gloves, no '
          'sensors — a camera and floor space are the whole kit.',
          style: JText.body,
        ),
        const SizedBox(height: 14),
        Text(
          'Everything runs on your phone. Video is read as you move and is '
          'never stored or sent anywhere.',
          style: JText.bodyMuted,
        ),
      ],
    );
  }
}

/// ② Dürüstlük ön-beyanı — ürünün ölçmediği şeyler, İÇERİ GİRMEDEN ÖNCE.
class _Honesty extends StatelessWidget {
  const _Honesty({
    super.key,
    required this.library,
    required this.onOpenWhyNot,
  });

  final ShellLibrary library;
  final VoidCallback onOpenWhyNot;

  @override
  Widget build(BuildContext context) {
    // TÜRETİLMİŞ, elle yazılmadı — `WhyNotPage`in okuduğu aynı liste.
    final int excluded = library.exclusions.length;
    final String intro = library.whyNotIntro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('BEFORE YOU START', style: JText.label),
        const SizedBox(height: 10),
        Text('What this\ncannot do.', style: JText.pageTitle),
        const SizedBox(height: 18),
        Text(
          'A single camera sees shape and timing. It does not see force, and '
          'it does not see another person. So there is no power number here, '
          'and no score for anything that needs a partner.',
          style: JText.body,
        ),
        const SizedBox(height: 16),
        GlassPanel(
          tier: GlassTier.observation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('LEFT OUT ON PURPOSE', style: JText.label),
              const SizedBox(height: 8),
              // Sayı da veriden: liste büyürse bu cümle kendiliğinden doğru
              // kalır. Elle yazılmış bir "6 things" bir sonraki içerik
              // turunda sessizce yalan olurdu.
              Text(
                excluded == 1
                    ? 'One thing is deliberately not in this app.'
                    : '$excluded things are deliberately not in this app.',
                key: const Key('onboarding-excluded-count'),
                style: JText.body,
              ),
              if (intro.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(intro, style: JText.bodyMuted),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                key: const Key('onboarding-why-not'),
                onTap: onOpenWhyNot,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('See the list',
                        style: JText.body.copyWith(
                            color: JColors.cool,
                            decoration: TextDecoration.underline,
                            decorationColor: JColors.cool3)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: JColors.cool),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'When the camera cannot read you, the app says so instead of going '
          'quiet. Silence would read as approval.',
          style: JText.bodyMuted,
        ),
      ],
    );
  }
}

/// ③ Kurulum — telefon nereye konur, ve izin verilmezse ne OLUR.
class _Setup extends StatelessWidget {
  const _Setup({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('SET UP ONCE', style: JText.label),
        const SizedBox(height: 10),
        Text('Where to put\nthe phone.', style: JText.pageTitle),
        const SizedBox(height: 18),
        // ADR-003: ön-eğik ~30-45°. Bir ÖNERİ olarak yazılıyor, ölçüm
        // iddiası olarak değil — uygulama açının kaç derece olduğunu
        // ölçmüyor ve "45 derece dur" demek ölçtüğümüz izlenimi verirdi.
        _SetupLine(
          n: '1',
          text: 'Lean it somewhere stable at about waist height.',
        ),
        _SetupLine(
          n: '2',
          text: 'Stand back until your feet and hands both fit in frame.',
        ),
        _SetupLine(
          n: '3',
          text: 'Turn slightly toward the camera rather than square on — '
              'a front-oblique angle reads your guard best.',
        ),
        const SizedBox(height: 18),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('IF YOU SAY NO TO THE CAMERA', style: JText.label),
              const SizedBox(height: 8),
              // Bu bir vaat DEĞİL, bugünkü davranışın beyanı: kamerasız ders
              // saat ve anlatıyla TAM koşuyor (`SessionScreen.liveJab` null
              // olabilir ve akış bozulmaz). Çıkmaz sokak olmaması UI-BRIEF
              // §3.1'in açık şartı.
              Text(
                'Conditioning rounds still run — the round clock and the '
                'coach both work without it. Only the form feedback needs '
                'to see you.',
                key: const Key('onboarding-permission-note'),
                style: JText.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupLine extends StatelessWidget {
  const _SetupLine({required this.n, required this.text});

  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 22, child: Text(n, style: JText.mono)),
          Expanded(child: Text(text, style: JText.body)),
        ],
      ),
    );
  }
}

/// İlerleme noktaları — sayı DEĞİL. "2/3" bir ölçüm gibi okunur ve bu
/// ürün sayıları ölçüme saklıyor; konum bir sayı istemiyor.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Container(
            key: Key('onboarding-dot-$i'),
            width: i == step ? 22 : 8,
            height: 4,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: i == step ? JColors.accent : JColors.ink4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
