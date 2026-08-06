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

---

## Ek — 2026-08-06/07: 4 parçanın TAMAMI kapandı, N/A satırları GERÇEK sonuca döndü

> Kapsam artık TÜM app-özgü yüzey: Ayarlar (`677849c`+`1a5a565`) + yıldız
> ekran (`5fc2d65`) + Sayfa B (`4945895`) + Sayfa A (`7d6e707`). Kapsam
> DIŞI kalan (bilinçli, frozen/dev-only): `WhyNotPage`, `ContentFailureScreen`,
> `CameraHarnessScreen` — ne bu tur ne önceki turlar bunlara dokundu; genel
> MaterialApp temasıyla render ediyorlar, bu bir İHLAL değil kapsam sınırı.

| # | Madde | Sınıf | Kanıt |
|---|---|---|---|
| ④ | Çok maddeli yeşil form-checklist yok | uygun | Ders ekranında/hiçbir yerde "form doğru" ima eden bir checklist YOK — `HonestyBox`un "What this measures/doesn't" listesi checklist DEĞİL, ölçüm-kapsamı beyanı (K8'in kendisi bunu engelliyor) |
| ⑨ | Analiz başlamamışken çıplak "0" yok | **uygun, TESTLİ** | `LiveCoachSurface`in `if (eventCount != null)` kapısı korundu; `live_jab_path_test.dart`'ın "BAŞLANGIÇ hâli ayrı" testi + `_countSlotTests` bunu doğruluyor, bu turda BOZULMADI |
| ⑫ | Seçim ekranı her doluluk seviyesinde kasıtlı | **uygun** | `ItemStatus.live` (kurs listesi + expand/collapse) vs `!live` (Soon rozeti + coming-soon-note) görsel olarak AYRI kalıplardan geçiyor (`GlassPanel` normal vs `UnknownGlassPanel` kesikli) — simülatörde 8 disiplinin hepsi doğrulandı (5 "Soon", 1 "3 courses" — Boxing) |
| ⑭ | Kurs sayfası üç geçmiş hâli ayrı | **uygun (metinle ayrışıyor)** | `historyUnavailable` → `UnknownGlassPanel` (yapısal olarak AYRI tier); "incomplete" ve "complete" AYNI `GlassTier.observation` panelini paylaşıyor ama `historyIncomplete` metni sayılardan ÖNCE, ayrı bir satır olarak giriyor (J-092 sırası) — ayrışma RENK değil METİN üzerinden, aile emsaliyle tutarlı (bu ailede metin zaten birincil sinyal) |
| ⑮ | Canlı ekranda beş(-sekiz) dürüst hâl ayrı | **kısmen uygun — bilinçli AÇIK kalem** | `clean`/`correcting`/`noVerdict` üç YÜZEY-sınıfı ikon+tipografi ile ayrışıyor (bkz. `LiveCoachSurface`) ama `noVerdict`in KENDİ İÇİNDEKİ 8 alt-sebebi (izin reddi/kamera hatası/kadraj-dışı/düşük-güven/gövde-referansı vb.) TEK şablondan geçiyor, yalnız METİN farklı — renk/ikon farkı YOK. `DESIGN-AHEAD-OF-CODE.md`ye zaten not düşüldü, bu turun kapsamı DEĞİLDİ (koordinatöre soru olarak bırakıldı) |
| ⑯ | Anlatı/hüküm yuvası görsel ayrı | **uygun** | `jablabSessionTheme`de `narration` KENDİ yuvası (`labelLarge` → mono, cool-toned) `cue`/`noVerdictReason`den (`titleLarge` → Familjen Grotesk, correction-stili) AYRI bir FONT AİLESİNDEN bile geçiyor — hüküm susarken bile anlatının farklı bir "ses" taşıdığı görsel olarak kanıtlı |

## Genel özet (4 parça TAMAMLANDI)

**İhlal: 0** — dört parçanın hiçbirinde bir madde ihlal edilmedi.
**N/A kalan: 0** — önceki turun 6 N/A satırının (④⑨⑫⑭⑮⑯) HEPSİ gerçek
sonuca döndü (5 uygun, 1 kısmen-uygun-bilinçli-açık).
**Belirsiz/açık: 2** (değişmedi) — ⑰ portrait kilidi bu turda da
ölçülmedi/uygulanmadı (kod tarafı hâlâ dokunulmadı) · ⑱ kardeş-ayrışması
hâlâ yalnız tek-yönlü doğrulanabiliyor (4 kardeşin gerçek ekranı görülmedi).
**Bilinçli AÇIK (yeni sınıf, bu ekte tanıtıldı):** ⑮ — İHLAL değil, koordinatöre
bırakılmış bir tasarım sorusu (8 alt-sebebin görsel ayrışması gerekip
gerekmediği).
