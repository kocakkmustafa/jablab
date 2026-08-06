# Uyum Denetimi — 2026-08-06 (Faz 2 kapanışı)

> Koordinatörün ilk görev mesajındaki 18 maddelik liste, §4/1'deki sınıflandırma
> ayrımıyla (uygun / **İHLAL** / belirsiz — "yüzey yok" ile "yüzey var ve uymuyor"
> KARIŞTIRILMAZ). **Kapsam: yalnız Ayarlar köşesi** (`677849c`, `1a5a565`) — Sayfa
> A/B/C henüz tasarım tokenlarına geçmedi, o yüzden bu ekranlara özgü maddeler
> BELİRSİZ değil **UYGULANAMAZ** (N/A) işaretlendi; "belirsiz" ile karıştırılmasın,
> o madde bu turda hiç ölçülmedi çünkü ilgili yüzey hiç giydirilmedi.

| # | Madde | Sınıf | Kanıt |
|---|---|---|---|
| ① | Kalibrasyonsuz sayısal skor yok — bant | **uygun** | Ayarlar hiç skor göstermiyor; tek sayısal-görünümlü alan `{price}` yuvası, o da "Pricing is not set yet." dürüst beyanı (Tier-2d/kesikli) |
| ② | kcal/kalori yok | uygun | Yok, hiç geçmiyor |
| ③ | Kas ısı haritası yok | uygun | Yok |
| ④ | Çok maddeli yeşil form-checklist yok | N/A | Bu madde ders ekranına ait, Ayarlar'da form-checklist kavramı yok |
| ⑤ | "AI detection active" sınıfı ibare yok | uygun | Yok |
| ⑥ | power/force/kph dili yok | uygun | Yok |
| ⑦ | "coming soon" yok | uygun | Ayarlar'da disiplin/kurs listesi yok, "yakında" dili hiç geçmiyor |
| ⑧ | sol/sağ denmez → lead/rear hand | uygun (eksiklikle) | Ayarlar'da taraf dili hiç geçmiyor — çünkü profil kartı (tasarımdaki "Orthodox · lead hand left") HİÇ render edilmiyor (bkz. DESIGN-AHEAD-OF-CODE, gerçek stance verisi yok). İhlal değil ama not: madde teknik olarak "boş küme üzerinde doğru" |
| ⑨ | Analiz başlamamışken çıplak "0" yok | N/A | Ders ekranına ait, Ayarlar'da sayaç yok |
| ⑩ | Fiyat sabit yazılmaz | **uygun, TESTLİ** | `pricing-not-set` key + `shell_test.dart`'ın "fiyat sabit yazılmamış" testi; kod `{price}` yerine gerçek cümle basıyor, hardcoded rakam yok |
| ⑪ | Motivasyon tonda, iddiada değil | uygun | "you see what the coaching is actually like before anything is asked of you" — süreç cümlesi, sonuç vaadi değil |
| ⑫ | Seçim ekranı her doluluk seviyesinde kasıtlı | N/A | Sayfa A'ya ait, bu turda giydirilmedi |
| ⑬ | "Neyi yapmıyoruz" yüzeyi var, 4. sayfa değil | **uygun** | `why-not-link` Ayarlar'dan `WhyNotPage`'e açılıyor (Sayfa A'nın aynısına) — ayrı bir 4. "sayfa" değil, mevcut 3 sayfa + köşe modeline ek yapmıyor |
| ⑭ | Kurs sayfası üç geçmiş hâli ayrı | N/A | Sayfa B'ye ait, bu turda giydirilmedi (yapısal olarak Faz 1'de var — `course_page.dart` `_WhereYouLeftOff` — ama GÖRSEL giydirme henüz yok) |
| ⑮ | Canlı ekranda beş dürüst hâl ayrı | N/A | Ders ekranına ait, ayrı tur |
| ⑯ | Anlatı/hüküm yuvası görsel ayrı | N/A | Ders ekranına ait |
| ⑰ | Portrait yönelim | **belirsiz** | Z8 bunu ölçülmüş bir gereklilik olarak koydu (kurulum replikleri ayakta tam-vücut kadrajı gerektiriyor) ama **kod tarafında yönelim kilidi bu turda kontrol edilmedi/uygulanmadı** — `Info.plist`/`AndroidManifest`'in portrait-only olup olmadığı ÖLÇÜLMEDİ. Açık kalem, ders ekranı turunda kapatılmalı. |
| ⑱ | Kardeş ayrışması (koyu+buzlu cam+akkor kırmızı+kesik/hızlı hareket) | kısmen doğrulanabilir | `design_tokens.dart` Material varsayılanından tamamen ayrışıyor (OKLCH kırmızı/ember, 26px blur, 120-420ms overshoot'suz eğriler) — **ama diğer 4 kardeşin GERÇEK ekranlarını görmedim**, yalnızca kendi paletimin Material-varsayılanından farklı olduğunu doğrulayabiliyorum, "4 kardeşten de görsel olarak ayrışıyor" iddiasını değil |

## Özet

**İhlal: 0.** Uygulanan tek yüzeyde (Ayarlar) hiçbir madde ihlal edilmedi.
**N/A: 8** (④⑨⑫⑭⑮⑯ — ders ekranı/Sayfa A/B'ye ait, bu turda hiç giydirilmedi).
**Belirsiz/açık: 2** (⑰ portrait kilidi ölçülmedi · ⑱ kardeş-ayrışması yalnız
tek-yönlü doğrulanabildi).

Ders ekranı + Sayfa A/B turu açıldığında bu tablo GENİŞLETİLECEK, üzerine
yazılmayacak — N/A satırları o turda gerçek sonuca dönüşecek.
