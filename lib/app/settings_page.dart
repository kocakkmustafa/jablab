import 'package:flutter/material.dart';

import '../shell_candidate/shell_scaffold.dart' show PaywallStub;
import 'camera_harness_screen.dart';

/// Ayarlar köşesi (design: `docs/design/DESIGN-PANEL-PROMPT.md` §2
/// "Köşe — Ayarlar"). Ayrı sekme DEĞİL — Sayfa A/B'nin köşe ikonundan
/// açılan bir sayfa.
///
/// Tasarımda profil kartı (isim/stance) ve koçluk-tercihleri listesi
/// (ses seviyesi, düzeltme sıklığı vb.) var — ama bu turda bunların
/// karşılığı olan GERÇEK bir kullanıcı/ayar sistemi yok. Sahte veri
/// BASILMAZ (bu app'in tüm kimliği bu ilkeye dayanıyor); bu iki öğe
/// kapanış raporunda DESIGN-AHEAD-OF-CODE olarak kayda geçiyor.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onOpenWhyNot});

  final VoidCallback onOpenWhyNot;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const PaywallStub(
              freeUntil:
                  'The first assessment and the first course are free — you see '
                  'what the coaching is actually like before anything is asked of you.',
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                key: const Key('why-not-link'),
                title: const Text("What we don't do, and why"),
                subtitle: const Text(
                    'Seven things left out on purpose, each with its reason.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenWhyNot,
              ),
            ),
            // DEV HARNESS girişi — YALNIZ debug derlemede (J-072). Release'de
            // bu satır hiç render edilmez (bkz. `_ProfilePage`'den taşınan
            // gerekçe, `CameraHarnessScreen.isAvailable`).
            if (CameraHarnessScreen.isAvailable) ...<Widget>[
              const SizedBox(height: 24),
              const Divider(),
              Builder(
                builder: (BuildContext context) => ListTile(
                  key: const Key('open-camera-harness'),
                  leading: const Icon(Icons.biotech_outlined),
                  title: const Text('Camera bridge — dev harness'),
                  subtitle: const Text(
                      'Debug build only. Raw bridge metrics, no preview, '
                      'no judgement.'),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                        builder: (_) => const CameraHarnessScreen()),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
