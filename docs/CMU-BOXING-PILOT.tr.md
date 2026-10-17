# CMU boxing — sınırlı araştırma pilotu

Kullanıcının internet kaynaklı eğitim araştırmasını başlatma kararıyla bu pilot yapıldı. Sonuç **baseline üzerinde kazanç yok; üretime kabul yok**. Tam öğretim hedefi korunur; bu çalışma bir teknik doğruluk modeli veya uzman kabulü değildir.

## Kaynak ve koşullar

CMU Graphics Lab'ın resmi [ana sayfası](http://mocap.cs.cmu.edu/) ticari ürüne dahil etmeyi izinli, ham veya dönüştürülmüş veriyi doğrudan yeniden satmayı yasak olarak açıklıyor. [FAQ](http://mocap.cs.cmu.edu/faqs.php) kopyalama/değiştirme/yeniden dağıtma ve ASF uzunluk dönüşümünü açıklıyor. Atıf: “The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217.” Kaynak videoların hakları ayrıca değerlendirilir; video indirilmedi.

[Subject13](http://mocap.cs.cmu.edu/search.php?subjectnumber=13) metadata'sındaki `boxing` kayıtları 13_17/13_18, nominal 120Hz. Yalnız 13.asf ve bu iki AMC alındı; toplu tarama yapılmadı. HTTPS web okumaları timeout verdi; kullanıcının belirttiği resmi HTTP kaynakları kullanıldı. TLS doğrulaması kapatılmadı veya tarayıcı uyarısı atlanmadı. SHA'lar alınan baytları tanımlar; HTTP sunucu kimliğini kriptografik olarak doğrulamaz.

## Veri ve yöntem

- 13_17:4.840 kare, eğitimde her 4. kareyle 1.210 örnek.13_18:3.000 kare, yalnız araştırma diagnostik ölçümünde 750 örnek. Kare indeksi sürekliliği ve tüm DOF alanları kontrol edildi. 120 Hz kaynak beyanıdır; bağımsız gerçek zaman damgası yoktur.
- ASF birim dönüşümü 0,0254/0,45=0,056444…m. AMC yerel eklem açıları sin/cos olarak normalize edildi; root/global poz, el/bilek/parmak/başparmak/ayak/parmak kanalları öğrenme girişinden çıkarıldı. Hiçbir kayıp kanal sıfırla doldurulmadı.
- 38 açı→76 sin/cos özellik, yalnız 13_17'den merkez ve 8 boyutlu PCA bazı. Rütbe 8 / ridge 0,001 maskeli sol humerus/radius görevi koşudan önce sabitlendi. Model artefaktı diagnostik skorlamadan önce hashlendi; 13_18 ile ayar taraması yapılmadı.
- Her 4. kareyle 30 Hz decimation anti-alias filtresi kullanmıyor; zamanlama/hız/frekans doğruluğu iddiası yok. Görsel, yalnız ASF dinlenim geometrisi ve açı tanılamasıdır; hareketli forward-kinematics veya body33 eşliği doğrulanmış sayılmaz.

| Ölçüm | Sonuç |
|---|---:|
| Maskeli 4 açı MAE |16,154764°|
| Eğitim ortalama-pozu baseline MAE |16,150120°|
| Model eksi baseline |+0,004644° (daha kötü)|
| Eğitim PCA açıklanan varyans |%82,6435 (sınıflandırma doğruluğu değildir)|
| Model arşivi |6.039 bayt; yalnız NumPy araştırma artefaktı|

Kanal bazlı tüm sonuçlar kanıt JSON'unda durur; yalnız iyileşen eksenler seçilmedi. NumPy/Pillow mevcut kurulumdan kullanıldı. Tek CPU thread, ortak `machine-runtime.lock` tüm koşu boyunca tutuldu ve finally bırakıldı. Yeni executable/framework, GPU veya provider çağrısı yok.

## Kabul sınırı ve karar

İki motion aynı subject 13'ten; gerçek kişi veya session bağımsızlığı bilinmiyor. CMU aynı kişinin farklı subject ID'lerle bulunabileceğini açıkça söylüyor. Bu ölçüm **validation/test holdout değildir**; zamanla ilişkili örneklerden kişi genellemesi veya anlamlılık çıkarılmaz.

Veride jab/hook/uppercut sınırları, doğru/yanlış teknik, uzman uygunluğu veya kamera/occlusion etiketleri yok. Bu pilot J-007/J-011, özgün stance/jab referansı veya öğretim kabulünü kapatmaz. Baseline kazancı olmadığından bu kapsamda daha büyük eğitim yapılmadı.

Araştırma girişi `cmu.asf-amc.local-euler.sin-cos.v1`; uygulamanın `body33.image.v1`/`image2d.aspectCorrected` girdisiyle uyumlu değildir. Mevcut Google Pose Landmarker full-v1 dosyası ve SHA pini değiştirilmedi. RGB olmadığından MediaPipe çalıştırılmış veya kamera eşliği kurulmuş sayılmaz. Mevcut JabLab adapter'ı gerçek araştırma manifestini `replayOnly`, üretim modu taklidini `incompatible` olarak reddetti; seçili provider null, kb-12 `calibrationRequired`.

[BoxingVI](https://github.com/Bikudebug/BoxingVI) README'sinde 6.915 klip / 20 YouTube videosu / 18 atlet ve punch sınıf/sınır etiketleri var. İncelenen kök/README'de lisans bulunmadı; kaynak video hakları veya teknik hata etiketleri doğrulanmadı. Dataset/Drive bağlantısı indirilmedi; eğitimde kullanılmadı.

## Tekrar üretim ve ortak Core sınırı

Ham veri/model arşivi Git'e eklenmez; yerel kanıt kökünde kalır. `runconfig.json`, `dataset-manifest.json`, `downloads.json`, `parser-tests.log`, `lease-run.json`, `out/metrics.json`, `out/analysis.json`, `out/diagnostics.png` ve artefakt hashleri `Documents/Codex/2026-10-17/task-14/cmu-boxing-pilot/` altındadır.

`python3 tool/research/cmu_boxing_pilot.py --root <kanıt-kökü>` yalnız yerel dosyaları kullanır; indirme veya ürün provider'ı yoktur. Yeniden ağır koşu ancak ortak CPU/native lease altında yapılmalıdır. Test kaynağının hashleri koşan dosyayla eşleştirildi; tamamlanan testler sebepsiz tekrarlanmadı.

Core pipeline'ın tek yazarı Lissom oturumudur; buradan Core'a yazılmadı. Gelecek koordinasyon için artefakt, açıkça üçüncü taraf motion kaynağı, nominal clock, belirsiz kişi/session grubu ve araştırma-only schema taşır; first-party video/izin makbuzu veya üretim kalibrasyonu gibi kabul edilmemelidir. Daha anlamlı teknik modeli için ayrı hak/etiket ve bağımsız değerlendirme kapsamı gerekir; otomatik üretim etkinleştirmesi yapılmaz.
