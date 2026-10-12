# Yazılı hatırlama ve geri bildirim — 12 Ekim 2026

Bu ek, mevcut kaynak derslerini okuma/aktif hatırlama ile çalıştırır. Hareket veya ekipman gerekmez. Öğrenen yazılı cevabı kaynaktan ayrı kurup karşılaştırır. Fiziksel uygunluk, tekniğin doğruluğu, demonstrasyon/lisans ve tam müfredat kabulü verilmez.

| Onaylı alan | Mevcut ders/birim | Yeni okuma | Açık kapsam |
|---|---:|---:|---|
| boxing | 39 | 2 | Actual solo stance, punch and recovery feedback needs readable learner footage; J-007 blur/occlusion and J-011 sustained device FPS/thermal acceptance remain open. |
| taichi | 32 | 2 | Foundations and Yang16 written task identity, transfer and same-target correction need competent physical review; task A is not Yang13. |
| kickboxing | 16 | 2 | Front-kick prerequisites and safe support/return need physical demonstration and review; roundhouse/pivot acceptance cannot be inherited. |
| karate | 26 | 2 | Kihon/KA-P1 and Taikyoku written contracts retain their physical prerequisite gates and exact sequence identity; full kata teaching needs competent review. |
| muaythai | 16 | 2 | All physical prerequisite/acceptance gates remain; contact, check/clinch, partner resistance and live guard effectiveness are not verified. |

Kaynak dosyaları ve bölüm referansları `lib/app/study_review_content.dart` içindeki `sourceRefs` alanındadır. Eski ders metinleri, süre/doz, sensör eşikleri, fiziksel kabul ve ders ilerlemesi değiştirilmez.

`study_review.dart` durumları ayrı tutar: denenmedi → örneği yeniden oku; belirsiz → kesin terimi/geçişi adlandır ve uygun eğitmene soru hazırla; tek fark → yalnız aynı yazılı noktayı düzeltip kaynağı gizleyerek yeniden hatırla; durdum → bitir, hareket/ekipman görevini tekrar etmeyi önerme. Notlar geçicidir; kalıcı sağlık/hesap/ilerleme kaydı yoktur.

`test/study_review_test.dart` TR/EN dar ekran/büyük metin, kaynak cevabının gizlenip açılması, dört farklı geri bildirim ve çıkışta not/durum atılmasını sınar. Gerçek cihaz, fiziksel öğretim, sensör ve mağaza testi değildir.
