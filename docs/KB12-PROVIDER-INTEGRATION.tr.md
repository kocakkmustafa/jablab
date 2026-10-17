# JabLab görev/provider bağlantısı — kb-12

Bu sürüm tam ders hedefini korur. Model eğitimi ertelenmiştir. Üretimde `kb-12` için **kalibrasyon gerekli**, diğer yeni ders görevleri için **desteklenmiyor** gösterilir. Kamera değerlendirmesi açılmaz. Yazılı inceleme ve kullanıcının çalışma beyanı fiziksel teknik kabulü değildir.

## Bağlı görev

`TechniqueTasks.lowFrontKick` yalnız `jablab.kickboxing_a` / `kb-12` çiftine bağlıdır. Fazlar hazırlık, uzatma, geri toplama ve başlangıca dönüştür. Görev sürümü, gerçek kurs/model hashleri, izinli profil açıları, body33 şeması ve zorunlu eklemler `docs/evidence/kb12-task.v1.json` dosyasındadır. Bu dosya doğrudan `toJson()` çıktısıdır; sonuna satır sonu eklenmeden kompakt UTF-8 olarak hashlenir.

Görev SHA-256: `edf16e2126fdbea85a45f0ae4976e3ffa98f5c8aacdc6d380b10cbaca9a6b56d`

Gerçek anatomik taraf, ön/arka taraf, landmark eşlemesi ve ekran aynalaması ayrı girdilerdir. Görüntü düzlemindeki açı/mesafe özellikleri kuvvet, temas, ağrı, kişiye uygunluk veya teknik doğruluğu kanıtlamaz. Yanlış model/görev/taraf, düşük güven, görüş dışı, belirsiz eşleme, saat kesintisi, eksik geometri, arka plan/hesap/provider değişimi eski faz adayını geçersiz kılar. Faz adayı ve tamamlanan aday dizisinin ilerlemeye etkisi sıfırdır.

Mevcut boks oturumunda motor sadece dersin ilan ettiği teknikleri ve kombinasyon tekniklerini gözler. Boş teknik listesine sahip kurulum/duruş derslerinde yumruk sayılmaz; jab dersinde cross/fallback sayılmaz.

## Eğitilmiş modeli sonra bağlama kapısı

1. Ortak Core'un `MotionProviderManifest/Requirement/Selection` sözleşmesi bu sürümde yayımlanmış tam `62c105567a9fdfa9d907a8f8a399494c8ae5b598` SHA'sından benimsenmiştir (`motion_core` 0.13.0, sözleşme 1.0.0; ortak PR #9). App ve motor descriptor/lock/grafikleri aynı Git kaynağını çözer. Normal pub çözümlemesi kullanılır; Core kaynağı/cache elle değiştirilmez. `TechniqueProviderAdapter` görev SHA'sını capability kimliğine bağlar ve ortak readiness/selection/rollback mantığını doğrudan kullanır. Üretim manifesti `calibrationRequired` kalır.
2. Bağımsız kabul makbuzu; görev SHA, kurs/ruleset SHA, model ve kalibrasyonun gerçekten yüklenmiş bayt hashleri, provider/ABI/sürüm, şema, koordinat, açı/taraf ve gözlenemeyen durumlara bağlanmalıdır. Adayın kendi beyanı kabul makbuzu üretmez. `VerifiedPoseModel` zaten gerçek model boyutu/SHA kontrolünü yapar.
3. Eğitim ve bağımsız kalibrasyon kabulünden sonra gerçek inference provider'ını `TechniquePhaseProvider` portuna bağlayan **üretim** factory ekle. `TechniqueProviderArtifacts.fromLoadedBytes` gerçek yüklenen model/kalibrasyon baytlarını hashler; bağımsız incelenmiş kabul hashini aday manifestinden almaz. Görev model pinine uymayan baytlar, yanlış görev hashli capability, replay veya ABI/şema/koordinat uyuşmazlığı hazır sayılmaz. Mevcut üretim factory yalnız abstention döndürür. `replayForTesting` release'de hata verir; sahte provider yalnız test dosyalarındadır. Kullanıcıya replay açma seçeneği veya otomatik fallback yoktur.
4. Değişimde kamera kapanışını bekle; yeni provider/model/kalibrasyon/hesap/lifecycle kimliğiyle yeni gözlem oturumu aç. Reddedilen aday kısmi denemeyi devam ettiremez. Açık rollback de güncel baytlar ve kabul hashleriyle tekrar denetlenmelidir.
5. Kişi/oturum/kaynak ayrımı ve izin/hash kabulü için ortak `8455a56b` veri hazırlığını kullan. Eğitim/referans, doğrulama ve açılmamış test ayrımını koru. Sayısal eşikler, uzman etiketleri ve görüş/taraf kapsamı test açılmadan dondurulmalıdır; bu sürümde belirlenmiş ya da sağlanmış sayılmaz.
6. Holdout'ta tüm uygun klipleri, eksik sonuçları ve abstention paydalarını sakla; kişi/cihaz/açı/taraf bazında karışıklık, precision/recall, fazla/kaçan deneme ve faz zamanı hatalarını raporla. Aynı sabit model/kalibrasyonla host–native eşliği ve bağımsız uzman/öğretim kabulü ayrı kapılardır. Kullanıcıya riskli hareket yaptıran test talimatı verilmez.

## Açık kabul sınırları

- **J-007:** Görüş dışı/düşük güven yazılım testleri vardır. Pose verisi blur ile occlusion'ı ayıramaz. Bağımsız özgün klipler ve gerekirse Core sahibinin bölgesel kalite arayüzü gerekir.
- **J-011:** Fiziksel cihazda uzun FPS/termal kabulü açık. Simülatör UI testi bu kapıyı kapatmaz.
- **Özgün referanslar:** Dört stance ve dört jab kontrolü gerçek kaynak artefaktları gelene kadar NO_CALL kalır.
- **Gösterimler:** Üretim medya kataloğu boş. Mevcut solo-boxing slot/altyazı/lifecycle arayüzü içerik kabulü değildir. Diğer branşlar için lisanslı gösterim ve kaynak/lesson/scene eşliği hâlâ teslim/kabul bekler. Video teslim edilmiş varsayılmaz.
- **Hesap/IAP/paket:** Gerçek hesap/restore, güncel signed iOS/Android paket eşliği, gizlilik/mağaza varlıkları ve kullanıcı yayın kararı ayrı kapılardır. Push/CI/upload bu yerel çalışmaya dahil değildir.

Yerel test logları ve kaynak/artefakt makbuzları `Documents/Codex/2026-10-17/task-14/` altında tutulur. Sentetik, widget, native UI, gerçek hesap ve fiziksel doğruluk kanıtları ayrı raporlanır.
