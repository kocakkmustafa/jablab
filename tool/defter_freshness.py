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


def defter_numbers() -> set[str]:
    """Deftere yazılmış J numaraları. Birleşik kayıt (J-185/186) AÇILIR."""
    out: set[str] = set()
    for line in DEFTER.read_text(encoding="utf-8").splitlines():
        m = ROW.match(line)
        if not m:
            continue
        raw = m.group(1)                      # "J-185/186"
        head, *rest = raw.split("/")          # "J-185", ["186"]
        out.add(head)
        for tail in rest:
            out.add(f"J-{tail}")
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

    Dönüş: `({numara: ilk başlık}, atıflı, atıfsız, taranan)` — hepsi BAŞLIK
    birimi; `found` ise NUMARA birimi (ayrı birim, ayrı basılır).
    """
    titles = subprocess.run(
        ["git", "-C", str(APP), "log", f"-{limit}", "--format=%s"],
        capture_output=True, text=True, check=True,
    ).stdout.splitlines()
    found: dict[str, str] = {}
    attributed = 0
    unattributed = 0          # ⚠️ BAĞIMSIZ sayılır, TÜRETİLMEZ (aşağı bak)
    for t in titles:
        raw = _record_ref(t)
        if raw is None:
            unattributed += 1
            continue
        attributed += 1
        head, *rest = raw.split("/")
        for num in [head] + [f"J-{x}" for x in rest]:
            found.setdefault(num, t)
    return found, attributed, unattributed, len(titles)


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

    # ③ TABAN TEMİZ Mİ — Gravita'nın 47'yi yakalayan sorusu
    nums = defter_numbers()
    check("defter-dolu", len(nums) > 100, True)
    for probe in ("J-001", "J-224"):
        check(f"defter-içeriyor-{probe}", probe in nums, True)
    check("defter-uydurma", "J-9999" in nums, False)

    # ⭐ PAYDA ARİTMETİĞİ — payda YAZMAK, paydayı DENETLEMEK değildir (J-226).
    _ref, _att, _un, _scan = commit_numbers(400)
    # İki sayaç BAĞIMSIZ; bu yüzden toplamları gerçek bir iddiadır.
    check("payda-toplamı", _att + _un, _scan)
    check("taranan-gerçek", _scan <= 400, True)
    check("birim-ayrı", _att >= len(_ref), True)  # başlık ≥ benzersiz numara
    check("sayaçlar-dolu", _att > 0 and _un > 0, True)

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
    return ok


def main() -> int:
    limit = 400
    if "--self-test" in sys.argv:
        print("DEFTER TAZELİĞİ — öz-test")
        good = self_test()
        print("  SELF-TEST OK" if good else "  SELF-TEST BAŞARISIZ")
        return 0 if good else 1

    written = defter_numbers()
    referenced, attributed, unattributed, scanned = commit_numbers(limit)
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
    print(
        f"DEFTER TAZELİĞİ · taranan başlık: {scanned} "
        f"(istenen üst sınır {limit}) = atıflı {attributed} + atıfsız "
        f"{unattributed} ✓ · benzersiz kayıt numarası: {len(referenced)} "
        f"(atıflı başlıktan {attributed - len(referenced)} eksik: aynı "
        f"numaraya birden fazla commit) · deftere yazılı: {len(written)}"
    )
    if not missing:
        print("  ✅ commit'te anılıp deftere YAZILMAMIŞ kayıt: 0")
        return 0
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
