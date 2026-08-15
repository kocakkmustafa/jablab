import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/onboarding_store.dart';

/// H-20/21 ÜÇLÜ SABOTAJ — kalıcı depo İ/Ç DAYANIKLILIĞI.
///
/// `session_store_test.dart`ın karşılığı, ama bambaşka bir yüzey:
/// `OnboardingStore` JSON TAŞIMIYOR (tek-bitlik VARLIK bayrağı — J-106),
/// yani "geçersiz JSON" / "geçerli JSON + yanlış tip" buraya uygulanmıyor —
/// ayrıştırma yok ki bozulsun. Buradaki gerçek risk sınıfı dosya sistemi
/// hatasıdır (izin reddi, yol bir dizin, vb). `seen()`/`markSeen()` ikisi
/// de `on Object catch (_)` kullanıyor (dosyanın kendi dokümanı) — burada
/// SENTETİK/DAVRANIŞSAL olarak sınanıyor, kaynak okuyup güvenmek yerine.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('jablab-onboarding-');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('seen(): yol bir DİZİN → false döner, FIRLAMAZ', () async {
    final Directory asDir = Directory('${tmp.path}/onboarding_seen');
    await asDir.create();
    final OnboardingStore store =
        OnboardingStore(fileOverride: File(asDir.path));
    expect(await store.seen(), isFalse,
        reason: 'dizin bir dosya DEĞİLDİR — "görülmemiş" doğru varsayılan '
            '(fazla göstermeye düş, az göstermeye değil — sınıf dokümanı)');
  });

  test('markSeen(): yol bir DİZİN → sessizce yutulur, uygulama ÇÖKMEZ',
      () async {
    final Directory asDir = Directory('${tmp.path}/onboarding_seen');
    await asDir.create();
    final OnboardingStore store =
        OnboardingStore(fileOverride: File(asDir.path));
    // Fırlamamalı — sınıfın kendi gerekçesi: yazma hatasında patlamak
    // kullanıcıyı bir bayrak yüzünden uygulamadan atmak olurdu.
    await store.markSeen();
    expect(await store.seen(), isFalse,
        reason: 'yazma başarısız oldu (yol hâlâ dizin) — sonraki okuma da '
            'dürüst kalmalı, "yazıldı" YALANI söylememeli');
  });

  test('POZİTİF KONTROL: gerçek dosyada seen()/markSeen() beklendiği gibi çalışır',
      () async {
    // Vakum koruması: yukarıdaki iki test "her zaman false" döndüren KIRIK
    // bir uygulamayı da vakumla geçirir. Bu, mekanizmanın gerçekten
    // çalıştığını (ateşlendiğini) kanıtlıyor.
    final File f = File('${tmp.path}/onboarding_seen');
    final OnboardingStore store = OnboardingStore(fileOverride: f);
    expect(await store.seen(), isFalse, reason: 'henüz yazılmadı');
    await store.markSeen();
    expect(await store.seen(), isTrue,
        reason: 'gerçek dosyada markSeen sonrası seen() true dönmüyor — '
            'yukarıdaki "false" sonuçları dayanıklılık değil kırıklık '
            'olabilirdi');
  });
}
