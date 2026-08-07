import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// İSKELET, MOTORUN KENDİ BELİRSİZLİĞİNE SAYGI DUYUYOR (J-170).
///
/// ## `ölçülmemiş` kutusuna PROXY MERCEĞİ uygulandı
///
/// Choreia'nın merceği: ***bir proxy'nin meşruiyeti tekniğinden değil
/// İŞİNDEN gelir — rozet ATAYAN proxy kesinlik ister, incelemeye ÇAĞIRAN
/// proxy yalnız duyarlılık.***
///
/// *"Ne gördüğümü çiziyorum"* iddiasını **ATAYAN** bir kapı (çizim gerçekten
/// sadık mı) **cihaz** ister — o kısım hâlâ `ölçülmemiş` ve doğru
/// sınıflandırılmış. Ama iddianın bir parçası **bugün ölçülebilir**:
///
/// > **Motor kendi okumasını güvenilmez ilan ettiğinde, ekran yine de
/// > normal parlaklıkta bir iskelet çiziyor mu?**
///
/// Ölçüldü: `_SkeletonPainter` `sceneAlpha`yı `noVerdict` hâlinde
/// düşürüyor — yani çizim **geri çekiliyor**. Davranış VARDI, **kapısı
/// yoktu**; `live_honesty_bucket_test` `0.85`i yalnız bir **kontrast
/// hesabına girdi** olarak kullanıyor, düşüşü ölçmüyor.
///
/// ## ⚠️ NE ÖLÇMÜYOR (atayan tarafı — hâlâ cihaz işi)
///
/// * Çizimin gerçek poza **sadık** olduğunu.
/// * Gerçek MediaPipe topolojisini (cihaz günü §7.3-7.7).
/// * Alfa farkının **algısal** olarak fark edilir olduğunu — bu, ikon
///   ayırt etme sorusuyla aynı sınıf: **yalnız göz.**
void main() {
  test('belirsiz hâlde iskelet GERİ ÇEKİLİYOR — ve fark yönü doğru', () {
    final String src =
        File('lib/app/skeleton_overlay.dart').readAsStringSync();

    // Değerler KAYNAKTAN türetiliyor, elle yazılmıyor: sabit yazsaydım
    // painter değişince kapı sessizce yalan söylerdi.
    final RegExp expr = RegExp(
        r'sceneAlpha\s*=\s*state\s*==\s*LiveState\.noVerdict\s*\?\s*'
        r'([\d.]+)\s*:\s*([\d.]+)');
    final RegExpMatch? m = expr.firstMatch(src);
    expect(m, isNotNull,
        reason: 'iskelet artık belirsizliğe göre alfa AYARLAMIYOR (ya da '
            'ifade yeniden yazıldı). "Ne gördüğümü çiziyorum" iddiasının '
            'ölçülebilir tek parçası buydu: motor okumasını güvenilmez '
            'ilan ederken ekran normal parlaklıkta çizmemeli (J-170)');

    final double unsure = double.parse(m!.group(1)!);
    final double clean = double.parse(m.group(2)!);
    expect(unsure, lessThan(clean),
        reason: 'belirsiz hâlin alfası ($unsure) temiz hâlinkinden '
            '($clean) DÜŞÜK olmalı — aksi hâlde ekran, güvenmediği bir '
            'okumayı güvendiğinden daha görünür çiziyor');
    // Fark ANLAMLI olmalı: 0.01'lik bir düşüş kuralı harfiyen tutup
    // ruhunu çiğnerdi. Eşik icat etmemek için oran kullanılıyor —
    // belirsiz hâl temizin en fazla YARISI kadar görünür olmalı... değil;
    // bu bir eşik icadı olurdu. Onun yerine yalnız YÖN ölçülüyor ve
    // "anlamlılık" ALGI sorusu olarak kutuda bırakılıyor.
  });
}
