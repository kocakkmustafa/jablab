#!/usr/bin/env python3
"""DEFTER ENVANTERİ — paydanın TANIMI, paydanın kendisinden kalıcı (J-237).

## ⛔ NEDEN BU DOSYA VAR

2026-08-12'de bu hat *"kapalı **175** · korumasız **53**"* raporladı. Bir
tur sonra aynı dosyada **hiçbir makul tanım o sayıyı vermedi** (181 / 166 /
161 / 148). Sebep: sayaç **dosyaya yazılmamış tek satırlık bir kabuk
komutuydu** — tanım, sayının kendisinden daha kısa ömürlüydü.

> ***BİR PAYDA YENİDEN ÜRETİLEMİYORSA ÖLÇÜM DEĞİL, ANIDIR.***

Sayılar geri çekildi. Bu betik onların yerine geçmiyor: **yeni bir sayı
iddia etmiyor**, yalnız *hangi tanımın hangi sayıyı verdiğini* basıyor.
Okuyan, sayıyı tanımından ayrı alamaz.

## ① PAYDA — "kayıt" nedir

Kayıt = **kayıt tablosunun gövdesindeki satır.** Biçim değil, **tablo
üyeliği** (`defter_freshness.record_rows`, aynı çapa — iki sayaç iki farklı
şey saymasın diye TEK yerden gelir). Anlatı tablosu (`| # | ne |`) dışarıda:
o satırlar kayıt biçimindedir ama kayıt değildir.

## ② "KAPALI" — DÖRT OKUMA, DÖRDÜ DE BASILIR

`Durum` sütununda dizge taraması. Dört okuma ayrı ayrı basılır çünkü
**hangisinin kastedildiği sayıdan okunamaz**:

  · `gevşek`  — `kapal|kapand` metnin HERHANGİ bir yerinde
  · `başta`   — satır `kapal|kapand` ile BAŞLIYOR
  · `açıksız` — gevşek, ama `açık` geçmiyor (kısmî kapanışları eler)
  · `dar`     — başta VE `açık` geçmiyor

⚠️ **Hiçbiri "doğru" değil**; bu hattın kayıtları *"kapandı (ölçüm) / açık:
şu"* gibi **kısmî** hâller taşıyor ve bu meşru. Kural: bir raporda `kapalı`
yazan, **hangi okumayı** kullandığını da yazar.

## ③ KORUMA — `Kapanış kanıtı` sütununda ARAÇ ADI aranır

Bir kayıt *korumalı*dır ancak ve ancak kanıtı **yeniden koşan bir şeye**
işaret ediyorsa. Sınıflar (bir kayıt İLK eşleşen sınıfa girer):

  · `A · araç`   — kanıtta bir dosya yolu var (`_test.dart`, `tool/…`,
                   `.py`, `.sh`) ⇒ kapı/betik her koşuda yeniden ölçer
  · `B · sayı`   — araç yok ama **rakamlı ölçüm** var (°, %, MB, oran…)
  · `C · sha`    — yalnız commit/SHA/dal adı ⇒ *yapıldı*, ama yeniden
                   ölçülmüyor
  · `D · yok`    — kanıt hücresi boş ya da yalnız düzyazı

⚠️ **TÜRKÇE JETON TUZAĞI, bilerek kaçınıldı (J-235).** `A` sınıfı için
`kapı`/`gate` KELİMESİ aranmaz — bu defterde `kapı` hem **araç** hem
**içerik** olarak geçiyor ve kelimeyi desen yapmak öbür anlamı da yakalar.
Yerine **dosya-yolu biçimi** aranır: bir yol, ürün cümlesi olamaz.

⚠️ **Bu harfler, geri çekilen `A104/B18/C38/D15` DEĞİLDİR.** O tanımlar
yazılmamıştı, dolayısıyla yeniden üretilemez ve **yeniden kurulmaya
çalışılmadı.** Aynı harfleri kullanmak yanıltıcı olurdu; sınıf adları
niteliğe göre yeniden yazıldı.
"""

from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

