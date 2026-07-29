
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
