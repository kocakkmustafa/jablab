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

## ⚠️ HATTA GÖRE DEĞİŞEN ŞEY: KONUM

Koordinatörün uyarısı *"defterin BİÇİMİ hatta göre değişir"* — ölçüldü ve
JabLab'da **defter tek biçim** (223 tablo satırı, prose başlığı 0), yani
Gravita'nın 47 yanlış-pozitif sebebi burada YOK.

Ama aynı sınıf kusur **commit tarafında** çıktı: Gravita `J-NNN` başlığın
BAŞINDA yazıyor; **JabLab SONDA, parantez içinde** — ölçüldü (son 60
başlık: J-numarası içeren **39**, başında olan yalnız **10**). Gravita'nın
"baştaki numara" ölçütü buraya olduğu gibi taşınsaydı kapı, gerçek
kayıtların çoğunu **görmez** ve fark kümesi sahte gediklerle dolardı.

Bu yüzden ② burada **konum olarak** uygulanıyor: sondaki `(J-NNN …)`
parantezi = *bu commit'in kayıt kalemi*. Ortada geçen bir numara sayılmaz.

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

# ② KONUM ÖLÇÜTÜ — sondaki parantez. "(J-224)" · "(J-224 yan)" · "(J-185/186)"
TRAILING = re.compile(r"\((J-\d+(?:/\d+)*)[^)]*\)\s*$")
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


def commit_numbers(limit: int) -> tuple[dict[str, str], int]:
    """Başlıklardan (yalnız `%s`) J numaraları. Dönüş: {numara: başlık}, atıfsız."""
    titles = subprocess.run(
        ["git", "-C", str(APP), "log", f"-{limit}", "--format=%s"],
        capture_output=True, text=True, check=True,
    ).stdout.splitlines()
    found: dict[str, str] = {}
    unattributed = 0
    for t in titles:
        m = TRAILING.search(t)
        if not m:
            unattributed += 1
            continue
        raw = m.group(1)
        head, *rest = raw.split("/")
        for num in [head] + [f"J-{x}" for x in rest]:
            found.setdefault(num, t)
    return found, unattributed


def self_test() -> bool:
    """İKİ YÖNLÜ öz-test — kapı hem ötmeli hem susmalı."""
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        if got != want:
            print(f"  ÖZ-TEST DÜŞTÜ [{name}]: {got!r} != {want!r}")
            ok = False

    # ② sözünü etmek ≠ kayıt
    check("sonda-parantez", bool(TRAILING.search("kapı: bir şey (J-224)")), True)
    check("sonda-ekli", bool(TRAILING.search("düzelt: x (J-224 yan)")), True)
    check("ORTADA-anma", bool(TRAILING.search("J-224 hakkında not düşüldü")), False)
    check("gövde-benzeri", bool(TRAILING.search("bkz (J-1) ve devamı")), False)
    # birleşik kayıt açılıyor mu
    m = TRAILING.search("kayıt: iki şey (J-185/186)")
    check("birleşik", m.group(1) if m else None, "J-185/186")
    # defter satırı biçimi
    check("defter-satırı", bool(ROW.match("| J-224 | ders | P0 | … |")), True)
    check("defter-prose", bool(ROW.match("## J-224 bir şey")), False)

    # ③ TABAN TEMİZ Mİ — Gravita'nın 47'yi yakalayan sorusu
    nums = defter_numbers()
    check("defter-dolu", len(nums) > 100, True)
    for probe in ("J-001", "J-224"):
        check(f"defter-içeriyor-{probe}", probe in nums, True)
    check("defter-uydurma", "J-9999" in nums, False)
    return ok


def main() -> int:
    limit = 400
    if "--self-test" in sys.argv:
        print("DEFTER TAZELİĞİ — öz-test")
        good = self_test()
        print("  SELF-TEST OK" if good else "  SELF-TEST BAŞARISIZ")
        return 0 if good else 1

    written = defter_numbers()
    referenced, unattributed = commit_numbers(limit)
    missing = sorted(
        (n for n in referenced if n not in written),
        key=lambda s: int(s.split("-")[1]),
    )

    # ③ PAYDA HER ZAMAN YAZILIR
    print(
        f"DEFTER TAZELİĞİ · taranan commit başlığı: {limit} · "
        f"atıflı: {len(referenced)} · atıfsız: {unattributed} · "
        f"deftere yazılı kayıt: {len(written)}"
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
