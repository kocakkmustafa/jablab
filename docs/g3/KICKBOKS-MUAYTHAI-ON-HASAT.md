# Kickboks & Muay Thai — Ön-Hasat Haritası (M-F-14)

**Tarih:** 2026-07-26 · **Statü:** kaynak haritası — hiçbir video izlenmedi, kadraj doğrulanmadı
**Neden şimdi:** ADR-004 motoru branş-bağımsız ilan etti. Bu harita o iddianın **ilk gerçek sınavı**: ikinci branşın kaynakları ve ölçüm ihtiyaçları, motoru değiştirmeden karşılanabiliyor mu?
**Kapsam sınırı:** V1 boks. Bu doküman *hasat çapası* atar, motor rollout'unu değiştirmez.

---

## 1. Baş bulgu: branş farkı YENİ ÖLÇÜM gerektirmiyor — yeni EŞİK gerektiriyor

Araştırmadan çıkan beş somut boks↔Muay Thai farkı, `boxing@1.0.0`'da **zaten tanımlı** ölçülere birebir düşüyor:

| Fark | Boks | Muay Thai / kickboks | Karşılık gelen mevcut ölçü |
|---|---|---|---|
| Kalça/omuz dönüklüğü | ~50-80° yan ("bladed") | belirgin daha **kare/frontal** | `shoulderRotation` ✅ |
| Gövde dikliği | öne eğik, yuvarlak (çene omuz arkasında) | daha **dik** (savunma kafa hareketi değil blok/check) | `trunkLeanAngle` ✅ |
| Gard yüksekliği | alçak, sıkı, omuzlar öne | **yüksek**, avuç içleri dışa (tekme/dirsek yakalamak için) | `guardHeightDelta` ✅ |
| Duruş genişliği | daha geniş | daha dar/paralel *(sayısal ölçüm teyit EDİLMEDİ — anlatı düzeyinde)* | `stanceWidthRatio` ✅ |
| Ağırlık dağılımı | ön/arka ~%50-50 | **arka bacağa kaymış** (~%30-40 ön) — ön bacak teep/check için hafif | ❌ **EKSİK** |

**Dört buçuk ölçünün beşi mevcut.** Tek eksik: ön/arka **ayak yükü oranı**. `copOverBase` denge poligonunu ölçüyor, ön-arka dağılımı değil.

→ **Aksiyon:** `boxing@1.0.0 measures` bloğuna `frontFootLoadRatio` eklenecek (kalça orta noktasının ön↔arka ayak ekseni üzerindeki izdüşümü; poz-tabanlı vekil, kuvvet ölçümü DEĞİL — "yük" dili pazarlamaya girmez).

> **ADR-004 için hüküm: iddia AYAKTA.** İkinci branş bir `muaythai@1.0.0` config'i + bir yeni ölçü demek; state-machine, hata üretici, skor bileşenleri ve faz mantığı **aynen** çalışıyor. Bu, "kickboks sonradan takılır" sözünün ilk kanıtlanmış hâli.

## 2. Kapsam bulgusu: `check` solo gösterilemiyor

Taranan tekniklerin tamamı arasında **tek istisna**: check (tekme bloklama) doğası gereği *gelen bir tekmeye tepkidir*. Solo modda yalnız izole "şin çevirme / bacak kaldırma" provası çekilebilir; gerçek check'in **zamanlama ve hedef bulma** boyutu tek kişilik kamerada yakalanamaz.

Bu bir motor eksikliği değil, **ürün sınırı** — `jablab-plan §3`'ün "partner/rakip yok" kısıtının kickboks kolundaki karşılığı. Kayda geçti: check, ileride bile V-solo kapsamına giremez; girerse "hareket provası" olarak girer, **savunma becerisi olarak değil**. Aynı mantık boks tarafında `slip/duck/roll` için de geçerli — bu yüzden PRD'de zaten 🔴 bant D'deler.

## 3. Kaynak tablosu

