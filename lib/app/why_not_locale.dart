import 'package:flutter/widgets.dart';

import '../shell_candidate/shell_models.dart';
import 'ui_language.dart';

const String _englishIntro =
    'Some of this a phone camera cannot see. Some of it needs a second person. And some of it nobody could honestly tell you, however much we measured. Rather than ship a version that guesses, we leave them out and say which is which.';
const String _turkishIntro =
    'Telefon kamerası bunların bir kısmını göremez. Bazıları ikinci bir kişiyi gerektirir. Bazılarında ise ne kadar ölçüm yapsak da dürüstçe hüküm veremeyiz. Tahmin eden bir sürüm yayımlamak yerine bunları dışarıda bırakıp nedenini söylüyoruz.';

String whyNotIntro(BuildContext context, String source) =>
    source == _englishIntro
    ? UiLanguage.text(context, en: source, tr: _turkishIntro)
    : source;

typedef _ExclusionCopy = ({String enReason, String trTitle, String trReason});

// ShellExclusion has no ID. Both English fields must still match the authored
// source, or the new source remains visible until reviewed.
const Map<String, _ExclusionCopy> _exclusions = <String, _ExclusionCopy>{
  'Brazilian Jiu-Jitsu': (
    enReason:
        'Grappling is defined by contact and resistance from another person. A solo camera sees neither, so any score would be invented.',
    trTitle: 'Brezilya Jiu-Jitsusu',
    trReason:
        'Grappling, başka bir kişinin teması ve direnciyle tanımlanır. Tek kişiyi gören kamera bunların hiçbirini göremez; verilecek puan uydurma olur.',
  ),
  'Wrestling': (
    enReason:
        'Same reason as BJJ: the technique lives in the connection between two bodies. Solo drilling exists, but grading it would mean grading the half you can see.',
    trTitle: 'Güreş',
    trReason:
        'BJJ ile aynı neden: teknik iki bedenin etkileşimindedir. Tek başına tekrar çalışılabilir, fakat bunu puanlamak yalnızca görebildiğimiz yarıyı puanlamak olur.',
  ),
  'Judo': (
    enReason:
        "Throws depend on your partner's balance and reaction. Uchikomi without a partner is a movement rehearsal, not the technique.",
    trTitle: 'Judo',
    trReason:
        'Atışlar partnerinin dengesine ve tepkisine bağlıdır. Partnersiz uchikomi hareket provasıdır; tekniğin tamamı değildir.',
  ),
  'Weapon arts (kendo, escrima, HEMA…)': (
    enReason:
        'The technique is defined by where the weapon is. Pose estimation tracks the body, not the object, so the part that matters most is invisible.',
    trTitle: 'Silahlı sanatlar (kendo, escrima, HEMA…)',
    trReason:
        'Tekniği silahın konumu belirler. Poz tahmini nesneyi değil bedeni izler; bu yüzden en önemli bölüm görünmez.',
  ),
  'Clinch and sparring': (
    enReason:
        'Both need a second person. We support solo drills that prepare you for them, and we say clearly that this is not the same thing.',
    trTitle: 'Clinch ve sparring',
    trReason:
        'İkisi de ikinci bir kişi gerektirir. Bunlara hazırlayan tek kişilik çalışmaları destekliyoruz ve bunun aynı şey olmadığını açıkça söylüyoruz.',
  ),
  'Punch power': (
    enReason:
        'Force needs a sensor. A camera can estimate timing and tempo — we show those as bands — but we will not print a power number we cannot measure.',
    trTitle: 'Yumruk gücü',
    trReason:
        'Kuvveti ölçmek için sensör gerekir. Kamera zamanlama ve tempoyu tahmin edebilir; bunları aralık olarak gösteriyoruz. Ölçemediğimiz bir güç sayısını göstermiyoruz.',
  ),
  'Self-defence guarantees': (
    enReason:
        'We can help you train movement. Nobody can promise how a real situation goes, and an app that implies otherwise is doing you harm.',
    trTitle: 'Öz savunma garantisi',
    trReason:
        'Hareket çalışmana yardımcı olabiliriz. Gerçek bir durumun nasıl sonuçlanacağını kimse garanti edemez; bunu ima eden bir uygulama sana zarar verir.',
  ),
  'Slipping and rolling': (
    enReason:
        "We can see your head move. We cannot tell you whether it was the right move, because right is defined by a punch that isn't there. Grading a slip with nothing to slip would be grading a guess.",
    trTitle: 'Başla kaçınma ve sıyrılma',
    trReason:
        'Başının hareketini görebiliriz. Ancak ortada kaçınılacak bir yumruk olmadığı için hareketin doğru olup olmadığını söyleyemeyiz. Gerçek bir saldırı yokken kaçınmayı puanlamak tahmini puanlamak olur.',
  ),
  'Heavy bag and pad work': (
    enReason:
        'We track your body, not the bag — so the thing a coach actually watches, how the bag moves, is invisible to us. Contact also changes what we do read: a punch that lands stops early and returns differently from one that travels free.',
    trTitle: 'Kum torbası ve pad çalışması',
    trReason:
        'Torbayı değil bedenini izliyoruz; antrenörün baktığı torbanın hareketi bize görünmez. Temas, okuyabildiğimiz hareketi de değiştirir: hedefe değen yumruk daha erken durur ve boşluğa atılandan farklı geri döner.',
  ),
  'Breathing': (
    enReason:
        'A phone across the room cannot hear you, and chest movement during boxing is mostly the boxing. Telling you to breathe on a schedule we cannot check would be advice dressed as feedback.',
    trTitle: 'Nefes',
    trReason:
        'Odanın karşısındaki telefon nefesini duyamaz; boks sırasındaki göğüs hareketinin çoğu da boks hareketidir. Doğrulayamadığımız bir nefes düzenini geri bildirim gibi sunmuyoruz.',
  ),
  'Pain and injury': (
    enReason:
        'We read shape, not tissue. Nothing here can tell a sore shoulder from a tired one, and nothing here is medical advice. If something hurts, that decision belongs to you and a professional, not to a camera.',
    trTitle: 'Ağrı ve sakatlık',
    trReason:
        'Dokuyu değil hareket biçimini okuyoruz. Buradaki hiçbir ölçüm ağrıyan omuz ile yorulan omuzu ayıramaz; burada tıbbi tavsiye yoktur. Bir şey ağrıyorsa karar kameraya değil sana ve bir uzmana aittir.',
  ),
  "Whether you're ready to spar": (
    enReason:
        'That call weighs things we never see: how you take a shot, how you behave when tired and hit, who you would be in with. A number from solo practice cannot carry it, so we do not print one.',
    trTitle: 'Sparringe hazır olup olmadığın',
    trReason:
        'Bu karar, göremediğimiz şeyleri de içerir: darbeyi nasıl karşıladığın, yorgunken ve darbe aldığında nasıl davrandığın, kiminle çalışacağın. Tek kişilik antrenmanın sayısı bu kararı taşıyamaz; böyle bir sayı göstermiyoruz.',
  ),
};

List<ShellExclusion> whyNotExclusions(
  BuildContext context,
  List<ShellExclusion> source,
) {
  return source
      .map((ShellExclusion item) {
        final _ExclusionCopy? translated = _exclusions[item.title];
        if (translated == null || translated.enReason != item.reason) {
          return item;
        }
        return ShellExclusion(
          UiLanguage.text(context, en: item.title, tr: translated.trTitle),
          UiLanguage.text(context, en: item.reason, tr: translated.trReason),
        );
      })
      .toList(growable: false);
}
