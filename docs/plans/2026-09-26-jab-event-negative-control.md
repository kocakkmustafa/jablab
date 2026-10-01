# JabLab: düz yumruk olayında negatif kontrol

Tarih: 2026-09-26  
Durum: yerel uygulama planı; gerçek kamera doğrulaması değildir.

## Problem ve sınır

`boxing@1.0.0` düz yumruk fazları `extensionRatio` ile kolun düzleşmesini
ölçüyor. Bu oran kolun yönünü ölçmüyor. Mevcut sentetik testte garddan aşağı
sarkan düz kola 250 ms'de geçip geri dönmek `jab` olayı üretiyor; 500 ms
varyantı yalnız zaman aşımı sayesinde reddediliyor. Yanlış olay bir ders
ilerlemesini veya tekrar sayısını kirletebilir.

Bu çalışma yalnız mevcut iskelet motorunun olay mantığını ve çevrimdışı
kontrolünü kapsar. Şu anda farklı kişileri ve cihazları içeren lisanslı,
etiketli jab/cross ve negatif hareket veri kümesi yok. Mevcut iki hasat
golden'ı YouTube kaynaklı ölçü matematiği çapraz kontrolüdür; kullanım hakkı
ve olay etiketleri belgelenmediğinden eğitim veya olay doğrulaması girdisi
olmayacaktır. Sıfır gerçek çekim üzerinden hassasiyet, hız, kuvvet, eklem
açısı doğruluğu veya güvenlik sonucu çıkarılamaz.

## Tasarım

Kol düzlüğünün yanında, bileğin omza göre görüntü düzlemindeki aşağı yönlü
konumunu aynı karenin kol uzunluğuna oranlayan bir ölçü adayı sınanır.
Ölçü, kamera en-boy düzeltmesinden sonra hesaplanır. Yalnız `jab`/`cross`
gibi düz yumrukların uzanma/tepe koşulunda ve gerekiyorsa genel vuruş
yedeğinde kullanılır. Bu bir 2B hareket ayrımıdır: kameraya doğru gerçek
derinlik, klinik kol açısı veya yumruk şiddeti değildir. Eşik ham sinyal ve
sentetik kontroller için geçicidir; gerçek kullanıcıya form hükmü açmaz.

Kabul, ayrı pozitif ve negatif sentetik vakaların aynı koşucuda sayılmasıdır:
250 ms ve 500 ms aşağı kol sallaması ile gard/slip ve eksik uzanma olay
üretmemeli; standart ve farklı tempolu düz yumruklar olay üretmeye devam
etmelidir. Her vaka için beklenen etiket, gözlenen olay ve yanlış
olumlu/olumsuz sayısı raporlanır. Beklenmeyen olay veya kayıp pozitif test
kapısını kırar. Bu, gerçek dünya doğrulaması değil mantık regresyonudur.

## Uygulama sırası

- [x] Mevcut 250 ms vaka ve standart pozitif kontrolü değiştirmeden çalıştır.
- [x] Tekrarlanabilir sentetik vaka tablosu ve kırmızı negatif kontrol kapısı ekle.
- [x] Ölçü adayını ayrı birim testte geometrik anlamıyla doğrula.
- [x] Kural setinde yalnız kanıtlanan düz yumruk koşullarını değiştir; yedek
  sınıflandırmanın yanlış olayı geri getirmediğini kontrol et.
- [x] Negatif ve pozitif vaka tablosu, mevcut motor testleri, biçimlendirme ve
  analiz çalıştır; değişiklikleri ve önceden var olan WIP'i ayrı incele.

## Solo boks kursunun uygulama tasarımı

39 çekirdek ders sekiz modülde ilerler: güvenli kurulum ve temel duruş (5),
ayak çalışması (5), düz yumruklar (6), kontrollü savunma şekilleri (5),
kroşe/aparkat tanıtımı (5), kısa kombinasyonlar (5), raunt kurma (5) ve
bağımsız bitirme (3). Mevcut yedi kondisyon dersi ek çalışmadır; çekirdek
ön koşul değildir. Partner, torba ve temaslı sparring kurs akışına girmez.

Yeni sürümlü varlık `assets/content/solo_boxing_course.v1.json` mevcut
21 derslik miras kütüphaneden bağımsız bir **tek kurs** taşır. Her dersin
kalıcı kimliği, TR/EN başlık ve özgün öğretim adımları, pratik, öz denetim,
genel uyarlama, durma işaretleri, kaynak kimliği, ön koşul ve çekim brifi
zorunludur. Bu kursun hiçbir dersi kamera puanı veya ustalık ölçümü istemez.
Bu ayrım eski oturum kayıtlarını yeni derslere yanlış eşlemez.

Uygulama girişindeki mevcut kurs sayfasına görünür bir solo yol kartı eklenir.
JabLab renk/tipografi tokenlarıyla sekiz modül, 39 ders, bugün sıradaki ders,
ders ayrıntısı ve ilerleme tablosu açılır. Dersi okumak `görüldü`, kullanıcının
"çalıştım" demesi `çalışıldı`, öz denetim maddelerini işaretleyip onaylaması
`öz beyanla tamamlandı` olur. Kamerayla gözlem/puan burada üretilmez.
Ön koşullar sıralı öneri olarak gösterilir; kullanıcı içeriği okumak için
sahte kilide takılmaz. Tekrar sayısı öz beyanla kaydedilir.

İlerleme uygulama destek dizininde, konuk ve UUID hesap için ayrı JSON
dosyasına atomik yazılır. Okuma hatası sıfır ilerleme gibi gösterilmez;
hesap değişimi depoyu yeniden yükler, hesap silme akışı bu dosyayı da siler.
İçerik sürümü her kayıtta korunur. Kaydın `görüldü` ve öz beyan düzeyleri
gerçek beceri doğrulaması sayılmaz.

- [x] 39 dersin tamamını TR/EN kaynak, pedagojik sıra ve çekim brifiyle yaz.
- [x] Şema denetimi: sayı, tekil kimlik, kaynak, çevrimsiz ön koşul,
  iki dilin doluluğu, yanlış sensör iddiası ve bitirme görevi.
- [x] Hesap ayrımlı yerel ilerleme deposu; yeniden açılış, hesap değişimi,
  bozuk veri ve silme testleri.
- [x] Tema uyumlu yol/ayrıntı/ilerleme ekranı ve kök kurstan erişim.
- [x] Odaklı widget ve içerik testleri, statik analiz, diff incelemesi.

## Kanıt

Yerel sonuçlar ve gerçek dünya sınırları: `docs/evidence/production-line/2026-09-26-solo-boxing.md`. 31 motor testi, 30 app testi, odaklı Dart/Flutter analiz ve üretici denetimi geçti. AI medya üretimi ve cihaz/mağaza kabulü bu sonuçla tamamlanmış sayılmaz.
