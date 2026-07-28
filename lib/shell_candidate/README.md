# `lib/shell_candidate/` — motion_shell'e terfi adayları

**Karar:** M-F-25 — platform katmanı ailede **BİR KEZ** üretilir (`motion-core/packages/motion_shell`). JabLab bu üretimin **pilotudur**.

## Kural

Bu klasördeki her şey, 5 app'in de kullanacağı **alan-bağımsız** kabuk parçasıdır ve koordinatör tarafından `motion_shell`'e terfi ettirilecektir. Buraya yazarken tek soru: *"Bu dosya Ostinato'da (çello) ve Choreia'da (salsa) da anlamlı mı?"*

- ✅ **Buraya ait:** sekme çatısı · kütüphane/disiplin/kurs/ders sayfa şablonları · ilerleme grafikleri · ayarlar/profil · paywall iskeleti · dürüstlük kutusu bileşeni · "yakında" rozeti · "Neden yok?" sayfası şablonu
- ❌ **Buraya ait DEĞİL:** canlı kamera seansı, yumruk görselleştirmesi, boks turu zamanlayıcısı, disipline özgü metin — bunlar `lib/app/` altında

## Sözleşme

1. **Alan sözlüğü yok.** Bu klasörde `punch`, `jab`, `round`, `boxing` gibi kelimeler geçmez. Öğeler `Discipline`/`Course`/`Lesson` genel adlarıyla anılır.
2. **İçerik enjekte edilir, gömülmez.** Widget'lar veriyi parametre olarak alır; hiçbir dosya `library.json`'ı kendi okumaz — okuma `lib/app/` katmanının işidir.
3. **Tema token üzerinden.** Sabit renk/ölçü yazılmaz; `Theme.of(context)` kullanılır ki her app kendi karakterinde görünebilsin.
4. **Terfi ettiğinde app'te kalan tek şey import satırıdır.** Bir dosya `lib/app/`'e bağımlıysa terfi edemez — bağımlılık yönü daima `app → shell_candidate`, asla tersi.

Terfi sonrası bu klasör boşalır ve `motion_shell` bağımlılığı gelir.
