#!/usr/bin/env python3
"""DEFTER TAZELİĞİ — commit'te anılan ama deftere yazılmamış kayıtlar (J-225).

Desen Gravita'dan (`tools/defter_freshness.py`, `1d110be`) ADAPTE edildi,
icat edilmedi. Koordinatörün ilettiği üç tuzak burada da gömülü:

  ① Yalnız commit BAŞLIKLARI okunur (`%s`), gövde DEĞİL. Böylece bir
     sentinel/örnek dizge yapısal olarak taramaya karışamaz — Gravita'nın
     `G-999`u onun ilk taramasını şişirmişti.
  ② "Sözünü etmek ≠ kayıt": bir başlıkta J-numarası, o commit'in KAYIT
     kalemi olduğunu gösteren KONUMDA olmalı. (Bu, bu hattın J-221'de
     yazdığı kuralın kapıya gömülü hâli: *bir kavramdan SÖZ eden cümle, o
     kavramın BÖLÜMÜ değildir.*)
  ③ PAYDA HER ZAMAN YAZILIR — "0 gedik" cümlesi, kaç kaydın tarandığı
     bilinmeden okunamaz.

## ⚠️ HATTA GÖRE DEĞİŞEN ŞEY: KONUM — ve BU İKİ KEZ ÖLÇÜLDÜ

Koordinatörün uyarısı *"defterin BİÇİMİ hatta göre değişir"*. Ölçüldü:
**defter tek biçim** (tablo satırı; prose başlığı **0**) → Gravita'nın 47
yanlış-pozitif sebebi burada yok. Satır başında duran **6 düzyazı atfı**
tek tek okundu: *kayıt değil, atıf* — desen gevşetilmedi, öz-testte
sınanıyorlar.

🔴 **Ama aynı sınıf kusur COMMIT tarafında çıktı, ve ilk ölçümüm YANLIŞTI.**
Konvansiyonu **60 başlıkta** ölçüp *"JabLab sonda parantez kullanır"* diye
sonuca vardım. **225 başlıkta gerçek:** J taşıyan **148** · sonda **32** ·
**başta `J-NNN:` 83** (baskın!) · conventional **20**. İlk sürüm yalnız
sondakini tanıyordu → **kapsam %21**, ve o dar pencerede *"0 gedik"*
diyordu. Genişletilince **hemen gerçek bir gedik çıktı: `J-171`** (08-07'de
commit'lenmiş, deftere hiç geçmemiş).

→ ***Bir konvansiyon zamanla değişir; onu DAR bir pencerede ölçmek, en yeni
hâlini "tek hâl" sanmaktır.*** Ve *"temiz çıkmak, sistemin çalıştığını
değil, o güne kadar şansın yaver gittiğini gösterebilir"* (Lissom).

⛔ **Yanlış-pozitif çıkarsa deseni GEVŞETME** — o, ②'yi geri getirir:
*bir kapıyı yanlış-pozitiften kurtarmanın iki yolu var: deseni gevşetmek,
ya da ölçtüğü şeyi makine-okur kılmak. Birincisi kapıyı ZAYIFLATIR,
ikincisi VERİYİ güçlendirir.*

## NE ÖLÇMEZ

Bu kapı *"kayıt yazıldı mı"*yı ölçer, **içeriğinin doğru olduğunu değil**.
Ve J-numarası TAŞIMAYAN commit'leri gedik saymaz — onlar ayrı bir soru
(bkz. çıktıdaki `atıfsız` sayısı, bilgi olarak basılır).
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
DEFTER = APP.parent / "workspace" / "DEFTER.md"

# ② KONUM ÖLÇÜTÜ — ÜÇ ölçülmüş konum (gevşetme DEĞİL, sayım).
#
# 🔴 İLK HÂLİ YALNIZ SONDAKİ PARANTEZİ TANIYORDU ve KAPSAMI %21'Dİ.
# Sebebi bir ölçüm hatasıydı: konvansiyonu **60 başlıkta** ölçüp sonuca
# vardım. 225 başlıkta gerçek şu:
#     J-numarası taşıyan : 148
#     sonda parantez     :  32   ← ilk hâlin gördüğü
#     başta "J-NNN:"     :  83   ← GÖRMEDİĞİ (baskın gelenek!)
#     conventional       :  20   ← GÖRMEDİĞİ
# Yani commit geleneğim ZAMAN İÇİNDE DEĞİŞMİŞ, ve dar pencerede ölçmek
# yeni geleneği "tek gelenek" sanmama yol açtı. Lissom'un defterinde iki
# biçim vardı; bende COMMIT tarafında üç biçim var — aynı sınıf, karşı yaka.
#
# ⛔ Bu bir GEVŞETME değil: üç desenin üçü de KONUM-ÇAPALI (başlangıç,
# conventional kapsam, ya da sondaki parantez). Cümle ORTASINDA geçen bir
# numara hâlâ sayılmıyor — "sözünü etmek ≠ kayıt" korunuyor.
# Herhangi bir yerde J-numarası ANAN başlık — A/B ayrımı için (J-227).
_ANY_J = re.compile(r"J-\d+")

_POSITIONS = (
    re.compile(r"^(J-\d+(?:/\d+)*)\b"),              # J-174: …
    re.compile(r"^[a-z]+\((J-\d+(?:/\d+)*)\)"),      # feat(J-072): …
    re.compile(r"\((J-\d+(?:/\d+)*)[^)]*\)\s*$"),   # … (J-224) · (J-224 yan)
)


def _record_ref(title: str) -> str | None:
    """Başlıkta KAYIT KONUMUNDA bir J numarası varsa döndürür."""
    for pat in _POSITIONS:
        m = pat.search(title)
        if m:
            return m.group(1)
    return None
# Defterdeki kayıt satırı — TEK biçim (ölçüldü: prose başlığı 0)
ROW = re.compile(r"^\|\s*(J-\d+(?:/\d+)*)\s*\|")

# ══════════════════════════════════════════════════════════════════════
# KATMAN ÇAPASI — kayıt satırı BİÇİMLE değil, TABLO ÜYELİĞİYLE tanınır
#
# 🔴 İlk sürüm bütün DOSYAYI tarıyor ve `^| J-n |` biçimli HER satırı
# kayıt sayıyordu. Ölçüldü (2026-08-12): defterde **iki** tablo var —
# 6 sütunlu KAYIT tablosu (`| ID | Tür | Şiddet | Bulgu | Durum |
# Kapanış kanıtı |`) ve 2 sütunlu ANLATI tablosu (`| # | ne |`,
# *"bu vardiyada kapanan dört kayıt"*). Anlatı satırları da desene
# uyuyordu ⇒ kapı **`J-095`i YAZILI sanıyordu** (`True`), oysa kayıt
# tablosunda satırı **YOK** ve **üç commit onu anıyor** (biri kanonik
# `J-095:` konumunda).
#
# > ***Bir kapının güvencesi, GÖRDÜĞÜ KATMANLA sınırlıdır.*** *"Eksik
# > kayıt 0"* hiçbir zaman *"her numara bir KAYITTIR"* demiyordu; yalnız
# > *"her numara KAYIT BİÇİMLİ bir satırda geçiyor"* diyordu.
#
# 📌 Bu, yukarıdaki ② kuralının (*sözünü etmek ≠ kayıt*) **dördüncü**
# biçimi — ve en sinsisi, çünkü öncekiler (commit gövdesi · kod yorumu ·
# config `_why`) kayda BENZEMİYORDU; bu, **kaydın biçimini taşıyor.**
#
# ⚠️ AYIRT EDİCİ ÖLÇÜLDÜ, TAHMİN EDİLMEDİ — iki aday sınandı:
#   · **hücre sayısı** → 🔴 ELENDİ. Kayıt satırları 8/9/10/11/12/13
#     hücreli (metin içinde kaçaksız `|`), anlatı 4. Bir `>=8` süzgeci
#     *bugün* çalışır ama bir **biçim sezgisidir**; ilk kısa kayıt
#     satırında sessizce düşer. (Aynı kaçaksız-`|` tuzağı J-234'te
#     envanteri 174/175 yapmıştı.)
#   · **tablo üyeliği** → ✅ YAPISAL, seçilen bu. Kayıt gövdesi =
#     6-sütunlu başlığın ayıracından sonraki **kesintisiz `|` bloğu**.
#     Ölçüm: gövde 235 satır, **hepsi** `| J-n`, anlatı tablosu blok
#     **dışında**, gövdede `| J-n` olmayan satır **0**.
# ══════════════════════════════════════════════════════════════════════
RECORD_HEADER = "| ID | Tür |"

# ⚠️ ID HÜCRESİ DE GENİŞLETİLDİ, ve sebebi ölçüldü: eski `J-\d+(/\d+)*`
# deseni **iki GERÇEK kaydı** düşürüyordu — `J-191 (devam)` ve `J-194b`.
# Sayaç 235 yerine 233 diyordu ve fark **hiçbir yerde görünmüyordu.**
# → *Bir kimliğin biçimi zamanla zenginleşir; onu ilk gördüğü biçimle
#   sabitleyen sayaç, sonradan gelenleri SESSİZCE atar.*
ID_CELL = re.compile(r"^\|\s*(J-\d[^|]*?)\s*\|")


def record_rows() -> list[str]:
    """KAYIT TABLOSUNUN GÖVDESİ — anlatı tablosu bilerek DIŞARIDA."""
    lines = DEFTER.read_text(encoding="utf-8").splitlines()
    start = next(
        (i for i, ln in enumerate(lines) if ln.startswith(RECORD_HEADER)), None
    )
    if start is None:                       # başlık yoksa SESSİZ GEÇME
        raise SystemExit(
            f"KAYIT TABLOSU BAŞLIĞI BULUNAMADI ({RECORD_HEADER!r}) — "
            "defterin yapısı değişmiş; kapı ne taradığını bilmiyor"
        )
    out: list[str] = []
    for ln in lines[start + 2:]:            # +2: başlık + `|---|` ayıracı
        if not ln.startswith("|"):
            break
        out.append(ln)
    return out


def record_ids() -> list[str]:
    """Gövdedeki ID hücreleri — AYNEN, normalize edilmeden.

    Benzersizlik çapası bunu kullanır: `J-191` ile `J-191 (devam)`
    **farklı** hücrelerdir (kasıtlı devam), `J-105` ile `J-105`
    **aynıdır** (çakışma). *Ayrımı kural icat ederek değil, yazarın
    yazdığı dizgeye bakarak yapıyoruz.*
    """
    return [m.group(1) for ln in record_rows() if (m := ID_CELL.match(ln))]


def defter_numbers() -> set[str]:
    """Deftere yazılmış J numaraları. Birleşik kayıt (J-185/186) AÇILIR."""
    out: set[str] = set()
    for raw in record_ids():
        for num in re.findall(r"\d+", raw):   # "J-185/186" → 185, 186
            out.add(f"J-{num}")
    return out


def commit_numbers(limit: int) -> tuple[dict[str, str], int, int]:
    """Başlıklardan (yalnız `%s`) J numaraları.

    ⚠️ ÜÇ SAYI DÖNER ÇÜNKÜ İKİ AYRI BİRİM VAR (J-226) — ilk sürüm bunları
    karıştırıyordu: `atıflı` **benzersiz NUMARA** sayıyordu, `atıfsız` ise
    **BAŞLIK**, ve ikisi yan yana bir BÖLME gibi basılıyordu. Toplamıyordu:
    `121 + 91 = 212`, oysa taranan `226`. Aradaki **14**, aynı numaraya
    birden fazla commit atan başlıklardı (19 numara 2-3 commit'li).

    > **Bir payda YAZILMIŞ olabilir ve yine de TOPLAMIYOR olabilir — payda
    > yazmak, paydayı DENETLEMEK değildir.** Ve iki sayı yan yana
    > basıldığında, okuyan onların AYNI BİRİMDE olduğunu varsayar.

    ⚠️ İKİ SAYAÇ DA BAĞIMSIZ SAYILIR, biri ötekinden TÜRETİLMEZ. İlk
    düzeltmemde `unattributed = scanned - attributed` yazmış, sonra
    `attributed + unattributed == scanned` diye "denetlemiştim" — yapı
    gereği HER ZAMAN doğru olan bir kontrol. Mutasyonla ölçüldü: sayacı
    bozdum, **kapı ötmedi.**

    > ***Türetilmiş bir sayıyı kaynağına karşı denetleyemezsin: aritmetik
    > kimlik bir ÖLÇÜM değildir.*** Bugün üç kez "vakum-doğru test"
    > yakaladım; dördüncüsü kendi payda denetimimdi.

    Dönüş: `({numara: ilk başlık}, atıflı, atıfsız, anan, taranan)` — dördü
    de BAŞLIK birimi; `found` ise NUMARA birimi (ayrı birim, ayrı basılır).
    """
    titles = subprocess.run(
        ["git", "-C", str(APP), "log", f"-{limit}", "--format=%s"],
        capture_output=True, text=True, check=True,
    ).stdout.splitlines()
    found: dict[str, str] = {}
    attributed = 0
    unattributed = 0          # ⚠️ BAĞIMSIZ sayılır, TÜRETİLMEZ (aşağı bak)
    mentioning = 0            # ⚠️ O DA BAĞIMSIZ — A/B ayrımı için (J-227)
    for t in titles:
        if _ANY_J.search(t):
            mentioning += 1
        raw = _record_ref(t)
        if raw is None:
            unattributed += 1
            continue
        attributed += 1
        head, *rest = raw.split("/")
        for num in [head] + [f"J-{x}" for x in rest]:
            found.setdefault(num, t)
    return found, attributed, unattributed, mentioning, len(titles)


# ══════════════════════════════════════════════════════════════════════
# YÖN-2 — "deftere YAZILI ama hiçbir commit ANMIYOR" (J-243, A6)
#
# Kapı 2026-08-13'e kadar TEK YÖNLÜYDÜ: yalnız `referenced − written`.
# Ters yön ölçüldü: **109 numara / 110 satır** (iki birim, aşağıda ayrı
# basılır). Ham hâliyle kırmızı yapmak YANLIŞ olurdu — bir `bulgu` ya da
# `karar` kaydının commit üretmemesi kusur değil, DOĞASIDIR.
#
# ## BİRİM NEREDEN GELDİ — iki kardeş, iki farklı birim, ve İKİSİ DE ALINMADI
#
# Gravita birimi (`Tür` sütunu) ve Lissom birimi (`Kapanış kanıtı` bir KOD
# dosyası anıyor mu) bu ağaçta İKİSİ DE ölçüldü:
#     ADAY-A → 34 kırmızı · ADAY-B → 26 kırmızı · KESİŞİM yalnız **13**
# ⇒ İki birim aynı şeyi ÖLÇMÜYOR. Birini kopyalasaydım sonuç bir SAYI olurdu,
#   bir ölçüm değil.
# > ***AKTARILABİLİR OLAN DESEN DEĞİL KAVRAMDIR*** — ve ayrışma okununca
# > her ikisinin de bu ağaca özgü yanlış-pozitifi göründü:
#   · ADAY-B körlüğü YAPISAL: bu defterin `Kapanış kanıtı` sütunu uzun bir
#     ANLATI; bir `bulgu` kaydı doğal olarak `engine_test.dart` diye
#     BULGUNUN YERİNİ anar, DEĞİŞEN DOSYAYI değil. (Lissom'un alanı kısaydı.)
#   · ADAY-A körlüğü: `görev` kayıtlarının bir kısmı kurucu-kapılı RAPORLA,
#     plan dokümanıyla ya da BAŞKA BİR DEPODA kapanmış.
#
# ## KATMANLAR — hepsi bu defterin KENDİ sütunlarından türedi
#
#   ham 110 satır
#     − ① `Durum` AÇIK        → borç YOK: iş henüz yapılmamış     (37)
#     − ② `Tür` kod İDDİA ETMİYOR → bulgu/karar/ölçüm commit üretmez (44)
#     − ③ kanıtta ÇÖZÜLEN SHA → ikinci provenans kanalı            (20)
#     = 9 → muaf 3 → **GEDİK 0**
#
# 🔴 ①'i bulmam bir ÖZ-KUSUR düzeltmesiydi: önce yalnız `Tür`e bakıyordum ve
# `açık` kayıtları gedik sayıyordum. *Bir AÇIK kaydın commit'i yoktur çünkü
# İŞİ YAPILMAMIŞTIR.* Sütun oradaydı; bakmayan bendim.
#
# ⭐ ③ bu ağacın kendi bulgusu: 34 "öksüzün" **20'si hiç öksüz değildi** —
# kaydın kendi kapanış kanıtı GERÇEK bir commit SHA'sı anıyor ve o SHA
# çözülüyor. Kapı bunu göremiyordu çünkü yalnız COMMIT BAŞLIĞI kanalını
# okuyordu. Kayıt→commit bağı bu defterde İKİ kanaldan kuruluyor.
#
# 🪤 VE BU ÖLÇÜM BENİ AZ KALSIN YANLIŞ BULGUYA GÖTÜRÜYORDU: ilk koşumda 3 SHA
# "çözülmedi" çıktı ve *"provenans kusuru"* yazacaktım. Sebep: `motion-core`
# bir git deposu DEĞİL — depo `motion-core/lib/` altında. Aracım oraya
# YAPISAL OLARAK bakamıyordu.
# > ***BİR ARACIN BULAMAMASI, ARANAN ŞEYİN YOKLUĞU DEĞİLDİR*** — ve fark,
# > `❌` ile `⛔ ÖLÇÜLEMEDİ` arasındaki farktır. Bu yüzden aşağıda depo
# > erişilemezse SHA "çözülmedi" DEĞİL, `ölçülemedi` sayılır.
#
# ## ⛔ ARTIK RİSK — ADIYLA (kapatılmadı, KAPATILAMAZ)
#
#   ① **Kayıt KENDİNİ sınıflandırıyor.** ① ve ② kaydın kendi `Durum`/`Tür`
#      beyanına dayanır; `Tür=bulgu` yazan bir kayıt bu kapıdan geçer.
#      Kapı YAZIM DİSİPLİNİNİ ölçmez, YAZILANI ölçer.
#   ② **③ commit'in VAR olduğunu doğrular, DOĞRU commit olduğunu değil.**
#      Çözülen bir SHA "bu iş orada kapandı" iddiasını KANITLAMAZ; yalnız
#      iddianın gerçek bir commit'e işaret ettiğini gösterir.
#   ③ **`workspace/` sürüm kontrolü DIŞINDA** (git kökü `jablab/app`).
#      Ürünü DEFTER/PROGRESS olan bir kaydın commit'i OLAMAZ — muaf kümenin
#      iki kalemi tam olarak bu.
# ══════════════════════════════════════════════════════════════════════

# 🔴 TÜRKÇE KİP TUZAĞI: Python `.lower()` `İ`de KÖRDÜR — `İÇERİK`.lower()
# birleşen noktalı `i̇çerik` üretir ve `içerik` ile EŞLEŞMEZ. Ölçüldü: ham
# taramada belirteç gerçekten `'i̇çeri̇k'` olarak çıktı.
def _tr_lower(s: str) -> str:
    return s.replace("İ", "i").replace("I", "ı").lower()


def _norm(s: str) -> str:
    """Süsü at — `**`, backtick, emoji. Kelimeleri BIRAK."""
    s = re.sub(r"\*\*|\*|`", "", s)
    return re.sub(r"[^\w\s+ığüşöçİĞÜŞÖÇ—-]", " ", s).strip()


def tur_tokens(cell: str) -> set[str]:
    """`Tür` hücresini belirteçlere ayır. `—` ve `(` SONRASI atılır (şerh)."""
    t = _norm(cell).split("—")[0].split("(")[0]
    return {_tr_lower(x).strip() for x in re.split(r"[+/,]", t) if x.strip()}


# KOD İDDİA EDEN belirteçler — bu defterde GEÇEN 36 belirtecin tamamı
# sınıflandırıldı (tam fonksiyon; `_UNKNOWN` yolu aşağıda).
IDDIA_EDER = {
    "görev", "düzeltme", "düzelt", "kapı", "betik", "genişletme",
    "öz-düzeltme", "hüküm uygulandı", "denetim", "sabotaj", "içerik",
}
IDDIA_ETMEZ = {
    "bulgu", "ölçüm", "karar", "risk", "hüküm", "ders", "envanter",
    "sözleşme", "yöntem", "kayıt", "kural", "sınıflandırma", "öz-kusur",
    "öz-denetim", "kusur", "eksik", "ürün", "tasarım cevabı", "p0",
    "aile p0", "sınıf değişimi", "sessiz-yeşil bulgusu", "hüküm düzeltmesi",
    "3 ölçüm kusuru", "kapı  2", "kapı 2",
}
# ⚠️ TANINMAYAN BELİRTEÇ **İDDİA EDER SAYILIR** — sessizce muaf DEĞİL.
# Sebebi: yeni bir `Tür` kelimesi yazıldığı gün kapı SUSARSA, muafiyet
# kümesi kimse fark etmeden büyür. *Bilinmeyen, kapıyı KONUŞTURMALIDIR.*

_DURUM_ACIK = re.compile(r"\baçık\b|koordinatörde|kurucuda|sırada|devred", re.I)
_DURUM_KAPALI = re.compile(
    r"kapan|kapalı|düzeltildi|düzelti̇ldi̇|reddedil|rapor edildi", re.I
)
_SHA = re.compile(r"`([0-9a-f]{7,40})`")

# ── MUAF KÜME — ⚠️ **SABİT TABAN**, ve KAPININ KAYNAĞINDA (izlenen dosya).
#
# 🔴 NEDEN DEFTER'DE DEĞİL: `workspace/` sürüm kontrolü DIŞINDA. Muafiyet
# oraya bir işaretle yazılsaydı, bir sonraki oturum kendini **hiçbir iz
# bırakmadan** muaf edebilirdi.
# > ***BİR TABANI HAREKET ETTİREBİLEN KAPI, ÖLÇTÜĞÜ BORCU DA HAREKET ETTİRİR.***
# Burada büyümesi bir KOD DEĞİŞİKLİĞİ + öz-test güncellemesi gerektirir.
MUAF: dict[str, str] = {
    "J-086": "kaydın KENDİSİ söylüyor: 'yama atıldı; hiçbir şey push edilmedi' "
             "— commit tasarımı gereği YOK",
    "J-236": "ürünü `workspace/DEFTER.md` (4 hücre) — depo DIŞINDA, "
             "commit'lenemez",
    "J-238": "ürünü tazelik kapısının KOŞUMU + DEFTER kaydı — depo DIŞINDA",
}


def siniflandir(tur: str, durum: str, kanit: str, sha_cozer) -> str:
    """TEK kaydın hükmü. Saf fonksiyon ⇒ sentetik veriyle sınanabilir.

    🪤 Bilerek SAF: canlı bir kusura dayanan pozitif kontrol, kusur
    düzelince yanlış alarma döner (bu dosyada iki kez ısırdı).
    """
    d = _norm(durum)
    acik, kapali = bool(_DURUM_ACIK.search(d)), bool(_DURUM_KAPALI.search(d))
    if not (acik or kapali):
        return "okunamadı"          # ⛔ SESSİZCE "kapalı" VARSAYMA
    if acik and not kapali:
        return "açık"               # ① iş yapılmamış — borç yok
    # ② bulgu/karar/ölçüm — AMA yalnız SINIFLANDIRILMIŞ belirteçler muaftır.
    #
    # 🔴 İLK YAZIMIMDA BU SATIR `if not (tokens & IDDIA_EDER)` İDİ ve tanınmayan
    # her kelimeyi SESSİZCE muaf ediyordu — üstelik hemen üstündeki yorum
    # bunun TERSİNİ iddia ediyordu. Öz-test yakaladı (`y2-bilinmeyen-tür-ötüyor`).
    # > ***BİR YORUMUN İDDİA ETTİĞİ KORUMA, KODDA VAR OLDUĞUNUN KANITI DEĞİLDİR***
    # > — ve bunu bu gece BEN adlandırmıştım (`4.14`). Teşhis, bağışıklık değil.
    tokens = tur_tokens(tur)
    if not (tokens & IDDIA_EDER) and not (tokens - IDDIA_ETMEZ):
        return "iddia-etmez"
    for s in _SHA.findall(kanit):
        if sha_cozer(s):
            return "izli"           # ③ ikinci provenans kanalı
    return "gedik"


CORE = APP.parent.parent / "motion-core" / "lib"   # ⚠️ `lib/` — depo ORADA


def _cells(row: str) -> list[str]:
    """Satırı hücrelere ayır — **KAÇIRILMIŞ boruya saygı duyarak.**

    🔴 Naif `split("|")` üç satırda YANLIŞ hücreyi `Durum` sanıyordu. Sebep
    tahmin edilmedi, OKUNDU: `errorClass: form\\|setup` ve
    `toleranceSource: floor\\|variance\\|ceiling` — yazar boruyu markdown
    için KAÇIRMIŞ, ayırıcı saymamış. Kapı ise saymıştı.
    > ***BİR AYIRICI, KAÇIŞ DİZGESİ OKUNMADAN AYIRICI DEĞİLDİR.***
    """
    return re.split(r"(?<!\\)\|", row)


def _sha_resolver():
    """`(çözer, erişilemeyen_depolar)` — depo YOKSA "çözülmedi" DEMEZ.

    🪤 Bu ayrımı bir yanlış bulguya bir adım kala öğrendim: `motion-core`
    kökü git deposu değil (depo `motion-core/lib/`), ve üç SHA "çözülmedi"
    çıkmıştı. *Bir aracın bulamaması, aranan şeyin yokluğu değildir.*
    """
    repos, unreachable = [], []
    for path in (APP, CORE):
        ok = subprocess.run(
            ["git", "-C", str(path), "rev-parse", "--git-dir"],
            capture_output=True, text=True,
        ).returncode == 0
        (repos if ok else unreachable).append(path)
    cache: dict[tuple[str, str], bool] = {}

    def resolve(sha: str) -> bool:
        for r in repos:
            key = (str(r), sha)
            if key not in cache:
                p = subprocess.run(
                    ["git", "-C", str(r), "cat-file", "-t", sha],
                    capture_output=True, text=True,
                )
                cache[key] = p.returncode == 0 and p.stdout.strip() == "commit"
            if cache[key]:
                return True
        return False

    return resolve, unreachable


def yon_iki(referenced: set[str]) -> dict:
    """YÖN-2 — deftere yazılı ama hiçbir commit anmıyor.

    ⚠️ İKİ BİRİM AYRI DÖNER: `numara` (küme farkı) ve `satır` (tablo).
    Eşit DEĞİLLER ve olmaları da gerekmiyor — `J-194` ile `J-194b` **iki
    satır, tek numara**. İlk ölçümümde 109 ve 110 yan yana çıktı; ikisini
    tek sayı sanmak tam olarak bu dosyanın J-226'da düştüğü tuzaktı.
    """
    written = defter_numbers()
    oksuz_num = written - referenced
    resolve, unreachable = _sha_resolver()
    kova: dict[str, list[str]] = {
        "açık": [], "iddia-etmez": [], "izli": [], "gedik": [], "okunamadı": []
    }
    aday = 0
    for ln in record_rows():
        c = _cells(ln)
        ident = c[1].strip()
        if not ({f"J-{n}" for n in re.findall(r"\d+", ident)} & oksuz_num):
            continue
        aday += 1
        kova[siniflandir(c[2], c[-3], c[-2], resolve)].append(ident)
    # ══════════════════════════════════════════════════════════════════
    # ⛔ UÇUŞTAKİ KAYIT — kapı kendi ürününü CEZALANDIRMASIN (J-245)
    #
    # 🔴 KUSUR CANLI ÖLÇÜLDÜ: `J-244` kaydı yazıldı, commit mesajı onu
    # anıyordu, ama **pre-commit kapısı commit'ten ÖNCE koşuyor** ⇒ o anda
    # kayıt "yazılı ama anılmıyor" ve kapı **commit'i reddetti**. Yani kapı,
    # kendisini tatmin edecek commit'in oluşmasını engelliyordu.
    # > ***BİR KAPI KENDİ ÜRÜNÜNÜN İLERLEMESİNİ CEZALANDIRIYORSA,
    # > ÜRÜNÜN DÜŞMANIDIR.***
    #
    # 🪤 Ve `J-243` bunu **TESADÜFEN** aşmıştı: kapanış kanıtında BAŞKA
    # kayıtların SHA'larını andığı için ③ onu `izli` saydı. Yani bu dosyada
    # adıyla yazılı artık risk (ii) — *"③ commit'in VAR olduğunu doğrular,
    # DOĞRU commit olduğunu değil"* — bir turu sessizce kurtardı ve kusuru
    # bir tur GİZLEDİ. *Bir kusurun bir kez fark edilmemesi, o kusurun
    # yokluğu değil; onu maskeleyen ikinci bir kusurun kanıtıdır.*
    #
    # ⚠️ DÜZELTME DAR TUTULDU — "en yeniyi affet" DEĞİL:
    # Yalnız **en yeni ATIFLI kaydın ÖTESİNDEKİ** numaralar uçuşta sayılır.
    # Eski bir gedik hâlâ kırmızıdır; sayaç geriye doğru KÖR DEĞİLDİR.
    # (Aksi hâlde "her zaman en yeni kayıt muaf" derdik ve bir oturum
    #  kayıtları sürekli tazeleyerek borcunu SONSUZA KADAR öteleyebilirdi.)
    def _no(s: str) -> int:
        return int(re.findall(r"\d+", s)[0])

    son_atifli = max((_no(n) for n in referenced), default=0)
    ucusta = [i for i in kova["gedik"] if _no(i) > son_atifli]
    gedik = [
        i for i in kova["gedik"] if i not in MUAF and i not in ucusta
    ]
    kova["uçuşta"] = ucusta
    return {
        "numara": len(oksuz_num), "satır": aday, **kova,
        "muaf_uygulanan": [i for i in kova["gedik"] if i in MUAF],
        "gedik_net": gedik, "erişilemeyen_depo": unreachable,
        "son_atıflı": son_atifli,
    }


def self_test() -> bool:
    """İKİ YÖNLÜ öz-test — kapı hem ötmeli hem susmalı."""
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        if got != want:
            print(f"  ÖZ-TEST DÜŞTÜ [{name}]: {got!r} != {want!r}")
            ok = False

    # ② sözünü etmek ≠ kayıt
    # ÜÇ ÖLÇÜLMÜŞ KONUM — üçü de bu depoda GERÇEKTEN kullanılıyor
    check("sonda-parantez", _record_ref("kapı: bir şey (J-224)"), "J-224")
    check("sonda-ekli", _record_ref("düzelt: x (J-224 yan)"), "J-224")
    check("başta", _record_ref("J-174: splash yer tutucu"), "J-174")
    check("conventional", _record_ref("feat(J-072): emülatör smoke"), "J-072")
    # ② sözünü etmek ≠ kayıt — ORTADA geçen numara sayılmaz
    check("ORTADA-anma", _record_ref("kayıt notu artık J-224 diyor"), None)
    check("birleşik", _record_ref("kayıt: iki şey (J-185/186)"), "J-185/186")
    # defter satırı biçimi
    check("defter-satırı", bool(ROW.match("| J-224 | ders | P0 | … |")), True)
    check("defter-prose", bool(ROW.match("## J-224 bir şey")), False)

    # ⭐ KATMAN ÇAPASI — İKİ YÖNLÜ (J-237)
    #
    # ÖTMELİ yönü: anlatı satırı kayıt SAYILMAMALI. Bunu dizgeyle değil,
    # GERÇEK dosyayla sınıyoruz — çünkü kusur tam olarak "desen doğruydu,
    # KAPSAM yanlıştı"tı ve bir dizge fixture'ı o kapsamı taklit edemez.
    body = record_rows()
    check("gövde-dolu", len(body) > 200, True)
    check("gövde-hepsi-kayıt", all(ID_CELL.match(ln) for ln in body), True)
    # Anlatı tablosu GERÇEKTEN dışarıda mı.
    #
    # 🪤 İLK SÜRÜM BUNU `"J-095" not in defter_numbers()` DİYE SINADI ve
    # **kusur kapanınca kontrol ÖLDÜ** — J-095'e gerçek kayıt yazıldığı an
    # öz-test kırmızıya döndü, oysa çapa kusursuz çalışıyordu.
    # > ***CANLI BİR KUSURA DAYANAN POZİTİF KONTROL, KUSUR DÜZELİNCE
    # > YANLIŞ ALARMA DÖNÜŞÜR*** — kontrol, kusurun VARLIĞINI değil,
    # > mekanizmanın DAVRANIŞINI ölçmeli.
    # Kalıcı biçim: dosyada `| J-n` biçimli AMA gövde DIŞINDA satır var mı,
    # ve çapa onları gerçekten dışarıda tutuyor mu. (Anlatı tablosu silinse
    # bile bu kontrol anlamlı kalır: o zaman "dışarıda satır 0" olur ve
    # aşağıdaki ikinci `check` kendiliğinden konuyu haber verir.)
    raw = DEFTER.read_text(encoding="utf-8").splitlines()
    body_set = set(body)
    outside = [ln for ln in raw if ID_CELL.match(ln) and ln not in body_set]
    check("gövde-dışı-satır-VAR", len(outside) > 0, True)  # bugün: anlatı ×4
    check(
        "gövde-dışı-hiçbiri-gövdede-değil",
        any(ln in body_set for ln in outside),
        False,
    )
    # SUSMALI yönü: gövdedeki gerçek kayıtlar hâlâ görülüyor. (Çapa fazla
    # dar olsaydı burası düşerdi ve kapı 235 kaydı birden "eksik" sayardı.)
    for probe in ("J-001", "J-094", "J-191", "J-194", "J-236"):
        check(f"gövde-içeriyor-{probe}", probe in defter_numbers(), True)

    # ⭐ GENİŞLETİLMİŞ ID HÜCRESİ — düşen iki kayıt geri geldi mi
    cells = record_ids()
    check("satır==hücre", len(cells), len(body))
    for suffixed in ("J-191 (devam)", "J-194b"):
        check(f"ekli-ID-{suffixed}", suffixed in cells, True)
    check("eski-desen-bunu-kaçırıyordu",
          bool(ROW.match("| J-194b | genişletme |")), False)

    # ⭐ BENZERSİZLİK ÇAPASI — İKİ YÖNLÜ
    def clash(seq: list[str]) -> list[str]:
        d: dict[str, int] = {}
        for x in seq:
            d[x] = d.get(x, 0) + 1
        return sorted(k for k, v in d.items() if v > 1)

    # ÖTMELİ — aynı ID iki kez (gerçek hâl: J-105)
    check("çakışma-ötüyor", clash(["J-105", "J-104", "J-105"]), ["J-105"])
    # 🪤 AYNI KUSUR BURADA DA VARDI: ilk sürüm `clash(cells) == ["J-105"]`
    # diyordu — yani **o günkü kusurun kendisini** bekliyordu. J-105
    # `(kapanış)` ekini alınca öz-test kırmızıya döndü, oysa çapa doğru
    # çalışıyordu. Bugün bu tuzağa **iki ayrı kontrolde** düştüm.
    # > *Bir kontrol, düzeltilmesini istediğin şeyi BEKLİYORSA, düzeltme
    # > geldiği gün seni cezalandırır.* Beklenen hâl DÜZELMİŞ hâldir;
    # > kapının ötme yeteneği ise SENTETİK veriyle sınanır (üstteki satır).
    check("gerçek-defterde-çakışma-YOK", clash(cells), [])
    # SUSMALI — kasıtlı devam AYNI ID değildir; çapa bunu çakışma saymamalı
    check("devam-susuyor", clash(["J-191", "J-191 (devam)", "J-194b"]), [])

    # ③ TABAN TEMİZ Mİ — Gravita'nın 47'yi yakalayan sorusu
    nums = defter_numbers()
    check("defter-dolu", len(nums) > 100, True)
    for probe in ("J-001", "J-224"):
        check(f"defter-içeriyor-{probe}", probe in nums, True)
    check("defter-uydurma", "J-9999" in nums, False)

    # ⭐ PAYDA ARİTMETİĞİ — payda YAZMAK, paydayı DENETLEMEK değildir (J-226).
    _ref, _att, _un, _men, _scan = commit_numbers(400)
    # İki sayaç BAĞIMSIZ; bu yüzden toplamları gerçek bir iddiadır.
    check("payda-toplamı", _att + _un, _scan)
    check("taranan-gerçek", _scan <= 400, True)
    check("birim-ayrı", _att >= len(_ref), True)  # başlık ≥ benzersiz numara
    check("sayaçlar-dolu", _att > 0 and _un > 0, True)
    # A/B AYRIMI (J-227): ikisi BAĞIMSIZ sayılır, biri ötekinden türetilmez.
    # Eşit olmaları meşrudur (226'da ikisi de 14'tü) — ama aynı şey
    # olmadıkları için kapı onları AYRI basar.
    check("anan >= çapalı", _men >= _att, True)
    check("çapalı >= benzersiz", _att >= len(_ref), True)

    # ⭐ KENDİ ÖLÇÜLMÜŞ KİRLENME RİSKİM — Gravita'nın sentinel testi
    # KOPYALANMADI (o riski ölçtüm: bu depoda `J-9xx` yalnız BU dosyada
    # geçiyor, deftere ya da başlığa karışamaz). Onun yerine benim GERÇEK
    # riskim sınanıyor: DEFTER'de satır başında duran **düzyazı atıfları**
    # (ölçüldü: 6 satır — "**J-091 sonrası tek mühür kaydı.**" gibi).
    # Bunlar KAYIT DEĞİL; ROW onları saymamalı.
    # > Bir öz-testi kopyalamak, koruduğu RİSKİ de devraldığını varsaymaktır.
    for prose in (
        "**J-091 sonrası tek mühür kaydı.** Bu vardiyanın tam dökümü",
        "3. analiz başlamamışken çıplak \"0\" — (J-096)",
    ):
        check(f"düzyazı-atıf-sayılmıyor[{prose[:14]}]", bool(ROW.match(prose)), False)

    # ══════════════════════════════════════════════════════════════════
    # ⭐ YÖN-2 SINIFLANDIRICI — SENTETİK veriyle, İKİ YÖNLÜ (J-243)
    #
    # `siniflandir` SAF olduğu için canlı deftere hiç dokunmadan sınanır.
    # 🪤 Bu dosya iki kez şu tuzağa düştü: pozitif kontrol O GÜNKÜ KUSURU
    # bekliyordu ve kusur düzelince kontrol yanlış alarma döndü. Sentetik
    # girdi o bağı KESER — kontrol MEKANİZMAYI ölçer, defterin hâlini değil.
    # ══════════════════════════════════════════════════════════════════
    yok = lambda _s: False          # noqa: E731 — hiçbir SHA çözülmez
    var = lambda _s: True           # noqa: E731 — her SHA çözülür

    # ÖTMELİ — kapalı + kod iddia eden + izsiz = GEDİK
    check("y2-gedik", siniflandir("görev", "**kapalı**", "bir kanıt", yok), "gedik")
    # SUSMALI ① — AÇIK kaydın borcu yok (bu katmanı bulmam öz-kusur düzeltmesiydi)
    check("y2-açık-susuyor", siniflandir("görev", "açık", "bir kanıt", yok), "açık")
    # SUSMALI ② — bulgu/karar commit üretmez
    for t in ("bulgu", "**karar**", "risk", "ölçüm"):
        check(f"y2-iddia-etmez[{t}]",
              siniflandir(t, "kapandı", "bir kanıt", yok), "iddia-etmez")
    # SUSMALI ③ — kanıtta ÇÖZÜLEN SHA varsa izli
    check("y2-izli", siniflandir("görev", "kapandı", "iz `1980a47`", var), "izli")
    # ÖTMELİ ③′ — SHA ÇÖZÜLMÜYORSA iz sayılmaz (yoksa dizge yeter olurdu)
    check("y2-çözülmeyen-sha-iz-değil",
          siniflandir("görev", "kapandı", "iz `deadbee`", yok), "gedik")
    # ÖTMELİ — `Durum` okunamıyorsa SESSİZCE "kapalı" varsayma
    check("y2-okunamadı", siniflandir("görev", "variance", "x", yok), "okunamadı")
    # 🔴 ÖTMELİ — TANINMAYAN `Tür` belirteci İDDİA EDER sayılır.
    # Aksi hâlde yeni bir kelime yazıldığı gün muaf küme SESSİZCE büyürdü.
    check("y2-bilinmeyen-tür-ötüyor",
          siniflandir("zamazingo", "kapandı", "x", yok), "gedik")
    # SUSMALI — bileşik `Tür`de kod iddia eden BİR belirteç yeter
    check("y2-bileşik", siniflandir("**bulgu+düzelt**", "kapandı", "x", yok), "gedik")
    # 🔴 TÜRKÇE KİP — `İÇERİK` büyük kipte de tanınmalı (`.lower()` `İ`de kör)
    check("y2-türkçe-büyük-kip",
          siniflandir("İÇERİK", "kapandı", "x", yok), "gedik")

    # ⭐ KAÇIRILMIŞ BORU — ayırıcı, kaçış okunmadan ayırıcı değildir.
    # ÖTMELİ yönü: naif `split` bu satırda 6 hücre görür, doğrusu 4.
    kacisli = r"| J-037 | bulgu | `errorClass: form\|setup` | **kapalı** |"
    check("kaçış-saygılı", len(_cells(kacisli)), 6)
    check("naif-split-YANILIYOR", len(kacisli.split("|")), 7)
    # SUSMALI yönü: kaçışsız satır bozulmamalı
    check("kaçışsız-bozulmuyor", len(_cells("| a | b | c |")), 5)

    # ⭐ SABİT TABAN — muaf küme büyürse öz-test DÜŞER (bilerek).
    # > *Bir tabanı hareket ettirebilen kapı, ölçtüğü borcu da hareket ettirir.*
    check("muaf-küme-SABİT", len(MUAF), 3)
    check("muaf-gerekçeli", all(len(v) > 30 for v in MUAF.values()), True)

    # ⭐ VAKUM KORUMASI — aday kümesi boşalırsa "0 gedik" ANLAMSIZDIR.
    # (Tek kanallı bir ölçümün en gerçek riski: kanal susarsa kapı yeşil öter.)
    y2 = yon_iki(set(commit_numbers(400)[0]))
    check("y2-aday-kümesi-DOLU", y2["satır"] > 0, True)
    check("y2-birimler-ayrı-basılıyor", y2["numara"] > 0 and y2["satır"] > 0, True)
    # Katmanlar TOPLAMALI — payda denetimi (türetilmiş değil, bağımsız sayım)
    toplam = sum(len(y2[k]) for k in
                 ("açık", "iddia-etmez", "izli", "gedik", "okunamadı"))
    check("y2-payda-toplamı", toplam, y2["satır"])

    # ⭐ UÇUŞ AFFI DAR MI (J-245) — yapısal değişmez.
    # Af yalnız **en yeni atıflı kaydın ÖTESİNE** uygulanabilir; bir gün
    # genişletilirse (örn. "son 5 kayıt muaf") burası düşer.
    # > *Bir affın tehlikesi affettiğinde değil, SINIRI kayarken başlar.*
    _no = lambda s: int(re.findall(r"\d+", s)[0])  # noqa: E731
    check(
        "uçuş-affı-yalnız-son-atıflının-ÖTESİ",
        all(_no(i) > y2["son_atıflı"] for i in y2["uçuşta"]),
        True,
    )
    check("uçuşta-gedikte-DEĞİL",
          any(i in y2["gedik_net"] for i in y2["uçuşta"]), False)
    # Af, ölçülen bir gerçeğe dayanmalı: hiç atıflı commit yoksa `son_atıflı`
    # 0 olur ve af **her şeyi** yutardı. O hâl bir kusurdur, sessiz değil.
    check("son-atıflı-ölçüldü", y2["son_atıflı"] > 0, True)
    return ok


def main() -> int:
    limit = 400
    if "--self-test" in sys.argv:
        print("DEFTER TAZELİĞİ — öz-test")
        good = self_test()
        print("  SELF-TEST OK" if good else "  SELF-TEST BAŞARISIZ")
        return 0 if good else 1

    written = defter_numbers()
    referenced, attributed, unattributed, mentioning, scanned = commit_numbers(limit)
    missing = sorted(
        (n for n in referenced if n not in written),
        key=lambda s: int(s.split("-")[1]),
    )

    # ③ PAYDA HER ZAMAN YAZILIR — VE DENETLENİR.
    #
    # ⚠️ `limit` BASILMAZ: `-400` bir ÜST SINIRDIR, bir sayım değil. Depoda
    # 226 commit var; ilk sürüm "taranan: 400" yazıyordu ve kapsamı
    # OLDUĞUNDAN GENİŞ gösteriyordu — hem de tam bu kapının kapsam sorunu
    # olduğu gün. *Bir pencereyi İSTEMEK, onu ÖLÇMEK değildir.*
    assert attributed + unattributed == scanned, (
        f"PAYDA TOPLAMIYOR: {attributed} + {unattributed} != {scanned}"
    )
    # ⚠️ A ve B AYRI SATIR (J-227). 226 commit'te İKİSİ DE 14'tü ve bu bir
    # RASTLANTIYDI: yapısal olarak farklı iki büyüklük aynı sayıya eşitti.
    # Depo iki commit büyüyünce kendiliğinden ayrıştılar (A=14, B=15).
    # > BİR EŞLEŞME BİR SEBEP DEĞİLDİR — ve tek satırda basılsalardı
    # > "buldum" diyen biri YANLIŞ açıklamayı kabul edebilir, hiçbir şey de
    # > ötmezdi çünkü sayı tutuyordu.
    a_gap = mentioning - attributed      # anma, atıf DEĞİL
    b_gap = attributed - len(referenced)  # bir numaraya birden çok commit
    print(
        f"DEFTER TAZELİĞİ · taranan başlık: {scanned} "
        f"(istenen üst sınır {limit}) = atıflı {attributed} + atıfsız "
        f"{unattributed} ✓ · deftere yazılı: {len(written)}"
    )
    print(
        f"  A · anan {mentioning} − çapalı {attributed} = {a_gap}  "
        f"(J-numarası ANIYOR ama kayıt KONUMUNDA değil → sözünü etmek ≠ kayıt)"
    )
    print(
        f"  B · çapalı {attributed} − benzersiz {len(referenced)} = {b_gap}  "
        f"(aynı kayıt numarasına birden fazla commit)"
    )
    # ⭐ BENZERSİZLİK ÇAPASI (J-237) — "satır sayısı == benzersiz ID".
    #
    # Ölçüldü: gövdede **iki ayrı `J-105`** var (biri kapanış, biri bulgu)
    # ⇒ ***bir atıf İKİ kayda çözülüyor*** ve hiçbir şey ötmüyordu. Sayı ile
    # kimlik aynı şey değil: bir tabloda 235 satır olması, 235 kayıt olduğu
    # anlamına gelmez. Çakışma **ID hücresi AYNEN eşitse** sayılır — bu
    # yüzden `J-191` ↔ `J-191 (devam)` çakışma DEĞİL (kasıtlı devam).
    ids = record_ids()
    seen: dict[str, int] = {}
    for one in ids:
        seen[one] = seen.get(one, 0) + 1
    clashes = sorted(k for k, v in seen.items() if v > 1)
    rows_n = len(record_rows())
    print(
        f"  C · kayıt satırı {rows_n} · ID hücresi {len(ids)} · benzersiz "
        f"{len(seen)} → çakışma {len(clashes)}"
        + (f"  🔴 {clashes}" if clashes else "  ✅")
    )
    if rows_n != len(ids):
        print(
            f"  🔴 {rows_n - len(ids)} kayıt satırının ID HÜCRESİ okunamadı — "
            "sayaç sessizce eksik sayıyor"
        )

    # Kimlik kusuru da KIRMIZI — bir atıfın iki kayda çözülmesi, bir kaydın
    # hiç yazılmamış olması kadar ağırdır: ikisinde de "J-n" bir KAYDA
    # götürmüyor. (Biri sıfır kayda, öteki ikiye.)
    integrity = bool(clashes) or rows_n != len(ids)

    # ══════════════════════════════════════════════════════════════════
    # YÖN-2 — HER ZAMAN BASILIR, ve muaf küme SAYIYLA (J-243, A6)
    # > *Sessiz bir muafiyet altı ay sonra envanter sanılır.*
    # ══════════════════════════════════════════════════════════════════
    y2 = yon_iki(set(referenced))
    print(
        f"  D · YÖN-2 · deftere yazılı ama commit ANMIYOR: "
        f"{y2['numara']} numara / {y2['satır']} satır  "
        f"(eşit DEĞİL: `J-194`+`J-194b` = 2 satır 1 numara)"
    )
    print(
        f"      = açık {len(y2['açık'])} (iş yapılmadı) + iddia-etmez "
        f"{len(y2['iddia-etmez'])} (bulgu/karar) + izli {len(y2['izli'])} "
        f"(kanıtta ÇÖZÜLEN SHA) + gedik-adayı "
        f"{len(y2['gedik_net']) + len(y2['muaf_uygulanan'])} + okunamadı "
        f"{len(y2['okunamadı'])} ✓"
    )
    print(
        f"      UÇUŞTA (en yeni atıflı J-{y2['son_atıflı']} ÖTESİ, "
        f"commit henüz oluşmadı): {len(y2['uçuşta'])} {sorted(y2['uçuşta'])}"
    )
    print(
        f"      MUAF (SABİT taban, kapı kaynağında): "
        f"{len(y2['muaf_uygulanan'])}/{len(MUAF)} uygulandı "
        f"→ {sorted(y2['muaf_uygulanan'])}"
    )
    if y2["okunamadı"]:
        # ⛔ ÖLÇÜLEMEDİ ≠ YOK. Sessizce "kapalı" varsaymak, bu ailenin
        # `sessiz-yeşil` sınıfıdır — bu yüzden ADIYLA basılır.
        print(
            f"      ⛔ `Durum` hücresi OKUNAMADI: {len(y2['okunamadı'])} "
            f"{sorted(y2['okunamadı'])} — sınıflandırılMADI, gedik de "
            "SAYILMADI. (Bugün tek satır: `J-199`, `Durum`u standart bir hâl "
            "kelimesi taşımıyor: 'YENİ OTURUMUN 1. İŞİ'. Tek satıra desen "
            "UYDURULMADI — bir satıra uydurulan desen ölçüm değil ezberdir; "
            "elle hükmedildi: `Tür=kayıt` ⇒ gedik DEĞİL, J-243.)"
        )
    if y2["erişilemeyen_depo"]:
        print(
            f"      ⛔ SHA kanalı ÖLÇÜLEMEDİ (depo yok): "
            f"{[p.name for p in y2['erişilemeyen_depo']]}"
        )
    yon2_kirmizi = bool(y2["gedik_net"])
    if not yon2_kirmizi:
        print("      ✅ YÖN-2 net gedik: 0")

    # TAZELİK HÜKMÜ HER ZAMAN BASILIR — kimlik kusuru onu GİZLEMEZ.
    # (Mutasyon 1'de ölçüldü: iki hüküm tek `return`e bağlıyken, kimlik
    # kırmızıysa tazelik satırı hiç basılmıyordu. *İki ayrı ölçüm, iki ayrı
    # satır* — A/B ayrımının aynısı, bu kez hükümlerde.)
    if not missing:
        print("  ✅ commit'te anılıp deftere YAZILMAMIŞ kayıt: 0")
    if yon2_kirmizi:
        print(
            f"\n  🔴 YÖN-2 GEDİK {len(y2['gedik_net'])}: "
            f"{sorted(y2['gedik_net'])}\n"
            "  Kapanmış, kod iddia eden, ama hiçbir commit'e bağlanmayan\n"
            "  kayıt. İki kanal da sessiz: ne commit başlığı anıyor, ne de\n"
            "  kaydın kapanış kanıtı çözülen bir SHA taşıyor."
        )
    if not missing and not integrity and not yon2_kirmizi:
        return 0
    if integrity:
        print(
            "\n  🔴 KİMLİK KUSURU: bir `J-n` atfı TEK bir kayda çözülmüyor.\n"
            "  Çakışan ID, defterdeki en ucuz sessiz hatadır — okuyan\n"
            "  yanlış kaydı okur ve YANLIŞ OKUDUĞUNU BİLMEZ."
        )
    if not missing:
        return 1
    print(f"  🔴 DEFTERE YAZILMAMIŞ {len(missing)} kayıt:")
    for n in missing:
        print(f"     {n} ← {referenced[n]}")
    print(
        "\n  Bir iş yapılmış, commit'lenmiş ve numarası verilmiş ama hattın\n"
        "  DEFTERİNE geçmemiş. Defterden okuyan bir sonraki oturum onu HİÇ\n"
        "  görmez — iş yalnız commit mesajında yaşıyor demektir."
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
