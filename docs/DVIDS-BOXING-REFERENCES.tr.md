# DVIDS MCMAP — yerel referans ingestion

Üç gerçek kaynak video edinildi ve mevcut Pose Landmarker full-v1 ile zaman damgalı eklem/görünürlük/yol dizileri çıkarıldı. Bu iş **referans çıkarma kabulüdür**; kalite modeli eğitimi, spor boksunda evrensel doğru teknik veya bağımsız test kabulü değildir. CMU PCA denemesi büyütülmedi.

## Kaynak ve hak kapsamı

Yayıncı Bruce Hardcastle / U.S. Marine Corps Training and Education Command; çekim tarihi 2020-06-19. Üç sayfa da `PUBLIC DOMAIN` işaretli ve indirilen MP4'ü açık video `<source>` etiketinde sunuyor:

- [Hook](https://www.dvidshub.net/video/756773/hook), VIRIN 200619-M-RN637-020.
- [Lead Hand Punch](https://www.dvidshub.net/video/756778/lead-hand-punch), VIRIN 200619-M-RN637-023. Adı **jab olarak değiştirilmedi**.
- [Uppercut](https://www.dvidshub.net/video/756817/uppercut), VIRIN 200619-M-RN637-038.

[DVIDS koşulları](https://www.dvidshub.net/about/copyright) kişi mahremiyet/publicity haklarını, işaret/trademark sınırlarını ve kurum desteği izlenimi vermeme şartını korur. Bu görev videoları üründe veya reklamda yayımlamaz, kişileri tanımaz, kurum desteği iddia etmez. Kimlik/ayrı kişi onayı veya ticari görsel kullanım izni türetilmedi. Çıktılar yerelde kaldı. Girişli download butonu kullanılmadı; açık HTTPS oynatıcı kaynakları alındı, TLS doğrulaması açık tutuldu. İlk indirme CreateProcess çağrısı otomatik izin incelemesi deadline'ında hiç çalışmadı; boş media dizini/ledger kontrolünden sonra izin verilen tek aynı çağrı yeniden incelemesi başarılı oldu.

## Gerçek zaman ve görünürlük

| Kaynak adı | Kaynak frame | Pose görülen | Normalize referans frame | Çözünürlük |
|---|---:|---:|---:|---|
|Hook|138|67|65|1024×576|
|Lead Hand Punch|104|32|30|1920×1080|
|Uppercut|137|66|64|1920×1080|
|Toplam|379|165|159| |

Hepsi gerçek kaynak PTS denetiminde 23,976023976FPS ve artan zamanlıdır. Kaynak PTS–index/FPS en yüksek farkı 0,333… mikrosaniye; yeniden örnekleme, kırpma, proxy veya kare düşürme yapılmadı. Modelin mevcut canonical VIDEO yolu integer-ms timestamp kullanır; orijinal PTS, time_base ve extractor'ın serileştirilmiş zamanı ayrı saklandı. Bunlar sensör exposure zamanı veya gerçek cihaz kabulü değildir.

Videolar yaklaşık 3 s başlık kartı gösterip tek kamera ön/oblik tam beden gösterime geçiyor. Başlıklar da paydada saklanır. Basit 32×32gray fark heuristiği her klipte bir geçiş adayı buldu: Hook frame 71, Lead Hand Punch frame 72, Uppercut frame 71. Görsel yerel kontrol başlık–gösterim geçişini doğruladı; heuristik tüm olası editleri veya hareket fazlarını sertifikalandırmaz. Kamera açısı/ayna ve anatomik taraf bağımsız doğrulanmadı.

Normalization: x için width/height oranı uygulanır; kalça ortası çıkarılır ve shoulder–hip torso uzunluğuna bölünür. Görünürlük ve presence en az 0,5 olmalı, ilgili nokta kadrajda/sonlu olmalıdır. Eksik/kapalı eklemler null kalır. Geçiş çevresi ve eksik pozlarda yol segmenti kesilir; eski parça yeni denemeye bağlanmaz. Raw 33 landmark ve model-world tahminleri korunur; görüntü-normalize XY metriki kuvvet veya gerçek 3D ölçüm değildir. Düşük güven blur/occlusion ayrımı etiketi sayılmaz. MediaPipe NORM_RECT/projection uyarısı logda korunmuştur.

## Sınırlar, test ve yeniden üretim

- Her harekette bir kaynak video vardır; üçü tek muhafazakâr belirsiz kişi/session grubundadır. Kimlik tanıma yapılmadı. Train/validation/test bölünmesi, sınıflandırıcı veya hata kalite başlığı oluşturulmadı.
- 11 sentetik timing/normalization/gap testi geçti. Üç gerçek sequence'in hash/frame/PTS/görünürlük/null/yol segment denetimi geçti; kişisel/teknik doğruluk ölçümü sayılmadı.
- Mevcut Google full-v1 SHA `5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1` kullanıldı. Yeni model/runtime indirilmedi. App pinli Core 62c10556'nın canonical extractor'ı salt okunur kullanıldı; Core'a yazılmadı. Mevcut Lissom MediaPipe runtime'ı salt okunur kullanıldı; `PYTHONDONTWRITEBYTECODE=1` kullanıldı; Matplotlib cache bu görevin dizinine yönlendirildi.
- Ortak CPU/native flock tüm çıkarım boyunca tutuldu ve finally bırakıldı. Host inference 6.78–7.32 ms/frame fiziksel cihaz FPS/termal kabulü değildir.

`python3 tool/research/dvids_reference_ingest.py --root <kanıt-kökü>` yalnız yerel dosyaları okur. Öncesinde `runconfig.json` pin/hashleri ve ortak CPU/native lease doğrulanmalıdır. VFR/gap veya desteklenmeyen rotation çıkarsa araç sessizce düzeltmez; durur. Shared Core genişlemesini Lissom sahibi koordine eder.

Ham videolar, normalize diziler ve görseller Git'e alınmadı; yerel kanıt kökü `Documents/Codex/2026-10-17/task-14/dvids-boxing-references/`. `source-plan.json`, `download-ledger.json`, `runconfig.json`, `out/*.reference.json`, `out/*.ffprobe.json`, `out/ingestion-result.json`, `artifact-checks.json`, `view-notes.json` ve `lease-run.json` hash/provenance/ölçümleri bağlar. Lisans metadata'sı, tek örnek veya model tahmini; gerçek hata etiketi, bağımsız sporcu, uzman incelemesi, cihaz/paket ve ürün kabulünün yerine geçmez.
