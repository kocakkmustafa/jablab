# 🥊 CROSS — HASAT ÖNCESİ ÖLÇÜT DONDURMA (FAZ-0)

> **Yazıldığı an: hiçbir aday kaynağa BAKILMADI.** Bu belgenin tek işlevi budur —
> orkestratörün D17 uyarısı: *"önceden ilan edilmiş bir başarısızlık dalı, ancak
> tetiği adaylar görülmeden yazıldıysa gerçektir."* Aşağıdaki eşikler bu dosya
> commit'lendikten SONRA hiçbir adayın sonucuna göre gevşetilmez (D11 — taban
> gevşemez, ilkesi burada uygulanıyor).
>
> Yöntem **icat edilmedi** — `workspace/HASAT-TURU-HOOK-UPPERCUT.md`nin ölçülüp
> doğrulanmış metodolojisi CROSS'a uyarlandı (M-C-04, M-F-239). Farklı yer:
> hook'un ≤2 turluk penceresi yoktu, cross'un var (D17, bu belgenin §5'i).

## 1 · "Bağımsız eğitmen" tanımı

**Kimlik = EKRANDAKİ EĞİTMEN, kanal/marka adı DEĞİL** (M-F-239, hook'ta ölçülüp
doğrulandı — `ihifYbOBBHM` "ayrı eğitmen" sanılmıştı, gerçekte havuzdaki
Yankello'nun kendi ikinci kanalıydı). Uygulama:

1. Her aday video için **gösteren kişi** tespit edilir (yüz/beden + ses/isim
   geçen transkript ipucu) — kanal adı yalnız bir İPUCUDUR, KİMLİK DEĞİLDİR.
2. Aynı kişi birden fazla kanalda/videoda görünüyorsa → **TEK kimlik**, kaç
   video/kanalda geçtiğine bakılmaksızın.
3. **Yoğunlaşma denetimi** (M-F-239'un ikinci yarısı, hook'ta ölçüldü — "hiçbir
   marka konsensüsün çoğunluğunu vermiyor"): bulunan bağımsız kimliklerin
   **hiçbiri** nihai kümenin **yarısından fazlasını** aynı marka/kanal-ailesinden
   almamalı. Karşılanmazsa o küme "3 bağımsız" görünse bile GERÇEKTE bağımsız
   SAYILMAZ (Gravita'nın %72-tek-kaynak arızasının tekrarı).

## 2 · "Bulundu" tanımı — kanıt barı

Bir eğitmen aşağıdaki **DÖRDÜNÜ BİRDEN** geçmeden "bulundu" SAYILMAZ — hook'un
kendi dersi: *"'görünüyor' kelimesi kasıtlı; kanonik damga TAM KOŞUMDA gelir."*
Yalnız triyaj-temiz olmak yetmez.

1. **Netlik eşiği ≥ 40** (harvest_rig'in mevcut, teknikten-bağımsız metriği —
   hook'ta aynı eşikle ölçüldü, `coach_anthony` 39,2 ile bu eşikte REDDEDİLDİ).
2. **Transkript-doğrulanmış coaching-varlığı** — J-090'ın birinci-şahıs
   tekil/çoğul aile deseniyle ("I throw"/"we drive" sınıfı), yalnız
   başlık/açıklama zayıf-işaretiyle DEĞİL (hook'ta `Hy94qxbdtvI` bu ayrımla
   kazanıldı, `vlLmPtwSQlM` zayıf kaldı).
3. **TAM kanonik koşum** `romMode=active` + `eligible=True` üretir — STAGE
   kaydından, ÖZET alanından DEĞİL (hook'un 5.2 dersi: özet alanları bayatlar,
   `harvest.py`nin GERÇEK son koşumu kanonik kaynak).
4. **Malzeme yeterli derinlikte** — yalnız isim geçmesi/tek kısa klip yetmez;
   segment_punches'ın cross'u ayrıştırabileceği en az bir gerçek çalışma
   penceresi üretebilecek uzunluk/tekrar olmalı (kennyweldon hook'ta bu
   sebeple elendi: "`unknown` + malzeme ince").

## 3 · Sayısal eşikler (dondu)

| ölçüt | değer | kaynak |
|---|---|---|
| Bağımsız eğitmen tabanı | **≥3** | M-C-04 (aile-geneli, bağlayıcı) |
| Netlik eşiği | **≥40** | harvest_rig metriği, hook'ta doğrulandı |
| Yoğunlaşma tavanı | **tek marka nihai kümenin yarısından FAZLASI olamaz** | M-F-239, hook'ta ölçüldü |
| Malzeme yeterliliği | segment_punches'a en az 1 gerçek pencere üretecek uzunluk | hook'un kennyweldon reddi |

## 4 · Plan B tetiği — TAM OLARAK ne, ne zaman

**Tetik koşulu:** Aşağıdaki §5'teki pencere (≤2 hasat turu) TÜKENDİĞİNDE
§3'teki 4 kanıt barını BİRDEN geçen bağımsız kimlik sayısı **3'ün altındaysa**,
Plan B (PRD §2.0, jab-öncelikli daraltma) **OTOMATİK tetiklenir** — ayrı bir
onay/tartışma turu beklemeden. "3'e yakın ama tam değil" (ör. 2 tam + 1 kısmi,
hook'un ilk ölçümündeki gibi) **Plan B'yi tetiklemekten MUAF DEĞİLDİR** —
kısmi bir kanıt barını geçmemiş bağımsız kimlik SAYILMAZ.

**Turun bitiş koşulu (bir hasat turu ne zaman "tükendi" sayılır):**
Havuzdaki (§5.1) aday kaynakların TAMAMI ya (a) TAM kanonik koşumdan geçirildi
(kanıt barını geçti/geçmedi kaydı ile) ya da (b) triyaj aşamasında ADIYLA
elendi (netlik/malzeme/yinelenen-kimlik gerekçesiyle) — havuzda "bakılmadı/
sırada" durumunda kaynak KALMADIĞINDA tur biter. Bir turun ortasında "3 bulundu
gibi görünüyor, dur" denip tam koşum atlanmaz (§2 madde 3'ün ihlali olurdu).

## 5 · Pencere ve gevşetilemezlik

**§5.1 Aday havuzu (ölçülecek, henüz BAKILMADI):** hook/uppercut hasadının
ZATEN triyaj etmiş olduğu genel boks kanalları havuzu (precision_striking ·
yankello · myboxingcoach · marvin_cook · tony_jeffries · fightcamp ·
kennyweldon · coach_anthony) — bu kanalların çoğu temel teknikleri (jab/cross
dahil) de gösteriyor OLABİLİR, ama bu bir VARSAYIM, turu-1'in İLK işi bu
havuzun cross içeriğini GERÇEKTEN taşıyıp taşımadığını ölçmek. Havuz yetersiz
çıkarsa turu-1 İÇİNDE yeni kanal arama genişler (bu, pencereyi AŞMAZ — yalnız
kaynak keşfi, hâlâ tur-1).

**§5.2 Pencere:** en fazla **2 hasat turu** (D17). 2. turun sonunda §4'teki
eşik karşılanmamışsa Plan B kesindir.

**§5.3 GEVŞETİLEMEZ (D11):** Bu belgedeki dört sayı (§3 tablosu) ve iki turluk
pencere, commit'lendikten sonra hiçbir adayın sonucuna göre değiştirilmez.
Değiştirilmesi gerektiği düşünülürse bu KARAR ayrı bir DEFTER kaydıyla,
GÖRÜLEN adaylardan BAĞIMSIZ bir gerekçeyle (ör. harvest_rig'in kendisinde bir
kusur bulunması) ve orkestratör onayıyla olur — "adaylar az çıktı, eşiği
düşürelim" GEÇERSİZ bir gerekçedir.

---

**Mühür:** Bu belge commit'lendiği an F3'ün "Faz-0" kapanır. Hasat turu-1
bundan sonraki turda başlar ve YALNIZ bu belgedeki tanımları uygular.
