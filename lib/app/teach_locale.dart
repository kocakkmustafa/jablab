import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import 'ui_language.dart';

typedef _TeachCopy = ({String sourceSha256, String tr});

// The English lesson in library.json owns the meaning. A source edit must be
// reviewed before its Turkish copy is shown again.
String localizedTeachBody(BuildContext context, String id, String source) {
  final _TeachCopy? copy = _teachCopies[id];
  if (copy == null ||
      sha256.convert(utf8.encode(source)).toString() != copy.sourceSha256) {
    return source;
  }
  return UiLanguage.text(context, en: source, tr: copy.tr);
}

const Map<String, String> _materialReasonsTr = <String, String>{
  'We could not find this lesson in the library, so there is nothing to show here.':
      'Bu dersi kütüphanede bulamadık; burada gösterecek bir anlatım yok.',
  'There is no lesson material to watch or read here — we have not made it. The session still works: the next step is you moving, and nothing is scored while you learn the shape.':
      'Bu ders için izlenecek veya okunacak anlatım hazırlamadık. Seans yine çalışır: sıradaki adım hareket etmektir. Hareketi öğrenirken hiçbir şey puanlanmaz.',
  'We could not find this lesson in the library, so there is nothing to name here.':
      'Bu dersi kütüphanede bulamadık; burada adlandırılacak bir hareket yok.',
  'This lesson does not drill a named technique — the shape itself is the work. Move through it slowly and stay in frame.':
      'Bu ders adlandırılmış bir yumruk tekniği çalıştırmıyor; çalışılan şey duruşun kendisi. Yavaş hareket et ve kadrajda kal.',
};

String localizedMaterialReason(BuildContext context, String source) =>
    UiLanguage.text(
      context,
      en: source,
      tr: _materialReasonsTr[source] ?? source,
    );