_SPEC = importlib.util.spec_from_file_location(
    "defter_freshness", Path(__file__).with_name("defter_freshness.py")
)
_FRESH = importlib.util.module_from_spec(_SPEC)
assert _SPEC.loader is not None
_SPEC.loader.exec_module(_FRESH)

CLOSED = {
    "gevşek": lambda d: bool(re.search(r"kapal|kapand", d, re.I)),
    "başta": lambda d: bool(re.match(r"\s*\**\s*(kapal|kapand)", d, re.I)),
    "açıksız": lambda d: bool(re.search(r"kapal|kapand", d, re.I))
    and not re.search(r"açık", d, re.I),
    "dar": lambda d: bool(re.match(r"\s*\**\s*(kapal|kapand)", d, re.I))
    and not re.search(r"açık", d, re.I),
}

# Dosya-yolu biçimi — bir YOL, ürün cümlesi olamaz (Türkçe jeton tuzağı yok).
TOOL = re.compile(r"[\w/.-]+\.(?:dart|py|sh|ya?ml|kts?)\b|\btool/|\btest/")
NUMBER = re.compile(r"\d+[,.]?\d*\s*(?:°|%|MB|KB|ms|kare|kayıt|ders|/\d)")
SHA = re.compile(r"\b[0-9a-f]{7,40}\b|\bmain\b|\bcommit\b|\bPR\b", re.I)


def klass(evidence: str) -> str:
    if TOOL.search(evidence):
        return "A · araç"
    if NUMBER.search(evidence):
        return "B · sayı"
    if SHA.search(evidence):
        return "C · sha"
    return "D · yok"


def self_test() -> bool:
    """POZİTİF KONTROL — sınıflandırıcı AYIRT EDİYOR mu, ve fazla mı geniş.

    ⛔ Totolojik toplam denetiminin yerine geçen şey bu: burada her iddia
    YANLIŞ ÇIKABİLİR.
    """
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        if got != want:
            print(f"  ÖZ-TEST DÜŞTÜ [{name}]: {got!r} != {want!r}")
            ok = False

    # ÖTMELİ — araç adı gerçekten tanınıyor mu (yoksa A sınıfı BOŞ çıkar ve
    # "hiçbir kayıt korumalı değil" diye YANLIŞ bir manzara doğar)
    check("araç-test", klass("test/dead_end_test.dart yeşil"), "A · araç")
    check("araç-tool", klass("tool/defter_freshness.py 4/4"), "A · araç")
    check("araç-sh", klass("tool/setup_hooks.sh koşuldu"), "A · araç")
    # SUSMALI — Türkçe `kapı` KELİMESİ araç değildir (J-235 jeton tuzağı)
    check("kapı-kelimesi-araç-DEĞİL",
          klass("izin reddedilirse kapı gösterilir"), "D · yok")
    # B — rakamlı ölçüm, ama araç yok
    check("sayı-derece", klass("14° kapısı: 26,0–32,8°"), "B · sayı")
    check("sayı-mb", klass("release 46,0 MB"), "B · sayı")
    # C — yalnız SHA/dal
    check("sha", klass("main `cab88bc`"), "C · sha")
    check("sha-uzun", klass("`f13bdc93b2eae2f741bfcdb4c9270a88e5d75e5d`"),
          "C · sha")
    # D — kanıt yok
    check("boş", klass(""), "D · yok")
    check("düzyazı", klass("koordinatör hükmü uygulandı"), "D · yok")
    # SIRA ÖNEMLİ: araç + sha birlikteyse ARAÇ kazanır (daha güçlü kanıt)
    check("araç-sha'yı-yener",
          klass("main `abc1234`; test/x_test.dart"), "A · araç")

    # DÖRT SINIFIN DÖRDÜ DE GERÇEK DEFTERDE DOLU MU — biri boşsa
    # sınıflandırıcı ayırt etmiyordur, sayılar anlamsız olur.
    rows = _FRESH.record_rows()
    got = {klass([c.strip() for c in r.split("|")][-2]) for r in rows}
    check("dört-sınıf-da-dolu", len(got), 4)

    # KAPALI okumaları GERÇEKTEN farklı mı — hepsi aynı sayıyı verseydi
    # "dört okuma" bir süs olurdu.
    durum = [[c.strip() for c in r.split("|")][-3] for r in rows]
    ns = {n: sum(1 for d in durum if fn(d)) for n, fn in CLOSED.items()}
    check("okumalar-farklı", len(set(ns.values())), 4)
    # ve sıralama mantıklı: dar ⊆ açıksız ⊆ gevşek, dar ⊆ başta ⊆ gevşek
    check("dar<=başta", ns["dar"] <= ns["başta"], True)
    check("başta<=gevşek", ns["başta"] <= ns["gevşek"], True)
    check("açıksız<=gevşek", ns["açıksız"] <= ns["gevşek"], True)
    return ok


