import 'package:flutter/material.dart';

/// "Neler ölçülür / neler ÖLÇÜLMEZ" kutusu.
///
/// Standart §2 her öğe sayfasında bunu ZORUNLU kılıyor ve §8 gerekçesini
/// veriyor: ölçemediğimizi söylemek, ölçüyormuş gibi yapmaktan üstündür.
/// Bileşen bilerek **katı**: `notMeasured` boş geçilemez — bir öğe neyi
/// ölçemediğini söyleyemiyorsa o sayfa yayınlanmamalıdır.
class HonestyBox extends StatelessWidget {
  const HonestyBox({
    super.key,
    required this.measured,
    required this.notMeasured,
  }) : assert(notMeasured.length > 0,
            'Dürüstlük kutusu "ölçülmez" listesi olmadan gösterilemez');

  final List<String> measured;
  final List<String> notMeasured;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('What this measures', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ...measured.map((String m) => _Line(icon: Icons.check, text: m)),
            if (measured.isEmpty)
              // ⚠️ DONMUŞ AĞAÇTA TEK KELİMELİK DÜZELTME (J-122, koordinatör
              // hükmü). Eskiden *"Nothing yet — this section is not open."*
              // yazıyordu ve bu cümle 7 KAPALI DİSİPLİNİN 7'sinde de
              // kullanıcıya görünüyor (`measured` onlarda boş) — yani
              // M-F-186'nın canlı ihlali, ve J-108'de `library.json`dan
              // silinen cümlenin ikizi.
              //
              // Freeze'i çiğnemiyor: freeze *"kabuk envanterini BÜYÜTME"*
              // için kondu; bir kelime silmek envanteri büyütmüyor, vaat
              // dilini kaldırarak küçültüyor. Ayrıca freeze bir ÇALIŞMA
              // DİSİPLİNİ, M-F-186 bir ÜRÜN SINIRI — süreç kuralı,
              // kullanıcıya görünen bir dürüstlük ihlalinin önüne geçmez.
              Text('This section is not open.',
                  style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            Text("What it doesn't", style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ...notMeasured.map((String m) => _Line(icon: Icons.close, text: m)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}