const Map<String, _TeachCopy> _teachCopies = <String, _TeachCopy>{
  'boxing.foundations.camera': (
    sourceSha256:
        '1467249a4fc744c39122173c7d73f3fcc6933fd1ce33066001017ef545b92da1',
    tr: '''Her yöne iki adım atabileceğin, hiçbir yere çarpmayacağın bir yerde dur. Telefonu yaklaşık bel hizasında, sandalye, raf veya duvar gibi sağlam bir yere dayayarak sabitle.

Sonra ayaklarınla ellerin aynı anda görüntüye sığana kadar geri çekil. Kontrol bu kadar. Yumruk atarken ayakların kadrajdan çıkıyorsa kameraya fazla yakınsın.

Kameraya tam karşıdan bakmak yerine hafifçe yan dön. Boks gardında vücut yan durur; tam karşıdan bakıldığında arkadaki elin gövdenin arkasında kalır. Kamera göremediği eli yokmuş gibi algılayabilir.

Oda, kendi ellerini rahatça görebileceğin kadar aydınlık olsun. Işığı ölçmüyoruz; ortamın ne zaman fazla karanlık olduğunu uygulama söyleyemez, sen anlayabilirsin.''',
  ),
  'boxing.foundations.stance': (
    sourceSha256:
        '20a4e5cd0e475442bca3f9f98e4d2ae6675259235a30ecf77b7ae8820575eb08',
    tr: '''Ayakların yaklaşık omuz genişliğinde olsun; öndeki ayak ileride, arkadaki topuk hafifçe kalkık. Ağırlığını iki ayağın arasında tut: ne parmak uçlarına fazla yüklen ne de topuklarına yaslan.

Ellerini kaldır: öndeki el yaklaşık çene hizasında, arkadaki el yanağına yakın olsun. Arkadaki el hem seni korur hem de önce yorulan eldir. Düştüğünde uygulama bunu bildirir.

Dik dur. İlk haftanın en yaygın hatası daha uzağa erişmek için belden öne katlanmaktır. Güçlü hissettirebilir ama dengeni bozar.

Duruş genişliğini, ayakların çaprazlanmasını ve dengeyi görebiliyor ve bunları değerlendiriyoruz. Gard elini de görebiliyor, düştüğünde uyarıyoruz; ancak sayısal puan vermiyoruz. Deneyimli antrenörler elin tam olarak nerede durması gerektiğinde aynı fikirde değil.''',
  ),
  'boxing.foundations.jab': (
    sourceSha256:
        'dc177d4d489a2ff91d51afea0cdc91250f16abea158dc90acc217f662b677f3e',
    tr: '''Jab, öndeki elinin düz bir çizgide gidip aynı çizgiden geri dönmesidir. Büyük bir yumruk değildir; mesafeyi ölçer ve sana zaman kazandırır.

Yerden it, omzunu çevir, kolun onu izlesin. Yumruğun baktığın noktaya doğru uzansın. Dirseğin yumruğun altında ve arkasında kalsın; dirsek yana açıldığında hareket artık jab olmaktan çıkar.

Geri dönüş de yumruk kadar önemlidir. Yavaş dönen el, gerektiğinde yerinde olmaz. Bugün uygulama bu hatayı bildirmiyor; kendin izle.

Sürdürebileceğin bir tempoda çalış. Formunu bozan hız, iyi hız değildir; istemediğin bir hareketi daha hızlı tekrarlamana yol açar.''',
  ),
  'boxing.foundations.guard': (
    sourceSha256:
        '48f2ab0343d5f83b5e190681aa710bae590bacedc8d300e26629a7cffe0964f0',
    tr: '''İki elin de yüzünün önünde kalsın; yumruklar oradan çıksın. Öndeki el yaklaşık çene hizasında, arkadaki el yanağında olsun. Dirseklerini aşağıda ve içe yakın tut. Dirsekler dışarı açıldığında eller yukarıda olduğu için gard sağlam görünebilir, ama orta bölge açık kalır.

Bu derste jab atarsın, fakat odak jab değildir. Öndeki el uzaktayken diğer elin ne yaptığına ve jab elinin nasıl geri döndüğüne bak.

Yorgunluk ilk olarak arkadaki eli aşağı çeker. El azar azar düşer ve bunu hissetmeyebilirsin. Elin yerinde kaldığını hissedebileceğin kadar yavaş çalış.

Yumruk sırasında iki eli de görebiliyor, arkadaki el düştüğünde uyarıyoruz. Öndeki elin yavaş dönüşü de gerçek bir hatadır, ancak bugün onu bildirmiyoruz. Bunların hiçbirine sayı vermiyoruz: deneyimli antrenörler gardın tam konumunda uzlaşmıyor. Bu yüzden puan değil, uyarı gösteriyoruz.''',
  ),
  'boxing.foundations.range': (
    sourceSha256:
        '9425053d01bc7690717c14c0789754304e1116201b3d4e78259f27f6e4782c98',
    tr: '''Yumruk gereğinden uzağa ulaşmaya çalıştığında iki şey ters gider: dirsek kestirme yol ararken yana açılır, gövde de mesafeyi kapatmak için öne eğilir.

Önce dirsek. Düz yumrukta dirsek olabildiğince uzun süre yumruğun altında ve arkasında kalır. Yana kalktığında yumruk bir yay çizerek gider: daha geniş, daha yavaş ve çalıştığın yumruktan farklı.

Sonra öne eğilme. Temas etmek için öne düşmen gerekiyorsa doğru mesafede değildin. Uzanmak ağırlığını öndeki ayağın üstüne taşır ve sonraki yumruğu atacak dengeni alır.

Çözüm önünde değil, ayaklarının altında: önce adım at, sonra yumruk. Mesafe sorunu çoğu zaman kol sorunu gibi görünen bir ayak çalışması sorunudur.

Dirsek açısını ve öne eğilmeyi görebiliyor, ikisi için de uyarıyoruz. Hiçbirine sayı vermiyoruz: bu uyarıların eşikleri kalibre edilmedi. Bu yüzden puan yerine uyarı alırsın.''',
  ),
  'boxing.foundations.cross': (
    sourceSha256:
        '13cf19d918bd35cccaa4c3831e5eae69628826d44a15348f18e075dfa639923b',
    tr: '''Cross, arkadaki elle atılır ve daha uzun bir yol izler: el uzaktan başlar, hedefe ulaşmak için gövdenin önünden geçer. Gücü de olası hataları da bu mesafeden gelir.

Önce arkadaki ayağını ve kalçanı, sonra omzunu çevir; elin hareketi en son izlesin. Kol önce giderse yalnız kolla vurur, hedefe göğsünle uzanırsın.

Cross atarken öndeki elin yerinde kalsın. Buradaki en yaygın form hatası, bir el uzanırken diğer elin aşağı düşmesidir.

Yumruğun ne kadar sert isabet ettiğini söyleyemeyiz. Kamera şekli ve zamanlamayı görür, kuvveti ölçmez. Ölçmediğimiz bir sayı göstermeyeceğiz.''',
  ),
  'boxing.foundations.one_two': (
    sourceSha256:
        '3a79f414a9d59ed7395f43b3ffa8ee2990036cf2d07147179c7292980489ba9a',
    tr: '''Bir jab, iki cross demektir. Birlikte atıldıklarında jab yalnızca bir yumruk değildir; ardından gelen yumruğa alan açar.

Cross çıkmadan önce jab geri dönsün. İki yumruk aynı çizgiyi ve dengeyi paylaşır. İlk yumruk hâlâ giderken ikincisini başlatırsan iki elin de yüzünden uzakta kalır ve vücudun yumruğa doğru eğilir.

Kombinasyonu duruşuna geri dönerek bitir. Pozisyonunu kaybederek tamamlanan iki iyi yumruk, üçüncü yumruğu zorlaştırır.

Jab ve cross'u ayrı ayrı, diğer derslerdeki gibi izliyoruz. İkisini bir kombinasyon olarak değerlendirip yanlış eli veya sırayı saptamak bugün uygulamanın yaptığı bir şey değil.''',
  ),
  'boxing.foundations.first_round': (
    sourceSha256:
        'f715e22cbd36a37d3b46942b37ca8933d8a5bc34d661dc935c6da9eac6ce1160',
    tr: '''Üç dakika, tek raunt; yetişmen gereken bir sayı yok. Tek hedef, süre ilerlerken ve kolların yorulurken çalıştığın formu korumak.

İkinci bir raunt olmasa da ona devam edebileceğin tempoda çalış. Ellerini geri getiremeyecek kadar hızlı yumruk atıyorsan yumruğu değil, hatayı tekrarlıyorsun.

İkinci dakika civarında arkadaki el biraz aşağıda kalmaya başlayabilir. Bu bir kişilik kusuru değil, yorgunluktur. Raunt bunun için vardır: formunun nerede bozulduğunu gösterir.

Kamera seni göremese bile saat işlemeye devam eder. Görüntünü kaybederse sessiz kalmak yerine bunu bildirir.''',
  ),
  'boxing.footwork.moving': (
    sourceSha256:
        'e7c042d17114ccbf1bc718b703c6864578c58bafcf299ec1fbcf076d138f1b4f',
    tr: '''Duruşun hareket ederken kendiliğinden korunmaz. Onu iki ayrı parça gibi değil, bir bütün olarak taşımalısın.

Gideceğin yöne yakın ayakla adım at, diğer ayağın aynı mesafeyi izlesin. İleri giderken önce öndeki ayak hareket eder, arkadaki ayak başlangıçtaki açıklığı yeniden kurar. Geri giderken önce arkadaki ayak hareket eder, öndeki ayak onu izler. Ayaklar birbirini geçmez: çaprazlandıklarında ne yumruk atacak ne de savunacak sağlam bir tabanın kalır.

Küçük adımlar büyük adımlardan daha iyidir. Büyük adım mesafeyi hızla kapatır ama seni gereğinden uzun süre tek ayak üstünde bırakır. Küçük adım, hareket boyunca iki ayağını da kullanmana izin verir.

Tabanlarına tamamen basmak yerine ayaklarının ön kısmında kal. Tam taban üzerinde durmak ileri, geri ve yana tepkiyi biraz yavaşlatır.

Ayaklarının çaprazlandığını görebiliyor ve uyarıyoruz. Ancak adımın boyunun veya zamanının doğru olup olmadığını değerlendiremiyoruz; bu, kameradan çok antrenörün gözünü gerektirir.''',
  ),
  'boxing.footwork.step_then_punch': (
    sourceSha256:
        'd6b0dd0acf6e7b350c76e379b428039ae30ddf40dca772b1c8e78b71dbd2c243',
    tr: '''Mesafe dersi şunu söylemişti: uzanma hatası, kol hatası gibi görünen bir ayak çalışması sorunudur. Bu ders o cümlenin ayak kısmı.

Önce mesafeyi kapat. Doğru mesafeye girene kadar adım at; ayağın yere bassın, ancak sonra yumruğu çıkar. Hâlâ öne giderken atılan yumruk gücünü dengeli duruştan değil, hareketin hızından alır. Rastlantıyla sert isabet edebilir ama dengeni bozar.

İpucu, yumruk isabet ettikten hemen sonra ne olduğudur. Yumruk hedefe ulaştığında ağırlığın hâlâ öne gidiyorsa adım ve yumruk sırayla değil, aynı anda gerçekleşmiştir. Duruşuna yeniden yerleşiyorsan sıralama doğrudur.

Amaç yavaşlamak değil. Hızlı boksörler de önce adım atıp ayağını yere basar; sıra yine önce adım, sonra yumruktur, yalnızca daha kısa sürede gerçekleşir.

Yumruktan çıkarken dengeni kaybettiğini görebilir ve uyarabiliriz. Bunun adımı aceleye getirmen veya atlaman yüzünden olduğunu söyleyemeyiz; yalnızca yumruk isabet ederken sağlam bir tabanın olmadığını saptarız.''',
  ),
  'boxing.conditioning.r3': (
    sourceSha256:
        '6f47fb8a451c68393b3220f2a0d68b05c1818fd369559bcea6ca6307999a86c4',
    tr: '''Üçer dakikalık üç raunt; aralarında doksan saniye dinlenme. Bu süreler rastgele bir stil tercihi değil: dersin toplamı on iki dakika, bunun dokuzu çalışma. Kalan süre dinlenmeden oluşur.

İlk raunt kolay gelir; tuzak da budur. Orada seçtiğin tempoyu üçüncü rauntta da sürdürmen gerekir. Sana doğru gelenden biraz yavaş başla.

Dinlenme aralarını kullan. Doksan saniye nefesini toparlamaya yeterli olabilir. Raunta zaten yorgun dönmek vücuduna istemediğin bir formu tekrarlatır.

Kamera seni göremese bile saat işlemeye devam eder. Görüntünü kaybederse bunu söyler, raunt sürer.''',
  ),
  'boxing.conditioning.tempo': (
    sourceSha256:
        'de06cde822e7d2a3460846d94dd0227e665742b684e19aa2440c10e1604623e8',
    tr: '''On dakika, tek raunt, ara yok. Burada amaç aralıksız çalışmak.

Dinlenme, yorgunluğun zamanlamanda yarattığı değişimi sıfırlar. Bu dersin izlediği şey de tam olarak bu değişimdir. Çalışmayı parçalara bölersen yorulan bir boksörü bir kez izlemek yerine taze başlayan boksörü üç kez izlemiş olursun.

Tek bir tempoyu koru. En hızlısını veya aşırı yavaşını değil, dokuzuncu dakikada da sürdürebileceğin hızı seç. Çoğu kişi bunun başlangıç temposunun yaklaşık üçte ikisi olduğunu görür.

Tempoyu yumruğun uzama süresinden okuyoruz; ekranda bir şeyin ne kadar hızlı yer değiştirdiğinden değil. Bu nedenle kameraya yakın yavaş bir kol ile uzaktaki hızlı bir kol ölçümü aynı şekilde yanıltmaz.

Bu temponun formunu bozup bozmadığını değerlendirmiyoruz; o kararı sen vermelisin.''',
  ),
  'boxing.conditioning.r5': (
    sourceSha256:
        '622632690dfe705eed82a449ba6ea22784b54d45a98bb04e3511719564f79ce4',
    tr: '''Tek raunt, beş dakika. Bilerek bir boks raundundan uzun: burada müsabaka değil kondisyon çalışıyorsun.

Üçüncü dakikadan sonra eforun sürerken formun bozulmaya başlayabilir. Eller biraz aşağı iner, geri dönüş yavaşlar, ayaklar başlangıç konumuna dönmez. Büyük bir değişiklik gibi görünmez; bu yüzden dikkat etmeye değer.

Bunu fark edince açığı kapatmak için hızlanma. Formun geri gelene kadar yavaşla. Burada temiz bir dakika, bozuk formla geçen iki dakikadan değerlidir.

Dinlenme yok; çünkü ardından ikinci bir raunt gelmiyor.''',
  ),
  'boxing.conditioning.r10': (
    sourceSha256:
        '9c5a3656497aeea0f06aff31a1c61cbc03337f49d55694bf186d1eaec2982f16',
    tr: '''Dinlenme aralarıyla üç raunda bölünmüş on dakikalık çalışma.

Raunt başına iki yüz saniye gelenekten değil, hesaptan gelir: on dakikalık çalışma üçe bölünür. Yirmi dakikalık derste aynı hesap ayrı yapıldığında da raunt süresi aynıdır.

Dinlenme oranını üçe üç dersinden aldık; bunu ayrıca ölçmedik. Kontrol edemediğin bir sayının en azından nereden geldiğini bilmeni istiyoruz.

Üçüncü raundu birinci raundaki formunla bitirmeye çalış. Egzersizin hedefi budur.''',
  ),
  'boxing.conditioning.r20': (
    sourceSha256:
        'b550930d306c899d6b28c222dc6386870c37a3fa7ce11c76d2f1e68122643c39',
    tr: '''Altı raunt, yirmi dakika çalışma. Bu kurstaki en uzun seans.

Rauntlar arasında altmış saniye var. Bu, ölçümle belirlenmiş bir süre değil, boks köşesindeki yaygın mola süresinden alınmış bir seçim. Yorgunluğun sonraki raunda taşınmasına yetecek kadar kısa; uzun seansın amacı da bu.

Dördüncü rauntta formunun önce hangi bölümünün bozulduğunu fark edebilirsin. Birçok kişide önce arkadaki el, sonra elin geri dönüşü, ardından ayaklar etkilenir. Kendi sıranı öğrenmek, gösterebileceğimiz herhangi bir puandan daha değerlidir.

Seans uygulamanın takibini de sınayacak kadar uzun; uygulama görüntünü kaybederse bunu bildirir.''',
  ),
  'boxing.conditioning.hiit': (
    sourceSha256:
        '97c0650d49e64b4eb982e6c5fbe7dee9a1caed1410c592a04c01f345fd2eded4',
    tr: '''Otuzar saniyelik on iki yoğun bölüm; her birinin arasında otuz saniye toparlanma. On iki dakikalık sürenin altı dakikası çalışmadır.

Yoğun bölümde gerçekten yüksek tempoda çalış. Bu derste hız, hareketin kusursuzluğunun önüne geçer.

Bu yoğunlukta formun bozulması beklenir; bunu başarısızlık sayma. Senden formunu zorlayan bir tempo istedik. Buradaki düzeltmeleri raunt hakkında hüküm olarak değil, sınırını gösteren bilgi olarak değerlendir.

Otuz saniye çalışma, otuz saniye dinlenme yaygın bir başlangıç düzenidir; bizim ölçümümüz değil. Fazla geliyorsa çalışma bölümünü kısaltmak yerine yoğunluğu yaklaşık dörtte üçe indir. Süreyi doğru tutmak, burada yoğunluktan daha önemlidir.''',
  ),
  'boxing.conditioning.technique_round': (
    sourceSha256:
        '215dae759c1ee94345dbee3638964716ca55785027c2832e94a7b7025e00e896',
    tr: '''Üçer dakikalık üç raunt. Bu, form geri bildiriminin çalışma boyunca açık kaldığı tek raunt türü.

Bu yüzden buradaki en yavaş ders olmalı. Amaç süreye çok sayıda yumruk sığdırmak değil, her yumruğu bir öncekine benzer biçimde atmak.

Sürekli geri bildirim vermenin bir sakıncası olabilir; bunu gizlemeyelim: her tekrarda düzeltilmek, hareketi öğrenmek yerine uyarıya bağımlı kalmana yol açabilir. Şimdilik bu bir olasılık. Düzeltme yalnızca kamera seni okuyabildiğinde görünür; gerçek cihazda bunu düzenli yapabildiğinde geri bildirimin biçimini yeniden incelemek gerekecek.

Dinlenme doksan saniye; bu çalışma için cömert bir süre. Burada dinlenme nefeslenmekten çok yeniden hazırlanmak içindir. Sonraki raunt, önceki raundun bozulan formuyla değil, kurduğun duruşla başlasın.''',
  ),
  'boxing.intermediate.fatigue': (
    sourceSha256:
        '0a3bf69a6102b4a797b40f31fb88483fd261ec6bb9674a419616299822cc7ccb',
    tr: '''Beşer dakikalık dört raunt. Rauntlar bilerek uzun tutuldu; aynı yirmi dakikayı altı kısa raunda bölmek, yirmi dakikalık dersi tekrar etmek olurdu.

Bitirebilmek için tempoyu değiştirme. Amaç tek bir tempoyu, sınırın isteğin değil tekniğin olana kadar korumak.

Dinlenme altmış saniye ve bilerek kısa. Rauntlar arasında yorgunluk taşınmazsa değişimin izini göremeyiz.

Aradığın cevap bitirip bitirmediğin değil; önce neyin, ne kadar erken bozulduğu. Bu cevap sana ait ve yanında bir sayı olması gerekmiyor.''',
  ),
};