| Teknik | Aday 1 | Aday 2 | Aday 3 | ≥3? | Solo? |
|---|---|---|---|---|---|
| Roundhouse (low/mid/high) | Muay Thai Guy | FightTIPS | Evolve MMA | ✅ | ✅ |
| Teep / push kick | Muay Thai Guy | Evolve MMA | Master Toddy | ✅ | ✅ |
| Front kick | Muay Thai Guy | FightTIPS | Sitsongpeenong | ✅ | ✅ |
| Thai roundhouse | Muay Thai Guy | Liam Harrison | Evolve / Sitsongpeenong | ✅ | ✅ |
| Dirsek (yatay/yukarı) | Evolve MMA | Kevin Ross | Muay Thai Guy | ✅ | ✅ |
| Duruş / gard farkı | Evolve MMA | Muay Thai Guy | *(3. kanal sınırda)* | 🟡 | ✅ |
| Diz (düz) | Evolve MMA | Kevin Ross | Master Toddy | ✅ | 🟡 öğretimin çoğu **klinç içinde** → solo segment ayıklanmalı |
| Switch kick | Muay Thai Guy | Evolve MMA | Kevin Ross *(kanal bağı teyit edilmedi)* | 🟡 | ✅ |
| Duruş geçişleri | Evolve MMA | FightTIPS *(spesifik video teyit edilmedi)* | — | 🟡 | ✅ |
| **Side kick** | Bill "Superfoot" Wallace | — | — | ❌ **1 kaynak** | ✅ |
| **Check** | Evolve MMA | Muay Thai Guy | *(kimlik zayıf)* | 🟡 | ❌ **solo gösterilemez** |

## 4. Kanal kimlik kartları — popülerlik ≠ kimlik belgesi

**ÇOK GÜÇLÜ (rakip-sporcu + eğitmen kimliği doğrulanmış):**
- **Master Toddy** — 50+ yıl eğitmenlik, 40+ dünya şampiyonu, Tayland Eğitim Bakanlığı onaylı MTIA kurucusu
- **Liam Harrison** — 8× dünya şampiyonu, 118 profesyonel maç
- **Kevin Ross** — Bellator kickboxing ilk dünya şampiyonu, WBC Muay Thai şampiyonu, Master Toddy öğrencisi
- **Sylvie von Duuglas-Ittu** (Muay Thai Scholar) — 470+ profesyonel maç, 2× IPCC + WBC dünya şampiyonu. ⚠️ Format ağırlıklı **analiz**, "solo böyle yap" dersi değil → ikincil kaynak
- **Bas Rutten** — UFC Hall of Fame; **formatı doğrudan işimize yarıyor**: partnersiz/ekipmansız sesli solo antrenman sistemi
- **Bill "Superfoot" Wallace** — side kick'te tarihsel otorite. ⚠️ Stil 1970-80 Amerikan point-kickboxing kökenli; modern K1/MT'de side kick sınırlı → **bağlam farkı notu şart**

**GÜÇLÜ:** Muay Thai Guy (Sean Fagan — 35 pro maç, Lion Fight şampiyonu, Tayland'da yaşamış) · Evolve MMA (kurumsal; ⚠️ içerik pazarlama ağırlıklı olabilir) · Sitsongpeenong (Bangkok kampı, Lumpinee/Rajadamnern şampiyonları)

**ORTA — dikkatli kullan:** FightTIPS (2M+ abone ama **kendi profesyonel dövüş kaydı teyit edilemedi**) · Muay Thai Pros (dolaylı otorite: güçlü hocalardan öğrenmiş pratisyen, kendi maç kaydı yok) · Sweet Science of Fighting (spor bilimi yüksek lisansı var, **rakip-sporcu kimliği yok** — biyomekanik referansı olarak değerli, teknik referansı olarak değil)

**TEYİT EDİLMEDİ — tabloya alınmadı:** ElasticSteel · FightCamp (side-kick bağlamında geçen) · Fight Vision · Howcast (genel eğitim sitesi, kimlik zayıf)

⚠️ **JabLab boks tarafını ilgilendiren uyarı:** "Precision Striking" kanalının Ramsey Dewey tarafından işletildiği **teyit edilemedi**. Dewey'nin kendi kimliği güçlü (aktif antrenör/hakem, çok branşlı), ama kanal-kişi bağı kurulamadı. Boks envanterinde bu kanalı kullanırken kimlik doğrulaması ayrıca yapılmalı → J-015 aday listesine şerh düşüldü.

## 5. Boşluklar ve sıradaki adım

| Boşluk | Aksiyon |
|---|---|
| **Side kick 1 kaynakta kaldı** | Ek tarama görevi (M-C-04 ≥3 kuralı sağlanmadan referans üretilmez) |
| Diz öğretimleri klinç bağlamında | Video-içi **solo segment** ayıklaması (provenance `segments` alanı tam bu iş için var) |
| Duruş genişliği farkı sayısallaşmadı | Hasat sonrası **ölçülecek** — kaynakta yok, bizim veriden çıkar |
| `frontFootLoadRatio` ölçüsü yok | `boxing@1.0.0 measures`'a eklenecek |

**Hasat sırası önerisi:** Muay Thai roundhouse + teep + dirsek (üçü de ≥3 kaynak + tam solo) ilk turda; side kick ve check **beklet**.
