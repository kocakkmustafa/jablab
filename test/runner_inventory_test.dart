import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KOŞUM ENVANTERİ (J-146) — *"testler yeşil"* cümlesinin KAPSAMI.
///
/// ## Neden bu kapı var
///
/// Bu gece kırk kez *"kapılar N/N yeşil"* raporladım. O **app** süitiydi.
/// **Motor süiti J-104'ten beri kırmızıydı** ve kırmızılığın sebebi bendim
/// (J-145). Cümle yanlış değildi — **eksikti**.
///
/// > **Bir kapının yeşili, o kapının KAPSADIĞI kadar geçerlidir.**
/// > **İki süitli bir depoda *"testler yeşil"* EKSİK bir cümledir.**
///
/// Bu kapı o cümlenin kapsamını **sabitliyor**: bugün iki Dart koşumu var
/// (app + motor) ve bir analyzer. Üçüncü bir paket eklenirse *"yeşil"*
/// sessizce daralır — çünkü kimse yeni koşumu koşmayı akıl etmeyebilir.
/// O an bu test **öter ve ne yapılacağını söyler.**
///
/// ## Ölçülmüş kapsam (varsayım değil)
///
/// * `flutter test` → `app/test` (bu süit)
/// * `dart test` → `app/packages/jablab_engine/test` (**AYRI koşum**)
/// * `flutter analyze` → app kökünden koşunca **motor paketini de
///   kapsıyor**; deneyle ölçüldü (motora kasıtlı kullanılmayan import
///   kondu, app kökündeki analyze onu bildirdi). Yani analyzer tarafında
///   ikinci bir koşum GEREKMİYOR.
/// * Çalıştırılabilir başka kapı YOK — `tool/fetch_pose_model.sh` bir
///   getirme betiği, kapı değil.
///
/// ## ⚠️ NE ÖLÇMÜYOR
///
/// * Diğer koşumun **yeşil olduğunu** — bir süit başka bir süiti koşamaz.
///   Bu kapı yalnız *"kaç koşum var"*ı sabitler; koşmak rapor edenin işi.
/// * CI yapılandırmasını (bugün yok).
void main() {
  test('bu depoda TAM İKİ Dart koşumu var — "yeşil" bu kadarını kapsar', () {
    final List<String> packages = <String>[];
    void walk(Directory d) {
      for (final FileSystemEntity f in d.listSync()) {
        if (f is Directory) {
          final String name = f.uri.pathSegments
              .where((String s) => s.isNotEmpty)
              .last;
          // Üretilmiş/platform ağaçları taranmaz: içlerinde pubspec
          // bulunabilir ve hiçbiri ayrı bir KOŞUM değildir.
          if (<String>['build', '.dart_tool', 'ios', 'android', 'macos',
                  'windows', 'linux', 'web', '.git']
              .contains(name)) {
            continue;
          }
          walk(f);
        } else if (f is File && f.path.endsWith('pubspec.yaml')) {
          packages.add(f.path);
        }
      }
    }

    walk(Directory('.'));
    packages.sort();

    expect(packages.length, 2,
        reason: 'Dart paketi sayısı ${packages.length} (beklenen 2):\n'
            '  ${packages.join('\n  ')}\n\n'
            'ÜÇÜNCÜ BİR KOŞUM EKLENDİYSE: "testler yeşil" cümlesinin '
            'kapsamı değişti. Yapılacak iki şey var — (a) yeni koşumu her '
            'raporda KOŞ (b) bu testi ve `docs/design/KAPI-ENVANTERI.md` '
            'koşum listesini güncelle. Bu gece bu cümlenin eksikliği '
            'motor süitinin saatlerce kırmızı kalmasına yol açtı (J-145).');

    // Kimlik de ölçülüyor: sayı doğru olup paketlerin YERİ değişmiş
    // olabilir ve o zaman koşum komutları sessizce yanlış yere bakar.
    expect(packages.any((String p) => p.endsWith('./pubspec.yaml')), isTrue,
        reason: 'app paketi bulunamadı');
    expect(
        packages.any(
            (String p) => p.contains('packages/jablab_engine/pubspec.yaml')),
        isTrue,
        reason: 'motor paketi bulunamadı — yeri değiştiyse `dart test` '
            'komutu artık yanlış dizine bakıyor olabilir');
  });
}
