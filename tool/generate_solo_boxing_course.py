#!/usr/bin/env python3
"""Author and deterministically render JabLab's original TR/EN solo course.

The teaching text is original paraphrase linked to governing-body manuals.
No third-party video, image, audio, or pose sequence is included or trained on.
Run with --check to verify the committed JSON matches this source.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def L(en: str, tr: str) -> dict[str, str]:
    return {"en": en, "tr": tr}


sources = [
    {
        "id": "boxing_canada_beginner",
        "publisher": "Boxing Canada",
        "title": "Instruction Beginners Reference Manual",
        "url": "https://boxingcanada.org/wp-content/uploads/2025/01/Instruction-Beginners-Reference-Manual-EN.pdf",
    },
    {
        "id": "boxing_canada_competition",
        "publisher": "Boxing Canada",
        "title": "Competition Introduction Manual",
        "url": "https://boxingcanada.org/wp-content/uploads/2025/06/Competition-Introduction-manual-EN.pdf",
    },
    {
        "id": "england_boxing_level1",
        "publisher": "England Boxing",
        "title": "Boxing Coaching Handbook Part 1",
        "url": "https://www.englandboxing.org/wp-content/uploads/2022/03/EB_Boxing-Coaching-Handbook-Part-1_v8-002.pdf",
    },
    {
        "id": "acog_pregnancy",
        "publisher": "American College of Obstetricians and Gynecologists",
        "title": "Exercise During Pregnancy",
        "url": "https://www.acog.org/womens-health/faqs/exercise-during-pregnancy",
    },
    {
        "id": "cdc_activity",
        "publisher": "US Centers for Disease Control and Prevention",
        "title": "Adding Physical Activity as an Adult",
        "url": "https://www.cdc.gov/physical-activity-basics/adding-adults/index.html",
    },
]

modules: list[dict] = []
previous_lesson: str | None = None
current_module: dict | None = None


def module(module_id: str, title: dict, intro: dict) -> None:
    global current_module
    current_module = {"id": module_id, "title": title, "intro": intro, "lessons": []}
    modules.append(current_module)


def lesson(
    slug: str,
    title: dict,
    objective: dict,
    steps: list[dict],
    practice: dict,
    self_checks: list[dict],
    adaptation: dict,
    stop_signal: dict,
    media_brief: dict,
    source_ids: list[str],
    minutes: int = 10,
) -> None:
    global previous_lesson
    assert current_module is not None
    lesson_id = f"{current_module['id']}.{slug}"
    current_module["lessons"].append(
        {
            "id": lesson_id,
            "title": title,
            "objective": objective,
            "steps": steps,
            "practice": practice,
            "selfChecks": self_checks,
            "adaptation": adaptation,
            "stopSignal": stop_signal,
            "mediaBrief": media_brief,
            "prerequisites": [previous_lesson] if previous_lesson else [],
            "sourceIds": source_ids,
            "minutes": minutes,
            "evidenceMode": "self_report",
        }
    )
    previous_lesson = lesson_id


module(
    "boxing.start",
    L("Start safely", "Güvenli başlangıç"),
    L("Prepare a clear solo space, then learn a balanced stance before throwing a punch.",
      "Yumruk atmadan önce boş bir çalışma alanı ve dengeli duruş kur."),
)

lesson(
    "space",
    L("Your space and the rules", "Alan ve çalışma kuralları"),
    L("Set up a non-contact practice space and understand what this course can observe.",
      "Temassız çalışma alanını hazırla ve kursun neyi gözlemleyebildiğini öğren."),
    [L("Clear an arm's reach plus two small steps in every direction. Use a stable floor, shoes that do not slip, and no partner or bag.",
       "Her yönde kol erişimi ve iki küçük adım kadar alanı boşalt. Kaymayan zemin ve ayakkabı kullan; eş veya torba kullanma."),
     L("Begin with this relaxed space check. This course records your own practice report; it cannot measure impact, joint safety or mastery.",
       "Bu rahat alan kontrolüyle başla. Bu kurs kendi çalışma beyanını kaydeder; darbe gücünü, eklem güvenliğini veya ustalığı ölçemez.")],
    L("Walk the perimeter, extend one arm slowly, then make two easy steps in each direction without touching an object.",
      "Alanı dolaş, bir kolunu yavaşça uzat ve hiçbir nesneye değmeden her yöne iki kolay adım at."),
    [L("I can move without hitting furniture or another person.", "Mobilyaya veya birine çarpmadan hareket edebiliyorum."),
     L("I know this is solo practice, not a contact or safety assessment.", "Bunun temas veya güvenlik değerlendirmesi değil, tek başına çalışma olduğunu biliyorum.")],
    L("Begin with a shorter seated orientation or smaller steps if standing practice is difficult; a clinician can advise on condition-specific limits.",
      "Ayakta çalışma zorsa daha kısa oturarak hazırlık veya küçük adımlar seç; duruma özel sınırlar için sağlık uzmanına danış."),
    L("Stop if the floor feels unsafe, you feel dizzy, or you develop chest pain or unusual breathlessness.",
      "Zemin güvensiz gelirse, başın dönerse, göğüs ağrısı veya olağandışı nefes darlığı olursa dur."),
    L("Original overhead room diagram and side view: clear floor, no partner, no impact; subtitles in both languages.",
      "Özgün üstten alan şeması ve yandan görünüm: boş zemin, eş ve darbe yok; iki dilde altyazı."),
    ["boxing_canada_beginner", "cdc_activity", "acog_pregnancy"],
    6,
)

lesson(
    "stance",
    L("Find your stance", "Duruşunu bul"),
    L("Choose a comfortable lead side and return to a balanced base.",
      "Rahat bir ön taraf seç ve dengeli tabana dönebil."),
    [L("Place one foot a small step ahead and keep space between the feet. Knees stay soft; keep the head over the base rather than leaning to reach.",
       "Bir ayağını küçük bir adım öne al ve ayaklar arasında açıklık bırak. Dizleri rahat tut; uzanmak için öne eğilmek yerine başını tabanın üzerinde tut."),
     L("Try both lead sides without forcing a 'correct' dominant side. Make a tiny forward and backward rock; neither heel nor toe should carry you away.",
       "Zorunlu bir baskın taraf seçmeden iki önü de dene. Çok küçük öne ve arkaya salın; topuğa veya parmak ucuna düşme.")],
    L("Hold each side for three relaxed breaths, then step out and rebuild the same stance five times.",
      "Her tarafı üç rahat nefes tut, sonra çıkıp aynı duruşu beş kez yeniden kur."),
    [L("My feet are separated rather than on one line.", "Ayaklarım tek çizgide değil, aralarında açıklık var."),
     L("I can stop the small rock without needing a rescue step.", "Küçük salınımı ek denge adımı atmadan durdurabiliyorum.")],
    L("Use a shorter stance or hold a wall during orientation; avoid a stance width that causes discomfort.",
      "İlk öğrenmede daha kısa duruş veya duvar desteği kullan; rahatsız eden açıklığı zorlama."),
    L("Stop if the stance causes joint pain or you cannot keep balance in the available space.",
      "Duruş eklem ağrısı yaparsa veya alanda dengeyi koruyamazsan dur."),
    L("Original front and side silhouettes show foot separation and neutral balance, without numerical angle labels.",
      "Özgün ön ve yan siluetler ayak açıklığını ve dengeli ağırlığı gösterir; sayısal açı etiketi kullanma."),
    ["boxing_canada_beginner"],
)

lesson(
    "guard",
    L("A relaxed guard", "Rahat gard"),
    L("Keep both hands available without stiffening the shoulders.",
      "Omuzları kasmadan iki eli de hazır tut."),
    [L("For this non-contact practice, curl the fingers gently and rest the thumb outside them, never tucked inside. Keep the wrist comfortably in line with the forearm and avoid squeezing hard; this is not an impact or bag drill.",
       "Bu temassız çalışma için parmakları hafifçe kıvır; başparmak dışlarında dursun, içeride sıkışmasın. Bileği önkolla rahat hizada tut, eli sert sıkma; bu darbe veya torba alıştırması değildir."),
     L("Bring the rear hand near the cheek and the lead hand slightly ahead. Keep elbows comfortably toward the ribs and eyes forward.",
       "Arka eli yanağa yakın, ön eli biraz önde tut. Dirsekleri rahatça kaburgalara yaklaştır, bakışı ileri ver."),
     L("Release the shoulders and hands between repetitions. A guard is a movable starting place, not a frozen pose.",
       "Tekrarlar arasında omuz ve elleri gevşet. Gard donmuş bir poz değil, hareketli bir başlangıç yeridir.")],
    L("Raise the guard, lower it, and rebuild it ten slow times. Turn slightly side-on while keeping both hands visible to yourself.",
      "Gardı kaldır, indir ve on kez yavaşça yeniden kur. İki elini de görebilerek hafif yana dön."),
    [L("I can see ahead without hiding behind my gloves.", "Ellerimin arkasına saklanmadan ileriyi görebiliyorum."),
     L("My shoulders can relax while the hands remain ready.", "Eller hazırken omuzlarımı gevşetebiliyorum.")],
    L("Lower the hands between sets or shorten the hold if shoulders tire; choose a comfortable range with a qualified coach if needed.",
      "Omuzlar yorulursa setler arasında elleri indir veya tutuşu kısalt; gerekirse rahat aralığı nitelikli antrenörle seç."),
    L("Stop for sharp shoulder, elbow or wrist pain; fatigue is not a reason to force the guard higher.",
      "Keskin omuz, dirsek veya bilek ağrısında dur; yorgunluk gardı zorla yükseltme nedeni değildir."),
    L("Original three-quarter view: begin with a close-up of the thumb outside softly curled fingers and comfortable wrist, then show hands, elbows and sightline with relaxed shoulders. No impact demonstration.",
      "Özgün üç çeyrek görünüm: önce hafif kıvrılmış parmakların dışındaki başparmağı ve rahat bileği yakından, ardından elleri, dirsekleri ve bakışı gevşek omuzlarla göster. Darbe gösterimi yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "breath",
    L("Breath and easy pace", "Nefes ve rahat tempo"),
    L("Move and breathe without holding the breath during effort.",
      "Çaba sırasında nefesi tutmadan hareket et."),
    [L("Take an ordinary breath while settling in guard; exhale gently as one hand extends and breathe again on the return.",
       "Gardda normal nefes al; bir el uzanırken yumuşakça nefes ver ve dönüşte yeniden nefes al."),
     L("Keep a pace at which you could still speak a short sentence. This is preparation, not a speed test.",
       "Kısa bir cümle söyleyebileceğin tempoda kal. Bu hazırlıktır, hız sınavı değil.")],
    L("Alternate ten tiny hand reaches with easy breathing; rest whenever you need it.",
      "Kolay nefesle dönüşümlü on küçük el uzatması yap; gerektiğinde dinlen."),
    [L("I did not hold my breath to finish a reach.", "Uzanmayı bitirmek için nefesimi tutmadım."),
     L("I could slow down without losing my stance.", "Duruşumu bozmadan yavaşlayabildim.")],
    L("Reduce the number of reaches or practise breathing in a supported stance; seek condition-specific advice before exertion when appropriate.",
      "Uzanma sayısını azalt veya destekli duruşta nefes çalış; gerektiğinde efor öncesi duruma özel danışmanlık al."),
    L("Stop if breathing feels unusually difficult, you feel faint, or chest discomfort appears.",
      "Nefes olağandışı zorlaşırsa, bayılacak gibi olursan veya göğüs rahatsızlığı başlarsa dur."),
    L("Original close and wide alternation: gentle exhale with one reach, visible pause, no speed meter.",
      "Özgün yakın ve geniş açı geçişi: tek uzanmada yumuşak nefes veriş, görünür ara, hız sayacı yok."),
    ["cdc_activity", "england_boxing_level1"],
    8,
)

lesson(
    "reset",
    L("Return to your base", "Tabanına geri dön"),
    L("Recover the same stance and guard after each small movement.",
      "Her küçük hareketten sonra aynı duruş ve garda dön."),
    [L("From guard, step a little to one side, stop, check the space between your feet, then bring the hands back to their ready place.",
       "Garddan yana küçük adım at, dur, ayak açıklığını kontrol et, sonra elleri hazır yerine getir."),
     L("Repeat on both sides. Keep each reset unhurried; later punches will end in this base.",
       "İki tarafta tekrarla. Her dönüşü acele etmeden yap; ileride yumruklar bu tabanda bitecek.")],
    L("Make five small side steps each way with a full pause and reset after every step.",
      "Her yöne beş küçük yan adım at; her adım sonrası tam durup yeniden yerleş."),
    [L("I can pause without crossing my feet.", "Ayaklarımı çaprazlamadan durabiliyorum."),
     L("Both hands return before I start the next step.", "Sonraki adımdan önce iki elim de yerine dönüyor.")],
    L("Use only a weight shift if stepping is uncomfortable; keep support close during early practice.",
      "Adım rahatsız ediyorsa yalnız ağırlık aktar; ilk çalışmada desteği yakın tut."),
    L("Stop if resetting requires a sudden catch step or causes pain.",
      "Yeniden yerleşmek ani kurtarma adımı gerektirirse veya ağrı yaparsa dur."),
    L("Original wide front view with a pause frame after each step; highlight foot spacing and hand return.",
      "Özgün geniş ön görünümde her adımdan sonra duraklama karesi; ayak açıklığı ve el dönüşünü vurgula."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

module(
    "boxing.footwork",
    L("Move the base", "Tabanı hareket ettir"),
    L("Learn small steps before adding punches; the feet return to a usable stance after every move.",
      "Yumruk eklemeden önce küçük adımları öğren; her hareketten sonra ayaklar kullanılabilir duruşa döner."),
)

lesson(
    "forward_back",
    L("Forward and back", "İleri ve geri"),
    L("Move in either direction without narrowing or crossing the stance.",
      "Duruşu daraltmadan veya ayakları çaprazlamadan iki yönde hareket et."),
    [L("Forward: lead foot starts, rear foot follows. Backward: rear foot starts, lead foot follows. Keep the step small enough to stop midway.",
       "İleri: önce ön ayak, sonra arka ayak. Geri: önce arka ayak, sonra ön ayak. Adımı yarıda durabilecek kadar küçük tut."),
     L("Pause after each pair of steps and check your original foot spacing. Speed comes after you can stop balanced.",
       "Her adım çiftinden sonra durup başlangıçtaki ayak açıklığını kontrol et. Hız, dengede durabildikten sonra gelir.")],
    L("Trace a short line on the floor mentally: five forward-follow steps, five backward-follow steps, each with a pause.",
      "Zihninde yerde kısa bir çizgi izle: beş ileri-takip, beş geri-takip adımı; her birinde dur."),
    [L("The foot nearest the travel direction moved first.", "Gidiş yönüne yakın ayak önce hareket etti."),
     L("My feet never met or passed one another.", "Ayaklarım birleşmedi veya birbirini geçmedi.")],
    L("Reduce travel to a small weight shift or use a stable support if balance is uncertain.",
      "Denge belirsizse yolu küçük bir ağırlık aktarımına indir veya sağlam destek kullan."),
    L("Stop if you stumble, the floor slips, or pain changes your gait.",
      "Tökezlersen, zemin kayarsa veya ağrı yürüyüşünü değiştirirse dur."),
    L("Original overhead foot map and wide side view; arrows show lead-then-rear and rear-then-lead, never crossing.",
      "Özgün üstten ayak haritası ve geniş yan görünüm; oklar ön-arka ve arka-ön sırasını, çaprazlamamayı gösterir."),
    ["boxing_canada_beginner"],
)

lesson(
    "lateral",
    L("Side steps", "Yan adımlar"),
    L("Carry the stance to either side while keeping the same usable spacing.",
      "Aynı kullanılabilir açıklığı koruyarak duruşu iki yana taşı."),
    [L("To the lead side, lead foot starts; to the rear side, rear foot starts. The other foot follows rather than overtaking.",
       "Ön tarafa giderken ön ayak, arka tarafa giderken arka ayak başlar. Diğeri geçmek yerine takip eder."),
     L("Keep the head within the base and the hands in guard. Do not drag the trailing foot across the floor.",
       "Başını tabanın içinde, elleri gardda tut. Arkadan gelen ayağı zeminde sürükleme.")],
    L("Take four small steps to each side and reset after each pair; reverse your lead side and repeat once.",
      "Her yana dört küçük adım at ve her çiftte yeniden yerleş; ön tarafı değiştirip bir kez tekrarla."),
    [L("I could freeze after each step without leaning.", "Her adım sonrası eğilmeden donabildim."),
     L("My trailing foot restored, rather than erased, stance width.", "Takip eden ayağım duruş açıklığını silmek yerine yeniden kurdu.")],
    L("Use two-inch side shifts or a supported standing position when the full step is difficult.",
      "Tam adım zorsa çok küçük yan kaymalar veya destekli ayakta duruş kullan."),
    L("Stop if the knees or ankles hurt or you cannot keep the path clear.",
      "Diz veya ayak bileği ağrırsa ya da yolu boş tutamazsan dur."),
    L("Original front wide shot with floor arrows and freeze frames for restored stance; no foot-speed claim.",
      "Özgün geniş ön çekim, zemin okları ve yeniden kurulan duruşun duraklama kareleri; ayak hızı iddiası yok."),
    ["boxing_canada_beginner"],
)

lesson(
    "diagonal",
    L("Diagonal steps", "Çapraz yönlere adım"),
    L("Change both distance and side without tangling the feet.",
      "Ayakları dolaştırmadan hem mesafeyi hem yönü değiştir."),
    [L("Aim a small step toward a front corner with the nearer foot and let the other restore the base. Repeat toward a back corner.",
       "Ön köşeye yakın ayakla küçük adım at, diğer ayak tabanı yeniden kursun. Arka köşeye de tekrarla."),
     L("Think of the corner as a direction on the floor, not an opponent to chase. Stop before any foot crosses the other.",
       "Köşeyi kovalanacak rakip değil, zemindeki yön olarak düşün. Ayaklar çaprazlanmadan dur." )],
    L("Draw a small X mentally and travel one arm-length along each ray, returning to the centre between rays.",
      "Zihninde küçük bir X çiz; her kola bir kol boyu ilerle ve aralarda merkeze dön."),
    [L("Each trip ended in the same stance width.", "Her yol aynı duruş açıklığında bitti."),
     L("I could name which foot started each direction.", "Her yönde hangi ayağın başladığını söyleyebiliyorum.")],
    L("Shrink the X or trace it with weight shifts only; keep a stable reference point nearby.",
      "X'i küçült veya yalnız ağırlık aktarımıyla izle; yakında sağlam referans bulundur."),
    L("Stop if turning a corner brings dizziness or unexpected joint pain.",
      "Köşe değişimi baş dönmesi veya beklenmedik eklem ağrısı yaparsa dur."),
    L("Original overhead X diagram plus front three-quarter performer view, pausing after each diagonal.",
      "Özgün üstten X şeması ve üç çeyrek ön oyuncu görünümü; her çaprazdan sonra durakla."),
    ["boxing_canada_beginner"],
)

lesson(
    "pivot",
    L("A small pivot", "Küçük dönüş"),
    L("Reorient the stance without twisting a planted knee.",
      "Sabit diz üzerinde burulmadan duruş yönünü değiştir."),
    [L("Move the rear foot in a small arc while the lead foot turns comfortably on the ball; let hips and shoulders face the new direction together.",
       "Arka ayağı küçük yayda taşı, ön ayak rahatça ön kısmında dönsün; kalça ve omuzlar birlikte yeni yöne baksın."),
     L("Make only a modest turn, stop, and rebuild the guard. A pivot is an exit to a new line, not a spin for speed.",
       "Yalnız ölçülü dön, dur ve gardı yeniden kur. Pivot hız için dönme değil, yeni hatta çıkıştır.")],
    L("Make three small turns each way with a full reset and a pause after each.",
      "Her yöne üç küçük dönüş yap; her birinden sonra tam yerleş ve dur."),
    [L("My knee followed the foot rather than twisting under it.", "Dizim sabit ayak altında burulmak yerine ayağı izledi."),
     L("I could hold the final stance without a catching step.", "Son duruşu kurtarma adımı olmadan tutabildim.")],
    L("Use an even smaller arc or step the lead foot to turn if pivoting on one foot is uncomfortable.",
      "Tek ayak üzerinde dönmek rahatsızsa yayı küçült veya ön ayağı da adımlayarak dön."),
    L("Stop with knee, ankle or hip pain, or if the surface grips the foot and forces twisting.",
      "Diz, ayak bileği veya kalça ağrısında ya da zemin ayağı tutup burulmaya zorlarsa dur."),
    L("Original overhead shoe path with no fixed angle target; side cut shows knee and foot turning together.",
      "Özgün üstten ayak yolu, sabit açı hedefi yok; yan kesit dizle ayağın birlikte döndüğünü gösterir."),
    ["boxing_canada_competition"],
)

lesson(
    "enter_exit",
    L("Enter and leave range", "Mesafeye gir ve çık"),
    L("Use footwork to approach an imagined target and leave in balance.",
      "Hayalî hedefe adımla yaklaş ve dengede uzaklaş."),
    [L("Choose a spot ahead at comfortable arm's reach. Step in until a relaxed straight reach could arrive without leaning; do not actually strike an object.",
       "Önde rahat kol erişiminde bir nokta seç. Eğilmeden düz uzanma yetişecek kadar gir; gerçek bir nesneye vurma."),
     L("Step back or diagonally out before resetting. Keep the feet underneath you on entry and exit.",
       "Yeniden yerleşmeden önce geriye veya çapraza çık. Giriş ve çıkışta ayaklarını altında tut." )],
    L("Repeat five entry-pause-exit cycles, alternating the exit direction; the hands stay in guard.",
      "Çıkış yönünü değiştirerek beş gir-dur-çık döngüsü yap; eller gardda kalsın."),
    [L("I reached the imagined spot without folding at the waist.", "Hayalî noktaya belden katlanmadan eriştim."),
     L("My exit left space and a stable base for the next move.", "Çıkış sonraki hareket için alan ve dengeli taban bıraktı." )],
    L("Use a shorter entry or mark a closer imagined spot if balance or reach is limited.",
      "Denge veya erişim sınırlıysa daha kısa giriş veya daha yakın hayalî nokta seç."),
    L("Stop if you begin lunging into furniture or pain changes how you step.",
      "Mobilyaya doğru hamle yapmaya başlarsan veya ağrı adımını değiştirirse dur."),
    L("Original side-on wide frame shows imagined target line, step-in pause and diagonal exit; no impact effect.",
      "Özgün geniş yan kadraj hayalî hedef hattını, giriş duruşunu ve çapraz çıkışı gösterir; darbe efekti yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

module(
    "boxing.straights",
    L("Straight punches", "Düz yumruklar"),
    L("Learn the lead and rear straight line slowly, with a complete return to guard after each action.",
      "Ön ve arka düz hattı yavaşça öğren; her harekette garda tam dön."),
)

lesson(
    "jab_line",
    L("The lead-hand jab", "Ön el jab"),
    L("Extend the lead hand on a direct path while the rear hand stays ready.",
      "Arka el hazır kalırken ön eli doğrudan bir hatta uzat."),
    [L("Begin in guard. Let the lead hand travel toward an imagined eye-level point, without winding it behind the shoulder first.",
       "Garddan başla. Ön eli önce omuz arkasına çekmeden hayalî göz hizası noktasına götür."),
     L("Keep the rear hand near the cheek and the head over the feet. Reach within your comfortable range; do not lock or snap the elbow.",
       "Arka el yanağa yakın, baş ayakların üzerinde kalsın. Rahat menzile uzan; dirseği kilitleme veya sertçe açma.")],
    L("Perform six slow lead-hand reaches to one imagined point, fully pausing in guard between them.",
      "Tek hayalî noktaya altı yavaş ön el uzatması yap; aralarda gardda tam dur."),
    [L("The lead hand took a direct path rather than a wide arc.", "Ön el geniş yay yerine doğrudan yol izledi."),
     L("The rear hand stayed available while the lead hand moved.", "Ön el giderken arka el hazır kaldı.")],
    L("Shorten the reach and reduce repetitions if the shoulder or elbow is uncomfortable; do not force full extension.",
      "Omuz veya dirsek rahatsızsa erişimi ve tekrarı azalt; tam açılmayı zorlama."),
    L("Stop if the wrist, elbow or shoulder hurts sharply or if balance moves beyond the lead foot.",
      "Bilek, dirsek veya omuz keskin ağrırsa ya da denge ön ayağın dışına giderse dur."),
    L("Original three-quarter and side views show lead-hand path and rear-hand guard; no speed or force number.",
      "Özgün üç çeyrek ve yan görünüm ön el yolunu ve arka el gardını gösterir; hız veya kuvvet sayısı yok."),
    ["boxing_canada_beginner"],
)

lesson(
    "jab_return",
    L("The jab comes home", "Jab geri döner"),
    L("Finish a jab by bringing the lead hand back to guard before moving again.",
      "Yeni harekete geçmeden ön eli garda getirerek jabı bitir."),
    [L("Reach to the same imagined point as before. Reverse the path with the elbow and hand returning together; avoid letting the hand hang low on the way back.",
       "Önceki hayalî noktaya uzan. Dirsek ve eli birlikte geri getir; dönüşte elin aşağıda asılı kalmasına izin verme."),
     L("Pause with both hands visible in your own field of view. One reach plus return is a whole repetition.",
       "İki el de kendi görüş alanında iken dur. Bir uzanma ve dönüş tek tam tekrardır.")],
    L("Do two sets of five slow jabs. On each return say 'home' quietly before the next one.",
      "İki set beş yavaş jab yap. Her dönüşte sonraki jabdan önce sessizce 'yerinde' de."),
    [L("I waited for the hand to return before the next reach.", "Sonraki uzanmadan önce elin dönüşünü bekledim."),
     L("My chin and balance did not follow the fist forward.", "Çenem ve dengem yumruğu ileri izlemedi.")],
    L("Use fewer repetitions and a partial reach; a clean return matters more than reaching far.",
      "Daha az tekrar ve kısmi uzanma kullan; temiz dönüş uzak erişimden önemlidir."),
    L("Stop when return quality breaks down or any upper-limb pain appears.",
      "Dönüş niteliği bozulursa veya kolda ağrı başlarsa dur."),
    L("Original split-screen: outbound and return paths with a freeze on the recovered guard, not a punch counter.",
      "Özgün iki bölmeli görüntü: gidiş ve dönüş yolları, yeniden kurulan gardda duraklama; yumruk sayacı yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "double_jab",
    L("Two jabs, one base", "İki jab, tek taban"),
    L("Repeat the lead straight without losing the rear-hand guard or foot spacing.",
      "Arka el gardını ve ayak açıklığını kaybetmeden ön düz yumruğu tekrarla."),
    [L("Send one small jab, let it return, then send a second. The second begins from guard, not from a hand left in midair.",
       "Bir küçük jab gönder, geri getir, sonra ikincisini gönder. İkincisi havada kalmış elden değil garddan başlar."),
     L("Keep the same imagined target and an easy rhythm. Do not speed up until both returns are complete.",
       "Aynı hayalî hedefi ve rahat ritmi koru. İki dönüş de tamamlanmadan hızlanma.")],
    L("Perform five double-jab pairs with a full stance reset between pairs.",
      "Çiftler arasında tam duruş dönüşüyle beş çift jab yap."),
    [L("I could distinguish two separate starts from guard.", "Garddan başlayan iki ayrı çıkışı ayırt edebildim."),
     L("The rear hand did not follow the jabs downward.", "Arka el jablarla birlikte aşağı inmedi.")],
    L("Practise one jab at a time until the return is clear; a smaller reach is acceptable.",
      "Dönüş belirginleşene kadar tek jab çalış; daha küçük erişim kabul edilir."),
    L("Stop when the pair becomes a rushed arm flail or balance is lost.",
      "Çift hareket acele kol savurmaya dönerse veya denge kaybolursa dur."),
    L("Original front three-quarter shot labels start, return, start, return; show rear hand in every frame.",
      "Özgün üç çeyrek ön çekim çıkış, dönüş, çıkış, dönüşü gösterir; her karede arka el görünür."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "rear_straight",
    L("The rear straight", "Arka düz yumruk"),
    L("Coordinate the rear hand with a comfortable turn through the base.",
      "Arka eli tabandan gelen rahat dönüşle eşgüdümle."),
    [L("From guard, allow the rear foot, hip and shoulder to turn as the rear hand travels on a straight imagined line. Keep the lead hand ready.",
       "Garddan arka ayak, kalça ve omzun rahatça dönmesine izin ver; arka el hayalî düz hatta giderken ön el hazır kalsın."),
     L("Do not force a large twist or chase reach by leaning. The whole body stops in a base from which the hand can return.",
       "Büyük burulmayı zorlama veya eğilerek uzak menzili kovalama. Bütün vücut elin dönebileceği tabanda durur.")],
    L("Make six slow rear-hand straights, checking the lead guard and foot position after each.",
      "Altı yavaş arka düz yap; her birinden sonra ön gardı ve ayakları kontrol et."),
    [L("The turn felt comfortable through foot, hip and shoulder, not forced in one joint.",
       "Dönüş tek eklemde zorlanmak yerine ayak, kalça ve omuz boyunca rahattı."),
     L("The lead hand stayed near guard.", "Ön el garda yakın kaldı.")],
    L("Use a small torso turn or a shorter reach; ask a qualified coach about individual movement limits.",
      "Küçük gövde dönüşü veya kısa erişim kullan; kişisel hareket sınırları için nitelikli antrenöre danış."),
    L("Stop for back, hip, knee, shoulder or wrist pain, especially during the turn.",
      "Özellikle dönüşte bel, kalça, diz, omuz veya bilek ağrısında dur."),
    L("Original rear-side three-quarter view and foot inset show comfortable whole-body turn, no fixed angle target.",
      "Özgün arka üç çeyrek görünüm ve ayak yakın planı rahat bütün-vücut dönüşünü gösterir; sabit açı hedefi yok."),
    ["boxing_canada_beginner"],
)

lesson(
    "rear_return",
    L("Recover after the rear straight", "Arka düzden sonra toparlan"),
    L("Return the rear hand and base together before another action.",
      "Yeni harekete geçmeden arka eli ve tabanı birlikte geri getir."),
    [L("After a slow rear straight, bring the rear hand to the cheek as the turning foot and hip settle back into stance.",
       "Yavaş arka düzden sonra dönen ayak ve kalça duruşa yerleşirken arka eli yanağa getir."),
     L("Avoid leaving the rear shoulder ahead or the hand low. Pause after every return and check both hands and feet.",
       "Arka omzu önde veya eli aşağıda bırakma. Her dönüşte durup iki eli ve ayağı kontrol et.")],
    L("Alternate one rear straight and a three-breath guard pause for five repetitions.",
      "Beş kez bir arka düz ve üç nefeslik gard duruşu dönüşümlü yap."),
    [L("The rear hand arrived home before I began again.", "Yeniden başlamadan arka el yerine vardı."),
     L("My stance after the punch matched the stance before it.", "Yumruk sonrası duruşum öncesindekiyle aynıydı.")],
    L("Use a shorter rear-hand path and more time to settle if coordination is hard.",
      "Eşgüdüm zorsa arka el yolunu kısalt ve yerleşmek için daha fazla süre ayır."),
    L("Stop if repeated turning causes discomfort or dizziness.",
      "Tekrarlanan dönüş rahatsızlık veya baş dönmesi yaparsa dur."),
    L("Original side-on sequence includes start, extension, hand return and feet reset as four distinct frames.",
      "Özgün yan dizi başlangıç, uzanma, el dönüşü ve ayak yerleşmesini dört ayrı karede gösterir."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "one_two",
    L("Jab then rear straight", "Jab sonra arka düz"),
    L("Link one lead straight and one rear straight while preserving the guard between them.",
      "Aradaki gardı koruyarak bir ön ve bir arka düz yumruğu bağla."),
    [L("Send a jab and start its return. Then turn into the rear straight while the lead hand comes home; do not send both hands away together.",
       "Jabı gönder ve dönüşünü başlat. Ön el yerine gelirken arka düze dön; iki eli aynı anda uzaklaştırma."),
     L("Finish in the original stance with both hands ready. Make each pair slow enough to identify its two parts.",
       "İki el hazır ve ilk duruşunda bitir. Her çifti iki parçasını seçebilecek kadar yavaş yap.")],
    L("Do six slow one-two pairs with a full pause after each pair; imagine a target, never a person.",
      "Her çift sonrası tam durarak altı yavaş bir-iki yap; insan değil hayalî hedef düşün."),
    [L("The lead hand was returning as the rear hand departed.", "Arka el çıkarken ön el dönüyordu."),
     L("I ended in a stance I could step from.", "Adım atabileceğim bir duruşta bitirdim.")],
    L("Separate the pair with an extra guard pause or return to single punches if timing becomes tangled.",
      "Zamanlama karışırsa çiftin arasına gard duruşu ekle veya tek yumruklara dön."),
    L("Stop if you lose balance or upper-limb pain appears while linking the two actions.",
      "İki hareketi bağlarken denge kaybolursa veya kolda ağrı olursa dur."),
    L("Original wide three-quarter demonstration with two distinct numbered phases and a visible final reset; no combination score.",
      "Özgün geniş üç çeyrek gösterim, iki ayrı numaralı faz ve görünür son yerleşme; kombinasyon puanı yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
    12,
)

module(
    "boxing.defence",
    L("Solo defensive shapes", "Tek başına savunma şekilleri"),
    L("Rehearse planned exits and guard movements without claiming a real attack or reaction time.",
      "Gerçek saldırı veya tepki süresi iddiası olmadan planlı çıkış ve gard hareketleri çalış."),
)

lesson(
    "distance",
    L("First defend with distance", "Önce mesafeyle savun"),
    L("Leave an imagined attack line by stepping to a stable position.",
      "Hayalî saldırı hattından dengeli konuma adımlayarak çık."),
    [L("Mark an imagined line from in front of you. Take one small backward step, recover the trailing foot, then stop in guard.",
       "Önünden gelen hayalî bir hat belirle. Küçük bir geri adım at, takip eden ayağı yerleştir ve gardda dur."),
     L("Repeat with a diagonal exit. These are rehearsed directions, not a tested response to an opponent.",
       "Çapraz çıkışla tekrarla. Bunlar rakibe karşı sınanmış tepki değil, prova edilen yönlerdir.")],
    L("Alternate five backward and five diagonal planned exits, resetting the feet and guard each time.",
      "Beş geri ve beş çapraz planlı çıkış yap; her seferinde ayakları ve gardı yeniden kur."),
    [L("I finished each exit balanced and able to move again.", "Her çıkışı dengede ve yeniden hareket edebilir halde bitirdim."),
     L("I did not call this a measured defensive reflex.", "Bunu ölçülmüş savunma refleksi saymadım.")],
    L("Use shorter exits or a supported weight shift when space or balance is limited.",
      "Alan veya denge sınırlıysa kısa çıkış veya destekli ağırlık aktarımı kullan."),
    L("Stop if an exit approaches an obstacle or makes you stumble.",
      "Çıkış engelle yakınlaşır veya tökezletirse dur."),
    L("Original overhead line and two exit arrows; no incoming human punch or reflex timer.",
      "Özgün üstten hat ve iki çıkış oku; gelen insan yumruğu veya refleks süresi yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "cover",
    L("Compact cover", "Toplu korunma"),
    L("Bring the hands close without losing sight or collapsing the stance.",
      "Görüşü veya duruşu kaybetmeden elleri yaklaştır."),
    [L("From relaxed guard, bring both hands a little closer to the temples and let elbows settle comfortably toward the body.",
       "Rahat garddan iki eli şakaklara biraz yaklaştır ve dirsekleri rahatça gövdeye indir."),
     L("Take one small step out, then return to ordinary guard. Avoid squeezing so hard that shoulders rise and breathing stops.",
       "Küçük bir çıkış adımı at, sonra normal garda dön. Omuzları kaldıracak veya nefesi kesecek kadar sıkma.")],
    L("Practise six cover-step-reset cycles slowly, alternating exit sides.",
      "Çıkış yönünü değiştirerek altı yavaş korun-adımla-dön döngüsü yap."),
    [L("I could still see the imagined line ahead.", "Öndeki hayalî hattı hâlâ görebiliyordum."),
     L("My shoulders relaxed again on returning to guard.", "Garda dönerken omuzlarım yeniden gevşedi.")],
    L("Keep the hands lower within a comfortable range or practise the cover without stepping.",
      "Elleri rahat aralıkta biraz daha aşağıda tut veya adım atmadan korunmayı çalış."),
    L("Stop if neck or shoulder tension becomes painful or breathing is restricted.",
      "Boyun veya omuz gerilimi ağrılı olur ya da nefes kısıtlanırsa dur."),
    L("Original front and side close views show sightline, relaxed shoulders and return to guard.",
      "Özgün ön ve yan yakın çekim görüş hattını, rahat omuzları ve garda dönüşü gösterir."),
    ["boxing_canada_beginner", "boxing_canada_competition"],
)

lesson(
    "catch_parry",
    L("Catch and parry rehearsal", "Karşılama ve yönlendirme provası"),
    L("Distinguish a rear-hand catch from a short outside parry against an imagined jab.",
      "Hayalî jaba karşı arka elle karşılama ile kısa dışa yönlendirmeyi ayırt et."),
    [L("Begin in your stance and imagine a slow jab toward the chin. For the catch, turn the rear palm toward that line close to its guard position; do not reach out.",
       "Duruşunu kurup çeneye doğru yavaş jab hayal et. Karşılamada arka avucu gard konumuna yakınken bu hatta çevir; ileri uzanma."),
     L("Rehearse a small receiving shape with the rear forearm behind the hand. The front hand stays in guard; there is no punch or contact to catch here.",
       "Arka önkol elin arkasındayken küçük karşılama şekli prova et. Ön el gardda kalır; burada karşılanacak gerçek yumruk veya temas yoktur."),
     L("For the outside parry, use the rear hand again: guide it a short distance across the imagined jab line toward the front shoulder, with a small controlled turn. Avoid a wide sweep or pulling the head back.",
       "Dışa yönlendirmede yine arka eli kullan: küçük kontrollü dönüşle eli hayalî jab hattında ön omuza doğru kısa mesafe kaydır. Geniş savurma veya başı geriye çekme."),
     L("Bring the rear hand back to the cheek and reset after either shape. This planned solo drill does not teach reacting to a real punch; live timing needs supervised partner instruction.",
       "İki şekilden sonra da arka eli yanağa getirip yeniden kur. Bu planlı solo alıştırma gerçek yumruğa tepki vermeyi öğretmez; canlı zamanlama gözetimli eş öğretimi gerektirir.")],
    L("Do five small rear-hand catches, then five rear-hand outside parries against an imagined jab. Pause at guard after each and name which shape receives and which redirects.",
      "Hayalî jaba karşı arka elle beş küçük karşılama, ardından beş dışa yönlendirme yap. Her birinden sonra gardda dur; hangi şeklin karşıladığını, hangisinin yönlendirdiğini söyle."),
    [L("I could distinguish receiving from redirecting without a wide hand sweep.", "Eli geniş savurmadan karşılama ile yönlendirmeyi ayırt edebildim."),
     L("The front hand stayed in guard and the rear hand returned after each shape.", "Ön el gardda kaldı; arka el her şekilden sonra yerine döndü.")],
    L("Use even smaller hand motions or keep the elbow supported if upper-limb movement is limited.",
      "Kol hareketi sınırlıysa eli daha az hareket ettir veya dirseği destekle."),
    L("Stop if the shoulder or wrist hurts; do not add an untrained partner strike.",
      "Omuz veya bilek ağrırsa dur; eğitimsiz eş yumruğu ekleme."),
    L("Show two labeled rear-hand shapes from front and side: catch near guard, then short outside parry toward the front shoulder. Keep the front guard visible and show the reset. Use an imagined jab line only, without contact or successful-defence claims.",
      "Önden ve yandan etiketli iki arka el şekli göster: garda yakın karşılama, ardından ön omuza doğru kısa dışa yönlendirme. Ön gardı ve toparlanmayı göster. Yalnız hayalî jab hattı kullan; temas veya başarılı savunma iddiası yok."),
    ["boxing_canada_beginner", "boxing_canada_competition"],
)

lesson(
    "slip",
    L("Small slips", "Küçük sıyrılmalar"),
    L("Move the head slightly off an imagined straight line while staying over the feet.",
      "Ayakların üzerinde kalarak başı hayalî düz hattan biraz çıkar."),
    [L("With eyes ahead and guard available, shift a little through ankles, knees and torso to one side; keep the bend modest.",
       "Bakış ileride ve gard hazırken ayak bileği, diz ve gövdeden biraz yana kay; eğilmeyi ölçülü tut."),
     L("Return to the middle, then try the other side. Avoid dropping the head below the hands or folding sharply at the waist.",
       "Ortaya dön, sonra diğer tarafı dene. Başı ellerin çok altına düşürme veya belden sert katlanma.")],
    L("Make three slow left-middle-right-middle sequences, with a breath and reset between them.",
      "Aralarda nefes ve yeniden yerleşmeyle üç yavaş sol-orta-sağ-orta dizisi yap."),
    [L("I could stop at either side without falling forward.", "İki tarafta da öne düşmeden durabildim."),
     L("My eyes and guard stayed oriented ahead.", "Bakışım ve gardım ileride kaldı.")],
    L("Use a very small weight shift or skip the head movement if neck or balance symptoms make it unsuitable.",
      "Boyun veya denge belirtileri uygunsuz kılıyorsa çok küçük ağırlık aktarımı kullan veya baş hareketini atla."),
    L("Stop for dizziness, headache, neck pain or loss of balance.",
      "Baş dönmesi, baş ağrısı, boyun ağrısı veya denge kaybında dur."),
    L("Original front wide view marks centre and two modest positions; avoid a large dramatic head drop.",
      "Özgün geniş ön görünüm merkez ve iki küçük konumu işaretler; büyük gösterişli baş düşüşünden kaçın."),
    ["boxing_canada_competition", "england_boxing_level1"],
)

lesson(
    "roll",
    L("Controlled roll shape", "Kontrollü yuvarlanma şekli"),
    L("Link a small bend and side shift without twisting or rushing.",
      "Burulmadan veya acele etmeden küçük bükülme ve yan kaymayı bağla."),
    [L("From guard, soften knees a little, move under an imagined high arc, then stand back into a stable stance on the other side.",
       "Garddan dizleri biraz yumuşat, hayalî yüksek yayın altından geç ve diğer yanda dengeli duruşa kalk."),
     L("Keep the arc small and the back comfortable. This rehearses a movement path, not proof that a real hook was avoided.",
       "Yayı küçük, beli rahat tut. Bu bir hareket yolu provasıdır; gerçek kroşeden kaçıldığı kanıtı değildir.")],
    L("Try four slow half-rolls each way with a full upright reset after every one.",
      "Her yöne dört yavaş yarım yuvarlanma dene; her birinden sonra tamamen dikleş."),
    [L("My feet stayed separated and my head returned over the base.", "Ayaklarım ayrı kaldı ve başım tabanın üzerine döndü."),
     L("I could breathe and stop anywhere in the path.", "Yolun herhangi yerinde nefes alıp durabildim.")],
    L("Replace the roll with a small lateral step if bending is uncomfortable; there is no required depth.",
      "Bükülme rahatsızsa yuvarlanma yerine küçük yan adım kullan; zorunlu derinlik yok."),
    L("Stop for dizziness or knee, back or neck pain; do not force a low duck.",
      "Baş dönmesi veya diz, bel ya da boyun ağrısında dur; alçak çömelmeyi zorlama."),
    L("Original wide side view of a modest arc and final stance, with no exact depth or avoidance score.",
      "Özgün geniş yan görünüm küçük yayı ve son duruşu gösterir; kesin derinlik veya kaçınma puanı yok."),
    ["boxing_canada_competition"],
)

module(
    "boxing.curves",
    L("Curved punches", "Kavisli yumruklar"),
    L("Introduce hooks and uppercuts as controlled solo shapes after straight punches and a reliable return to guard.",
      "Düz yumruk ve güvenilir gard dönüşünden sonra kroşe ve aparkatı kontrollü solo şekiller olarak öğren."),
)

lesson(
    "lead_hook",
    L("Lead hook shape", "Ön kroşe şekli"),
    L("Trace a compact lead-hand arc with the body turning together.",
      "Gövde birlikte dönerken ön elle toplu bir yay çiz."),
    [L("From guard, rotate comfortably through the feet and trunk as the lead hand traces a short arc toward an imagined side target.",
       "Garddan ayak ve gövde boyunca rahatça dön; ön el hayalî yan hedefe kısa yay çizsin."),
     L("Keep the wrist comfortable and the elbow neither pinned against the ribs nor thrown far behind. Return the hand and stance together.",
       "Bileği rahat tut; dirseği ne kaburgaya yapıştır ne de geriye savur. Eli ve duruşu birlikte geri getir.")],
    L("Trace six slow lead hooks in the air with a full guard pause between repetitions.",
      "Tekrarlar arasında tam gard duruşuyla havada altı yavaş ön kroşe çiz."),
    [L("The arc stayed compact rather than swinging the whole arm behind me.", "Yay kolu geriye savurmak yerine toplu kaldı."),
     L("The rear hand and final stance remained available.", "Arka el ve son duruş hazır kaldı.")],
    L("Make a smaller arc or rehearse only the gentle body turn if the arm path is uncomfortable.",
      "Kol yolu rahatsızsa yayı küçült veya yalnız yumuşak gövde dönüşünü çalış."),
    L("Stop for wrist, elbow, shoulder, back or knee pain; do not strike a bag with an unreviewed shape.",
      "Bilek, dirsek, omuz, bel veya diz ağrısında dur; denetlenmemiş şekille torbaya vurma."),
    L("Original overhead hand arc and three-quarter body view; show return to guard, no elbow-angle number or impact.",
      "Özgün üstten el yayı ve üç çeyrek gövde görünümü; gard dönüşü göster, dirsek açısı sayısı veya darbe yok."),
    ["boxing_canada_competition", "england_boxing_level1"],
)

lesson(
    "rear_hook",
    L("Rear hook shape", "Arka kroşe şekli"),
    L("Coordinate the rear-hand arc with a small turn and an intact lead guard.",
      "Arka el yayını küçük dönüş ve korunan ön gardla eşgüdümle."),
    [L("Begin in stance, let the rear foot and trunk turn comfortably, and draw a compact rear-hand arc across an imagined line.",
       "Duruştan başla; arka ayak ve gövde rahatça dönsün, arka elle hayalî hat üzerinden toplu yay çiz."),
     L("Keep the lead hand near guard. Let the rear hand return before moving the feet again; do not over-rotate past a balanced base.",
       "Ön eli garda yakın tut. Ayakları yeniden oynatmadan arka eli getir; dengeli tabanı geçecek kadar dönme.")],
    L("Practise four very slow rear hooks, reset, then four more from the opposite lead stance.",
      "Dört çok yavaş arka kroşe çalış, yerleş, sonra ters ön duruştan dört tane daha yap."),
    [L("The opposite hand did not leave guard.", "Diğer el gardı terk etmedi."),
     L("I ended able to stop and step, without spinning.", "Dönüp savrulmadan durup adımlayabilir halde bitirdim.")],
    L("Reduce both the turn and arm arc if coordination or joint comfort is limited.",
      "Eşgüdüm veya eklem rahatlığı sınırlıysa hem dönüşü hem kol yayını küçült."),
    L("Stop if rotational pain appears or you need an uncontrolled extra step.",
      "Dönüş ağrısı başlarsa veya kontrolsüz ek adım gerekiyorsa dur."),
    L("Original rear three-quarter shot with small foot-turn inset and static guard-hand marker.",
      "Özgün arka üç çeyrek çekim, küçük ayak dönüşü yakın planı ve sabit gard eli işareti."),
    ["boxing_canada_competition"],
)

lesson(
    "lead_uppercut",
    L("Lead uppercut shape", "Ön aparkat şekli"),
    L("Lift a compact lead-hand path without dropping the hand far below guard.",
      "Eli gardın çok altına indirmeden toplu ön el yükselişi yap."),
    [L("Start with the lead hand near guard. Soften the knees a little, then let the hand rise on a short imagined inside line as the body returns upright.",
       "Ön el gard yakınında başlasın. Dizleri biraz yumuşat, sonra gövde dikleşirken el hayalî iç hatta kısa yükselsin."),
     L("Do not swing from behind the hip or snap the elbow. Bring the hand back to guard before another repetition.",
       "Kalça arkasından savurma veya dirseği sertçe açma. Sonraki tekrardan önce eli garda getir." )],
    L("Perform six slow lead uppercut paths at a comfortable height with a full reset.",
      "Rahat yükseklikte altı yavaş ön aparkat yolu yap ve tamamen yerleş."),
    [L("The hand began and ended close to guard.", "El garda yakın başlayıp bitti."),
     L("The knees softened without a deep or painful dip.", "Dizler derin veya ağrılı çöküş olmadan yumuşadı.")],
    L("Use a smaller rise or omit the knee bend if it is uncomfortable.",
      "Rahatsızsa yükselişi küçült veya diz bükülmesini çıkar."),
    L("Stop for knee, back, shoulder, elbow or wrist pain; do not force a low starting position.",
      "Diz, bel, omuz, dirsek veya bilek ağrısında dur; alçak başlangıcı zorlama."),
    L("Original side and front views show short upward hand path from guard, without a deep dip or impact target.",
      "Özgün yan ve ön görünüm garddan kısa yukarı el yolunu gösterir; derin çöküş veya darbe hedefi yok."),
    ["boxing_canada_competition"],
)

lesson(
    "rear_uppercut",
    L("Rear uppercut shape", "Arka aparkat şekli"),
    L("Use a compact rear-hand rising path while keeping the lead guard.",
      "Ön gardı koruyarak arka elle toplu yükselen yol kullan."),
    [L("Begin with both hands ready. Allow a small rear-side turn and a gentle knee-softening while the rear hand rises close to the torso.",
       "İki el hazır başla. Arka el gövdeye yakın yükselirken küçük arka taraf dönüşü ve yumuşak diz hareketine izin ver."),
     L("Finish without throwing the shoulder upward or reaching far past the stance; return the rear hand and settle the feet.",
       "Omzu yukarı savurmadan veya duruşu aşan erişim olmadan bitir; arka eli ve ayakları yerine getir.")],
    L("Make five rear uppercut paths slowly and pause after each to check the lead hand.",
      "Beş arka aparkat yolunu yavaşça yap ve her birinde ön eli kontrol etmek için dur."),
    [L("The lead hand stayed available near guard.", "Ön el garda yakın hazır kaldı."),
     L("The movement finished balanced, not leaning behind the target.", "Hareket hedefin arkasına eğilmeden dengede bitti.")],
    L("Keep the rear turn minimal or rehearse the hand path alone if the coordinated move is uncomfortable.",
      "Eşgüdümlü hareket rahatsızsa arka dönüşü azalt veya yalnız el yolunu çalış."),
    L("Stop for back, knee or upper-limb pain, or if you must hold your breath to finish.",
      "Bel, diz veya kol ağrısında ya da bitirmek için nefes tutman gerekiyorsa dur."),
    L("Original rear-side and front split view: short inside rising path, lead guard and final reset.",
      "Özgün arka yan ve ön iki bölmeli görünüm: kısa iç yükseliş, ön gard ve son yerleşme."),
    ["boxing_canada_competition"],
)

lesson(
    "targets",
    L("Change imagined target level", "Hayalî hedef düzeyini değiştir"),
    L("Distinguish head and body lines without changing into a reach or a deep bend.",
      "Uzanmaya veya derin eğilmeye dönüşmeden baş ve gövde hattını ayır."),
    [L("Visualise two empty points at different heights. For the lower point, soften knees slightly and redirect the path while keeping the head over the feet.",
       "Farklı yükseklikte iki boş nokta hayal et. Alçak nokta için dizleri hafif yumuşat, baş ayakların üzerinde kalırken yolu yeniden yönlendir."),
     L("Alternate one comfortable straight at the higher line and one controlled curved shape at the lower line. Never punch a person or object.",
       "Yüksek hatta rahat bir düz, alçak hatta kontrollü bir kavisli şekil dönüşümlü yap. İnsana veya nesneye vurma.")],
    L("Trace four high-low pairs with a guard reset after each pair and no demand for exact height.",
      "Her çift sonrası gard dönüşüyle dört yüksek-alçak çift izle; kesin yükseklik hedefi yok."),
    [L("I changed level without falling over the lead foot.", "Ön ayağın üzerine düşmeden düzey değiştirdim."),
     L("The hands returned to guard after both paths.", "İki yoldan sonra eller garda döndü.")],
    L("Choose two closer, comfortable imaginary levels or keep both at the same level if bending is unsuitable.",
      "Bükülme uygun değilse birbirine yakın rahat iki hayalî düzey seç veya ikisini aynı düzeyde tut."),
    L("Stop if lowering the target produces knee, back or shoulder pain.",
      "Hedefi alçaltmak diz, bel veya omuz ağrısı yaparsa dur."),
    L("Original side view marks two imagined empty target lines and a modest body-level change; no numerical angle or hit animation.",
      "Özgün yan görünüm iki hayalî boş hedef hattını ve küçük gövde düzeyi değişimini gösterir; sayısal açı veya isabet animasyonu yok."),
    ["boxing_canada_competition", "england_boxing_level1"],
)

module(
    "boxing.combinations",
    L("Short combinations", "Kısa kombinasyonlar"),
    L("Join familiar shapes in short, explainable sequences; each ends with guard and balance.",
      "Tanıdık şekilleri kısa, anlaşılır dizilerde bağla; her biri gard ve dengede biter."),
)

lesson(
    "double_jab_cross",
    L("Double jab, rear straight", "Çift jab, arka düz"),
    L("Use the second jab as a separate action before the rear straight.",
      "Arka düzden önce ikinci jabı ayrı hareket olarak kullan."),
    [L("Send jab, return, jab, return, then rear straight. Count the three starts from guard aloud while learning.",
       "Jab, dönüş, jab, dönüş, sonra arka düz gönder. Öğrenirken garddan üç çıkışı sesli say."),
     L("Keep the feet quiet and the rear hand ready during both jabs. After the rear straight, bring it home before stepping away.",
       "İki jab sırasında ayakları sakin, arka eli hazır tut. Arka düzden sonra uzaklaşmadan önce eli yerine getir.")],
    L("Perform five slow three-punch sequences, each followed by a backward exit and full reset.",
      "Beş yavaş üçlü dizi yap; her birinden sonra geri çıkıp tam yerleş."),
    [L("I could pause between the two jabs without losing the sequence.", "İki jab arasında diziyi kaybetmeden durabildim."),
     L("Only one hand left guard at a time.", "Bir anda yalnız bir el garddan ayrıldı.")],
    L("Add a full guard pause between every action or return to the two-jab lesson.",
      "Her hareket arasına tam gard duruşu ekle veya çift jab dersine dön."),
    L("Stop when pace makes the hands hang low or the exit becomes unsafe.",
      "Tempo elleri aşağı bırakırsa veya çıkış güvensizleşirse dur."),
    L("Original wide three-quarter sequence with 1-1-2 captions and a clearly visible backward exit, no order score.",
      "Özgün geniş üç çeyrek dizide 1-1-2 altyazısı ve belirgin geri çıkış; sıra puanı yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "one_two_hook",
    L("One-two, lead hook", "Bir-iki, ön kroşe"),
    L("Add one compact curved action after two controlled straights.",
      "İki kontrollü düzden sonra bir toplu kavisli hareket ekle."),
    [L("Jab and return, rear straight and return, then draw the lead hook arc. Keep each action distinct before linking the rhythm.",
       "Jab ve dönüş, arka düz ve dönüş, sonra ön kroşe yayı çiz. Ritmi bağlamadan önce her hareketi ayrı tut."),
     L("The hook begins from a recovered lead guard, not from a hand left extended after the jab. End with both hands ready.",
       "Kroşe jabdan sonra uzatılmış elden değil, yeniden kurulmuş ön garddan başlar. İki el hazır bitir." )],
    L("Trace four slow 1-2-hook sequences with a complete rest and stance reset between them.",
      "Aralarında tam ara ve duruş dönüşüyle dört yavaş 1-2-kroşe dizisi çiz."),
    [L("The hook was compact rather than an arm swing from behind.", "Kroşe geriden kol savurma yerine topluydu."),
     L("My stance could support a step after the third action.", "Üçüncü hareketten sonra duruşum bir adımı destekleyebilirdi.")],
    L("Practise 1-2 alone or use a smaller final arc until the sequence is comfortable.",
      "Dizi rahatlayana kadar yalnız 1-2 çalış veya son yayı küçült."),
    L("Stop for shoulder, elbow or rotational pain, or when the third action pulls you off balance.",
      "Omuz, dirsek veya dönüş ağrısında ya da üçüncü hareket dengeni bozarsa dur."),
    L("Original three-quarter demonstration with separate jab, rear straight, compact hook frames and full guard recovery.",
      "Özgün üç çeyrek gösterimde ayrı jab, arka düz, toplu kroşe kareleri ve tam gard dönüşü."),
    ["boxing_canada_competition", "england_boxing_level1"],
)

lesson(
    "one_two_uppercut",
    L("One-two, lead uppercut", "Bir-iki, ön aparkat"),
    L("Follow two straights with a small inside rising path while retaining balance.",
      "İki düzden sonra dengeyi koruyarak küçük iç yükseliş ekle."),
    [L("Complete the jab and rear straight as separate actions. After the rear hand returns, soften the knees slightly and lift the lead hand on its short inside line.",
       "Jab ve arka düzü ayrı ayrı bitir. Arka el dönünce dizleri hafif yumuşat ve ön eli kısa iç hattında yükselt."),
     L("Do not dive forward to create the uppercut. Return upright with the lead hand back at guard.",
       "Aparkat için öne dalma. Ön el gardda olacak şekilde dikleş." )],
    L("Make four careful sequences at a speaking pace; pause after each to check both knees and hands.",
      "Konuşabilecek tempoda dört dikkatli dizi yap; her birinde dizleri ve elleri kontrol etmek için dur."),
    [L("The uppercut started near guard, not below the waist.", "Aparkat bel altından değil, garda yakın başladı."),
     L("I could stop after the third action without an extra step.", "Üçüncü hareketten sonra ek adım olmadan durabildim.")],
    L("Replace the uppercut with a short lead-hand reach or omit the knee movement if uncomfortable.",
      "Rahatsızsa aparkatı kısa ön el uzanmasıyla değiştir veya diz hareketini çıkar."),
    L("Stop for back, knee or arm pain, or if breathing becomes strained.",
      "Bel, diz veya kol ağrısında ya da nefes zorlanırsa dur."),
    L("Original side and front split view distinguishes the straight line from the final short rising line; no impact.",
      "Özgün yan ve ön iki bölmeli görünüm düz hattı son kısa yükselen hattan ayırır; darbe yok."),
    ["boxing_canada_competition"],
)

lesson(
    "defend_return",
    L("Planned defend-and-return", "Planlı savunma ve dönüş"),
    L("Rehearse a small exit followed by a single straight without claiming reaction skill.",
      "Tepki becerisi iddia etmeden küçük çıkıştan sonra tek düz çalış."),
    [L("Choose the sequence before starting: cover, diagonal step, reset, jab. Move on your own cue; nobody is attacking.",
       "Başlamadan diziyi seç: korun, çapraz adım, yerleş, jab. Kendi işaretinle hareket et; kimse saldırmıyor."),
     L("The step must end in balance before the jab. Finish with a hand return and a backward exit.",
       "Jabdan önce adım dengede bitmeli. El dönüşü ve geri çıkışla tamamla.")],
    L("Do three rehearsals to each diagonal side, slowly enough to name all five parts.",
      "Beş parçayı adlandırabilecek kadar yavaş, her çapraz tarafa üç prova yap."),
    [L("I did not punch while still falling into the step.", "Adıma doğru düşerken yumruk atmadım."),
     L("I understand this does not test response to a real opponent.", "Bunun gerçek rakibe tepkiyi sınamadığını biliyorum.")],
    L("Use cover-step-reset only, without a punch, if the full chain is tiring or uncomfortable.",
      "Tam zincir yorucu veya rahatsızsa yumruksuz korun-adımla-yerleş yap."),
    L("Stop if you rush into an obstacle or the sequence causes pain or dizziness.",
      "Engele doğru acele edersen veya dizi ağrı ya da baş dönmesi yaparsa dur."),
    L("Original wide floor diagram shows a self-cued five-step sequence; no opponent, incoming strike or reflex score.",
      "Özgün geniş zemin şeması kişinin kendi işaretiyle beş adımı gösterir; rakip, gelen yumruk veya refleks puanı yok."),
    ["boxing_canada_competition", "england_boxing_level1"],
)

lesson(
    "angle_exit",
    L("Combination and angle exit", "Kombinasyon ve açılı çıkış"),
    L("Finish a short combination by changing the line and restoring guard.",
      "Kısa kombinasyonu hattı değiştirip gardı kurarak bitir."),
    [L("Choose either jab-cross or jab-jab-cross. After the last hand returns, make one small side step or pivot to an open line.",
       "Jab-cross veya jab-jab-cross seç. Son el döndükten sonra boş hatta küçük yan adım veya pivot yap."),
     L("Keep the exit separate at first. Count 'hands home, then feet' to avoid moving with both hands away.",
       "Önce çıkışı ayrı tut. İki el uzaktayken hareket etmemek için 'eller yerinde, sonra ayaklar' diye say." )],
    L("Perform five combinations, alternating a side-step and a modest pivot exit.",
      "Beş kombinasyon yap; yan adım ve küçük pivot çıkışını dönüşümlü kullan."),
    [L("Both hands were back before my exit began.", "Çıkış başlamadan iki elim dönmüştü."),
     L("The exit ended in a stance I could continue from.", "Çıkış devam edebileceğim duruşta bitti.")],
    L("Choose the side step instead of pivoting if rotation is uncomfortable; reduce the combination to one jab.",
      "Dönüş rahatsızsa pivot yerine yan adım seç; kombinasyonu tek jaba indir."),
    L("Stop if the exit crosses the feet, approaches an obstacle, or causes joint pain.",
      "Çıkış ayakları çaprazlar, engele yaklaşır veya eklem ağrısı yaparsa dur."),
    L("Original overhead path and wide performer view show clear punch-return-exit phases with no success score.",
      "Özgün üstten yol ve geniş oyuncu görünümü ayrı yumruk-dönüş-çıkış fazlarını gösterir; başarı puanı yok."),
    ["boxing_canada_competition", "england_boxing_level1"],
)

module(
    "boxing.rounds",
    L("Build a round", "Raunt kur"),
    L("Apply a small number of cues in short solo rounds. Time is a practice aid, not a fitness or technique score.",
      "Kısa solo rauntlarda az sayıda ipucu uygula. Süre bir çalışma yardımcısıdır; kondisyon veya teknik puanı değildir."),
)

lesson(
    "short_round",
    L("A short quality round", "Kısa ve temiz raunt"),
    L("Keep one simple theme for a short interval without chasing a punch count.",
      "Yumruk sayısı kovalamadan kısa sürede tek basit tema koru."),
    [L("Choose jab and guard return as the only theme. Work for up to one easy minute, pausing whenever the shape or breathing changes.",
       "Tek tema olarak jab ve gard dönüşünü seç. Şekil veya nefes değişirse durarak en çok bir rahat dakika çalış."),
     L("Rest and reflect on one cue only. A round is useful even when you stop early; quality does not require a fixed number of punches.",
       "Dinlen ve yalnız bir ipucunu düşün. Erken dursan da raunt yararlıdır; kalite sabit yumruk sayısı gerektirmez.")],
    L("Try one 60-second ceiling round with optional pauses, then name one action you could repeat.",
      "İsteğe bağlı duraklamalarla üst sınırı 60 saniye olan tek raunt dene, sonra tekrarlayabileceğin bir hareketi adlandır."),
    [L("I kept the chosen theme clear instead of adding extra techniques.", "Ek teknik eklemek yerine seçilen temayı açık tuttum."),
     L("I took a pause when breathing or control asked for it.", "Nefes veya kontrol gerektirdiğinde ara verdim.")],
    L("Work for 20-30 seconds or replace punches with guard and easy steps if needed.",
      "Gerekirse 20-30 saniye çalış veya yumruk yerine gard ve kolay adım kullan."),
    L("Stop for dizziness, chest pain, unusual breathlessness or a sudden technique breakdown.",
      "Baş dönmesi, göğüs ağrısı, olağandışı nefes darlığı veya ani teknik bozulmada dur."),
    L("Original single fixed wide shot and simple optional timer; no punch score, fatigue estimate or dramatic impact.",
      "Özgün tek sabit geniş çekim ve basit isteğe bağlı sayaç; yumruk puanı, yorgunluk tahmini veya darbe yok."),
    ["england_boxing_level1", "cdc_activity"],
    8,
)

lesson(
    "footwork_round",
    L("A movement-only round", "Yalnız hareket rauntu"),
    L("Sustain a short planned footwork pattern without crossing the feet.",
      "Ayakları çaprazlamadan kısa planlı adım örüntüsünü sürdür."),
    [L("Choose forward, back, side, reset as a four-part loop. Keep hands in guard and use no punches for this round.",
       "Dört parçalı döngü seç: ileri, geri, yan, yerleş. Eller gardda kalsın; bu rauntta yumruk yok."),
     L("Move slowly enough to stop after any step. Change direction only after the base is restored.",
       "Her adımda durabilecek kadar yavaş git. Yönü ancak taban yeniden kurulduktan sonra değiştir.")],
    L("Repeat the loop for up to one minute, then pause and note where spacing drifted.",
      "Döngüyü en çok bir dakika tekrarla, sonra durup açıklığın nerede kaydığını not et."),
    [L("I could stop balanced after every segment.", "Her bölümden sonra dengede durabildim."),
     L("I noticed and corrected foot spacing before moving again.", "Yeniden hareket etmeden ayak açıklığını fark edip düzelttim.")],
    L("Use a smaller loop or weight shifts only when travel space or balance is limited.",
      "Yol veya denge sınırlıysa daha küçük döngü veya yalnız ağırlık aktarımı kullan."),
    L("Stop if you stumble, the floor becomes slippery, or joint pain appears.",
      "Tökezlersen, zemin kayarsa veya eklem ağrısı olursa dur."),
    L("Original overhead four-direction floor loop and wide front stance view; no footwork grade.",
      "Özgün üstten dört yönlü zemin döngüsü ve geniş ön duruş görünümü; ayak çalışması notu yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
)

lesson(
    "imagined_target",
    L("One imagined target", "Tek hayalî hedef"),
    L("Choose a consistent empty target line without increasing reach to chase it.",
      "Hedefi kovalamak için uzanmayı artırmadan tutarlı boş hedef hattı seç."),
    [L("Pick a point in empty air within comfortable reach. Use a jab, rear straight and pause in guard while keeping eyes on the same point.",
       "Rahat erişimde havada bir nokta seç. Aynı noktaya bakarken jab, arka düz ve gard duruşu yap."),
     L("If you would need to lean, take a small step first and reset. Accuracy here is your own path check, not a camera-measured hit.",
       "Eğilmen gerekecekse önce küçük adım atıp yerleş. Buradaki isabet kendi yol kontrolündür; kameranın ölçtüğü vuruş değil." )],
    L("Work up to 45 seconds on one target, then change to another comfortable empty point for a second short set.",
      "Tek hedefte en çok 45 saniye çalış, sonra ikinci kısa set için başka rahat boş nokta seç."),
    [L("I did not lengthen my reach by leaning.", "Eğilerek erişimimi uzatmadım."),
     L("I could return to guard and see the imagined point again.", "Garda dönüp hayalî noktayı yeniden görebildim.")],
    L("Keep the point closer or use only hand tracing if stepping is unsuitable.",
      "Adım uygun değilse noktayı yaklaştır veya yalnız el izleme yap."),
    L("Stop if aiming causes shoulder pain, neck strain or a loss of balance.",
      "Hedefleme omuz ağrısı, boyun gerilimi veya denge kaybı yaparsa dur."),
    L("Original empty translucent target dot at two positions, three-quarter view and no hit marker or precision score.",
      "Özgün boş yarı saydam hedef noktası iki konumda, üç çeyrek görünüm; isabet işareti veya hassasiyet puanı yok."),
    ["boxing_canada_beginner", "england_boxing_level1"],
    10,
)

lesson(
    "pace",
    L("Change pace on purpose", "Temponu bilinçli değiştir"),
    L("Move between easy and moderate self-chosen rhythms while preserving full returns.",
      "Tam dönüşü koruyarak kendin seçtiğin kolay ve orta ritim arasında geç."),
    [L("Begin with a few very easy jab-return cycles, then use a slightly quicker but still controlled rhythm for a short block.",
       "Birkaç çok rahat jab-dönüş döngüsüyle başla, sonra kısa bölümde biraz daha hızlı ama kontrollü ritim kullan."),
     L("Return to easy pace before fatigue changes guard or breathing. These are subjective rhythms; the app does not measure punch speed.",
       "Yorgunluk gardı veya nefesi değiştirmeden kolay tempoya dön. Bunlar öznel ritimlerdir; uygulama yumruk hızını ölçmez." )],
    L("Do three cycles of 20 seconds easy, up to 10 seconds moderate, then rest as needed.",
      "Üç kez 20 saniye kolay, en çok 10 saniye orta tempo ve gerektiği kadar dinlenme yap."),
    [L("I could name the moment control began to fade and slow down.", "Kontrolün azalmaya başladığı anı fark edip yavaşlayabildim."),
     L("The hand still returned fully in both rhythms.", "İki ritimde de el tamamen döndü.")],
    L("Keep all blocks easy or reduce work intervals; avoid prescribed exertion targets for health conditions.",
      "Tüm bölümleri kolay tut veya çalışma aralıklarını kısalt; sağlık durumlarında sabit efor hedefi dayatma."),
    L("Stop immediately for chest pain, dizziness, unusual breathlessness or new joint pain.",
      "Göğüs ağrısı, baş dönmesi, olağandışı nefes darlığı veya yeni eklem ağrısında hemen dur."),
    L("Original side-by-side easy/moderate examples show equal guard returns; no velocity, heart-rate or effort score.",
      "Özgün kolay/orta yan yana örnekler eşit gard dönüşünü gösterir; hız, nabız veya efor puanı yok."),
    ["england_boxing_level1", "cdc_activity"],
)

lesson(
    "personal_plan",
    L("Plan your own short round", "Kendi kısa rauntunu planla"),
    L("Choose a manageable theme, work window and rest before starting.",
      "Başlamadan yönetilebilir tema, çalışma süresi ve dinlenme seç."),
    [L("Choose one footwork pattern, one straight-punch pattern and one planned exit. Put them in an order you can explain aloud.",
       "Bir ayak örüntüsü, bir düz yumruk örüntüsü ve bir planlı çıkış seç. Sesli anlatabileceğin sıraya koy."),
     L("Pick a short time ceiling and a rest option. A changed plan after symptoms or fatigue is good judgement, not failure.",
       "Kısa süre üst sınırı ve dinlenme seçeneği belirle. Belirti veya yorgunlukta planı değiştirmek başarısızlık değil, iyi karardır." )],
    L("Write or say a three-part plan, practise one easy round, then note one part to repeat next time.",
      "Üç parçalı planı yaz veya söyle, bir rahat raunt çalış, sonra gelecek sefere tekrarlanacak bir parçayı not et."),
    [L("I could explain each action's place in the sequence.", "Dizide her hareketin yerini açıklayabildim."),
     L("My plan allowed rest and a safe early stop.", "Planım dinlenmeye ve güvenli erken bitirmeye izin verdi.")],
    L("Choose only stance and one step if a full round is unsuitable; keep the plan individual rather than copying a fixed workload.",
      "Tam raunt uygun değilse yalnız duruş ve tek adım seç; sabit yükü kopyalamak yerine planı kişiselleştir."),
    L("Stop or revise the plan if symptoms, pain or lost balance appear.",
      "Belirti, ağrı veya denge kaybı olursa dur ya da planı değiştir."),
    L("Original editable-looking three-card plan storyboard: movement, technique, exit, with a visible rest choice.",
      "Özgün düzenlenebilir görünümlü üç kart plan: hareket, teknik, çıkış; dinlenme seçeneği görünür."),
    ["england_boxing_level1", "cdc_activity"],
    12,
)

module(
    "boxing.integration",
    L("Independent practice", "Bağımsız çalışma"),
    L("Review the chain, rehearse it twice, then complete a self-directed solo round without a claimed mastery score.",
      "Zinciri gözden geçir, iki kez prova et, sonra ustalık puanı iddiası olmadan kendi solo rauntunu tamamla."),
)

lesson(
    "skill_review",
    L("Check the whole chain", "Bütün zinciri kontrol et"),
    L("Identify the parts you can perform and the parts that still need slow practice.",
      "Yapabildiğin ve yavaş tekrar gerektiren parçaları ayırt et."),
    [L("In order, rebuild stance and guard, move forward and back, jab and return, rear straight and return, then make one small planned exit.",
       "Sırayla duruş ve gardı kur, ileri-geri hareket et, jab ve dönüş, arka düz ve dönüş yap, sonra küçük planlı çıkış yap."),
     L("Add a compact hook or uppercut only if its separate lesson felt comfortable. Mark anything uncertain for repeat rather than hiding it in a fast sequence.",
       "Küçük kroşe veya aparkatı yalnız ayrı dersi rahat geldiyse ekle. Belirsiz parçayı hızlı dizide gizlemek yerine tekrar için işaretle." )],
    L("Walk through the chain three times, speaking the action names and pausing at guard after each.",
      "Hareket adlarını söyleyip her birinden sonra gardda durarak zinciri üç kez geç."),
    [L("I could name one strength and one movement to practise again.", "Bir güçlü yönümü ve tekrar çalışacağım bir hareketi adlandırabildim."),
     L("I did not use speed to cover a missing return or unstable step.", "Eksik dönüşü veya dengesiz adımı örtmek için hıza başvurmadım.")],
    L("Review only the first three elements or omit curved punches; an honest partial chain still informs the next practice.",
      "Yalnız ilk üç parçayı gözden geçir veya kavisli yumrukları çıkar; dürüst kısmi zincir bile sonraki çalışmayı yönlendirir."),
    L("Stop for pain, dizziness, unusual breathlessness or a loss of safe space.",
      "Ağrı, baş dönmesi, olağandışı nefes darlığı veya güvenli alan kaybında dur."),
    L("Original seven-card recap storyboard shows one clean action per card and a user-chosen repeat marker; no grades.",
      "Özgün yedi kartlık özet her kartta temiz bir hareket ve kullanıcı seçimi tekrar işareti gösterir; not yok."),
    ["boxing_canada_beginner", "boxing_canada_competition", "england_boxing_level1"],
    12,
)

lesson(
    "two_round_rehearsal",
    L("Two short rehearsal rounds", "İki kısa prova rauntu"),
    L("Sustain a chosen theme, rest, and repeat while keeping the same safe base.",
      "Seçilen temayı sürdür, dinlen ve aynı güvenli tabanla tekrarla."),
    [L("Round one: simple footwork and two straight punches. Rest as long as needed. Round two: the same base with one optional curved punch or planned exit.",
       "Birinci raunt: basit ayak çalışması ve iki düz yumruk. Gerektiği kadar dinlen. İkinci raunt: aynı tabanla isteğe bağlı bir kavisli yumruk veya planlı çıkış."),
     L("Keep each work window short enough to preserve control. Change or omit the optional element when quality falls; there is no fixed output target.",
       "Her çalışma aralığını kontrolü koruyacak kadar kısa tut. Kalite düşerse isteğe bağlı parçayı değiştir veya çıkar; sabit çıktı hedefi yok." )],
    L("Try two easy rounds of up to one minute each with an unhurried rest between; note one difference you felt.",
      "Aralarında acele etmeden dinlenerek en çok birer dakikalık iki rahat raunt dene; hissettiğin bir farkı not et."),
    [L("My hands and feet returned to a usable starting position in both rounds.",
       "İki rauntta da ellerim ve ayaklarım kullanılabilir başlangıca döndü."),
     L("I adjusted the second round based on the first rather than forcing a preset workload.",
       "Önceden belirlenmiş yükü zorlamak yerine ikinci rauntu ilkine göre uyarladım.")],
    L("Use shorter rounds, longer rest, or one round only when needed; condition-specific exercise limits belong with a clinician.",
      "Gerektiğinde daha kısa raunt, uzun ara veya tek raunt kullan; duruma özel egzersiz sınırları sağlık uzmanıyla belirlenir."),
    L("Stop for chest pain, dizziness, unusual breathlessness, new pain or loss of control.",
      "Göğüs ağrısı, baş dönmesi, olağandışı nefes darlığı, yeni ağrı veya kontrol kaybında dur."),
    L("Original two-panel round storyboard with optional rest and editable work windows; no endurance score or camera verdict.",
      "Özgün iki panelli raunt panosu, isteğe bağlı ara ve ayarlanabilir çalışma aralıkları; dayanıklılık puanı veya kamera hükmü yok."),
    ["england_boxing_level1", "cdc_activity"],
    14,
)

lesson(
    "independent_round",
    L("Your independent solo round", "Bağımsız solo rauntun"),
    L("Choose, perform and reflect on a complete non-contact shadowboxing plan.",
      "Tam temassız gölge boksu planını seç, uygula ve değerlendir."),
    [L("Write a short plan: stance and footwork, a straight combination, a controlled curved shape if comfortable, and a planned exit. Identify a rest and stop option before beginning.",
       "Kısa plan yaz: duruş ve adım, düz kombinasyon, rahatsa kontrollü kavisli şekil ve planlı çıkış. Başlamadan dinlenme ve durma seçeneğini belirle."),
     L("Work one self-chosen easy round, then reflect on balance, guard recovery and breathing. Record what you practised and what to revisit; the app cannot certify boxing skill.",
       "Kendi seçtiğin bir rahat raunt çalış, sonra dengeyi, gard dönüşünü ve nefesi değerlendir. Çalıştığını ve yeniden bakacağını kaydet; uygulama boks becerisini belgelendiremez." )],
    L("Complete one round of a comfortable length, followed by a spoken or written review of two strengths and one next practice goal.",
      "Rahat sürede bir raunt yap; ardından iki güçlü yön ve bir sonraki çalışma hedefini sözlü veya yazılı gözden geçir."),
    [L("I chose the sequence and could explain why each part was included.", "Diziyi ben seçtim ve her parçanın neden bulunduğunu açıklayabildim."),
     L("I stopped, rested or adapted when needed and named a realistic next goal.",
       "Gerektiğinde durup dinlendim veya uyarladım ve gerçekçi bir sonraki hedef belirledim." )],
    L("The complete task can be a very short stance-step-jab-return plan; omit any move that is uncomfortable and seek qualified guidance for individual limits.",
      "Tam görev çok kısa bir duruş-adım-jab-dönüş planı olabilir; rahatsız eden hareketi çıkar ve kişisel sınırlar için nitelikli destek al."),
    L("Stop for chest pain, dizziness, unusual breathlessness, new pain, or an unsafe environment; contact boxing is outside this course.",
      "Göğüs ağrısı, baş dönmesi, olağandışı nefes darlığı, yeni ağrı veya güvensiz ortamda dur; temaslı boks bu kursun dışındadır."),
    L("Original wide continuous solo demo with chapter markers for plan, practice, rest and reflection; no opponent, impact, mastery badge or numeric form grade.",
      "Özgün geniş kesintisiz solo gösterim; plan, çalışma, dinlenme ve öz değerlendirme bölüm işaretleri; rakip, darbe, ustalık rozeti veya sayısal form notu yok."),
    ["boxing_canada_beginner", "boxing_canada_competition", "england_boxing_level1", "cdc_activity", "acog_pregnancy"],
    18,
)

course = {
    "schemaVersion": 1,
    "courseId": "jablab.solo_boxing",
    "version": 1,
    "title": L("Solo boxing: from first stance to independent rounds",
               "Solo boks: ilk duruştan bağımsız raunta"),
    "goal": L("Build a repeatable stance, footwork, straight and curved punch shapes, planned defensive movements and self-directed shadowboxing. Practice is non-contact and completion is self-reported, not certified mastery.",
              "Tekrarlanabilir duruş, ayak çalışması, düz ve kavisli yumruk şekilleri, planlı savunma hareketleri ve bağımsız gölge boksu kur. Çalışma temassızdır; bitirme öz beyandır, belgelenmiş ustalık değildir."),
    "healthNotice": L(
        "If you have an injury, pregnancy or a chronic condition, treat the adaptation ideas as general information and ask a clinician and a qualified coach about your individual limits before deciding what to practise. This course cannot determine personal safety. Contact boxing is outside this course and should be avoided during pregnancy. Stop for chest pain, dizziness, unusual breathlessness or new pain.",
        "Sakatlık, gebelik veya kronik durum varsa uyarlama fikirlerini genel bilgi olarak değerlendir; neyi çalışacağına karar vermeden kişisel sınırlarını sağlık uzmanına ve nitelikli antrenöre danış. Bu kurs kişisel güvenliği belirleyemez. Temaslı boks kurs dışıdır ve gebelikte kaçınılmalıdır. Göğüs ağrısı, baş dönmesi, olağandışı nefes darlığı veya yeni ağrıda dur.",
    ),
    "sources": sources,
    "modules": modules,
}


# Original bilingual focused practice, recall and transfer enrichment.
# Course IDs/version and existing self-report progress remain stable.
course["sources"].extend([{'id': 'motor_spacing_primary',
  'publisher': 'Journal of Physical Therapy Science / J-STAGE',
  'title': 'Effectiveness of motor sequential learning according to practice schedules in healthy '
           'adults; distributed practice versus massed practice',
  'url': 'https://www.jstage.jst.go.jp/article/jpts/27/3/27_jpts-2014-619/_article'}])
lesson_enrichments = {'boxing.start.space': {'steps': [{'en': "Clear an arm's reach plus two small steps in every "
                                         'direction. Use a stable floor, shoes that do not slip, '
                                         'and no partner or bag.',
                                   'tr': 'Her yönde kol erişimi ve iki küçük adım kadar alanı '
                                         'boşalt. Kaymayan zemin ve ayakkabı kullan; eş veya torba '
                                         'kullanma.'},
                                  {'en': 'Begin with this relaxed space check. This course records '
                                         'your own practice report; it cannot measure impact, '
                                         'joint safety or mastery.',
                                   'tr': 'Bu rahat alan kontrolüyle başla. Bu kurs kendi çalışma '
                                         'beyanını kaydeder; darbe gücünü, eklem güvenliğini veya '
                                         'ustalığı ölçemez.'},
                                  {'tr': 'Alan kontrolünü yalnız kol uzatmayla bitirme. Rahat '
                                         'küçük ileri, geri ve yan adımı da dene; eş, torba ve '
                                         'elde ağırlık ekleme.',
                                   'en': 'Do not finish the space check after reaching only. Try '
                                         'small forward, back and side steps too; add no partner, '
                                         'bag or hand weights.'}],
                        'practice': {'tr': 'Alanı dolaş, bir kolunu yavaşça uzat ve hiçbir nesneye '
                                           'değmeden her yöne iki kolay adım at.\n'
                                           '\n'
                                           'Kısa odak çalışması: Mevcut alan turundan sonra her '
                                           'yöne bir küçük adım at, dur ve erişim yolunu bir kez '
                                           'daha kontrol et; alan dar ise çalışma yerini değiştir. '
                                           'Bölümler arasında dinlen; süreyi rahatlığına göre '
                                           'uzat.\n'
                                           '\n'
                                           'Rahat olduğunda tek değişken denemesi: Aynı alan '
                                           'kontrolünü ikinci bir boş yerde tekrar düşün; koşullar '
                                           'uygun değilse orada çalışmayı seçme.\n'
                                           '\n'
                                           'Sonraki pratik: Sonraki uygun oturumda kısa '
                                           'uygulamanın sırasını önce yardımsız hatırla. yalnız '
                                           'karışan kısmı yeniden kontrol et.',
                                     'en': 'Walk the perimeter, extend one arm slowly, then make '
                                           'two easy steps in each direction without touching an '
                                           'object.\n'
                                           '\n'
                                           'Short focused practice: After the existing space '
                                           'check, take one small step each way, stop and check '
                                           'the reach path once more; change location if space is '
                                           'too small. Rest between sections; take longer if you '
                                           'need it.\n'
                                           '\n'
                                           'When comfortable, try changing just one variable: '
                                           'Reconsider the same space check in a second clear '
                                           'location and choose not to practise there if '
                                           'conditions are unsuitable.\n'
                                           '\n'
                                           'Next practice: At the next suitable session, recall '
                                           'the short sequence without reading first. check only '
                                           'the confusing part again.'},
                        'selfChecks': [{'en': 'I can move without hitting furniture or another '
                                              'person.',
                                        'tr': 'Mobilyaya veya birine çarpmadan hareket '
                                              'edebiliyorum.'},
                                       {'en': 'I know this is solo practice, not a contact or '
                                              'safety assessment.',
                                        'tr': 'Bunun temas veya güvenlik değerlendirmesi değil, '
                                              'tek başına çalışma olduğunu biliyorum.'},
                                       {'tr': 'Kol yolu ve küçük ayak adımları için alanı ayrı '
                                              'kontrol ettim; bu pratiğe temas eklemiyorum.',
                                        'en': 'I checked space for arm paths and small foot steps '
                                              'separately and am not adding contact.'}],
                        'sourceIds': ['boxing_canada_beginner',
                                      'cdc_activity',
                                      'acog_pregnancy',
                                      'england_boxing_level1',
                                      'motor_spacing_primary']},
 'boxing.start.stance': {'steps': [{'en': 'Place one foot a small step ahead and keep space '
                                          'between the feet. Knees stay soft; keep the head over '
                                          'the base rather than leaning to reach.',
                                    'tr': 'Bir ayağını küçük bir adım öne al ve ayaklar arasında '
                                          'açıklık bırak. Dizleri rahat tut; uzanmak için öne '
                                          'eğilmek yerine başını tabanın üzerinde tut.'},
                                   {'en': "Try both lead sides without forcing a 'correct' "
                                          'dominant side. Make a tiny forward and backward rock; '
                                          'neither heel nor toe should carry you away.',
                                    'tr': 'Zorunlu bir baskın taraf seçmeden iki önü de dene. Çok '
                                          'küçük öne ve arkaya salın; topuğa veya parmak ucuna '
                                          'düşme.'},
                                   {'tr': 'Ayakları tek çizgiye yerleştirmek veya ağırlığı çok öne '
                                          'taşımak durmayı zorlaştırır. Açıklığı rahatça yeniden '
                                          'kur; küçük salınımı ek adım gerekmeden durdur.',
                                    'en': 'Feet on one line or too much forward leaning make '
                                          'stopping harder. Rebuild comfortable spacing and stop a '
                                          'small rock without needing another step.'}],
                         'practice': {'tr': 'Her tarafı üç rahat nefes tut, sonra çıkıp aynı '
                                            'duruşu beş kez yeniden kur.\n'
                                            '\n'
                                            'Kısa odak çalışması: Mevcut beş yeniden kurmanın '
                                            'ikisinde yalnız ayak açıklığını, ikisinde yalnız '
                                            'sakin durmayı izle; son denemede bir odağı kendin '
                                            'seç. Bölümler arasında dinlen; süreyi rahatlığına '
                                            'göre uzat.\n'
                                            '\n'
                                            'Rahat olduğunda tek değişken denemesi: Bir küçük adım '
                                            'sonrası duruşunu yeniden kur; ilk statik '
                                            'başlangıçtaki açıklığı hatırla.\n'
                                            '\n'
                                            'Sonraki pratik: Sonraki uygun oturumda kısa '
                                            'uygulamanın sırasını önce yardımsız hatırla. Alan ve '
                                            'çalışma kuralları dersini kısaca hatırla; yalnız '
                                            'karışan kısmı yeniden kontrol et.',
                                      'en': 'Hold each side for three relaxed breaths, then step '
                                            'out and rebuild the same stance five times.\n'
                                            '\n'
                                            'Short focused practice: In two of the existing five '
                                            'rebuilds focus only on foot spacing, in two only on a '
                                            'calm stop, and choose one focus yourself for the '
                                            'last. Rest between sections; take longer if you need '
                                            'it.\n'
                                            '\n'
                                            'When comfortable, try changing just one variable: '
                                            'Rebuild the stance after a small step and recall the '
                                            'spacing from the first static start.\n'
                                            '\n'
                                            'Next practice: At the next suitable session, recall '
                                            'the short sequence without reading first. Briefly '
                                            'revisit Your space and the rules; check only the '
                                            'confusing part again.'},
                         'selfChecks': [{'en': 'My feet are separated rather than on one line.',
                                         'tr': 'Ayaklarım tek çizgide değil, aralarında açıklık '
                                               'var.'},
                                        {'en': 'I can stop the small rock without needing a rescue '
                                               'step.',
                                         'tr': 'Küçük salınımı ek denge adımı atmadan '
                                               'durdurabiliyorum.'},
                                        {'tr': 'Duruşu metne bakmadan kurup küçük hareketi dengede '
                                               'durdurarak bitirebiliyorum.',
                                         'en': 'I can rebuild the stance without reading and '
                                               'finish a small movement with a balanced stop.'}],
                         'sourceIds': ['boxing_canada_beginner',
                                       'england_boxing_level1',
                                       'motor_spacing_primary']},
 'boxing.start.guard': {'steps': [{'en': 'For this non-contact practice, curl the fingers gently '
                                         'and rest the thumb outside them, never tucked inside. '
                                         'Keep the wrist comfortably in line with the forearm and '
                                         'avoid squeezing hard; this is not an impact or bag '
                                         'drill.',
                                   'tr': 'Bu temassız çalışma için parmakları hafifçe kıvır; '
                                         'başparmak dışlarında dursun, içeride sıkışmasın. Bileği '
                                         'önkolla rahat hizada tut, eli sert sıkma; bu darbe veya '
                                         'torba alıştırması değildir.'},
                                  {'en': 'Bring the rear hand near the cheek and the lead hand '
                                         'slightly ahead. Keep elbows comfortably toward the ribs '
                                         'and eyes forward.',
                                   'tr': 'Arka eli yanağa yakın, ön eli biraz önde tut. Dirsekleri '
                                         'rahatça kaburgalara yaklaştır, bakışı ileri ver.'},
                                  {'en': 'Release the shoulders and hands between repetitions. A '
                                         'guard is a movable starting place, not a frozen pose.',
                                   'tr': 'Tekrarlar arasında omuz ve elleri gevşet. Gard donmuş '
                                         'bir poz değil, hareketli bir başlangıç yeridir.'},
                                  {'tr': 'Gardı omuzları kaldırıp elleri sert sıkarak dondurma. '
                                         'Elleri yumuşat, omuzları bırak ve rahat görüş alanını '
                                         'yeniden kontrol et.',
                                   'en': 'Do not freeze the guard by raising the shoulders and '
                                         'squeezing the hands. Soften the hands, release the '
                                         'shoulders and check the comfortable field of view '
                                         'again.'}],
                        'practice': {'tr': 'Gardı kaldır, indir ve on kez yavaşça yeniden kur. İki '
                                           'elini de görebilerek hafif yana dön.\n'
                                           '\n'
                                           'Kısa odak çalışması: Mevcut on gard kurmayı iki kısa '
                                           'gruba ayır; arada elleri indirip rahatlığı kontrol et. '
                                           'Son iki kurmada yalnız arka elin hazır yerine '
                                           'dönmesini izle. Bölümler arasında dinlen; süreyi '
                                           'rahatlığına göre uzat.\n'
                                           '\n'
                                           'Rahat olduğunda tek değişken denemesi: Gardı bir küçük '
                                           'yan adım sonrası yeniden kur ve aynı rahat görüşü '
                                           'koru.\n'
                                           '\n'
                                           'Sonraki pratik: Sonraki uygun oturumda kısa '
                                           'uygulamanın sırasını önce yardımsız hatırla. Duruşunu '
                                           'bul dersini kısaca hatırla; yalnız karışan kısmı '
                                           'yeniden kontrol et.',
                                     'en': 'Raise the guard, lower it, and rebuild it ten slow '
                                           'times. Turn slightly side-on while keeping both hands '
                                           'visible to yourself.\n'
                                           '\n'
                                           'Short focused practice: Split the existing ten guard '
                                           'rebuilds into two short groups and lower the hands to '
                                           'check comfort between them. In the last two focus only '
                                           'on the rear hand returning to its ready place. Rest '
                                           'between sections; take longer if you need it.\n'
                                           '\n'
                                           'When comfortable, try changing just one variable: '
                                           'Rebuild the guard after a small side step and retain '
                                           'the same comfortable view.\n'
                                           '\n'
                                           'Next practice: At the next suitable session, recall '
                                           'the short sequence without reading first. Briefly '
                                           'revisit Find your stance; check only the confusing '
                                           'part again.'},
                        'selfChecks': [{'en': 'I can see ahead without hiding behind my gloves.',
                                        'tr': 'Ellerimin arkasına saklanmadan ileriyi '
                                              'görebiliyorum.'},
                                       {'en': 'My shoulders can relax while the hands remain '
                                              'ready.',
                                        'tr': 'Eller hazırken omuzlarımı gevşetebiliyorum.'},
                                       {'tr': 'Gardı rahatça yeniden kurabiliyor ve eller hazırken '
                                              'omuzları gevşetebiliyorum.',
                                        'en': 'I can rebuild a comfortable guard and relax the '
                                              'shoulders while the hands are ready.'}],
                        'sourceIds': ['boxing_canada_beginner',
                                      'england_boxing_level1',
                                      'motor_spacing_primary']},
 'boxing.start.breath': {'steps': [{'en': 'Take an ordinary breath while settling in guard; exhale '
                                          'gently as one hand extends and breathe again on the '
                                          'return.',
                                    'tr': 'Gardda normal nefes al; bir el uzanırken yumuşakça '
                                          'nefes ver ve dönüşte yeniden nefes al.'},
                                   {'en': 'Keep a pace at which you could still speak a short '
                                          'sentence. This is preparation, not a speed test.',
                                    'tr': 'Kısa bir cümle söyleyebileceğin tempoda kal. Bu '
                                          'hazırlıktır, hız sınavı değil.'},
                                   {'tr': 'Nefesi yumruğa yetiştirmek için tutma veya her '
                                          'harekette sertçe üfleme. Uzatmayı küçült, sıradan '
                                          'nefese ve konuşabildiğin rahat tempoya dön.',
                                    'en': 'Do not hold the breath to keep up or force a hard '
                                          'exhale on every movement. Reduce the reach and return '
                                          'to ordinary breathing and a comfortable conversational '
                                          'pace.'}],
                         'practice': {'tr': 'Kolay nefesle dönüşümlü on küçük el uzatması yap; '
                                            'gerektiğinde dinlen.\n'
                                            '\n'
                                            'Kısa odak çalışması: Mevcut küçük uzanmaların ilk '
                                            'beşinde yalnız rahat nefesi izle; durup kısa bir '
                                            'cümle söyle. Gerekirse kalanları azalt veya bırak. '
                                            'Bölümler arasında dinlen; süreyi rahatlığına göre '
                                            'uzat.\n'
                                            '\n'
                                            'Rahat olduğunda tek değişken denemesi: Rahat nefes '
                                            'odağını küçük adım eklediğin ayrı bir denemeye taşı.\n'
                                            '\n'
                                            'Sonraki pratik: Sonraki uygun oturumda kısa '
                                            'uygulamanın sırasını önce yardımsız hatırla. Rahat '
                                            'gard dersini kısaca hatırla; yalnız karışan kısmı '
                                            'yeniden kontrol et.',
                                      'en': 'Alternate ten tiny hand reaches with easy breathing; '
                                            'rest whenever you need it.\n'
                                            '\n'
                                            'Short focused practice: During the first five '
                                            'existing small reaches focus only on easy breathing, '
                                            'then stop and say a short sentence. Reduce or omit '
                                            'the remaining reaches if needed. Rest between '
                                            'sections; take longer if you need it.\n'
                                            '\n'
                                            'When comfortable, try changing just one variable: '
                                            'Carry the easy-breathing focus into a separate '
                                            'attempt with a small step.\n'
                                            '\n'
                                            'Next practice: At the next suitable session, recall '
                                            'the short sequence without reading first. Briefly '
                                            'revisit A relaxed guard; check only the confusing '
                                            'part again.'},
                         'selfChecks': [{'en': 'I did not hold my breath to finish a reach.',
                                         'tr': 'Uzanmayı bitirmek için nefesimi tutmadım.'},
                                        {'en': 'I could slow down without losing my stance.',
                                         'tr': 'Duruşumu bozmadan yavaşlayabildim.'},
                                        {'tr': 'Küçük uzanma sırasında nefesimi tutmadığımı fark '
                                               'ediyor ve gerektiğinde tempoyu düşürüyorum.',
                                         'en': 'I can notice that I am not holding the breath '
                                               'during a small reach and slow down when needed.'}],
                         'sourceIds': ['cdc_activity',
                                       'england_boxing_level1',
                                       'boxing_canada_beginner',
                                       'motor_spacing_primary']},
 'boxing.start.reset': {'steps': [{'en': 'From guard, step a little to one side, stop, check the '
                                         'space between your feet, then bring the hands back to '
                                         'their ready place.',
                                   'tr': 'Garddan yana küçük adım at, dur, ayak açıklığını kontrol '
                                         'et, sonra elleri hazır yerine getir.'},
                                  {'en': 'Repeat on both sides. Keep each reset unhurried; later '
                                         'punches will end in this base.',
                                   'tr': 'İki tarafta tekrarla. Her dönüşü acele etmeden yap; '
                                         'ileride yumruklar bu tabanda bitecek.'},
                                  {'tr': 'Bir sonraki harekete başlamadan tabanı kontrol etmeyi '
                                         'atlama. Önce ayak açıklığına, sonra ellerin hazır yerine '
                                         'dönüşüne tek tek bak.',
                                   'en': 'Do not skip checking the base before the next movement. '
                                         "Check foot spacing first, then the hands' return to "
                                         'their ready place.'}],
                        'practice': {'tr': 'Her yöne beş küçük yan adım at; her adım sonrası tam '
                                           'durup yeniden yerleş.\n'
                                           '\n'
                                           'Kısa odak çalışması: Her yana mevcut beş adımın ilk '
                                           'ikisini adım-dur-ayak-eller sırasıyla seslendir; '
                                           'kalanlarında aynı sırayı kendi kendine hatırla. '
                                           'Bölümler arasında dinlen; süreyi rahatlığına göre '
                                           'uzat.\n'
                                           '\n'
                                           'Rahat olduğunda tek değişken denemesi: Aynı yeniden '
                                           'yerleşmeyi yan adım yerine küçük geri adım sonrası '
                                           'seç.\n'
                                           '\n'
                                           'Sonraki pratik: Sonraki uygun oturumda kısa '
                                           'uygulamanın sırasını önce yardımsız hatırla. Duruşunu '
                                           'bul dersini kısaca hatırla; yalnız karışan kısmı '
                                           'yeniden kontrol et.',
                                     'en': 'Make five small side steps each way with a full pause '
                                           'and reset after every step.\n'
                                           '\n'
                                           'Short focused practice: Say step-stop-feet-hands for '
                                           'the first two of the existing five steps each way; '
                                           'recall the same order privately for the remainder. '
                                           'Rest between sections; take longer if you need it.\n'
                                           '\n'
                                           'When comfortable, try changing just one variable: '
                                           'Choose the same reset after a small back step rather '
                                           'than a side step.\n'
                                           '\n'
                                           'Next practice: At the next suitable session, recall '
                                           'the short sequence without reading first. Briefly '
                                           'revisit Find your stance; check only the confusing '
                                           'part again.'},
                        'selfChecks': [{'en': 'I can pause without crossing my feet.',
                                        'tr': 'Ayaklarımı çaprazlamadan durabiliyorum.'},
                                       {'en': 'Both hands return before I start the next step.',
                                        'tr': 'Sonraki adımdan önce iki elim de yerine dönüyor.'},
                                       {'tr': 'Yana adımdan sonra ayak ve elleri birlikte acele '
                                              'etmeden yeniden hazırlayabiliyorum.',
                                        'en': 'I can prepare the feet and hands again without '
                                              'rushing after a side step.'}],
                        'sourceIds': ['boxing_canada_beginner',
                                      'england_boxing_level1',
                                      'motor_spacing_primary']},
 'boxing.footwork.forward_back': {'steps': [{'en': 'Forward: lead foot starts, rear foot follows. '
                                                   'Backward: rear foot starts, lead foot follows. '
                                                   'Keep the step small enough to stop midway.',
                                             'tr': 'İleri: önce ön ayak, sonra arka ayak. Geri: '
                                                   'önce arka ayak, sonra ön ayak. Adımı yarıda '
                                                   'durabilecek kadar küçük tut.'},
                                            {'en': 'Pause after each pair of steps and check your '
                                                   'original foot spacing. Speed comes after you '
                                                   'can stop balanced.',
                                             'tr': 'Her adım çiftinden sonra durup başlangıçtaki '
                                                   'ayak açıklığını kontrol et. Hız, dengede '
                                                   'durabildikten sonra gelir.'},
                                            {'tr': 'Takip eden ayağı öndekinin yanına getirip '
                                                   'tabanı silme. Küçük ilk adımı at, sonra '
                                                   'başlangıçtaki açıklığı yeniden kuracak kadar '
                                                   'takip et.',
                                             'en': 'Do not bring the following foot against the '
                                                   'first and erase the base. Take a small first '
                                                   'step, then follow only enough to restore the '
                                                   'starting spacing.'}],
                                  'practice': {'tr': 'Zihninde yerde kısa bir çizgi izle: beş '
                                                     'ileri-takip, beş geri-takip adımı; her '
                                                     'birinde dur.\n'
                                                     '\n'
                                                     'Kısa odak çalışması: Mevcut ileri-geri '
                                                     'adımlarda her yönün ilk iki çiftini duraklı '
                                                     'yap ve ilk ayağı söyle; son çiftte yön '
                                                     'seçimini kendi kendine hatırla. Bölümler '
                                                     'arasında dinlen; süreyi rahatlığına göre '
                                                     'uzat.\n'
                                                     '\n'
                                                     'Rahat olduğunda tek değişken denemesi: '
                                                     'İleri-geri çiftlerin sırasını değiştir; '
                                                     'başlamadan önce ilk ayağı kendin seç.\n'
                                                     '\n'
                                                     'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                     'uygulamanın sırasını önce yardımsız hatırla. '
                                                     'Tabanına geri dön dersini kısaca hatırla; '
                                                     'yalnız karışan kısmı yeniden kontrol et.',
                                               'en': 'Trace a short line on the floor mentally: '
                                                     'five forward-follow steps, five '
                                                     'backward-follow steps, each with a pause.\n'
                                                     '\n'
                                                     'Short focused practice: For the existing '
                                                     'forward-back steps, pause through the first '
                                                     'two pairs each way and name the initiating '
                                                     'foot; recall the direction choice yourself '
                                                     'in the last pair. Rest between sections; '
                                                     'take longer if you need it.\n'
                                                     '\n'
                                                     'When comfortable, try changing just one '
                                                     'variable: Swap the forward-back pairs and '
                                                     'choose the first foot yourself before '
                                                     'starting.\n'
                                                     '\n'
                                                     'Next practice: At the next suitable session, '
                                                     'recall the short sequence without reading '
                                                     'first. Briefly revisit Return to your base; '
                                                     'check only the confusing part again.'},
                                  'selfChecks': [{'en': 'The foot nearest the travel direction '
                                                        'moved first.',
                                                  'tr': 'Gidiş yönüne yakın ayak önce hareket '
                                                        'etti.'},
                                                 {'en': 'My feet never met or passed one another.',
                                                  'tr': 'Ayaklarım birleşmedi veya birbirini '
                                                        'geçmedi.'},
                                                 {'tr': 'İleri ön, geri arka ayakla başlayabiliyor '
                                                        've her çiftte duruş açıklığına '
                                                        'dönebiliyorum.',
                                                  'en': 'I can start forward with the lead foot '
                                                        'and backward with the rear foot and '
                                                        'restore spacing after each pair.'}],
                                  'sourceIds': ['boxing_canada_beginner',
                                                'england_boxing_level1',
                                                'motor_spacing_primary']},
 'boxing.footwork.lateral': {'steps': [{'en': 'To the lead side, lead foot starts; to the rear '
                                              'side, rear foot starts. The other foot follows '
                                              'rather than overtaking.',
                                        'tr': 'Ön tarafa giderken ön ayak, arka tarafa giderken '
                                              'arka ayak başlar. Diğeri geçmek yerine takip eder.'},
                                       {'en': 'Keep the head within the base and the hands in '
                                              'guard. Do not drag the trailing foot across the '
                                              'floor.',
                                        'tr': 'Başını tabanın içinde, elleri gardda tut. Arkadan '
                                              'gelen ayağı zeminde sürükleme.'},
                                       {'tr': 'Yan adımda takip eden ayağın öne geçmesi veya '
                                              'ayakları birleştirmesi tabanı değiştirir. Yana '
                                              'yakın ayak başlasın; diğeri açıklığı geri kursun.',
                                        'en': 'Overtaking or joining the feet with the following '
                                              'foot changes the base in a side step. Let the foot '
                                              'nearer the direction start and the other restore '
                                              'spacing.'}],
                             'practice': {'tr': 'Her yana dört küçük adım at ve her çiftte yeniden '
                                                'yerleş; ön tarafı değiştirip bir kez tekrarla.\n'
                                                '\n'
                                                'Kısa odak çalışması: Her yana ilk iki adımı '
                                                'tamamen durarak yap; ikinci kısa bölümde aynı '
                                                'yolları seçtiğin sırada karıştır. Gardı rahat '
                                                'tut. Bölümler arasında dinlen; süreyi rahatlığına '
                                                'göre uzat.\n'
                                                '\n'
                                                'Rahat olduğunda tek değişken denemesi: Yana adımı '
                                                'bir ileri-geri çiftin ardından bağla, tabanı '
                                                'koru.\n'
                                                '\n'
                                                'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                'uygulamanın sırasını önce yardımsız hatırla. '
                                                'Rahat gard dersini kısaca hatırla; yalnız karışan '
                                                'kısmı yeniden kontrol et.',
                                          'en': 'Take four small steps to each side and reset '
                                                'after each pair; reverse your lead side and '
                                                'repeat once.\n'
                                                '\n'
                                                'Short focused practice: Stop fully after the '
                                                'first two steps each way, then mix the same paths '
                                                'in your chosen order in the second short section. '
                                                'Keep the guard comfortable. Rest between '
                                                'sections; take longer if you need it.\n'
                                                '\n'
                                                'When comfortable, try changing just one variable: '
                                                'Connect a side step after a forward-back pair '
                                                'while keeping the base.\n'
                                                '\n'
                                                'Next practice: At the next suitable session, '
                                                'recall the short sequence without reading first. '
                                                'Briefly revisit A relaxed guard; check only the '
                                                'confusing part again.'},
                             'selfChecks': [{'en': 'I could freeze after each step without '
                                                   'leaning.',
                                             'tr': 'Her adım sonrası eğilmeden donabildim.'},
                                            {'en': 'My trailing foot restored, rather than erased, '
                                                   'stance width.',
                                             'tr': 'Takip eden ayağım duruş açıklığını silmek '
                                                   'yerine yeniden kurdu.'},
                                            {'tr': 'Hangi yana hangi ayağın başlayacağını '
                                                   'söyleyebiliyor ve çaprazlamadan durabiliyorum.',
                                             'en': 'I can name the initiating foot for each side '
                                                   'and stop without crossing.'}],
                             'sourceIds': ['boxing_canada_beginner',
                                           'england_boxing_level1',
                                           'motor_spacing_primary']},
 'boxing.footwork.diagonal': {'steps': [{'en': 'Aim a small step toward a front corner with the '
                                               'nearer foot and let the other restore the base. '
                                               'Repeat toward a back corner.',
                                         'tr': 'Ön köşeye yakın ayakla küçük adım at, diğer ayak '
                                               'tabanı yeniden kursun. Arka köşeye de tekrarla.'},
                                        {'en': 'Think of the corner as a direction on the floor, '
                                               'not an opponent to chase. Stop before any foot '
                                               'crosses the other.',
                                         'tr': 'Köşeyi kovalanacak rakip değil, zemindeki yön '
                                               'olarak düşün. Ayaklar çaprazlanmadan dur.'},
                                        {'tr': 'Köşeye uzanırken ayakları çaprazlama. Çapraz yol '
                                               'uzunluğunu küçült ve ikinci ayağın tabanı yeniden '
                                               'kurmasını bekle.',
                                         'en': 'Do not cross the feet when reaching a corner. '
                                               'Reduce the diagonal distance and wait for the '
                                               'second foot to restore the base.'}],
                              'practice': {'tr': 'Zihninde küçük bir X çiz; her kola bir kol boyu '
                                                 'ilerle ve aralarda merkeze dön.\n'
                                                 '\n'
                                                 "Kısa odak çalışması: Küçük X'in önce ön iki "
                                                 'kolunu, dinlendikten sonra arka iki kolunu dene. '
                                                 'Her dönüşte merkezde dur; bir sonraki yönü '
                                                 'önceden söyle. Bölümler arasında dinlen; süreyi '
                                                 'rahatlığına göre uzat.\n'
                                                 '\n'
                                                 'Rahat olduğunda tek değişken denemesi: Küçük X '
                                                 'kollarını farklı sırada seç, merkeze dönüşü '
                                                 'koru.\n'
                                                 '\n'
                                                 'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                 'uygulamanın sırasını önce yardımsız hatırla. '
                                                 'İleri ve geri dersini kısaca hatırla; yalnız '
                                                 'karışan kısmı yeniden kontrol et.',
                                           'en': 'Draw a small X mentally and travel one '
                                                 'arm-length along each ray, returning to the '
                                                 'centre between rays.\n'
                                                 '\n'
                                                 'Short focused practice: Try the two front rays '
                                                 'of a small X first, then the two back rays after '
                                                 'a rest. Stop at the centre on every return and '
                                                 'name the next direction beforehand. Rest between '
                                                 'sections; take longer if you need it.\n'
                                                 '\n'
                                                 'When comfortable, try changing just one '
                                                 'variable: Choose the small X rays in a different '
                                                 'order while keeping the return to the centre.\n'
                                                 '\n'
                                                 'Next practice: At the next suitable session, '
                                                 'recall the short sequence without reading first. '
                                                 'Briefly revisit Forward and back; check only the '
                                                 'confusing part again.'},
                              'selfChecks': [{'en': 'Each trip ended in the same stance width.',
                                              'tr': 'Her yol aynı duruş açıklığında bitti.'},
                                             {'en': 'I could name which foot started each '
                                                    'direction.',
                                              'tr': 'Her yönde hangi ayağın başladığını '
                                                    'söyleyebiliyorum.'},
                                             {'tr': 'Dört küçük köşeye giderken ilk ayağı '
                                                    'seçebiliyor ve merkezde rahat tabana '
                                                    'dönebiliyorum.',
                                              'en': 'I can choose the first foot toward each small '
                                                    'corner and return to a comfortable base at '
                                                    'the centre.'}],
                              'sourceIds': ['boxing_canada_beginner',
                                            'england_boxing_level1',
                                            'motor_spacing_primary']},
 'boxing.footwork.pivot': {'steps': [{'en': 'Move the rear foot in a small arc while the lead foot '
                                            'turns comfortably on the ball; let hips and shoulders '
                                            'face the new direction together.',
                                      'tr': 'Arka ayağı küçük yayda taşı, ön ayak rahatça ön '
                                            'kısmında dönsün; kalça ve omuzlar birlikte yeni yöne '
                                            'baksın.'},
                                     {'en': 'Make only a modest turn, stop, and rebuild the guard. '
                                            'A pivot is an exit to a new line, not a spin for '
                                            'speed.',
                                      'tr': 'Yalnız ölçülü dön, dur ve gardı yeniden kur. Pivot '
                                            'hız için dönme değil, yeni hatta çıkıştır.'},
                                     {'tr': 'Ön ayak yerde sabitken dizi çevirmeye veya büyük '
                                            'dönüşü zorlamaya çalışma. Açıyı küçült; gerekirse ön '
                                            'ayağı da adımlayarak yön değiştir.',
                                      'en': 'Do not twist the knee over a fixed lead foot or force '
                                            'a large turn. Reduce the angle and step the lead foot '
                                            'as well if needed.'}],
                           'practice': {'tr': 'Her yöne üç küçük dönüş yap; her birinden sonra tam '
                                              'yerleş ve dur.\n'
                                              '\n'
                                              'Kısa odak çalışması: Mevcut üç dönüşün ilkinde çok '
                                              'küçük yay seç; duruşu yeniden kur. Sonraki '
                                              'dönüşlerde yalnız rahat yön değişimini izle, açıyı '
                                              'büyütme zorunluluğu yoktur. Bölümler arasında '
                                              'dinlen; süreyi rahatlığına göre uzat.\n'
                                              '\n'
                                              'Rahat olduğunda tek değişken denemesi: Dönüş öncesi '
                                              'bir küçük yan adım ekle ve her iki bölüm arasında '
                                              'tam yerleş.\n'
                                              '\n'
                                              'Sonraki pratik: Sonraki uygun oturumda kısa '
                                              'uygulamanın sırasını önce yardımsız hatırla. Çapraz '
                                              'yönlere adım dersini kısaca hatırla; yalnız karışan '
                                              'kısmı yeniden kontrol et.',
                                        'en': 'Make three small turns each way with a full reset '
                                              'and a pause after each.\n'
                                              '\n'
                                              'Short focused practice: Choose a very small arc for '
                                              'the first of the existing three turns and rebuild '
                                              'the stance. Focus only on a comfortable direction '
                                              'change in the others; a larger angle is optional. '
                                              'Rest between sections; take longer if you need it.\n'
                                              '\n'
                                              'When comfortable, try changing just one variable: '
                                              'Add a small side step before the turn and reset '
                                              'fully between both sections.\n'
                                              '\n'
                                              'Next practice: At the next suitable session, recall '
                                              'the short sequence without reading first. Briefly '
                                              'revisit Diagonal steps; check only the confusing '
                                              'part again.'},
                           'selfChecks': [{'en': 'My knee followed the foot rather than twisting '
                                                 'under it.',
                                           'tr': 'Dizim sabit ayak altında burulmak yerine ayağı '
                                                 'izledi.'},
                                          {'en': 'I could hold the final stance without a catching '
                                                 'step.',
                                           'tr': 'Son duruşu kurtarma adımı olmadan tutabildim.'},
                                          {'tr': 'Küçük dönüşü rahat bitirebiliyor ve uygun '
                                                 'olduğunda adımlayarak dönüş seçeneğini '
                                                 'kullanabiliyorum.',
                                           'en': 'I can finish a small turn comfortably and use a '
                                                 'stepping alternative when appropriate.'}],
                           'sourceIds': ['boxing_canada_competition',
                                         'england_boxing_level1',
                                         'boxing_canada_beginner',
                                         'motor_spacing_primary']},
 'boxing.footwork.enter_exit': {'steps': [{'en': "Choose a spot ahead at comfortable arm's reach. "
                                                 'Step in until a relaxed straight reach could '
                                                 'arrive without leaning; do not actually strike '
                                                 'an object.',
                                           'tr': 'Önde rahat kol erişiminde bir nokta seç. '
                                                 'Eğilmeden düz uzanma yetişecek kadar gir; gerçek '
                                                 'bir nesneye vurma.'},
                                          {'en': 'Step back or diagonally out before resetting. '
                                                 'Keep the feet underneath you on entry and exit.',
                                           'tr': 'Yeniden yerleşmeden önce geriye veya çapraza '
                                                 'çık. Giriş ve çıkışta ayaklarını altında tut.'},
                                          {'tr': 'Hayalî noktaya belden uzanarak yetişmek mesafe '
                                                 'çalışmasının amacını değiştirir. Noktayı '
                                                 'yaklaştır veya küçük adımla gir; gerçek nesneye '
                                                 'vurma.',
                                           'en': 'Reaching an imagined point by bending at the '
                                                 'waist changes the distance drill. Move the point '
                                                 'closer or enter with a small step; strike no '
                                                 'real object.'}],
                                'practice': {'tr': 'Çıkış yönünü değiştirerek beş gir-dur-çık '
                                                   'döngüsü yap; eller gardda kalsın.\n'
                                                   '\n'
                                                   'Kısa odak çalışması: Beş gir-dur-çık '
                                                   'döngüsünün ilk ikisinde geri çıkışı, sonraki '
                                                   'ikisinde küçük çapraz çıkışı dene; sonuncuda '
                                                   'rahat olanı seç. Bölümler arasında dinlen; '
                                                   'süreyi rahatlığına göre uzat.\n'
                                                   '\n'
                                                   'Rahat olduğunda tek değişken denemesi: Hayalî '
                                                   'noktayı daha yakın seç, aynı gir-dur-çık '
                                                   'zincirini koru.\n'
                                                   '\n'
                                                   'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                   'uygulamanın sırasını önce yardımsız hatırla. '
                                                   'Tabanına geri dön dersini kısaca hatırla; '
                                                   'yalnız karışan kısmı yeniden kontrol et.',
                                             'en': 'Repeat five entry-pause-exit cycles, '
                                                   'alternating the exit direction; the hands stay '
                                                   'in guard.\n'
                                                   '\n'
                                                   'Short focused practice: In the five '
                                                   'entry-stop-exit cycles, try back exits in the '
                                                   'first two and small diagonal exits in the next '
                                                   'two; choose the comfortable option for the '
                                                   'last. Rest between sections; take longer if '
                                                   'you need it.\n'
                                                   '\n'
                                                   'When comfortable, try changing just one '
                                                   'variable: Choose a closer imagined point while '
                                                   'retaining the entry-stop-exit chain.\n'
                                                   '\n'
                                                   'Next practice: At the next suitable session, '
                                                   'recall the short sequence without reading '
                                                   'first. Briefly revisit Return to your base; '
                                                   'check only the confusing part again.'},
                                'selfChecks': [{'en': 'I reached the imagined spot without folding '
                                                      'at the waist.',
                                                'tr': 'Hayalî noktaya belden katlanmadan eriştim.'},
                                               {'en': 'My exit left space and a stable base for '
                                                      'the next move.',
                                                'tr': 'Çıkış sonraki hareket için alan ve dengeli '
                                                      'taban bıraktı.'},
                                               {'tr': 'Hayalî erişim için öne düşmeden giriyor ve '
                                                      'çıkışta sonraki harekete hazır tabana '
                                                      'dönebiliyorum.',
                                                'en': 'I can enter without falling forward to '
                                                      'reach and recover a ready base on exit.'}],
                                'sourceIds': ['boxing_canada_beginner',
                                              'england_boxing_level1',
                                              'motor_spacing_primary']},
 'boxing.straights.jab_line': {'steps': [{'en': 'Begin in guard. Let the lead hand travel toward '
                                                'an imagined eye-level point, without winding it '
                                                'behind the shoulder first.',
                                          'tr': 'Garddan başla. Ön eli önce omuz arkasına çekmeden '
                                                'hayalî göz hizası noktasına götür.'},
                                         {'en': 'Keep the rear hand near the cheek and the head '
                                                'over the feet. Reach within your comfortable '
                                                'range; do not lock or snap the elbow.',
                                          'tr': 'Arka el yanağa yakın, baş ayakların üzerinde '
                                                'kalsın. Rahat menzile uzan; dirseği kilitleme '
                                                'veya sertçe açma.'},
                                         {'tr': 'Jab için dirseği sertçe kilitleme veya eli önce '
                                                'geriye çekme. Rahat garddan küçük düz yol aç, '
                                                'erişimi kısalt ve aynı yoldan geri dön.',
                                          'en': 'Do not snap-lock the elbow or pull the hand back '
                                                'first for a jab. Use a small straight path from '
                                                'comfortable guard, shorten the reach and return '
                                                'along it.'}],
                               'practice': {'tr': 'Tek hayalî noktaya altı yavaş ön el uzatması '
                                                  'yap; aralarda gardda tam dur.\n'
                                                  '\n'
                                                  'Kısa odak çalışması: İki kısa grupta üçer yavaş '
                                                  'ön el uzatması seç; her birinden sonra tam '
                                                  'gardda dur. Bir grupta yalnız düz yol, '
                                                  'diğerinde arka elin hazır yeri odak olsun. '
                                                  'Bölümler arasında dinlen; süreyi rahatlığına '
                                                  'göre uzat.\n'
                                                  '\n'
                                                  'Rahat olduğunda tek değişken denemesi: Jabı bir '
                                                  'küçük girişten sonra seç; önce tabanı ve gardı '
                                                  'kur.\n'
                                                  '\n'
                                                  'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                  'uygulamanın sırasını önce yardımsız hatırla. '
                                                  'Rahat gard dersini kısaca hatırla; yalnız '
                                                  'karışan kısmı yeniden kontrol et.',
                                            'en': 'Perform six slow lead-hand reaches to one '
                                                  'imagined point, fully pausing in guard between '
                                                  'them.\n'
                                                  '\n'
                                                  'Short focused practice: Choose two short groups '
                                                  'of three slow lead-hand reaches, stopping in '
                                                  'full guard after each. Focus on the straight '
                                                  'path in one group and rear-hand readiness in '
                                                  'the other. Rest between sections; take longer '
                                                  'if you need it.\n'
                                                  '\n'
                                                  'When comfortable, try changing just one '
                                                  'variable: Choose the jab after a small entry, '
                                                  'establishing the base and guard first.\n'
                                                  '\n'
                                                  'Next practice: At the next suitable session, '
                                                  'recall the short sequence without reading '
                                                  'first. Briefly revisit A relaxed guard; check '
                                                  'only the confusing part again.'},
                               'selfChecks': [{'en': 'The lead hand took a direct path rather than '
                                                     'a wide arc.',
                                               'tr': 'Ön el geniş yay yerine doğrudan yol izledi.'},
                                              {'en': 'The rear hand stayed available while the '
                                                     'lead hand moved.',
                                               'tr': 'Ön el giderken arka el hazır kaldı.'},
                                              {'tr': 'Ön elin rahat düz yolunu ve geri dönüşünü, '
                                                     'arka eli yerinden uzaklaştırmadan '
                                                     'kurabiliyorum.',
                                               'en': 'I can rehearse a comfortable lead-hand '
                                                     'straight path and return without moving the '
                                                     'rear hand away.'}],
                               'sourceIds': ['boxing_canada_beginner',
                                             'england_boxing_level1',
                                             'motor_spacing_primary']},
 'boxing.straights.jab_return': {'steps': [{'en': 'Reach to the same imagined point as before. '
                                                  'Reverse the path with the elbow and hand '
                                                  'returning together; avoid letting the hand hang '
                                                  'low on the way back.',
                                            'tr': 'Önceki hayalî noktaya uzan. Dirsek ve eli '
                                                  'birlikte geri getir; dönüşte elin aşağıda asılı '
                                                  'kalmasına izin verme.'},
                                           {'en': 'Pause with both hands visible in your own field '
                                                  'of view. One reach plus return is a whole '
                                                  'repetition.',
                                            'tr': 'İki el de kendi görüş alanında iken dur. Bir '
                                                  'uzanma ve dönüş tek tam tekrardır.'},
                                           {'tr': 'Jab uzatıp eli aşağıdan dolaştırarak geri '
                                                  'getirme. Kısa yol kullan ve yeni tekrar öncesi '
                                                  'elin başlangıç yerine döndüğünü fark et.',
                                            'en': 'Do not return the jab by looping the hand '
                                                  'downwards. Use a short path and notice that it '
                                                  'reaches the starting place before the next '
                                                  'repetition.'}],
                                 'practice': {'tr': 'İki set beş yavaş jab yap. Her dönüşte '
                                                    "sonraki jabdan önce sessizce 'yerinde' de.\n"
                                                    '\n'
                                                    'Kısa odak çalışması: Mevcut iki beşli grubun '
                                                    'ilkinde her dönüşte evine de; ikinci grupta '
                                                    'kelimeyi azaltıp hazır elden bir sonraki jabı '
                                                    'başlat. Bölümler arasında dinlen; süreyi '
                                                    'rahatlığına göre uzat.\n'
                                                    '\n'
                                                    'Rahat olduğunda tek değişken denemesi: Tek '
                                                    'jab dönüşünden sonra küçük geri çıkış ekle.\n'
                                                    '\n'
                                                    'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                    'uygulamanın sırasını önce yardımsız hatırla. '
                                                    'Ön el jab dersini kısaca hatırla; yalnız '
                                                    'karışan kısmı yeniden kontrol et.',
                                              'en': 'Do two sets of five slow jabs. On each return '
                                                    "say 'home' quietly before the next one.\n"
                                                    '\n'
                                                    'Short focused practice: Say home after each '
                                                    'return in the first of the existing two '
                                                    'five-repetition groups; reduce the cue in the '
                                                    'second and start the next jab from a ready '
                                                    'hand. Rest between sections; take longer if '
                                                    'you need it.\n'
                                                    '\n'
                                                    'When comfortable, try changing just one '
                                                    'variable: Add a small back exit after the '
                                                    "single jab's return.\n"
                                                    '\n'
                                                    'Next practice: At the next suitable session, '
                                                    'recall the short sequence without reading '
                                                    'first. Briefly revisit The lead-hand jab; '
                                                    'check only the confusing part again.'},
                                 'selfChecks': [{'en': 'I waited for the hand to return before the '
                                                       'next reach.',
                                                 'tr': 'Sonraki uzanmadan önce elin dönüşünü '
                                                       'bekledim.'},
                                                {'en': 'My chin and balance did not follow the '
                                                       'fist forward.',
                                                 'tr': 'Çenem ve dengem yumruğu ileri izlemedi.'},
                                                {'tr': 'Jab geri gelmeden yeni tekrar başlatmıyor '
                                                       've dönüşü tek başına çalışabiliyorum.',
                                                 'en': 'I do not start the next repetition before '
                                                       'the jab returns and can practise recovery '
                                                       'separately.'}],
                                 'sourceIds': ['boxing_canada_beginner',
                                               'england_boxing_level1',
                                               'motor_spacing_primary']},
 'boxing.straights.double_jab': {'steps': [{'en': 'Send one small jab, let it return, then send a '
                                                  'second. The second begins from guard, not from '
                                                  'a hand left in midair.',
                                            'tr': 'Bir küçük jab gönder, geri getir, sonra '
                                                  'ikincisini gönder. İkincisi havada kalmış elden '
                                                  'değil garddan başlar.'},
                                           {'en': 'Keep the same imagined target and an easy '
                                                  'rhythm. Do not speed up until both returns are '
                                                  'complete.',
                                            'tr': 'Aynı hayalî hedefi ve rahat ritmi koru. İki '
                                                  'dönüş de tamamlanmadan hızlanma.'},
                                           {'tr': 'İkinci jabı hızla yetiştirmek için ilk dönüşü '
                                                  'kısaltma. İki ayrı jab ve iki ayrı geri dönüş '
                                                  'olarak say; sonra rahatça bağla.',
                                            'en': 'Do not shorten the first return to rush the '
                                                  'second jab. Count two separate jabs and two '
                                                  'separate returns, then connect them '
                                                  'comfortably.'}],
                                 'practice': {'tr': 'Çiftler arasında tam duruş dönüşüyle beş çift '
                                                    'jab yap.\n'
                                                    '\n'
                                                    'Kısa odak çalışması: Mevcut beş çiftin ilk '
                                                    'ikisini jab-geri-jab-geri diye duraklı yap; '
                                                    'kalan çiftlerde yalnız ikinci başlangıcın '
                                                    'garddan gelmesini izle. Bölümler arasında '
                                                    'dinlen; süreyi rahatlığına göre uzat.\n'
                                                    '\n'
                                                    'Rahat olduğunda tek değişken denemesi: Çift '
                                                    'jab sonrası yavaş küçük yan çıkış seç; iki '
                                                    'dönüşü atlama.\n'
                                                    '\n'
                                                    'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                    'uygulamanın sırasını önce yardımsız hatırla. '
                                                    'Tabanına geri dön dersini kısaca hatırla; '
                                                    'yalnız karışan kısmı yeniden kontrol et.',
                                              'en': 'Perform five double-jab pairs with a full '
                                                    'stance reset between pairs.\n'
                                                    '\n'
                                                    'Short focused practice: Pause through '
                                                    'jab-return-jab-return for the first two of '
                                                    'the existing five pairs; in the remaining '
                                                    'pairs focus only on starting the second jab '
                                                    'from guard. Rest between sections; take '
                                                    'longer if you need it.\n'
                                                    '\n'
                                                    'When comfortable, try changing just one '
                                                    'variable: Choose a slow small side exit after '
                                                    'the double jab without skipping either '
                                                    'return.\n'
                                                    '\n'
                                                    'Next practice: At the next suitable session, '
                                                    'recall the short sequence without reading '
                                                    'first. Briefly revisit Return to your base; '
                                                    'check only the confusing part again.'},
                                 'selfChecks': [{'en': 'I could distinguish two separate starts '
                                                       'from guard.',
                                                 'tr': 'Garddan başlayan iki ayrı çıkışı ayırt '
                                                       'edebildim.'},
                                                {'en': 'The rear hand did not follow the jabs '
                                                       'downward.',
                                                 'tr': 'Arka el jablarla birlikte aşağı inmedi.'},
                                                {'tr': 'İki jabın ayrı dönüşlerini fark ediyor ve '
                                                       'çift sonunda aynı tabana dönebiliyorum.',
                                                 'en': 'I can distinguish both jab returns and '
                                                       'finish the pair in the same base.'}],
                                 'sourceIds': ['boxing_canada_beginner',
                                               'england_boxing_level1',
                                               'motor_spacing_primary']},
 'boxing.straights.rear_straight': {'steps': [{'en': 'From guard, allow the rear foot, hip and '
                                                     'shoulder to turn as the rear hand travels on '
                                                     'a straight imagined line. Keep the lead hand '
                                                     'ready.',
                                               'tr': 'Garddan arka ayak, kalça ve omzun rahatça '
                                                     'dönmesine izin ver; arka el hayalî düz hatta '
                                                     'giderken ön el hazır kalsın.'},
                                              {'en': 'Do not force a large twist or chase reach by '
                                                     'leaning. The whole body stops in a base from '
                                                     'which the hand can return.',
                                               'tr': 'Büyük burulmayı zorlama veya eğilerek uzak '
                                                     'menzili kovalama. Bütün vücut elin '
                                                     'dönebileceği tabanda durur.'},
                                              {'tr': 'Arka düzde kolu uzatırken başı tabanın '
                                                     'dışına fırlatma. Rahat ayak-gövde yön '
                                                     'değişimini küçük tut, ön eli hazır bırak ve '
                                                     'erişimi kısalt.',
                                               'en': 'Do not throw the head beyond the base while '
                                                     'extending the rear straight. Keep the '
                                                     'comfortable foot-and-torso turn small, leave '
                                                     'the lead hand ready and shorten the reach.'}],
                                    'practice': {'tr': 'Altı yavaş arka düz yap; her birinden '
                                                       'sonra ön gardı ve ayakları kontrol et.\n'
                                                       '\n'
                                                       'Kısa odak çalışması: Mevcut altı yavaş '
                                                       'tekrarın üçünde yalnız küçük yön '
                                                       'değişimini, üçünde ön elin hazır yerini '
                                                       'izle. Her tekrar sonrası tabanı yeniden '
                                                       'kur. Bölümler arasında dinlen; süreyi '
                                                       'rahatlığına göre uzat.\n'
                                                       '\n'
                                                       'Rahat olduğunda tek değişken denemesi: '
                                                       'Arka düz yolunu bir küçük ileri adım '
                                                       'sonrası ayrı kur; erişimi büyütme.\n'
                                                       '\n'
                                                       'Sonraki pratik: Sonraki uygun oturumda '
                                                       'kısa uygulamanın sırasını önce yardımsız '
                                                       'hatırla. Duruşunu bul dersini kısaca '
                                                       'hatırla; yalnız karışan kısmı yeniden '
                                                       'kontrol et.',
                                                 'en': 'Make six slow rear-hand straights, '
                                                       'checking the lead guard and foot position '
                                                       'after each.\n'
                                                       '\n'
                                                       'Short focused practice: In three of the '
                                                       'existing six slow repetitions focus only '
                                                       'on the small direction change, and in '
                                                       'three on lead-hand readiness. Rebuild the '
                                                       'base after each. Rest between sections; '
                                                       'take longer if you need it.\n'
                                                       '\n'
                                                       'When comfortable, try changing just one '
                                                       'variable: Rehearse the rear-straight path '
                                                       'separately after a small forward step '
                                                       'without increasing reach.\n'
                                                       '\n'
                                                       'Next practice: At the next suitable '
                                                       'session, recall the short sequence without '
                                                       'reading first. Briefly revisit Find your '
                                                       'stance; check only the confusing part '
                                                       'again.'},
                                    'selfChecks': [{'en': 'The turn felt comfortable through foot, '
                                                          'hip and shoulder, not forced in one '
                                                          'joint.',
                                                    'tr': 'Dönüş tek eklemde zorlanmak yerine '
                                                          'ayak, kalça ve omuz boyunca rahattı.'},
                                                   {'en': 'The lead hand stayed near guard.',
                                                    'tr': 'Ön el garda yakın kaldı.'},
                                                   {'tr': 'Arka düz yolunu rahatça kurup ön elimi '
                                                          'hazır tutabiliyor, sonra tabanıma '
                                                          'dönebiliyorum.',
                                                    'en': 'I can rehearse a comfortable '
                                                          'rear-straight path, keep the lead hand '
                                                          'ready and return to my base.'}],
                                    'sourceIds': ['boxing_canada_beginner',
                                                  'england_boxing_level1',
                                                  'motor_spacing_primary']},
 'boxing.straights.rear_return': {'steps': [{'en': 'After a slow rear straight, bring the rear '
                                                   'hand to the cheek as the turning foot and hip '
                                                   'settle back into stance.',
                                             'tr': 'Yavaş arka düzden sonra dönen ayak ve kalça '
                                                   'duruşa yerleşirken arka eli yanağa getir.'},
                                            {'en': 'Avoid leaving the rear shoulder ahead or the '
                                                   'hand low. Pause after every return and check '
                                                   'both hands and feet.',
                                             'tr': 'Arka omzu önde veya eli aşağıda bırakma. Her '
                                                   'dönüşte durup iki eli ve ayağı kontrol et.'},
                                            {'tr': 'Arka düzden sonra gövdeyi dönük ve eli aşağıda '
                                                   'bırakma. Elin hazır yerine ve ayakların rahat '
                                                   'tabana dönüşünü ayrı yavaş prova et.',
                                             'en': 'Do not leave the torso turned and the hand low '
                                                   "after the rear straight. Rehearse the hand's "
                                                   "return and the feet's comfortable base "
                                                   'recovery separately and slowly.'}],
                                  'practice': {'tr': 'Beş kez bir arka düz ve üç nefeslik gard '
                                                     'duruşu dönüşümlü yap.\n'
                                                     '\n'
                                                     'Kısa odak çalışması: Mevcut beş tekrarın ilk '
                                                     'ikisinde yalnız dönüş bölümünü küçültülmüş '
                                                     'halde çalış; kalanlarında uzat-dön-dur '
                                                     'zincirini bağla. Bölümler arasında dinlen; '
                                                     'süreyi rahatlığına göre uzat.\n'
                                                     '\n'
                                                     'Rahat olduğunda tek değişken denemesi: Arka '
                                                     'dönüş sonrası ileri gitmek yerine küçük geri '
                                                     'çıkışı seç.\n'
                                                     '\n'
                                                     'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                     'uygulamanın sırasını önce yardımsız hatırla. '
                                                     'Tabanına geri dön dersini kısaca hatırla; '
                                                     'yalnız karışan kısmı yeniden kontrol et.',
                                               'en': 'Alternate one rear straight and a '
                                                     'three-breath guard pause for five '
                                                     'repetitions.\n'
                                                     '\n'
                                                     'Short focused practice: Practise only the '
                                                     'reduced recovery portion in the first two of '
                                                     'the existing five repetitions, then connect '
                                                     'extend-return-stop in the remainder. Rest '
                                                     'between sections; take longer if you need '
                                                     'it.\n'
                                                     '\n'
                                                     'When comfortable, try changing just one '
                                                     'variable: Choose a small back exit rather '
                                                     'than moving forward after the rear '
                                                     'recovery.\n'
                                                     '\n'
                                                     'Next practice: At the next suitable session, '
                                                     'recall the short sequence without reading '
                                                     'first. Briefly revisit Return to your base; '
                                                     'check only the confusing part again.'},
                                  'selfChecks': [{'en': 'The rear hand arrived home before I began '
                                                        'again.',
                                                  'tr': 'Yeniden başlamadan arka el yerine vardı.'},
                                                 {'en': 'My stance after the punch matched the '
                                                        'stance before it.',
                                                  'tr': 'Yumruk sonrası duruşum öncesindekiyle '
                                                        'aynıydı.'},
                                                 {'tr': 'Arka el ve tabanım geri gelmeden yeni '
                                                        'hareket başlatmıyor, dönüşü bilinçli '
                                                        'anlatabiliyorum.',
                                                  'en': 'I wait for the rear hand and base to '
                                                        'return before another movement and can '
                                                        'describe recovery deliberately.'}],
                                  'sourceIds': ['boxing_canada_beginner',
                                                'england_boxing_level1',
                                                'motor_spacing_primary']},
 'boxing.straights.one_two': {'steps': [{'en': 'Send a jab and start its return. Then turn into '
                                               'the rear straight while the lead hand comes home; '
                                               'do not send both hands away together.',
                                         'tr': 'Jabı gönder ve dönüşünü başlat. Ön el yerine '
                                               'gelirken arka düze dön; iki eli aynı anda '
                                               'uzaklaştırma.'},
                                        {'en': 'Finish in the original stance with both hands '
                                               'ready. Make each pair slow enough to identify its '
                                               'two parts.',
                                         'tr': 'İki el hazır ve ilk duruşunda bitir. Her çifti iki '
                                               'parçasını seçebilecek kadar yavaş yap.'},
                                        {'tr': 'Bir-ikide iki eli birden önde bırakma. Önce yavaş '
                                               'ayrı geri dönüşlerle öğren; bağlantıda arka düz '
                                               'başlarken ön elin geri yolunu koru.',
                                         'en': 'Do not leave both hands forward in the one-two. '
                                               'Learn slowly with separate returns first; keep the '
                                               "lead hand's return path as the rear straight "
                                               'begins in the linked version.'}],
                              'practice': {'tr': 'Her çift sonrası tam durarak altı yavaş bir-iki '
                                                 'yap; insan değil hayalî hedef düşün.\n'
                                                 '\n'
                                                 'Kısa odak çalışması: İlk iki çifti jab-geri-arka '
                                                 'düz-geri diye duraklı yap. Sonraki iki çiftte '
                                                 'yalnız bağlantıyı rahatça kısalt; tam tabanda '
                                                 'bitir. Bölümler arasında dinlen; süreyi '
                                                 'rahatlığına göre uzat.\n'
                                                 '\n'
                                                 'Rahat olduğunda tek değişken denemesi: '
                                                 'Bir-ikiden sonra bilinen geri veya yan çıkıştan '
                                                 'birini kendin seç.\n'
                                                 '\n'
                                                 'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                 'uygulamanın sırasını önce yardımsız hatırla. Jab '
                                                 'geri döner dersini kısaca hatırla; yalnız '
                                                 'karışan kısmı yeniden kontrol et.',
                                           'en': 'Do six slow one-two pairs with a full pause '
                                                 'after each pair; imagine a target, never a '
                                                 'person.\n'
                                                 '\n'
                                                 'Short focused practice: Pause through '
                                                 'jab-return-rear straight-return for the first '
                                                 'two pairs. In the next two shorten only the '
                                                 'connecting pause comfortably and finish in the '
                                                 'full base. Rest between sections; take longer if '
                                                 'you need it.\n'
                                                 '\n'
                                                 'When comfortable, try changing just one '
                                                 'variable: Choose a familiar back or side exit '
                                                 'yourself after the one-two.\n'
                                                 '\n'
                                                 'Next practice: At the next suitable session, '
                                                 'recall the short sequence without reading first. '
                                                 'Briefly revisit The jab comes home; check only '
                                                 'the confusing part again.'},
                              'selfChecks': [{'en': 'The lead hand was returning as the rear hand '
                                                    'departed.',
                                              'tr': 'Arka el çıkarken ön el dönüyordu.'},
                                             {'en': 'I ended in a stance I could step from.',
                                              'tr': 'Adım atabileceğim bir duruşta bitirdim.'},
                                             {'tr': 'İki düz yolu ayırabiliyor ve çift sonunda iki '
                                                    'elimi de hazır yerine getirebiliyorum.',
                                              'en': 'I can distinguish the two straight paths and '
                                                    "bring both hands to readiness at the pair's "
                                                    'end.'}],
                              'sourceIds': ['boxing_canada_beginner',
                                            'england_boxing_level1',
                                            'motor_spacing_primary']},
 'boxing.defence.distance': {'steps': [{'en': 'Mark an imagined line from in front of you. Take '
                                              'one small backward step, recover the trailing foot, '
                                              'then stop in guard.',
                                        'tr': 'Önünden gelen hayalî bir hat belirle. Küçük bir '
                                              'geri adım at, takip eden ayağı yerleştir ve gardda '
                                              'dur.'},
                                       {'en': 'Repeat with a diagonal exit. These are rehearsed '
                                              'directions, not a tested response to an opponent.',
                                        'tr': 'Çapraz çıkışla tekrarla. Bunlar rakibe karşı '
                                              'sınanmış tepki değil, prova edilen yönlerdir.'},
                                       {'tr': 'Planlı geri adımı gerçek bir saldırıdan kaçınma '
                                              'kanıtı sanma. Burada yalnız alan ve taban '
                                              'yönetimini çalış; eşin saldırmasını isteme.',
                                        'en': 'Do not treat a planned back step as proof of '
                                              'avoiding a real attack. Rehearse only space and '
                                              'base management here and ask no partner to '
                                              'attack.'}],
                             'practice': {'tr': 'Beş geri ve beş çapraz planlı çıkış yap; her '
                                                'seferinde ayakları ve gardı yeniden kur.\n'
                                                '\n'
                                                'Kısa odak çalışması: İlk iki geri, ilk iki çapraz '
                                                'çıkışı ayrı duraklarla yap. Sonra bildiğin iki '
                                                'çıkışı kendi sıranla seç ve her birinde gardı '
                                                'yeniden kur. Bölümler arasında dinlen; süreyi '
                                                'rahatlığına göre uzat.\n'
                                                '\n'
                                                'Rahat olduğunda tek değişken denemesi: Geri ve '
                                                'çapraz çıkışların sırasını değiştir; hayalî '
                                                'saldırı hızını artırma.\n'
                                                '\n'
                                                'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                'uygulamanın sırasını önce yardımsız hatırla. '
                                                'Mesafeye gir ve çık dersini kısaca hatırla; '
                                                'yalnız karışan kısmı yeniden kontrol et.',
                                          'en': 'Alternate five backward and five diagonal planned '
                                                'exits, resetting the feet and guard each time.\n'
                                                '\n'
                                                'Short focused practice: Pause through the first '
                                                'two back and first two diagonal exits, then '
                                                'choose a sequence of the two familiar exits and '
                                                'rebuild guard after each. Rest between sections; '
                                                'take longer if you need it.\n'
                                                '\n'
                                                'When comfortable, try changing just one variable: '
                                                'Swap the back and diagonal exit order without '
                                                "increasing an imagined attack's speed.\n"
                                                '\n'
                                                'Next practice: At the next suitable session, '
                                                'recall the short sequence without reading first. '
                                                'Briefly revisit Enter and leave range; check only '
                                                'the confusing part again.'},
                             'selfChecks': [{'en': 'I finished each exit balanced and able to move '
                                                   'again.',
                                             'tr': 'Her çıkışı dengede ve yeniden hareket edebilir '
                                                   'halde bitirdim.'},
                                            {'en': 'I did not call this a measured defensive '
                                                   'reflex.',
                                             'tr': 'Bunu ölçülmüş savunma refleksi saymadım.'},
                                            {'tr': 'İki planlı çıkış yolunu seçebiliyor ve bu '
                                                   'provanın gerçek saldırı tepkisi olmadığını '
                                                   'biliyorum.',
                                             'en': 'I can choose two planned exit paths and '
                                                   'understand that this rehearsal is not a '
                                                   'reaction to a real attack.'}],
                             'sourceIds': ['boxing_canada_beginner',
                                           'england_boxing_level1',
                                           'motor_spacing_primary']},
 'boxing.defence.cover': {'steps': [{'en': 'From relaxed guard, bring both hands a little closer '
                                           'to the temples and let elbows settle comfortably '
                                           'toward the body.',
                                     'tr': 'Rahat garddan iki eli şakaklara biraz yaklaştır ve '
                                           'dirsekleri rahatça gövdeye indir.'},
                                    {'en': 'Take one small step out, then return to ordinary '
                                           'guard. Avoid squeezing so hard that shoulders rise and '
                                           'breathing stops.',
                                     'tr': 'Küçük bir çıkış adımı at, sonra normal garda dön. '
                                           'Omuzları kaldıracak veya nefesi kesecek kadar sıkma.'},
                                    {'tr': 'Korunmayı gözleri kapatmak veya omuzları sertçe '
                                           'sıkmakla kurma. Elleri rahat kompakt yerde tut, '
                                           'bakışını açık bırak ve küçük adımla yeniden yerleş.',
                                     'en': 'Do not build a cover by closing the eyes or squeezing '
                                           'the shoulders hard. Keep the hands comfortably '
                                           'compact, the gaze open and reset with a small step.'}],
                          'practice': {'tr': 'Çıkış yönünü değiştirerek altı yavaş '
                                             'korun-adımla-dön döngüsü yap.\n'
                                             '\n'
                                             'Kısa odak çalışması: İki korun-adım-dön döngüsünde '
                                             'yalnız rahat görüşü izle; sonraki ikide yalnız ayak '
                                             'tabanını kontrol et. Dinlenmek için elleri indir. '
                                             'Bölümler arasında dinlen; süreyi rahatlığına göre '
                                             'uzat.\n'
                                             '\n'
                                             'Rahat olduğunda tek değişken denemesi: Korunma '
                                             'sonrası başka küçük çıkış yönünü seç ve tabanı '
                                             'yeniden kur.\n'
                                             '\n'
                                             'Sonraki pratik: Sonraki uygun oturumda kısa '
                                             'uygulamanın sırasını önce yardımsız hatırla. Rahat '
                                             'gard dersini kısaca hatırla; yalnız karışan kısmı '
                                             'yeniden kontrol et.',
                                       'en': 'Practise six cover-step-reset cycles slowly, '
                                             'alternating exit sides.\n'
                                             '\n'
                                             'Short focused practice: Focus only on comfortable '
                                             'vision in two cover-step-return cycles, then only on '
                                             'the foot base in the next two. Lower the hands to '
                                             'rest. Rest between sections; take longer if you need '
                                             'it.\n'
                                             '\n'
                                             'When comfortable, try changing just one variable: '
                                             'Choose another small exit direction after the cover '
                                             'and rebuild the base.\n'
                                             '\n'
                                             'Next practice: At the next suitable session, recall '
                                             'the short sequence without reading first. Briefly '
                                             'revisit A relaxed guard; check only the confusing '
                                             'part again.'},
                          'selfChecks': [{'en': 'I could still see the imagined line ahead.',
                                          'tr': 'Öndeki hayalî hattı hâlâ görebiliyordum.'},
                                         {'en': 'My shoulders relaxed again on returning to guard.',
                                          'tr': 'Garda dönerken omuzlarım yeniden gevşedi.'},
                                         {'tr': 'Korunma şekli ve rahat görüşü birlikte '
                                                'kurabiliyor; darbeyi engellediğim sonucunu '
                                                'çıkarmıyorum.',
                                          'en': 'I can rehearse the cover shape with comfortable '
                                                'vision without claiming to have blocked an '
                                                'impact.'}],
                          'sourceIds': ['boxing_canada_beginner',
                                        'boxing_canada_competition',
                                        'england_boxing_level1',
                                        'motor_spacing_primary']},
 'boxing.defence.catch_parry': {'steps': [{'en': 'Begin in your stance and imagine a slow jab '
                                                 'toward the chin. For the catch, turn the rear '
                                                 'palm toward that line close to its guard '
                                                 'position; do not reach out.',
                                           'tr': 'Duruşunu kurup çeneye doğru yavaş jab hayal et. '
                                                 'Karşılamada arka avucu gard konumuna yakınken bu '
                                                 'hatta çevir; ileri uzanma.'},
                                          {'en': 'Rehearse a small receiving shape with the rear '
                                                 'forearm behind the hand. The front hand stays in '
                                                 'guard; there is no punch or contact to catch '
                                                 'here.',
                                           'tr': 'Arka önkol elin arkasındayken küçük karşılama '
                                                 'şekli prova et. Ön el gardda kalır; burada '
                                                 'karşılanacak gerçek yumruk veya temas yoktur.'},
                                          {'en': 'For the outside parry, use the rear hand again: '
                                                 'guide it a short distance across the imagined '
                                                 'jab line toward the front shoulder, with a small '
                                                 'controlled turn. Avoid a wide sweep or pulling '
                                                 'the head back.',
                                           'tr': 'Dışa yönlendirmede yine arka eli kullan: küçük '
                                                 'kontrollü dönüşle eli hayalî jab hattında ön '
                                                 'omuza doğru kısa mesafe kaydır. Geniş savurma '
                                                 'veya başı geriye çekme.'},
                                          {'en': 'Bring the rear hand back to the cheek and reset '
                                                 'after either shape. This planned solo drill does '
                                                 'not teach reacting to a real punch; live timing '
                                                 'needs supervised partner instruction.',
                                           'tr': 'İki şekilden sonra da arka eli yanağa getirip '
                                                 'yeniden kur. Bu planlı solo alıştırma gerçek '
                                                 'yumruğa tepki vermeyi öğretmez; canlı zamanlama '
                                                 'gözetimli eş öğretimi gerektirir.'},
                                          {'tr': "Karşılamayı ve parry'yi geniş kol savuruşu "
                                                 'yapma. Küçük karşıla-bırak ile küçük yana '
                                                 'yönlendir-dön hareketini ayrı adlandır.',
                                           'en': 'Do not turn a catch or parry into a large arm '
                                                 'swing. Name a small receive-release and a small '
                                                 'redirect-return separately.'}],
                                'practice': {'tr': 'Hayalî jaba karşı arka elle beş küçük '
                                                   'karşılama, ardından beş dışa yönlendirme yap. '
                                                   'Her birinden sonra gardda dur; hangi şeklin '
                                                   'karşıladığını, hangisinin yönlendirdiğini '
                                                   'söyle.\n'
                                                   '\n'
                                                   'Kısa odak çalışması: İkişer yavaş karşılama ve '
                                                   'yönlendirme provası yap; her biri arka el '
                                                   'gardından başlayıp oraya dönsün. Sonra '
                                                   'aralarındaki farkı kendi sözlerinle anlat. '
                                                   'Bölümler arasında dinlen; süreyi rahatlığına '
                                                   'göre uzat.\n'
                                                   '\n'
                                                   'Rahat olduğunda tek değişken denemesi: '
                                                   'Karşılama ve yönlendirme sırasını değiştir; '
                                                   'her biri sonrası tam gardda dur.\n'
                                                   '\n'
                                                   'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                   'uygulamanın sırasını önce yardımsız hatırla. '
                                                   'Rahat gard dersini kısaca hatırla; yalnız '
                                                   'karışan kısmı yeniden kontrol et.',
                                             'en': 'Do five small rear-hand catches, then five '
                                                   'rear-hand outside parries against an imagined '
                                                   'jab. Pause at guard after each and name which '
                                                   'shape receives and which redirects.\n'
                                                   '\n'
                                                   'Short focused practice: Rehearse two slow '
                                                   'catches and two redirects, each starting and '
                                                   'ending at rear-hand guard, then explain their '
                                                   'difference in your own words. Rest between '
                                                   'sections; take longer if you need it.\n'
                                                   '\n'
                                                   'When comfortable, try changing just one '
                                                   'variable: Swap catch and redirect order and '
                                                   'stop in full guard after each.\n'
                                                   '\n'
                                                   'Next practice: At the next suitable session, '
                                                   'recall the short sequence without reading '
                                                   'first. Briefly revisit A relaxed guard; check '
                                                   'only the confusing part again.'},
                                'selfChecks': [{'en': 'I could distinguish receiving from '
                                                      'redirecting without a wide hand sweep.',
                                                'tr': 'Eli geniş savurmadan karşılama ile '
                                                      'yönlendirmeyi ayırt edebildim.'},
                                               {'en': 'The front hand stayed in guard and the rear '
                                                      'hand returned after each shape.',
                                                'tr': 'Ön el gardda kaldı; arka el her şekilden '
                                                      'sonra yerine döndü.'},
                                               {'tr': 'İki şekli ayırıp küçük yoldan geri '
                                                      'dönebiliyorum; gerçek yumruğu karşılamayı '
                                                      'denemedim.',
                                                'en': 'I can distinguish both shapes and return '
                                                      'through a small path without testing them '
                                                      'against a real punch.'}],
                                'sourceIds': ['boxing_canada_beginner',
                                              'boxing_canada_competition',
                                              'england_boxing_level1',
                                              'motor_spacing_primary']},
 'boxing.defence.slip': {'steps': [{'en': 'With eyes ahead and guard available, shift a little '
                                          'through ankles, knees and torso to one side; keep the '
                                          'bend modest.',
                                    'tr': 'Bakış ileride ve gard hazırken ayak bileği, diz ve '
                                          'gövdeden biraz yana kay; eğilmeyi ölçülü tut.'},
                                   {'en': 'Return to the middle, then try the other side. Avoid '
                                          'dropping the head below the hands or folding sharply at '
                                          'the waist.',
                                    'tr': 'Ortaya dön, sonra diğer tarafı dene. Başı ellerin çok '
                                          'altına düşürme veya belden sert katlanma.'},
                                   {'tr': 'Sıyrılmayı belden derin katlanma veya büyük yana '
                                          'düşüşle karıştırma. Hareketi küçült, gözleri açık tut '
                                          've ortadaki rahat tabana geri dön.',
                                    'en': 'Do not confuse a slip with deep waist folding or a '
                                          'large sideways fall. Reduce the movement, keep the eyes '
                                          'open and return to the comfortable middle base.'}],
                         'practice': {'tr': 'Aralarda nefes ve yeniden yerleşmeyle üç yavaş '
                                            'sol-orta-sağ-orta dizisi yap.\n'
                                            '\n'
                                            'Kısa odak çalışması: Sol-orta-sağ-orta yolunu iki '
                                            'yavaş döngüyle dene; her ortada durup ayaklarını ve '
                                            'rahat nefesini kontrol et. Bölümler arasında dinlen; '
                                            'süreyi rahatlığına göre uzat.\n'
                                            '\n'
                                            'Rahat olduğunda tek değişken denemesi: Küçük '
                                            'sol-orta-sağ-orta yerine sağ-orta-sol-orta sırayı '
                                            'seç.\n'
                                            '\n'
                                            'Sonraki pratik: Sonraki uygun oturumda kısa '
                                            'uygulamanın sırasını önce yardımsız hatırla. Duruşunu '
                                            'bul dersini kısaca hatırla; yalnız karışan kısmı '
                                            'yeniden kontrol et.',
                                      'en': 'Make three slow left-middle-right-middle sequences, '
                                            'with a breath and reset between them.\n'
                                            '\n'
                                            'Short focused practice: Try two slow '
                                            'left-middle-right-middle cycles, stopping in the '
                                            'middle each time to check the feet and easy '
                                            'breathing. Rest between sections; take longer if you '
                                            'need it.\n'
                                            '\n'
                                            'When comfortable, try changing just one variable: '
                                            'Choose a small right-middle-left-middle order instead '
                                            'of left-middle-right-middle.\n'
                                            '\n'
                                            'Next practice: At the next suitable session, recall '
                                            'the short sequence without reading first. Briefly '
                                            'revisit Find your stance; check only the confusing '
                                            'part again.'},
                         'selfChecks': [{'en': 'I could stop at either side without falling '
                                               'forward.',
                                         'tr': 'İki tarafta da öne düşmeden durabildim.'},
                                        {'en': 'My eyes and guard stayed oriented ahead.',
                                         'tr': 'Bakışım ve gardım ileride kaldı.'},
                                        {'tr': 'İki küçük yönü ayırabiliyor, büyük eğilmeden orta '
                                               'tabana dönebiliyorum.',
                                         'en': 'I can distinguish the two small directions and '
                                               'return to the middle base without a large bend.'}],
                         'sourceIds': ['boxing_canada_competition',
                                       'england_boxing_level1',
                                       'boxing_canada_beginner',
                                       'motor_spacing_primary']},
 'boxing.defence.roll': {'steps': [{'en': 'From guard, soften knees a little, move under an '
                                          'imagined high arc, then stand back into a stable stance '
                                          'on the other side.',
                                    'tr': 'Garddan dizleri biraz yumuşat, hayalî yüksek yayın '
                                          'altından geç ve diğer yanda dengeli duruşa kalk.'},
                                   {'en': 'Keep the arc small and the back comfortable. This '
                                          'rehearses a movement path, not proof that a real hook '
                                          'was avoided.',
                                    'tr': 'Yayı küçük, beli rahat tut. Bu bir hareket yolu '
                                          'provasıdır; gerçek kroşeden kaçıldığı kanıtı değildir.'},
                                   {'tr': 'Yuvarlanma şeklini derin çömelme veya boynu çevirmekle '
                                          'üretme. Hayalî yay küçük olsun; dizlerin rahat '
                                          'hareketiyle gövdeyi birlikte taşı.',
                                    'en': 'Do not create the roll shape through a deep squat or '
                                          'neck twisting. Use a small imagined arc and move the '
                                          'torso together with comfortable knee motion.'}],
                         'practice': {'tr': 'Her yöne dört yavaş yarım yuvarlanma dene; her '
                                            'birinden sonra tamamen dikleş.\n'
                                            '\n'
                                            'Kısa odak çalışması: Her yöne iki küçük yarım yay '
                                            'seç; her birinin sonunda gard ve rahat tabanı yeniden '
                                            'kur. Rahatsızsa yön değişimini yalnız küçük adımla '
                                            'prova et. Bölümler arasında dinlen; süreyi '
                                            'rahatlığına göre uzat.\n'
                                            '\n'
                                            'Rahat olduğunda tek değişken denemesi: Yarım yay '
                                            'sonrası bir küçük yan adım seç ve araya gard dönüşü '
                                            'koy.\n'
                                            '\n'
                                            'Sonraki pratik: Sonraki uygun oturumda kısa '
                                            'uygulamanın sırasını önce yardımsız hatırla. Küçük '
                                            'sıyrılmalar dersini kısaca hatırla; yalnız karışan '
                                            'kısmı yeniden kontrol et.',
                                      'en': 'Try four slow half-rolls each way with a full upright '
                                            'reset after every one.\n'
                                            '\n'
                                            'Short focused practice: Choose two small half-arcs '
                                            'each way and rebuild guard and a comfortable base '
                                            'after each. If uncomfortable, rehearse the direction '
                                            'change with a small step only. Rest between sections; '
                                            'take longer if you need it.\n'
                                            '\n'
                                            'When comfortable, try changing just one variable: '
                                            'Choose a small side step after the half-arc with a '
                                            'guard reset between them.\n'
                                            '\n'
                                            'Next practice: At the next suitable session, recall '
                                            'the short sequence without reading first. Briefly '
                                            'revisit Small slips; check only the confusing part '
                                            'again.'},
                         'selfChecks': [{'en': 'My feet stayed separated and my head returned over '
                                               'the base.',
                                         'tr': 'Ayaklarım ayrı kaldı ve başım tabanın üzerine '
                                               'döndü.'},
                                        {'en': 'I could breathe and stop anywhere in the path.',
                                         'tr': 'Yolun herhangi yerinde nefes alıp durabildim.'},
                                        {'tr': 'Yayı küçültebiliyor ve bunun gerçek kroşeden kaçış '
                                               'testi olmadığını açıklayabiliyorum.',
                                         'en': 'I can reduce the arc and explain that this is not '
                                               'a test of evading a real hook.'}],
                         'sourceIds': ['boxing_canada_competition',
                                       'england_boxing_level1',
                                       'boxing_canada_beginner',
                                       'motor_spacing_primary']},
 'boxing.curves.lead_hook': {'steps': [{'en': 'From guard, rotate comfortably through the feet and '
                                              'trunk as the lead hand traces a short arc toward an '
                                              'imagined side target.',
                                        'tr': 'Garddan ayak ve gövde boyunca rahatça dön; ön el '
                                              'hayalî yan hedefe kısa yay çizsin.'},
                                       {'en': 'Keep the wrist comfortable and the elbow neither '
                                              'pinned against the ribs nor thrown far behind. '
                                              'Return the hand and stance together.',
                                        'tr': 'Bileği rahat tut; dirseği ne kaburgaya yapıştır ne '
                                              'de geriye savur. Eli ve duruşu birlikte geri '
                                              'getir.'},
                                       {'tr': 'Ön kroşeyi kolu arkaya açıp büyük savuruşla '
                                              'başlatma. Garddan kısa rahat yay seç, arka eli '
                                              'hazır tut ve tabana dön.',
                                        'en': 'Do not start the lead hook by winding the arm back '
                                              'into a large swing. Choose a short comfortable arc '
                                              'from guard, keep the rear hand ready and return to '
                                              'the base.'}],
                             'practice': {'tr': 'Tekrarlar arasında tam gard duruşuyla havada altı '
                                                'yavaş ön kroşe çiz.\n'
                                                '\n'
                                                'Kısa odak çalışması: İki kısa grupta üçer yavaş '
                                                'ön kroşe şekli dene; her tekrar sonrası tamamen '
                                                'dur. İlk grupta başlangıç, ikinci grupta dönüş '
                                                'odağını seç. Bölümler arasında dinlen; süreyi '
                                                'rahatlığına göre uzat.\n'
                                                '\n'
                                                'Rahat olduğunda tek değişken denemesi: Tek ön '
                                                'kroşe sonrası bildiğin küçük çıkışı seç; büyük '
                                                'kombinasyon ekleme.\n'
                                                '\n'
                                                'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                'uygulamanın sırasını önce yardımsız hatırla. '
                                                'Rahat gard dersini kısaca hatırla; yalnız karışan '
                                                'kısmı yeniden kontrol et.',
                                          'en': 'Trace six slow lead hooks in the air with a full '
                                                'guard pause between repetitions.\n'
                                                '\n'
                                                'Short focused practice: Try two short groups of '
                                                'three slow lead-hook shapes, stopping completely '
                                                'after each. Focus on the start in the first group '
                                                'and recovery in the second. Rest between '
                                                'sections; take longer if you need it.\n'
                                                '\n'
                                                'When comfortable, try changing just one variable: '
                                                'Choose a familiar small exit after one lead hook '
                                                'without adding a long combination.\n'
                                                '\n'
                                                'Next practice: At the next suitable session, '
                                                'recall the short sequence without reading first. '
                                                'Briefly revisit A relaxed guard; check only the '
                                                'confusing part again.'},
                             'selfChecks': [{'en': 'The arc stayed compact rather than swinging '
                                                   'the whole arm behind me.',
                                             'tr': 'Yay kolu geriye savurmak yerine toplu kaldı.'},
                                            {'en': 'The rear hand and final stance remained '
                                                   'available.',
                                             'tr': 'Arka el ve son duruş hazır kaldı.'},
                                            {'tr': 'Kroşe yolunu düz yumruktan ayırabiliyor ve '
                                                   'büyük geriye hazırlık yapmadan geri '
                                                   'dönebiliyorum.',
                                             'en': 'I can distinguish the hook path from a '
                                                   'straight and recover without a large '
                                                   'wind-up.'}],
                             'sourceIds': ['boxing_canada_competition',
                                           'england_boxing_level1',
                                           'boxing_canada_beginner',
                                           'motor_spacing_primary']},
 'boxing.curves.rear_hook': {'steps': [{'en': 'Begin in stance, let the rear foot and trunk turn '
                                              'comfortably, and draw a compact rear-hand arc '
                                              'across an imagined line.',
                                        'tr': 'Duruştan başla; arka ayak ve gövde rahatça dönsün, '
                                              'arka elle hayalî hat üzerinden toplu yay çiz.'},
                                       {'en': 'Keep the lead hand near guard. Let the rear hand '
                                              'return before moving the feet again; do not '
                                              'over-rotate past a balanced base.',
                                        'tr': 'Ön eli garda yakın tut. Ayakları yeniden oynatmadan '
                                              'arka eli getir; dengeli tabanı geçecek kadar '
                                              'dönme.'},
                                       {'tr': 'Arka kroşeyi ön kroşenin ters kopyası diye '
                                              'zorlamadan öğren. Küçük arka yayda ön elin hazır '
                                              'yerini ve rahat taban dönüşünü izle.',
                                        'en': 'Learn the rear hook without forcing it to be an '
                                              'exact reverse copy of the lead hook. Watch '
                                              'lead-hand readiness and comfortable base recovery '
                                              'during the small rear arc.'}],
                             'practice': {'tr': 'Dört çok yavaş arka kroşe çalış, yerleş, sonra '
                                                'ters ön duruştan dört tane daha yap.\n'
                                                '\n'
                                                'Kısa odak çalışması: Mevcut dört yavaş tekrarı '
                                                'ikişer bölüme ayır; arada elleri indirip dinlen. '
                                                'Ön tarafı değiştirirsen yeni arka eli önce '
                                                'adlandır. Bölümler arasında dinlen; süreyi '
                                                'rahatlığına göre uzat.\n'
                                                '\n'
                                                'Rahat olduğunda tek değişken denemesi: Ön tarafı '
                                                'değiştirmeyi seçersen yeni arka eli adlandırıp '
                                                'yalnız bir küçültülmüş prova yap.\n'
                                                '\n'
                                                'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                'uygulamanın sırasını önce yardımsız hatırla. '
                                                'Duruşunu bul dersini kısaca hatırla; yalnız '
                                                'karışan kısmı yeniden kontrol et.',
                                          'en': 'Practise four very slow rear hooks, reset, then '
                                                'four more from the opposite lead stance.\n'
                                                '\n'
                                                'Short focused practice: Split the existing four '
                                                'slow repetitions into two pairs, lowering the '
                                                'hands to rest between them. If changing stance, '
                                                'name the new rear hand first. Rest between '
                                                'sections; take longer if you need it.\n'
                                                '\n'
                                                'When comfortable, try changing just one variable: '
                                                'If choosing to change stance, name the new rear '
                                                'hand and use only one reduced rehearsal.\n'
                                                '\n'
                                                'Next practice: At the next suitable session, '
                                                'recall the short sequence without reading first. '
                                                'Briefly revisit Find your stance; check only the '
                                                'confusing part again.'},
                             'selfChecks': [{'en': 'The opposite hand did not leave guard.',
                                             'tr': 'Diğer el gardı terk etmedi.'},
                                            {'en': 'I ended able to stop and step, without '
                                                   'spinning.',
                                             'tr': 'Dönüp savrulmadan durup adımlayabilir halde '
                                                   'bitirdim.'},
                                            {'tr': 'Fiziksel sağ-sol el ile ön-arka elin farkını '
                                                   'biliyor ve arka kroşeden rahatça '
                                                   'dönebiliyorum.',
                                             'en': 'I know the difference between physical '
                                                   'left-right and lead-rear hands and can recover '
                                                   'comfortably from the rear hook.'}],
                             'sourceIds': ['boxing_canada_competition',
                                           'england_boxing_level1',
                                           'boxing_canada_beginner',
                                           'motor_spacing_primary']},
 'boxing.curves.lead_uppercut': {'steps': [{'en': 'Start with the lead hand near guard. Soften the '
                                                  'knees a little, then let the hand rise on a '
                                                  'short imagined inside line as the body returns '
                                                  'upright.',
                                            'tr': 'Ön el gard yakınında başlasın. Dizleri biraz '
                                                  'yumuşat, sonra gövde dikleşirken el hayalî iç '
                                                  'hatta kısa yükselsin.'},
                                           {'en': 'Do not swing from behind the hip or snap the '
                                                  'elbow. Bring the hand back to guard before '
                                                  'another repetition.',
                                            'tr': 'Kalça arkasından savurma veya dirseği sertçe '
                                                  'açma. Sonraki tekrardan önce eli garda getir.'},
                                           {'tr': 'Ön aparkatı eli kalçanın arkasına indirip büyük '
                                                  'yukarı savuruşla başlatma. Ön garddan kısa '
                                                  'rahat yükseliş seç ve arka eli hazır bırak.',
                                            'en': 'Do not start the lead uppercut by dropping the '
                                                  'hand behind the hip for a large upward swing. '
                                                  'Choose a short comfortable rise from lead guard '
                                                  'and keep the rear hand ready.'}],
                                 'practice': {'tr': 'Rahat yükseklikte altı yavaş ön aparkat yolu '
                                                    'yap ve tamamen yerleş.\n'
                                                    '\n'
                                                    'Kısa odak çalışması: Üç yavaş küçük ön '
                                                    'aparkat şekliyle yüksel-dön-dur sırasını kur; '
                                                    'kısa dinlenme sonrası istersen üç tekrar daha '
                                                    'seç. Bölümler arasında dinlen; süreyi '
                                                    'rahatlığına göre uzat.\n'
                                                    '\n'
                                                    'Rahat olduğunda tek değişken denemesi: Ön '
                                                    'aparkat sonrası küçük geri çıkış seç ve kısa '
                                                    'yükselişi koru.\n'
                                                    '\n'
                                                    'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                    'uygulamanın sırasını önce yardımsız hatırla. '
                                                    'Rahat gard dersini kısaca hatırla; yalnız '
                                                    'karışan kısmı yeniden kontrol et.',
                                              'en': 'Perform six slow lead uppercut paths at a '
                                                    'comfortable height with a full reset.\n'
                                                    '\n'
                                                    'Short focused practice: Use three slow small '
                                                    'lead-uppercut shapes for rise-return-stop, '
                                                    'then optionally choose three more after a '
                                                    'short rest. Rest between sections; take '
                                                    'longer if you need it.\n'
                                                    '\n'
                                                    'When comfortable, try changing just one '
                                                    'variable: Choose a small back exit after the '
                                                    'lead uppercut while retaining its short '
                                                    'rise.\n'
                                                    '\n'
                                                    'Next practice: At the next suitable session, '
                                                    'recall the short sequence without reading '
                                                    'first. Briefly revisit A relaxed guard; check '
                                                    'only the confusing part again.'},
                                 'selfChecks': [{'en': 'The hand began and ended close to guard.',
                                                 'tr': 'El garda yakın başlayıp bitti.'},
                                                {'en': 'The knees softened without a deep or '
                                                       'painful dip.',
                                                 'tr': 'Dizler derin veya ağrılı çöküş olmadan '
                                                       'yumuşadı.'},
                                                {'tr': 'Kısa yükselen yolu kroşe yayından '
                                                       'ayırabiliyor, eli büyük geriye hazırlık '
                                                       'yapmadan döndürebiliyorum.',
                                                 'en': 'I can distinguish the short rising path '
                                                       'from a hook arc and return without a large '
                                                       'wind-up.'}],
                                 'sourceIds': ['boxing_canada_competition',
                                               'england_boxing_level1',
                                               'boxing_canada_beginner',
                                               'motor_spacing_primary']},
 'boxing.curves.rear_uppercut': {'steps': [{'en': 'Begin with both hands ready. Allow a small '
                                                  'rear-side turn and a gentle knee-softening '
                                                  'while the rear hand rises close to the torso.',
                                            'tr': 'İki el hazır başla. Arka el gövdeye yakın '
                                                  'yükselirken küçük arka taraf dönüşü ve yumuşak '
                                                  'diz hareketine izin ver.'},
                                           {'en': 'Finish without throwing the shoulder upward or '
                                                  'reaching far past the stance; return the rear '
                                                  'hand and settle the feet.',
                                            'tr': 'Omzu yukarı savurmadan veya duruşu aşan erişim '
                                                  'olmadan bitir; arka eli ve ayakları yerine '
                                                  'getir.'},
                                           {'tr': 'Arka aparkatta başı yukarı sıçratma veya omzu '
                                                  'kulaklara sıkıştırma. Yükselişi küçült, '
                                                  'ayak-gövde yön değişimini rahat tut ve ön eli '
                                                  'hazır bırak.',
                                            'en': 'Do not jump the head upwards or squeeze the '
                                                  'shoulder toward the ear in a rear uppercut. '
                                                  'Reduce the rise, keep the foot-and-torso turn '
                                                  'comfortable and leave the lead hand ready.'}],
                                 'practice': {'tr': 'Beş arka aparkat yolunu yavaşça yap ve her '
                                                    'birinde ön eli kontrol etmek için dur.\n'
                                                    '\n'
                                                    'Kısa odak çalışması: İlk iki yavaş tekrarda '
                                                    'yalnız kısa yükselişi, sonraki ikide yalnız '
                                                    'geri dönüşü izle; beşinciyi rahat '
                                                    'hissediyorsan seç. Bölümler arasında dinlen; '
                                                    'süreyi rahatlığına göre uzat.\n'
                                                    '\n'
                                                    'Rahat olduğunda tek değişken denemesi: Arka '
                                                    'aparkatı bir küçük yön değişiminden sonra '
                                                    'ayrı kur.\n'
                                                    '\n'
                                                    'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                    'uygulamanın sırasını önce yardımsız hatırla. '
                                                    'Arka düzden sonra toparlan dersini kısaca '
                                                    'hatırla; yalnız karışan kısmı yeniden kontrol '
                                                    'et.',
                                              'en': 'Make five rear uppercut paths slowly and '
                                                    'pause after each to check the lead hand.\n'
                                                    '\n'
                                                    'Short focused practice: Watch only the short '
                                                    'rise in the first two slow repetitions and '
                                                    'only recovery in the next two; choose a fifth '
                                                    'if comfortable. Rest between sections; take '
                                                    'longer if you need it.\n'
                                                    '\n'
                                                    'When comfortable, try changing just one '
                                                    'variable: Rehearse the rear uppercut '
                                                    'separately after a small direction change.\n'
                                                    '\n'
                                                    'Next practice: At the next suitable session, '
                                                    'recall the short sequence without reading '
                                                    'first. Briefly revisit Recover after the rear '
                                                    'straight; check only the confusing part '
                                                    'again.'},
                                 'selfChecks': [{'en': 'The lead hand stayed available near guard.',
                                                 'tr': 'Ön el garda yakın hazır kaldı.'},
                                                {'en': 'The movement finished balanced, not '
                                                       'leaning behind the target.',
                                                 'tr': 'Hareket hedefin arkasına eğilmeden dengede '
                                                       'bitti.'},
                                                {'tr': 'Arka aparkatı küçük yolda kurup rahat '
                                                       'taban ve hazır ön elle bitirebiliyorum.',
                                                 'en': 'I can rehearse the rear uppercut through a '
                                                       'small path and finish with a comfortable '
                                                       'base and ready lead hand.'}],
                                 'sourceIds': ['boxing_canada_competition',
                                               'england_boxing_level1',
                                               'boxing_canada_beginner',
                                               'motor_spacing_primary']},
 'boxing.curves.targets': {'steps': [{'en': 'Visualise two empty points at different heights. For '
                                            'the lower point, soften knees slightly and redirect '
                                            'the path while keeping the head over the feet.',
                                      'tr': 'Farklı yükseklikte iki boş nokta hayal et. Alçak '
                                            'nokta için dizleri hafif yumuşat, baş ayakların '
                                            'üzerinde kalırken yolu yeniden yönlendir.'},
                                     {'en': 'Alternate one comfortable straight at the higher line '
                                            'and one controlled curved shape at the lower line. '
                                            'Never punch a person or object.',
                                      'tr': 'Yüksek hatta rahat bir düz, alçak hatta kontrollü bir '
                                            'kavisli şekil dönüşümlü yap. İnsana veya nesneye '
                                            'vurma.'},
                                     {'tr': 'Alçak hayalî hedefe kolu zorlayıp belden kapanarak '
                                            'uzanma. Hedefi yaklaştır, rahat düzey değişimini '
                                            'küçült ve başı taban üzerinde tut.',
                                      'en': 'Do not reach a low imagined target by forcing the arm '
                                            'and folding at the waist. Move the target closer, '
                                            'reduce the level change and keep the head over the '
                                            'base.'}],
                           'practice': {'tr': 'Her çift sonrası gard dönüşüyle dört yüksek-alçak '
                                              'çift izle; kesin yükseklik hedefi yok.\n'
                                              '\n'
                                              'Kısa odak çalışması: İki yüksek-alçak çiftte aynı '
                                              'yavaş yumruk yolunu kullan; her düzey sonrası tam '
                                              'gardda dur. Diğer çiftleri yalnız rahatlık '
                                              'korunuyorsa seç. Bölümler arasında dinlen; süreyi '
                                              'rahatlığına göre uzat.\n'
                                              '\n'
                                              'Rahat olduğunda tek değişken denemesi: Hedef '
                                              'düzeylerinin sırasını değiştir; gerçek bir nesne '
                                              'ekleme.\n'
                                              '\n'
                                              'Sonraki pratik: Sonraki uygun oturumda kısa '
                                              'uygulamanın sırasını önce yardımsız hatırla. '
                                              'Mesafeye gir ve çık dersini kısaca hatırla; yalnız '
                                              'karışan kısmı yeniden kontrol et.',
                                        'en': 'Trace four high-low pairs with a guard reset after '
                                              'each pair and no demand for exact height.\n'
                                              '\n'
                                              'Short focused practice: Use the same slow punch '
                                              'path for two high-low pairs and stop in full guard '
                                              'after each level. Choose the remaining pairs only '
                                              'while comfortable. Rest between sections; take '
                                              'longer if you need it.\n'
                                              '\n'
                                              'When comfortable, try changing just one variable: '
                                              'Swap the target-level order without adding a real '
                                              'object.\n'
                                              '\n'
                                              'Next practice: At the next suitable session, recall '
                                              'the short sequence without reading first. Briefly '
                                              'revisit Enter and leave range; check only the '
                                              'confusing part again.'},
                           'selfChecks': [{'en': 'I changed level without falling over the lead '
                                                 'foot.',
                                           'tr': 'Ön ayağın üzerine düşmeden düzey değiştirdim.'},
                                          {'en': 'The hands returned to guard after both paths.',
                                           'tr': 'İki yoldan sonra eller garda döndü.'},
                                          {'tr': 'Hayalî hedef düzeyini rahat değiştirebiliyor ve '
                                                 'bunun gerçek isabet testi olmadığını biliyorum.',
                                           'en': 'I can change an imagined target level '
                                                 'comfortably and know this is not a real accuracy '
                                                 'test.'}],
                           'sourceIds': ['boxing_canada_competition',
                                         'england_boxing_level1',
                                         'boxing_canada_beginner',
                                         'motor_spacing_primary']},
 'boxing.combinations.double_jab_cross': {'steps': [{'en': 'Send jab, return, jab, return, then '
                                                           'rear straight. Count the three starts '
                                                           'from guard aloud while learning.',
                                                     'tr': 'Jab, dönüş, jab, dönüş, sonra arka düz '
                                                           'gönder. Öğrenirken garddan üç çıkışı '
                                                           'sesli say.'},
                                                    {'en': 'Keep the feet quiet and the rear hand '
                                                           'ready during both jabs. After the rear '
                                                           'straight, bring it home before '
                                                           'stepping away.',
                                                     'tr': 'İki jab sırasında ayakları sakin, arka '
                                                           'eli hazır tut. Arka düzden sonra '
                                                           'uzaklaşmadan önce eli yerine getir.'},
                                                    {'tr': 'Üçlü dizide ikinci jabı atlamak veya '
                                                           'dönüşleri kısaltmak sırayı karıştırır. '
                                                           'Önce jab-geri-jab-geri-arka düz-geri '
                                                           'diye ayır, sonra rahat bağla.',
                                                     'en': 'Skipping the second jab or shortening '
                                                           'returns confuses the three-punch '
                                                           'sequence. Separate '
                                                           'jab-return-jab-return-rear '
                                                           'straight-return first, then connect '
                                                           'comfortably.'}],
                                          'practice': {'tr': 'Beş yavaş üçlü dizi yap; her '
                                                             'birinden sonra geri çıkıp tam '
                                                             'yerleş.\n'
                                                             '\n'
                                                             'Kısa odak çalışması: İlk iki üçlüyü '
                                                             'sözle duraklı yap; sonraki iki '
                                                             'üçlüyü rahat bağlayıp küçük geri '
                                                             'çıkışla bitir. Son deneme isteğe '
                                                             'bağlıdır. Bölümler arasında dinlen; '
                                                             'süreyi rahatlığına göre uzat.\n'
                                                             '\n'
                                                             'Rahat olduğunda tek değişken '
                                                             'denemesi: Üçlü sonrası geri yerine '
                                                             'küçük yan çıkış seç; önce elleri '
                                                             'geri getir.\n'
                                                             '\n'
                                                             'Sonraki pratik: Sonraki uygun '
                                                             'oturumda kısa uygulamanın sırasını '
                                                             'önce yardımsız hatırla. İki jab, tek '
                                                             'taban dersini kısaca hatırla; yalnız '
                                                             'karışan kısmı yeniden kontrol et.',
                                                       'en': 'Perform five slow three-punch '
                                                             'sequences, each followed by a '
                                                             'backward exit and full reset.\n'
                                                             '\n'
                                                             'Short focused practice: Say and '
                                                             'pause through the first two triples, '
                                                             'then connect the next two '
                                                             'comfortably and finish with a small '
                                                             'back exit. The last attempt is '
                                                             'optional. Rest between sections; '
                                                             'take longer if you need it.\n'
                                                             '\n'
                                                             'When comfortable, try changing just '
                                                             'one variable: Choose a small side '
                                                             'exit rather than back after the '
                                                             'triple, recovering the hands first.\n'
                                                             '\n'
                                                             'Next practice: At the next suitable '
                                                             'session, recall the short sequence '
                                                             'without reading first. Briefly '
                                                             'revisit Two jabs, one base; check '
                                                             'only the confusing part again.'},
                                          'selfChecks': [{'en': 'I could pause between the two '
                                                                'jabs without losing the sequence.',
                                                          'tr': 'İki jab arasında diziyi '
                                                                'kaybetmeden durabildim.'},
                                                         {'en': 'Only one hand left guard at a '
                                                                'time.',
                                                          'tr': 'Bir anda yalnız bir el garddan '
                                                                'ayrıldı.'},
                                                         {'tr': 'Çift jab ile bir-ikinin sıra '
                                                                'farkını biliyor ve üçlü sonrası '
                                                                'tabanıma dönebiliyorum.',
                                                          'en': 'I know how a double-jab sequence '
                                                                'differs from a one-two and can '
                                                                'return to the base after the '
                                                                'triple.'}],
                                          'sourceIds': ['boxing_canada_beginner',
                                                        'england_boxing_level1',
                                                        'motor_spacing_primary']},
 'boxing.combinations.one_two_hook': {'steps': [{'en': 'Jab and return, rear straight and return, '
                                                       'then draw the lead hook arc. Keep each '
                                                       'action distinct before linking the rhythm.',
                                                 'tr': 'Jab ve dönüş, arka düz ve dönüş, sonra ön '
                                                       'kroşe yayı çiz. Ritmi bağlamadan önce her '
                                                       'hareketi ayrı tut.'},
                                                {'en': 'The hook begins from a recovered lead '
                                                       'guard, not from a hand left extended after '
                                                       'the jab. End with both hands ready.',
                                                 'tr': 'Kroşe jabdan sonra uzatılmış elden değil, '
                                                       'yeniden kurulmuş ön garddan başlar. İki el '
                                                       'hazır bitir.'},
                                                {'tr': 'Kroşeyi arka düz henüz dönmeden geniş '
                                                       'savurma. Önce üç yolu duraklı ayır; '
                                                       'bağlantıda kısa ön kroşe ve hazır arka el '
                                                       'fikrini koru.',
                                                 'en': 'Do not swing a wide hook before recovering '
                                                       'from the rear straight. Separate the three '
                                                       'paths with pauses first and keep a short '
                                                       'lead hook with rear-hand readiness when '
                                                       'connecting them.'}],
                                      'practice': {'tr': 'Aralarında tam ara ve duruş dönüşüyle '
                                                         'dört yavaş 1-2-kroşe dizisi çiz.\n'
                                                         '\n'
                                                         'Kısa odak çalışması: İki duraklı '
                                                         'bir-iki-ön kroşe yap; kısa aradan sonra '
                                                         'iki bağlı deneme seç. Her dizide bitiş '
                                                         'gardını yeniden kur. Bölümler arasında '
                                                         'dinlen; süreyi rahatlığına göre uzat.\n'
                                                         '\n'
                                                         'Rahat olduğunda tek değişken denemesi: '
                                                         'Aynı üçlü sonrası çıkış yönünü değiştir, '
                                                         'kroşe yolunu büyütme.\n'
                                                         '\n'
                                                         'Sonraki pratik: Sonraki uygun oturumda '
                                                         'kısa uygulamanın sırasını önce yardımsız '
                                                         'hatırla. Jab sonra arka düz dersini '
                                                         'kısaca hatırla; yalnız karışan kısmı '
                                                         'yeniden kontrol et.',
                                                   'en': 'Trace four slow 1-2-hook sequences with '
                                                         'a complete rest and stance reset between '
                                                         'them.\n'
                                                         '\n'
                                                         'Short focused practice: Use two paused '
                                                         'one-two-lead-hook sequences, then choose '
                                                         'two connected attempts after a short '
                                                         'break. Rebuild the final guard each '
                                                         'time. Rest between sections; take longer '
                                                         'if you need it.\n'
                                                         '\n'
                                                         'When comfortable, try changing just one '
                                                         'variable: Change the exit direction '
                                                         'after the same triple without enlarging '
                                                         'the hook path.\n'
                                                         '\n'
                                                         'Next practice: At the next suitable '
                                                         'session, recall the short sequence '
                                                         'without reading first. Briefly revisit '
                                                         'Jab then rear straight; check only the '
                                                         'confusing part again.'},
                                      'selfChecks': [{'en': 'The hook was compact rather than an '
                                                            'arm swing from behind.',
                                                      'tr': 'Kroşe geriden kol savurma yerine '
                                                            'topluydu.'},
                                                     {'en': 'My stance could support a step after '
                                                            'the third action.',
                                                      'tr': 'Üçüncü hareketten sonra duruşum bir '
                                                            'adımı destekleyebilirdi.'},
                                                     {'tr': 'Düz ve yay yollarını sırayla '
                                                            'ayırabiliyor, üçlü sonunda iki elimi '
                                                            'hazır yere döndürüyorum.',
                                                      'en': 'I can distinguish the straight and '
                                                            'arc paths in order and return both '
                                                            'hands to readiness after the '
                                                            'triple.'}],
                                      'sourceIds': ['boxing_canada_competition',
                                                    'england_boxing_level1',
                                                    'boxing_canada_beginner',
                                                    'motor_spacing_primary']},
 'boxing.combinations.one_two_uppercut': {'steps': [{'en': 'Complete the jab and rear straight as '
                                                           'separate actions. After the rear hand '
                                                           'returns, soften the knees slightly and '
                                                           'lift the lead hand on its short inside '
                                                           'line.',
                                                     'tr': 'Jab ve arka düzü ayrı ayrı bitir. Arka '
                                                           'el dönünce dizleri hafif yumuşat ve ön '
                                                           'eli kısa iç hattında yükselt.'},
                                                    {'en': 'Do not dive forward to create the '
                                                           'uppercut. Return upright with the lead '
                                                           'hand back at guard.',
                                                     'tr': 'Aparkat için öne dalma. Ön el gardda '
                                                           'olacak şekilde dikleş.'},
                                                    {'tr': 'Aparkatı eklemek için öne dalma veya '
                                                           'eli geriye çekme. Önce kısa ön '
                                                           'yükselişi ayrı hatırla, sonra bir-iki '
                                                           'sonrası rahatça ekle.',
                                                     'en': 'Do not dive forwards or pull the hand '
                                                           'back to add the uppercut. Recall the '
                                                           'short lead rise separately first, then '
                                                           'add it comfortably after the '
                                                           'one-two.'}],
                                          'practice': {'tr': 'Konuşabilecek tempoda dört dikkatli '
                                                             'dizi yap; her birinde dizleri ve '
                                                             'elleri kontrol etmek için dur.\n'
                                                             '\n'
                                                             'Kısa odak çalışması: Bir tek ön '
                                                             'aparkat dönüşünü hatırla; iki '
                                                             'duraklı, ardından istersen iki bağlı '
                                                             'bir-iki-ön aparkat yap. Her '
                                                             'seferinde tam tabanda dur. Bölümler '
                                                             'arasında dinlen; süreyi rahatlığına '
                                                             'göre uzat.\n'
                                                             '\n'
                                                             'Rahat olduğunda tek değişken '
                                                             'denemesi: Üçlü sonrası farklı '
                                                             'bilinen küçük çıkış seç, yükselen '
                                                             'yolu kısa tut.\n'
                                                             '\n'
                                                             'Sonraki pratik: Sonraki uygun '
                                                             'oturumda kısa uygulamanın sırasını '
                                                             'önce yardımsız hatırla. Jab sonra '
                                                             'arka düz dersini kısaca hatırla; '
                                                             'yalnız karışan kısmı yeniden kontrol '
                                                             'et.',
                                                       'en': 'Make four careful sequences at a '
                                                             'speaking pace; pause after each to '
                                                             'check both knees and hands.\n'
                                                             '\n'
                                                             'Short focused practice: Recall one '
                                                             'lead-uppercut recovery, then use two '
                                                             'paused and optionally two connected '
                                                             'one-two-lead-uppercut sequences, '
                                                             'stopping in the full base each time. '
                                                             'Rest between sections; take longer '
                                                             'if you need it.\n'
                                                             '\n'
                                                             'When comfortable, try changing just '
                                                             'one variable: Choose a different '
                                                             'familiar small exit after the triple '
                                                             'and keep the rising path short.\n'
                                                             '\n'
                                                             'Next practice: At the next suitable '
                                                             'session, recall the short sequence '
                                                             'without reading first. Briefly '
                                                             'revisit Jab then rear straight; '
                                                             'check only the confusing part '
                                                             'again.'},
                                          'selfChecks': [{'en': 'The uppercut started near guard, '
                                                                'not below the waist.',
                                                          'tr': 'Aparkat bel altından değil, garda '
                                                                'yakın başladı.'},
                                                         {'en': 'I could stop after the third '
                                                                'action without an extra step.',
                                                          'tr': 'Üçüncü hareketten sonra ek adım '
                                                                'olmadan durabildim.'},
                                                         {'tr': 'Kroşe eklenen diziyle yükselen '
                                                                'yol eklenen dizinin farkını '
                                                                'açıklayabiliyorum.',
                                                          'en': 'I can explain the difference '
                                                                'between adding a hook arc and '
                                                                'adding a rising path to the '
                                                                'sequence.'}],
                                          'sourceIds': ['boxing_canada_competition',
                                                        'england_boxing_level1',
                                                        'boxing_canada_beginner',
                                                        'motor_spacing_primary']},
 'boxing.combinations.defend_return': {'steps': [{'en': 'Choose the sequence before starting: '
                                                        'cover, diagonal step, reset, jab. Move on '
                                                        'your own cue; nobody is attacking.',
                                                  'tr': 'Başlamadan diziyi seç: korun, çapraz '
                                                        'adım, yerleş, jab. Kendi işaretinle '
                                                        'hareket et; kimse saldırmıyor.'},
                                                 {'en': 'The step must end in balance before the '
                                                        'jab. Finish with a hand return and a '
                                                        'backward exit.',
                                                  'tr': 'Jabdan önce adım dengede bitmeli. El '
                                                        'dönüşü ve geri çıkışla tamamla.'},
                                                 {'tr': 'Planlı korunma sonrası hemen aceleyle '
                                                        'yumruk atma. Önce küçük çapraz adımla '
                                                        'tabanı kur; sonra yavaş jab ve geri '
                                                        'çıkışı seç.',
                                                  'en': 'Do not rush a punch immediately after the '
                                                        'planned cover. Rebuild the base with a '
                                                        'small diagonal step first, then choose a '
                                                        'slow jab and back exit.'}],
                                       'practice': {'tr': 'Beş parçayı adlandırabilecek kadar '
                                                          'yavaş, her çapraz tarafa üç prova yap.\n'
                                                          '\n'
                                                          'Kısa odak çalışması: Korun-çapraz '
                                                          'adım-yerleş-jab-geri çık zincirini önce '
                                                          'yalnız sözle anlat; iki yavaş prova '
                                                          'yapıp en zor bağlantıyı ayrı bir kez '
                                                          'dene. Bölümler arasında dinlen; süreyi '
                                                          'rahatlığına göre uzat.\n'
                                                          '\n'
                                                          'Rahat olduğunda tek değişken denemesi: '
                                                          'Zincirde yalnız çapraz çıkış yönünü '
                                                          'değiştir; savunmayı gerçek saldırıyla '
                                                          'sınama.\n'
                                                          '\n'
                                                          'Sonraki pratik: Sonraki uygun oturumda '
                                                          'kısa uygulamanın sırasını önce '
                                                          'yardımsız hatırla. Toplu korunma '
                                                          'dersini kısaca hatırla; yalnız karışan '
                                                          'kısmı yeniden kontrol et.',
                                                    'en': 'Do three rehearsals to each diagonal '
                                                          'side, slowly enough to name all five '
                                                          'parts.\n'
                                                          '\n'
                                                          'Short focused practice: Speak the '
                                                          'cover-diagonal step-reset-jab-back exit '
                                                          'chain first, then use two slow '
                                                          'rehearsals and revisit the hardest '
                                                          'connection once separately. Rest '
                                                          'between sections; take longer if you '
                                                          'need it.\n'
                                                          '\n'
                                                          'When comfortable, try changing just one '
                                                          'variable: Change only the diagonal '
                                                          'direction in the chain without testing '
                                                          'defence against a real attack.\n'
                                                          '\n'
                                                          'Next practice: At the next suitable '
                                                          'session, recall the short sequence '
                                                          'without reading first. Briefly revisit '
                                                          'Compact cover; check only the confusing '
                                                          'part again.'},
                                       'selfChecks': [{'en': 'I did not punch while still falling '
                                                             'into the step.',
                                                       'tr': 'Adıma doğru düşerken yumruk '
                                                             'atmadım.'},
                                                      {'en': 'I understand this does not test '
                                                             'response to a real opponent.',
                                                       'tr': 'Bunun gerçek rakibe tepkiyi '
                                                             'sınamadığını biliyorum.'},
                                                      {'tr': 'Savunma şekli ile geri dönüş '
                                                             'arasında tabanımı kurabiliyor ve '
                                                             'bunun planlı prova olduğunu '
                                                             'biliyorum.',
                                                       'en': 'I can establish the base between the '
                                                             'defensive shape and return action '
                                                             'and understand this as planned '
                                                             'rehearsal.'}],
                                       'sourceIds': ['boxing_canada_competition',
                                                     'england_boxing_level1',
                                                     'boxing_canada_beginner',
                                                     'motor_spacing_primary']},
 'boxing.combinations.angle_exit': {'steps': [{'en': 'Choose either jab-cross or jab-jab-cross. '
                                                     'After the last hand returns, make one small '
                                                     'side step or pivot to an open line.',
                                               'tr': 'Jab-cross veya jab-jab-cross seç. Son el '
                                                     'döndükten sonra boş hatta küçük yan adım '
                                                     'veya pivot yap.'},
                                              {'en': 'Keep the exit separate at first. Count '
                                                     "'hands home, then feet' to avoid moving with "
                                                     'both hands away.',
                                               'tr': 'Önce çıkışı ayrı tut. İki el uzaktayken '
                                                     "hareket etmemek için 'eller yerinde, sonra "
                                                     "ayaklar' diye say."},
                                              {'tr': 'Kombinasyon bitmeden büyük pivotla '
                                                     'uzaklaşmaya çalışma. Elleri geri getir, '
                                                     'sonra küçük yan adım veya rahat dönüş seç.',
                                               'en': 'Do not try to leave through a large pivot '
                                                     'before finishing the combination. Return the '
                                                     'hands first, then choose a small side step '
                                                     'or comfortable turn.'}],
                                    'practice': {'tr': 'Beş kombinasyon yap; yan adım ve küçük '
                                                       'pivot çıkışını dönüşümlü kullan.\n'
                                                       '\n'
                                                       'Kısa odak çalışması: Bir-iki sonrası yan '
                                                       'çıkışı iki kez, ardından aynı dizi sonrası '
                                                       'küçük dönüş seçeneğini iki kez dene; rahat '
                                                       'olan yolu kendin seç. Bölümler arasında '
                                                       'dinlen; süreyi rahatlığına göre uzat.\n'
                                                       '\n'
                                                       'Rahat olduğunda tek değişken denemesi: Düz '
                                                       'dizi aynı kalsın, yan adım ile küçük dönüş '
                                                       'çıkışını sırayla seç.\n'
                                                       '\n'
                                                       'Sonraki pratik: Sonraki uygun oturumda '
                                                       'kısa uygulamanın sırasını önce yardımsız '
                                                       'hatırla. Yan adımlar dersini kısaca '
                                                       'hatırla; yalnız karışan kısmı yeniden '
                                                       'kontrol et.',
                                                 'en': 'Perform five combinations, alternating a '
                                                       'side-step and a modest pivot exit.\n'
                                                       '\n'
                                                       'Short focused practice: Try a side exit '
                                                       'after the one-two twice, then a small-turn '
                                                       'option after the same sequence twice, and '
                                                       'choose the comfortable path yourself. Rest '
                                                       'between sections; take longer if you need '
                                                       'it.\n'
                                                       '\n'
                                                       'When comfortable, try changing just one '
                                                       'variable: Keep the straight sequence the '
                                                       'same and alternate the side-step and '
                                                       'small-turn exits.\n'
                                                       '\n'
                                                       'Next practice: At the next suitable '
                                                       'session, recall the short sequence without '
                                                       'reading first. Briefly revisit Side steps; '
                                                       'check only the confusing part again.'},
                                    'selfChecks': [{'en': 'Both hands were back before my exit '
                                                          'began.',
                                                    'tr': 'Çıkış başlamadan iki elim dönmüştü.'},
                                                   {'en': 'The exit ended in a stance I could '
                                                          'continue from.',
                                                    'tr': 'Çıkış devam edebileceğim duruşta '
                                                          'bitti.'},
                                                   {'tr': 'Dizi, el dönüşü ve çıkışı sırayla '
                                                          'kurabiliyor; çıkış yolunu bilinçli '
                                                          'seçiyorum.',
                                                    'en': 'I can sequence the combination, hand '
                                                          'recovery and exit and choose the exit '
                                                          'path deliberately.'}],
                                    'sourceIds': ['boxing_canada_competition',
                                                  'england_boxing_level1',
                                                  'boxing_canada_beginner',
                                                  'motor_spacing_primary']},
 'boxing.rounds.short_round': {'steps': [{'en': 'Choose jab and guard return as the only theme. '
                                                'Work for up to one easy minute, pausing whenever '
                                                'the shape or breathing changes.',
                                          'tr': 'Tek tema olarak jab ve gard dönüşünü seç. Şekil '
                                                'veya nefes değişirse durarak en çok bir rahat '
                                                'dakika çalış.'},
                                         {'en': 'Rest and reflect on one cue only. A round is '
                                                'useful even when you stop early; quality does not '
                                                'require a fixed number of punches.',
                                          'tr': 'Dinlen ve yalnız bir ipucunu düşün. Erken dursan '
                                                'da raunt yararlıdır; kalite sabit yumruk sayısı '
                                                'gerektirmez.'},
                                         {'tr': 'Süreyi doldurmak için jab dönüşünü veya gardı '
                                                'bırakma. Durmak ve daha kısa bitirmek geçerlidir; '
                                                'bu raunt yalnız tek jab-dönüş odağı taşır.',
                                          'en': 'Do not abandon jab recovery or guard just to fill '
                                                'the time. Pausing or ending earlier is valid; '
                                                'this round has only one jab-return focus.'}],
                               'practice': {'tr': 'İsteğe bağlı duraklamalarla üst sınırı 60 '
                                                  'saniye olan tek raunt dene, sonra '
                                                  'tekrarlayabileceğin bir hareketi adlandır.\n'
                                                  '\n'
                                                  'Kısa odak çalışması: Önce en çok 20 saniyelik '
                                                  'kısa bölüm seç; dinlen ve istersen aynı odakla '
                                                  'ikinci kısa bölüm yap. Mevcut 60 saniye bir '
                                                  'tavan, tamamlama hedefi değildir. Bölümler '
                                                  'arasında dinlen; süreyi rahatlığına göre uzat.\n'
                                                  '\n'
                                                  'Rahat olduğunda tek değişken denemesi: Sonraki '
                                                  'kısa bölümün tek odağını jab düz yolu yerine '
                                                  'jab dönüşü olarak seç.\n'
                                                  '\n'
                                                  'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                  'uygulamanın sırasını önce yardımsız hatırla. '
                                                  'Jab geri döner dersini kısaca hatırla; yalnız '
                                                  'karışan kısmı yeniden kontrol et.',
                                            'en': 'Try one 60-second ceiling round with optional '
                                                  'pauses, then name one action you could repeat.\n'
                                                  '\n'
                                                  'Short focused practice: Choose a short section '
                                                  'of at most 20 seconds first, rest and '
                                                  'optionally try another with the same focus. The '
                                                  'existing 60 seconds is a ceiling, not a '
                                                  'completion target. Rest between sections; take '
                                                  'longer if you need it.\n'
                                                  '\n'
                                                  'When comfortable, try changing just one '
                                                  'variable: Choose jab recovery rather than the '
                                                  "straight path as the next short section's "
                                                  'single focus.\n'
                                                  '\n'
                                                  'Next practice: At the next suitable session, '
                                                  'recall the short sequence without reading '
                                                  'first. Briefly revisit The jab comes home; '
                                                  'check only the confusing part again.'},
                               'selfChecks': [{'en': 'I kept the chosen theme clear instead of '
                                                     'adding extra techniques.',
                                               'tr': 'Ek teknik eklemek yerine seçilen temayı açık '
                                                     'tuttum.'},
                                              {'en': 'I took a pause when breathing or control '
                                                     'asked for it.',
                                               'tr': 'Nefes veya kontrol gerektirdiğinde ara '
                                                     'verdim.'},
                                              {'tr': 'Raunt boyunca seçtiğim jab-dönüş odağını '
                                                     'hatırlıyor, bozulduğunda durabiliyorum.',
                                               'en': 'I can remember the chosen jab-return focus '
                                                     'through the round and stop when it becomes '
                                                     'confused.'}],
                               'sourceIds': ['england_boxing_level1',
                                             'cdc_activity',
                                             'boxing_canada_beginner',
                                             'motor_spacing_primary']},
 'boxing.rounds.footwork_round': {'steps': [{'en': 'Choose forward, back, side, reset as a '
                                                   'four-part loop. Keep hands in guard and use no '
                                                   'punches for this round.',
                                             'tr': 'Dört parçalı döngü seç: ileri, geri, yan, '
                                                   'yerleş. Eller gardda kalsın; bu rauntta yumruk '
                                                   'yok.'},
                                            {'en': 'Move slowly enough to stop after any step. '
                                                   'Change direction only after the base is '
                                                   'restored.',
                                             'tr': 'Her adımda durabilecek kadar yavaş git. Yönü '
                                                   'ancak taban yeniden kurulduktan sonra '
                                                   'değiştir.'},
                                            {'tr': 'Hareket rauntuna yumruk veya sürekli aynı yöne '
                                                   'dönme eklemek odağı değiştirir. İleri-geri ve '
                                                   'yana küçük yolları planlayıp her bölümde '
                                                   'tabanı kontrol et.',
                                             'en': 'Adding punches or constantly circling one way '
                                                   'changes the movement-round focus. Plan small '
                                                   'forward-back and side paths and check the base '
                                                   'in each section.'}],
                                  'practice': {'tr': 'Döngüyü en çok bir dakika tekrarla, sonra '
                                                     'durup açıklığın nerede kaydığını not et.\n'
                                                     '\n'
                                                     'Kısa odak çalışması: Bir ileri-geri çift ile '
                                                     'bir yan çift seç; en çok 20 saniyelik '
                                                     'bölümde yalnız bu yolları kullan. Dinlenip '
                                                     'yol sırasını hatırla; devam etmek isteğe '
                                                     'bağlıdır. Bölümler arasında dinlen; süreyi '
                                                     'rahatlığına göre uzat.\n'
                                                     '\n'
                                                     'Rahat olduğunda tek değişken denemesi: '
                                                     'Sonraki kısa bölümde aynı ayak yollarının '
                                                     'sırasını değiştir.\n'
                                                     '\n'
                                                     'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                     'uygulamanın sırasını önce yardımsız hatırla. '
                                                     'İleri ve geri dersini kısaca hatırla; yalnız '
                                                     'karışan kısmı yeniden kontrol et.',
                                               'en': 'Repeat the loop for up to one minute, then '
                                                     'pause and note where spacing drifted.\n'
                                                     '\n'
                                                     'Short focused practice: Choose a '
                                                     'forward-back pair and a side pair and use '
                                                     'only those paths for a section of at most 20 '
                                                     'seconds. Rest and recall the path order; '
                                                     'continuing is optional. Rest between '
                                                     'sections; take longer if you need it.\n'
                                                     '\n'
                                                     'When comfortable, try changing just one '
                                                     "variable: Swap the same foot paths' order in "
                                                     'the next short section.\n'
                                                     '\n'
                                                     'Next practice: At the next suitable session, '
                                                     'recall the short sequence without reading '
                                                     'first. Briefly revisit Forward and back; '
                                                     'check only the confusing part again.'},
                                  'selfChecks': [{'en': 'I could stop balanced after every '
                                                        'segment.',
                                                  'tr': 'Her bölümden sonra dengede durabildim.'},
                                                 {'en': 'I noticed and corrected foot spacing '
                                                        'before moving again.',
                                                  'tr': 'Yeniden hareket etmeden ayak açıklığını '
                                                        'fark edip düzelttim.'},
                                                 {'tr': 'Ayak yollarını yumruk eklemeden '
                                                        'değiştirebiliyor, her geçişte duruş '
                                                        'açıklığını korumaya dikkat ediyorum.',
                                                  'en': 'I can change foot paths without adding '
                                                        'punches and attend to stance spacing at '
                                                        'each transition.'}],
                                  'sourceIds': ['boxing_canada_beginner',
                                                'england_boxing_level1',
                                                'motor_spacing_primary']},
 'boxing.rounds.imagined_target': {'steps': [{'en': 'Pick a point in empty air within comfortable '
                                                    'reach. Use a jab, rear straight and pause in '
                                                    'guard while keeping eyes on the same point.',
                                              'tr': 'Rahat erişimde havada bir nokta seç. Aynı '
                                                    'noktaya bakarken jab, arka düz ve gard duruşu '
                                                    'yap.'},
                                             {'en': 'If you would need to lean, take a small step '
                                                    'first and reset. Accuracy here is your own '
                                                    'path check, not a camera-measured hit.',
                                              'tr': 'Eğilmen gerekecekse önce küçük adım atıp '
                                                    'yerleş. Buradaki isabet kendi yol '
                                                    'kontrolündür; kameranın ölçtüğü vuruş değil.'},
                                             {'tr': 'Hayalî hedefi takip ederken uzağa eğilme veya '
                                                    'gerçek nesneye vurma. Rahat erişim içinde bir '
                                                    'nokta seç; nokta değişince yeniden tabanı '
                                                    'kur.',
                                              'en': 'Do not lean far or strike an object while '
                                                    'following an imagined target. Choose a point '
                                                    'within comfortable reach and reset the base '
                                                    'when it changes.'}],
                                   'practice': {'tr': 'Tek hedefte en çok 45 saniye çalış, sonra '
                                                      'ikinci kısa set için başka rahat boş nokta '
                                                      'seç.\n'
                                                      '\n'
                                                      'Kısa odak çalışması: Bir hayalî noktaya üç '
                                                      'yavaş düz yol seç, dur ve ikinci rahat '
                                                      'noktayı belirle. Yeni nokta için üç yavaş '
                                                      'yol daha isteğe bağlıdır. Bölümler arasında '
                                                      'dinlen; süreyi rahatlığına göre uzat.\n'
                                                      '\n'
                                                      'Rahat olduğunda tek değişken denemesi: '
                                                      'İkinci rahat noktayı farklı bir erişim '
                                                      'yönünde seç ve tabanı yeniden kur.\n'
                                                      '\n'
                                                      'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                      'uygulamanın sırasını önce yardımsız '
                                                      'hatırla. Mesafeye gir ve çık dersini kısaca '
                                                      'hatırla; yalnız karışan kısmı yeniden '
                                                      'kontrol et.',
                                                'en': 'Work up to 45 seconds on one target, then '
                                                      'change to another comfortable empty point '
                                                      'for a second short set.\n'
                                                      '\n'
                                                      'Short focused practice: Choose three slow '
                                                      'straight paths toward one imagined point, '
                                                      'stop and name a second comfortable point. '
                                                      'Three more toward the new point are '
                                                      'optional. Rest between sections; take '
                                                      'longer if you need it.\n'
                                                      '\n'
                                                      'When comfortable, try changing just one '
                                                      'variable: Choose the second comfortable '
                                                      'point along a different reach direction and '
                                                      'rebuild the base.\n'
                                                      '\n'
                                                      'Next practice: At the next suitable '
                                                      'session, recall the short sequence without '
                                                      'reading first. Briefly revisit Enter and '
                                                      'leave range; check only the confusing part '
                                                      'again.'},
                                   'selfChecks': [{'en': 'I did not lengthen my reach by leaning.',
                                                   'tr': 'Eğilerek erişimimi uzatmadım.'},
                                                  {'en': 'I could return to guard and see the '
                                                         'imagined point again.',
                                                   'tr': 'Garda dönüp hayalî noktayı yeniden '
                                                         'görebildim.'},
                                                  {'tr': 'Hayalî noktayı seçiyor ve nokta '
                                                         'değişiminde erişimimi rahatça '
                                                         'ayarlayabiliyorum.',
                                                   'en': 'I can choose an imagined point and '
                                                         'adjust the reach comfortably when it '
                                                         'changes.'}],
                                   'sourceIds': ['boxing_canada_beginner',
                                                 'england_boxing_level1',
                                                 'motor_spacing_primary']},
 'boxing.rounds.pace': {'steps': [{'en': 'Begin with a few very easy jab-return cycles, then use a '
                                         'slightly quicker but still controlled rhythm for a short '
                                         'block.',
                                   'tr': 'Birkaç çok rahat jab-dönüş döngüsüyle başla, sonra kısa '
                                         'bölümde biraz daha hızlı ama kontrollü ritim kullan.'},
                                  {'en': 'Return to easy pace before fatigue changes guard or '
                                         'breathing. These are subjective rhythms; the app does '
                                         'not measure punch speed.',
                                   'tr': 'Yorgunluk gardı veya nefesi değiştirmeden kolay tempoya '
                                         'dön. Bunlar öznel ritimlerdir; uygulama yumruk hızını '
                                         'ölçmez.'},
                                  {'tr': 'Daha hızlı bölümde yollar bozuluyorsa süreyi kovalamak '
                                         'yerine önceki kolay tempoya dön. Burada hızın değeri '
                                         'sayısal ölçülmüyor; seçim ve toparlanma önemlidir.',
                                   'en': 'Return to the earlier easy pace when paths become '
                                         'confused in the faster section instead of chasing the '
                                         'duration. Speed is not measured numerically here; '
                                         'choosing and recovering matter.'}],
                        'practice': {'tr': 'Üç kez 20 saniye kolay, en çok 10 saniye orta tempo ve '
                                           'gerektiği kadar dinlenme yap.\n'
                                           '\n'
                                           'Kısa odak çalışması: Önce 20 saniyeye kadar kolay '
                                           'bölüm yap; yalnız rahat hissediyorsan 10 saniyeye '
                                           'kadar daha canlı bölüm seç. Durup rahatlığı kontrol '
                                           'et; üç döngüyü tamamlamak zorunda değilsin. Bölümler '
                                           'arasında dinlen; süreyi rahatlığına göre uzat.\n'
                                           '\n'
                                           'Rahat olduğunda tek değişken denemesi: Aynı '
                                           'kolay-canlı-kolay fikrini daha kısa bir bölümde dene; '
                                           'süreyi tamamlamak zorunlu değildir.\n'
                                           '\n'
                                           'Sonraki pratik: Sonraki uygun oturumda kısa '
                                           'uygulamanın sırasını önce yardımsız hatırla. Nefes ve '
                                           'rahat tempo dersini kısaca hatırla; yalnız karışan '
                                           'kısmı yeniden kontrol et.',
                                     'en': 'Do three cycles of 20 seconds easy, up to 10 seconds '
                                           'moderate, then rest as needed.\n'
                                           '\n'
                                           'Short focused practice: Use an easy section of up to '
                                           '20 seconds first and choose a livelier section of up '
                                           'to 10 seconds only if comfortable. Stop and check '
                                           'comfort; completing three cycles is optional. Rest '
                                           'between sections; take longer if you need it.\n'
                                           '\n'
                                           'When comfortable, try changing just one variable: Try '
                                           'the same easy-livelier-easy idea over a shorter '
                                           'section; filling the duration is optional.\n'
                                           '\n'
                                           'Next practice: At the next suitable session, recall '
                                           'the short sequence without reading first. Briefly '
                                           'revisit Breath and easy pace; check only the confusing '
                                           'part again.'},
                        'selfChecks': [{'en': 'I could name the moment control began to fade and '
                                              'slow down.',
                                        'tr': 'Kontrolün azalmaya başladığı anı fark edip '
                                              'yavaşlayabildim.'},
                                       {'en': 'The hand still returned fully in both rhythms.',
                                        'tr': 'İki ritimde de el tamamen döndü.'},
                                       {'tr': 'Daha canlı ve kolay tempoyu bilinçli ayırabiliyor, '
                                              'rahatlık veya yol kaybolunca yavaşlıyorum.',
                                        'en': 'I can deliberately distinguish livelier and easier '
                                              'paces and slow down when comfort or the path is '
                                              'lost.'}],
                        'sourceIds': ['england_boxing_level1',
                                      'cdc_activity',
                                      'boxing_canada_beginner',
                                      'motor_spacing_primary']},
 'boxing.rounds.personal_plan': {'steps': [{'en': 'Choose one footwork pattern, one straight-punch '
                                                  'pattern and one planned exit. Put them in an '
                                                  'order you can explain aloud.',
                                            'tr': 'Bir ayak örüntüsü, bir düz yumruk örüntüsü ve '
                                                  'bir planlı çıkış seç. Sesli anlatabileceğin '
                                                  'sıraya koy.'},
                                           {'en': 'Pick a short time ceiling and a rest option. A '
                                                  'changed plan after symptoms or fatigue is good '
                                                  'judgement, not failure.',
                                            'tr': 'Kısa süre üst sınırı ve dinlenme seçeneği '
                                                  'belirle. Belirti veya yorgunlukta planı '
                                                  'değiştirmek başarısızlık değil, iyi karardır.'},
                                           {'tr': 'Kişisel planı bildiğin bütün kombinasyonları '
                                                  'sığdırma listesine çevirme. Bir ayak yolu, bir '
                                                  'düz dizi ve bir planlı çıkış seç; dinlenme '
                                                  'yerini de önceden belirle.',
                                            'en': 'Do not make the personal plan a list of every '
                                                  'combination you know. Choose one foot path, one '
                                                  'straight sequence and one planned exit, '
                                                  'including a rest point beforehand.'}],
                                 'practice': {'tr': 'Üç parçalı planı yaz veya söyle, bir rahat '
                                                    'raunt çalış, sonra gelecek sefere '
                                                    'tekrarlanacak bir parçayı not et.\n'
                                                    '\n'
                                                    'Kısa odak çalışması: Üç parçayı sözle planla; '
                                                    'her parçayı ayrı bir kez prova et. Dinlenme '
                                                    'sonrası istersen kısa süre tavanınla bağla ve '
                                                    'yalnız bir düzeltme noktası seç. Bölümler '
                                                    'arasında dinlen; süreyi rahatlığına göre '
                                                    'uzat.\n'
                                                    '\n'
                                                    'Rahat olduğunda tek değişken denemesi: Planın '
                                                    'yalnız çıkış yolunu değiştir ve geri kalan iki '
                                                    'parçayı hatırla.\n'
                                                    '\n'
                                                    'Sonraki pratik: Sonraki uygun oturumda kısa '
                                                    'uygulamanın sırasını önce yardımsız hatırla. '
                                                    'İleri ve geri dersini kısaca hatırla; yalnız '
                                                    'karışan kısmı yeniden kontrol et.',
                                              'en': 'Write or say a three-part plan, practise one '
                                                    'easy round, then note one part to repeat next '
                                                    'time.\n'
                                                    '\n'
                                                    'Short focused practice: Plan the three '
                                                    'sections aloud and rehearse each once '
                                                    'separately. After resting, optionally connect '
                                                    'them within your short time ceiling and '
                                                    'choose only one correction point. Rest '
                                                    'between sections; take longer if you need '
                                                    'it.\n'
                                                    '\n'
                                                    'When comfortable, try changing just one '
                                                    'variable: Change only the exit path and '
                                                    'recall the remainder of the three-section '
                                                    'plan.\n'
                                                    '\n'
                                                    'Next practice: At the next suitable session, '
                                                    'recall the short sequence without reading '
                                                    'first. Briefly revisit Forward and back; '
                                                    'check only the confusing part again.'},
                                 'selfChecks': [{'en': "I could explain each action's place in the "
                                                       'sequence.',
                                                 'tr': 'Dizide her hareketin yerini '
                                                       'açıklayabildim.'},
                                                {'en': 'My plan allowed rest and a safe early '
                                                       'stop.',
                                                 'tr': 'Planım dinlenmeye ve güvenli erken '
                                                       'bitirmeye izin verdi.'},
                                                {'tr': 'Planımın üç bölümünü, dinlenme seçeneğini '
                                                       've bir tekrar hedefini açıklayabiliyorum.',
                                                 'en': 'I can explain the three sections, rest '
                                                       'option and one review target in my plan.'}],
                                 'sourceIds': ['england_boxing_level1',
                                               'cdc_activity',
                                               'boxing_canada_beginner',
                                               'motor_spacing_primary']},
 'boxing.integration.skill_review': {'steps': [{'en': 'In order, rebuild stance and guard, move '
                                                      'forward and back, jab and return, rear '
                                                      'straight and return, then make one small '
                                                      'planned exit.',
                                                'tr': 'Sırayla duruş ve gardı kur, ileri-geri '
                                                      'hareket et, jab ve dönüş, arka düz ve dönüş '
                                                      'yap, sonra küçük planlı çıkış yap.'},
                                               {'en': 'Add a compact hook or uppercut only if its '
                                                      'separate lesson felt comfortable. Mark '
                                                      'anything uncertain for repeat rather than '
                                                      'hiding it in a fast sequence.',
                                                'tr': 'Küçük kroşe veya aparkatı yalnız ayrı dersi '
                                                      'rahat geldiyse ekle. Belirsiz parçayı hızlı '
                                                      'dizide gizlemek yerine tekrar için '
                                                      'işaretle.'},
                                               {'tr': 'Bütün zinciri bir seferde hızlandırmak '
                                                      'eksik bağlantıyı gizleyebilir. Duruş-gard, '
                                                      'ayak, düz yollar ve çıkışı ayrı kontrol et; '
                                                      'zor bağlantıyı küçült.',
                                                'en': 'Speeding up the whole chain can hide a '
                                                      'missing connection. Check stance-guard, '
                                                      'feet, straight paths and exit separately, '
                                                      'reducing the difficult connection.'}],
                                     'practice': {'tr': 'Hareket adlarını söyleyip her birinden '
                                                        'sonra gardda durarak zinciri üç kez geç.\n'
                                                        '\n'
                                                        'Kısa odak çalışması: Bir zinciri duraklı '
                                                        'yap; ardından metne bakmadan sırasını '
                                                        'anlat. İkinci denemede yalnız en zor '
                                                        'bağlantıyı, üçüncüde rahatça bütün '
                                                        'zinciri seç. Bölümler arasında dinlen; '
                                                        'süreyi rahatlığına göre uzat.\n'
                                                        '\n'
                                                        'Rahat olduğunda tek değişken denemesi: '
                                                        'Bir zincirdeki tek bağlantıyı değiştir; '
                                                        'daha önce rahat olan bölümleri koru.\n'
                                                        '\n'
                                                        'Sonraki pratik: Sonraki uygun oturumda '
                                                        'kısa uygulamanın sırasını önce yardımsız '
                                                        'hatırla. Tabanına geri dön dersini kısaca '
                                                        'hatırla; yalnız karışan kısmı yeniden '
                                                        'kontrol et.',
                                                  'en': 'Walk through the chain three times, '
                                                        'speaking the action names and pausing at '
                                                        'guard after each.\n'
                                                        '\n'
                                                        'Short focused practice: Pause through one '
                                                        'chain and describe its order without '
                                                        'reading. Choose only the hardest '
                                                        'connection for a second attempt and the '
                                                        'whole comfortable chain for a third. Rest '
                                                        'between sections; take longer if you need '
                                                        'it.\n'
                                                        '\n'
                                                        'When comfortable, try changing just one '
                                                        'variable: Change just one connection in a '
                                                        'chain and retain the sections that were '
                                                        'already comfortable.\n'
                                                        '\n'
                                                        'Next practice: At the next suitable '
                                                        'session, recall the short sequence '
                                                        'without reading first. Briefly revisit '
                                                        'Return to your base; check only the '
                                                        'confusing part again.'},
                                     'selfChecks': [{'en': 'I could name one strength and one '
                                                           'movement to practise again.',
                                                     'tr': 'Bir güçlü yönümü ve tekrar çalışacağım '
                                                           'bir hareketi adlandırabildim.'},
                                                    {'en': 'I did not use speed to cover a missing '
                                                           'return or unstable step.',
                                                     'tr': 'Eksik dönüşü veya dengesiz adımı '
                                                           'örtmek için hıza başvurmadım.'},
                                                    {'tr': 'Zincirin bölümlerini ve geliştireceğim '
                                                           'bağlantıyı adlandırabiliyorum; temas '
                                                           'veya ustalık sonucu çıkarmıyorum.',
                                                     'en': "I can name the chain's sections and "
                                                           'one connection to improve without '
                                                           'inferring contact competence or '
                                                           'mastery.'}],
                                     'sourceIds': ['boxing_canada_beginner',
                                                   'boxing_canada_competition',
                                                   'england_boxing_level1',
                                                   'motor_spacing_primary']},
 'boxing.integration.two_round_rehearsal': {'steps': [{'en': 'Round one: simple footwork and two '
                                                             'straight punches. Rest as long as '
                                                             'needed. Round two: the same base '
                                                             'with one optional curved punch or '
                                                             'planned exit.',
                                                       'tr': 'Birinci raunt: basit ayak çalışması '
                                                             've iki düz yumruk. Gerektiği kadar '
                                                             'dinlen. İkinci raunt: aynı tabanla '
                                                             'isteğe bağlı bir kavisli yumruk veya '
                                                             'planlı çıkış.'},
                                                      {'en': 'Keep each work window short enough '
                                                             'to preserve control. Change or omit '
                                                             'the optional element when quality '
                                                             'falls; there is no fixed output '
                                                             'target.',
                                                       'tr': 'Her çalışma aralığını kontrolü '
                                                             'koruyacak kadar kısa tut. Kalite '
                                                             'düşerse isteğe bağlı parçayı '
                                                             'değiştir veya çıkar; sabit çıktı '
                                                             'hedefi yok.'},
                                                      {'tr': 'İkinci raunt ilkinden uzun veya daha '
                                                             'hızlı olmak zorunda değildir. İlk '
                                                             'denemeden yalnız bir hedef seç, '
                                                             'yeterince dinlen ve aynı kısa sınırı '
                                                             'veya daha küçüğünü kullan.',
                                                       'en': 'The second round need not be longer '
                                                             'or faster than the first. Choose '
                                                             'only one target from the first, rest '
                                                             'adequately and use the same short '
                                                             'ceiling or a smaller one.'}],
                                            'practice': {'tr': 'Aralarında acele etmeden '
                                                               'dinlenerek en çok birer dakikalık '
                                                               'iki rahat raunt dene; hissettiğin '
                                                               'bir farkı not et.\n'
                                                               '\n'
                                                               'Kısa odak çalışması: İlk raunt '
                                                               'için bir düz dizi ve çıkış seç; en '
                                                               'çok bir dakika tavanında erken '
                                                               'bitirebilirsin. Dinlenme sonrası '
                                                               'ikinci raunt isteğe bağlıdır ve '
                                                               'tek geliştirme noktasını tekrar '
                                                               'eder. Bölümler arasında dinlen; '
                                                               'süreyi rahatlığına göre uzat.\n'
                                                               '\n'
                                                               'Rahat olduğunda tek değişken '
                                                               'denemesi: İkinci prova için aynı '
                                                               'süre tavanını koruyup yalnız bir '
                                                               'çıkış yönünü değiştir.\n'
                                                               '\n'
                                                               'Sonraki pratik: Sonraki uygun '
                                                               'oturumda kısa uygulamanın sırasını '
                                                               'önce yardımsız hatırla. Kendi kısa '
                                                               'rauntunu planla dersini kısaca '
                                                               'hatırla; yalnız karışan kısmı '
                                                               'yeniden kontrol et.',
                                                         'en': 'Try two easy rounds of up to one '
                                                               'minute each with an unhurried rest '
                                                               'between; note one difference you '
                                                               'felt.\n'
                                                               '\n'
                                                               'Short focused practice: Choose one '
                                                               'straight sequence and exit for the '
                                                               'first round, with permission to '
                                                               'finish before the one-minute '
                                                               'ceiling. A second round after rest '
                                                               'is optional and revisits only one '
                                                               'improvement. Rest between '
                                                               'sections; take longer if you need '
                                                               'it.\n'
                                                               '\n'
                                                               'When comfortable, try changing '
                                                               'just one variable: Keep the same '
                                                               'time ceiling for the second '
                                                               'rehearsal and change only one exit '
                                                               'direction.\n'
                                                               '\n'
                                                               'Next practice: At the next '
                                                               'suitable session, recall the short '
                                                               'sequence without reading first. '
                                                               'Briefly revisit Plan your own '
                                                               'short round; check only the '
                                                               'confusing part again.'},
                                            'selfChecks': [{'en': 'In each round I tried, my hands '
                                                                  'and feet returned to a usable '
                                                                  'base; if I chose one round, I '
                                                                  'do not claim a second.',
                                                            'tr': 'Denediğim her rauntta ellerim '
                                                                  've ayaklarım kullanılabilir '
                                                                  'tabana döndü; tek raunt '
                                                                  'seçtiysem ikinciyi yapılmış '
                                                                  'saymıyorum.'},
                                                           {'en': 'If I tried a second round, I '
                                                                  'adapted it from the first; if '
                                                                  'I stopped after one, I noted '
                                                                  'why instead of forcing a '
                                                                  'preset workload.',
                                                            'tr': 'İkinci rauntu denediysem ilkine '
                                                                  'göre uyarladım; tek rauntta '
                                                                  'durduysam önceden belirlenmiş '
                                                                  'yükü zorlamadan nedenini not '
                                                                  'ettim.'},
                                                           {'tr': 'İki raunt denediysem arada '
                                                                  'dinlenip ikinciyi ilkinden '
                                                                  'bir hedefle planladım; tek '
                                                                  'rauntta kaldıysam sonraki '
                                                                  'denemem için hedefi not ettim.',
                                                            'en': 'If I tried two rounds, I rested '
                                                                  'between them and planned the '
                                                                  'second around one target; if '
                                                                  'I did one, I noted a target '
                                                                  'for next time.'}],
                                            'sourceIds': ['england_boxing_level1',
                                                          'cdc_activity',
                                                          'boxing_canada_beginner',
                                                          'motor_spacing_primary']},
 'boxing.integration.independent_round': {'steps': [{'en': 'Write a short plan: stance and '
                                                           'footwork, a straight combination, a '
                                                           'controlled curved shape if '
                                                           'comfortable, and a planned exit. '
                                                           'Identify a rest and stop option before '
                                                           'beginning.',
                                                     'tr': 'Kısa plan yaz: duruş ve adım, düz '
                                                           'kombinasyon, rahatsa kontrollü kavisli '
                                                           'şekil ve planlı çıkış. Başlamadan '
                                                           'dinlenme ve durma seçeneğini belirle.'},
                                                    {'en': 'Work one self-chosen easy round, then '
                                                           'reflect on balance, guard recovery and '
                                                           'breathing. Record what you practised '
                                                           'and what to revisit; the app cannot '
                                                           'certify boxing skill.',
                                                     'tr': 'Kendi seçtiğin bir rahat raunt çalış, '
                                                           'sonra dengeyi, gard dönüşünü ve nefesi '
                                                           'değerlendir. Çalıştığını ve yeniden '
                                                           'bakacağını kaydet; uygulama boks '
                                                           'becerisini belgelendiremez.'},
                                                    {'tr': 'Bağımsız raunt kurmak eşli savunma, '
                                                           'darbe güvenliği veya profesyonel boks '
                                                           'yeterliği anlamına gelmez. Bildiğin '
                                                           'solo yolları seç, sınırlarını ve '
                                                           'sonraki eğitmen hedefini adlandır.',
                                                     'en': 'Building an independent round does not '
                                                           'establish partner defence, impact '
                                                           'safety or professional boxing '
                                                           'competence. Choose familiar solo paths '
                                                           'and name the limits and a future '
                                                           'coaching goal.'}],
                                          'practice': {'tr': 'Rahat sürede bir raunt yap; ardından '
                                                             'iki güçlü yön ve bir sonraki çalışma '
                                                             'hedefini sözlü veya yazılı gözden '
                                                             'geçir.\n'
                                                             '\n'
                                                             'Kısa odak çalışması: Ayak yolu-düz '
                                                             'dizi-isteğe bağlı kısa eğri '
                                                             'yol-çıkış-dinlenme için kendi kısa '
                                                             'planını kur. Bir rahat deneme '
                                                             'sonrası iki güçlü nokta ve bir '
                                                             'tekrar hedefini söyle; her yumruk '
                                                             'türünü eklemek zorunda değilsin. '
                                                             'Bölümler arasında dinlen; süreyi '
                                                             'rahatlığına göre uzat.\n'
                                                             '\n'
                                                             'Rahat olduğunda tek değişken '
                                                             'denemesi: Sonraki gün planın yalnız '
                                                             'bir geliştirme hedefini yeniden seç; '
                                                             'yeni hareket eklemek zorunlu '
                                                             'değildir.\n'
                                                             '\n'
                                                             'Sonraki pratik: Sonraki uygun '
                                                             'oturumda kısa uygulamanın sırasını '
                                                             'önce yardımsız hatırla. Ön kroşe '
                                                             'şekli dersini kısaca hatırla; yalnız '
                                                             'karışan kısmı yeniden kontrol et.',
                                                       'en': 'Complete one round of a comfortable '
                                                             'length, followed by a spoken or '
                                                             'written review of two strengths and '
                                                             'one next practice goal.\n'
                                                             '\n'
                                                             'Short focused practice: Build a '
                                                             'short '
                                                             'foot-path/straight-sequence/optional-small-curved-path/exit/rest '
                                                             'plan. After one comfortable attempt '
                                                             'name two strengths and one review '
                                                             'target; including every punch type '
                                                             'is optional. Rest between sections; '
                                                             'take longer if you need it.\n'
                                                             '\n'
                                                             'When comfortable, try changing just '
                                                             'one variable: Revisit only one '
                                                             'improvement target in the plan the '
                                                             'next day; adding a new movement is '
                                                             'optional.\n'
                                                             '\n'
                                                             'Next practice: At the next suitable '
                                                             'session, recall the short sequence '
                                                             'without reading first. Briefly '
                                                             'revisit Lead hook shape; check only '
                                                             'the confusing part again.'},
                                          'selfChecks': [{'en': 'I chose the sequence and could '
                                                                'explain why each part was '
                                                                'included.',
                                                          'tr': 'Diziyi ben seçtim ve her parçanın '
                                                                'neden bulunduğunu '
                                                                'açıklayabildim.'},
                                                         {'en': 'I stopped, rested or adapted when '
                                                                'needed and named a realistic next '
                                                                'goal.',
                                                          'tr': 'Gerektiğinde durup dinlendim veya '
                                                                'uyarladım ve gerçekçi bir sonraki '
                                                                'hedef belirledim.'},
                                                         {'tr': 'Kendi solo planımı, '
                                                                'durma-dinlenme seçeneğini ve '
                                                                'kursun dışındaki eğitmen '
                                                                'ihtiyacını açıklayabiliyorum.',
                                                          'en': 'I can explain my own solo plan, '
                                                                'stop-rest option and coaching '
                                                                'needs beyond the course.'}],
                                          'sourceIds': ['boxing_canada_beginner',
                                                        'boxing_canada_competition',
                                                        'england_boxing_level1',
                                                        'cdc_activity',
                                                        'acog_pregnancy',
                                                        'motor_spacing_primary']}}
# Late-course physical lessons are reusable solo-session plans. Keep their
# entry and exit sequence explicit whenever a learner returns on another day.
for session_lesson_id in (
    "boxing.rounds.short_round",
    "boxing.rounds.footwork_round",
    "boxing.rounds.imagined_target",
    "boxing.rounds.pace",
    "boxing.rounds.personal_plan",
    "boxing.integration.skill_review",
    "boxing.integration.two_round_rehearsal",
    "boxing.integration.independent_round",
):
    session_steps = lesson_enrichments[session_lesson_id]["steps"]
    if session_lesson_id == "boxing.rounds.footwork_round":
        session_start = L(
            "At every new solo session, recheck the clear, stable space. Start with easy general movement, then rehearse familiar stance, small steps and guard returns without punches; build gradually only while breathing and control stay comfortable.",
            "Her yeni solo oturumda açık, sağlam alanı yeniden kontrol et. Rahat genel hareketlerle başla; sonra bildiğin duruşu, küçük adımları ve yumruksuz gard dönüşlerini prova et. Nefes ve kontrol rahat kaldıkça kademeli ilerle.",
        )
    else:
        session_start = L(
            "At every new solo session, recheck the clear, stable space. Start with easy general movement, then rehearse familiar stance, small steps and light jab-and-guard returns; build gradually only while breathing and control stay comfortable.",
            "Her yeni solo oturumda açık, sağlam alanı yeniden kontrol et. Rahat genel hareketlerle başla; sonra bildiğin duruşu, küçük adımları ve hafif jab-gard dönüşlerini prova et. Nefes ve kontrol rahat kaldıkça kademeli ilerle.",
        )
    lesson_enrichments[session_lesson_id]["steps"] = [
        session_start,
        *session_steps,
        L(
            "When the planned work ends comfortably, lower the pace with familiar slow steps and easy breathing before resting and noting one observation. If a stop signal appears, stop immediately instead of tapering.",
            "Planlı çalışma rahatça bittiğinde, dinlenip tek gözlemini kaydetmeden önce bildiğin yavaş adımlarla ve rahat nefesle tempoyu düşür. Bir durma belirtisi çıkarsa hafif bitiş yapmadan hemen dur.",
        ),
    ]

for course_module in course["modules"]:
    for course_lesson in course_module["lessons"]:
        course_lesson.update(lesson_enrichments[course_lesson["id"]])


def main() -> None:
    target = Path(__file__).resolve().parents[1] / "assets/content/solo_boxing_course.v1.json"
    rendered = json.dumps(course, ensure_ascii=False, indent=2) + "\n"
    if "--check" in sys.argv:
        if not target.exists() or target.read_text(encoding="utf-8") != rendered:
            raise SystemExit("Solo boxing JSON is out of date; regenerate it")
        return
    target.write_text(rendered, encoding="utf-8")
    print(f"Wrote {target} with {sum(len(m['lessons']) for m in modules)} lessons")


if __name__ == "__main__":
    main()
