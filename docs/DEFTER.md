
## 2026-07-29 — stance referansı ürüne bağlandı (M-F-51)

**Karar:** `bindingStatus: blocked → active`, `clusterToleranceDeg: 35`.

**Gerekçe:** Koordinatörün ara hükmü take-kapısını "kaba aynı-hareket sorusu",
skorlama yetkisini "eklem-bazlı" olarak ayırdı. Ben bunu kabul etmeden önce
sınadım: referansı 35° VE 60° ile ayrı ayrı ürettim. **Eklem tabloları birebir
aynı çıktı.** Küme eşiği eklem ayrımını hiç etkilemiyor → iki kapı gerçekten
farklı soruları soruyor. Hüküm ampirik olarak doğrulandı.

**Sonuç:** 7 eklem skorlanır (dispersiyon ≤14°), 10 eklem koçlanır. Ayrım
anatomik değil ölçülmüş: lead_shoulder 13,3° ile skorlanırken rear_shoulder
28,2° ile skorlanmıyor — "kollar vs bacaklar" basitleştirmesi config'te YOK.

**Yan düzeltme (J-034 sınıfı):** referans aracı raporu artık `lead_*/rear_*`
basıyor. Mutlak taraf adı, ayna ataması değiştiğinde sessizce yanlış ekleme
işaret ediyordu; ölçülen öncü tarafa göre çevirmek bunu yapısal olarak
imkânsız kılıyor. Test nüksü yakalar, bu düzeltme nüksü engeller.

**Açık kalan:** tolerans hâlâ `provisional` (n=3). M-F-32 hedefi ~5 eğitmen;
n≥5 olduğunda `toleranceStatus` güncellenecek — testte hatırlatıcı var.

## 2026-07-29 — G6 müfredat bağları: iki dürüstlük düzeltmesi

**J-035 — `trunk_tilt` skorlanandan düştü.** sd 12,0° tabanın altındaydı.
Üç eğitmenin gövde eğimi −1,9° / −3,8° / −28,4°, take-içi sapma ≤2,2°.
Uzlaşı değil bimodal bölünme; sd n=3'te aykırıyı yutuyor. Kamera değil:
aykırı take'in bacak ekseni (7,9°) diğerleriyle aynı.
→ Kural: ham-tanımlı eklemlerde sd'nin yanına take açıklığı da bakılır.

**J-036 — stance kapısı sinyale indi.** `stanceWidthRatio` üç eğitmende
0,72/1,17/1,85 (medyanın %96,7'si). M-C-04 gereği tolerans bunu kapsamalı;
kapsayan bant ayırt edemez. Eski gerekçe bir eklem açısından sayı ödünç
almıştı — oran ölçüleri eklem tablosunda YOK. Yerine katılım kapısı (60 sn).

**J-037 — setup hatası drill öneremez.** Çerçeve/izleme sorununa egzersiz
reçete etmek, kullanıcıyı kendi kamerası için suçlamak.

**Yayınlanmayan ölçüm.** Eklemler-arası "açıklık" sütunu yazdım; iç açılar
8-14° verirken segment yönleri 60-160° verdi — sütun ayrışmayı değil kamera
yönelimini ölçüyordu. Kaldırdım. `trunk_tilt` istisna: çekirdek onu bilerek
ham tutuyor, orada karşılaştırma geçerli ve iki bağımsız yolla doğrulandı.

**Ders:** kapı yetkisi İKİ bağımsız kısıt ister — tespit güvenilir mi (band)
VE eğitmenler uzlaşıyor mu (referans). Yalnız birine bakan türetme, önce
`posture_reset`'i yanlış sınıflandırdı.