def main() -> int:
    if "--self-test" in sys.argv:
        print("DEFTER ENVANTERİ — öz-test")
        good = self_test()
        print("  SELF-TEST OK" if good else "  SELF-TEST BAŞARISIZ")
        return 0 if good else 1

    rows = _FRESH.record_rows()
    cells = [[c.strip() for c in r.split("|")] for r in rows]
    # Kaçaksız `|` yüzünden hücre sayısı sabit DEĞİL (8–13 ölçüldü) →
    # sondan sayılır: son hücre boş, -2 kanıt, -3 durum.
    durum = [c[-3] for c in cells]
    kanit = [c[-2] for c in cells]

    print(f"DEFTER ENVANTERİ · payda: kayıt tablosu gövdesi = {len(rows)} satır")
    print("  (biçim değil TABLO ÜYELİĞİ; anlatı tablosu dışarıda)")
    print("\n  KAPALI — dört okuma, hiçbiri 'doğru' değil:")
    for name, fn in CLOSED.items():
        n = sum(1 for d in durum if fn(d))
        print(f"    {name:8s} {n:3d}  ·  {len(rows)} − {len(rows) - n} açık/kısmî")

    print("\n  KORUMA — `Kapanış kanıtı` sütununda ARAÇ ADI (payda = tüm kayıtlar):")
    counts: dict[str, int] = {}
    for e in kanit:
        k = klass(e)
        counts[k] = counts.get(k, 0) + 1
    total = 0
    for k in ("A · araç", "B · sayı", "C · sha", "D · yok"):
        n = counts.get(k, 0)
        total += n
        print(f"    {k:9s} {n:3d}")
    # ⚠️ `toplam == payda` BURADA BİR DENETİM DEĞİL, TOTOLOJİDİR — `klass()`
    # her satıra dörtten BİRİNİ verir, yani toplam payda olmak ZORUNDA.
    # (J-226'da tam bu hatayı bulmuştum: `unattributed = scanned −
    # attributed` türetip sonra toplamı "denetlemek". Kendi yeni betiğimde
    # TEKRAR ettim ve sabotaj ötmedi — çünkü ötemezdi.)
    # > ***Bir denetim, YANLIŞ ÇIKABİLİYORSA denetimdir.***
    # Bu yüzden aşağıda basılan şey bir onay değil, bir HATIRLATMA; gerçek
    # denetim `--self-test` içindeki pozitif kontrollerdir.
    print(f"    {'toplam':9s} {total:3d}  ·  payda {len(rows)} "
          f"(totoloji — gerçek denetim: --self-test)")

    # ⚠️ İKİ EKSEN ÇARPILMAZ, KESİŞTİRİLİR — ve kesişim AYRICA basılır,
    # çünkü "korumasız kapalı" iki tanımın BİRLEŞİMİDİR ve tek sayı olarak
    # basılırsa hangi okumadan geldiği kaybolur. (Geri çekilen `53` tam
    # olarak böyle kaybolmuştu.)
    print("\n  KESİŞİM — korumasız (C+D) ∩ kapalı, HER OKUMA İÇİN ayrı:")
    for name, fn in CLOSED.items():
        n = sum(
            1
            for d, e in zip(durum, kanit)
            if fn(d) and klass(e) in ("C · sha", "D · yok")
        )
        print(f"    kapalı[{name}] ∩ korumasız = {n}")
    print("\n  ⛔ Bu betik bir sayıyı 'THE' payda ilan ETMEZ. Rapor yazan,")
    print("     hangi okumayı kullandığını YAZAR.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
