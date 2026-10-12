// Authored reading/recall activities derived from the source references below.
// These do not promote physical instruction, media rights, scoring or mastery.
final class StudyText {
  const StudyText(this.en, this.tr);
  final String en, tr;
}

final class RecallLesson {
  const RecallLesson({
    required this.id,
    required this.title,
    required this.teaching,
    required this.question,
    required this.answer,
  });
  final String id;
  final StudyText title, teaching, question, answer;
}

final class StudyArea {
  const StudyArea({
    required this.id,
    required this.title,
    required this.boundary,
    required this.sourceRefs,
    required this.lessons,
  });
  final String id;
  final StudyText title, boundary;
  final List<String> sourceRefs;
  final List<RecallLesson> lessons;
}

const List<StudyArea> studyAreas = <StudyArea>[
  StudyArea(
    id: "boxing",
    title: StudyText("Solo boxing", "Solo boks"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "assets/content/solo_boxing_course.v1.json#boxing.footwork.forward_back",
      "assets/content/solo_boxing_course.v1.json#boxing.start.space",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "boxing.1",
        title: StudyText("Foot order and spacing", "Ayak sırası ve aralık"),
        teaching: StudyText(
          "Small forward/back steps restore a usable stance after each move. Crossing the feet or narrowing the stance changes the base. This solo learning path excludes contact and sparring.",
          "Küçük ileri/geri adımlar her hareketten sonra kullanılabilir duruşa döner. Ayakları çaprazlamak veya duruşu daraltmak tabanı değiştirir. Bu solo yol temas ve sparring içermez.",
        ),
        question: StudyText(
          "What two features should a paper footwork plan keep separate from punching speed?",
          "Kâğıttaki ayak planında hangi iki özellik yumruk hızından ayrı tutulmalı?",
        ),
        answer: StudyText(
          "Foot order and the returned stance spacing. A faster punch does not verify either; describe an unknown base as unknown.",
          "Ayak sırası ve geri kurulan duruş aralığı. Hızlı yumruk ikisini de doğrulamaz; bilinmeyen tabanı bilinmiyor diye yaz.",
        ),
      ),
      RecallLesson(
        id: "boxing.2",
        title: StudyText("Observation is bounded", "Gözlem sınırlıdır"),
        teaching: StudyText(
          "A camera observation and a complete technique judgement have different scopes. Blur or occlusion can leave a moment unreadable; no observation is not a successful technique.",
          "Kamera gözlemiyle tam teknik hükmünün kapsamları farklıdır. Bulanıklık veya kapanma anı okunmaz bırakabilir; gözlem yokluğu başarılı teknik değildir.",
        ),
        question: StudyText(
          "A hand is obscured. Is “no error seen” enough to certify a punch?",
          "El kapanmış. “Hata görülmedi” yumruğu onaylamaya yeter mi?",
        ),
        answer: StudyText(
          "No. Keep that observation unavailable. Ask about the missing evidence before proposing a correction or a pass.",
          "Hayır. O gözlemi kullanılamaz bırak. Düzeltme veya başarı önermeden eksik kanıtı sor.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "taichi",
    title: StudyText("Tai Chi", "Tai Chi"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "assets/content/tai_chi_course.v1.json#tai_chi_foundations_01",
      "assets/content/tai_chi_course.v1.json#tai_chi_foundations_02",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "taichi.1",
        title: StudyText("Foundation task versus form", "Temel görev ve form"),
        teaching: StudyText(
          "The course’s task A is an original foundation task. It is not the Yang 13 form. The separate Yang16 written arrangement has its own sequence and evidence limits.",
          "Kursun A görevi özgün temel görevdir. Yang 13 formu değildir. Ayrı Yang16 yazılı düzenlemesinin kendi sırası ve kanıt sınırları vardır.",
        ),
        question: StudyText(
          "Can remembering A prove you know Yang 13 or Yang16?",
          "A’yı hatırlamak Yang 13 veya Yang16 bildiğini kanıtlar mı?",
        ),
        answer: StudyText(
          "No. Name the exact task you studied; a different named form requires its own instruction and review.",
          "Hayır. Çalıştığın kesin görevi adlandır; farklı adlı form kendi öğretimini ve incelemesini gerektirir.",
        ),
      ),
      RecallLesson(
        id: "taichi.2",
        title: StudyText(
          "Stopping is a valid outcome",
          "Durmak geçerli sonuçtur",
        ),
        teaching: StudyText(
          "The preparation requires a clear area and suitable stable support for the selected standing task. Unknown support or discomfort is not solved by finishing the sequence.",
          "Hazırlık, seçilen ayakta görev için boş alan ve uygun sabit destek gerektirir. Bilinmeyen destek veya rahatsızlık diziyi bitirerek çözülmez.",
        ),
        question: StudyText(
          "The setup cannot be verified. What can a written record honestly say?",
          "Kurulum doğrulanamıyor. Yazılı kayıt dürüstçe ne diyebilir?",
        ),
        answer: StudyText(
          "Uncertain or unattempted; identify the missing setup information. Do not turn a written answer into permission for a standing attempt.",
          "Belirsiz veya denenmedi; eksik kurulum bilgisini adlandır. Yazılı cevabı ayakta deneme iznine dönüştürme.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "kickboxing",
    title: StudyText("Kickboxing", "Kickboxing"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "assets/content/kickboxing_a.v1.json#kb-04",
      "assets/content/kickboxing_a.v1.json#kb-14",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "kickboxing.1",
        title: StudyText("Read the backward pair", "Geri adım çiftini oku"),
        teaching: StudyText(
          "The source table starts backward with the rear foot, then the lead foot. Lead/rear are relative to your chosen stance; they are not permanently left/right.",
          "Kaynak tablo geriye arka ayakla, ardından ön ayakla başlar. Ön/arka seçilen duruşa göredir; kalıcı sol/sağ değildir.",
        ),
        question: StudyText(
          "On paper, which foot starts backward in a right-lead stance?",
          "Kâğıtta sağ-ön duruşta geriye hangi ayak başlar?",
        ),
        answer: StudyText(
          "The rear left foot starts, then the lead right follows. Keep the chosen stance explicit.",
          "Arkadaki sol başlar, öndeki sağ izler. Seçilen duruşu açık tut.",
        ),
      ),
      RecallLesson(
        id: "kickboxing.2",
        title: StudyText("Distinguish kick families", "Tekme ailelerini ayır"),
        teaching: StudyText(
          "The written pathway separates its low front-kick preparation from other kick families and deferred scope. Explaining a front kick does not verify a roundhouse or a safe pivot.",
          "Yazılı yol alçak ön tekme hazırlığını diğer tekme aileleriyle ertelenmiş kapsamdan ayırır. Ön tekmeyi açıklamak roundhouse’u veya güvenli dönüşü doğrulamaz.",
        ),
        question: StudyText(
          "Your front-kick written answer is clear. Should an unreviewed roundhouse be marked learned?",
          "Ön tekme yazılı cevabın açık. İncelenmemiş roundhouse öğrenildi işaretlenmeli mi?",
        ),
        answer: StudyText(
          "No. Keep it a separate unattempted skill; prepare the exact question rather than borrowing acceptance from another kick.",
          "Hayır. Ayrı denenmemiş beceri bırak; diğer tekmenin kabulünü aktarmadan kesin soruyu hazırla.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "karate",
    title: StudyText(
      "Karate kihon and beginner kata",
      "Karate kihon ve başlangıç kata",
    ),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "assets/content/karate_a.v1.json#ka-04",
      "assets/content/karate_a.v1.json#ka-13",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "karate.1",
        title: StudyText("Read the hand sketch", "El şemasını oku"),
        teaching: StudyText(
          "The seiken preparation places the thumb outside the curled fingers and keeps a comfortable straight wrist/forearm relationship. This is a paper explanation, not an impact test.",
          "Seiken hazırlığında başparmak kıvrılmış parmakların dışında ve bilek/önkol rahat düz ilişkidedir. Bu kâğıt açıklamasıdır; darbe testi değildir.",
        ),
        question: StudyText(
          "In a sketch, should the thumb be trapped inside the fingers?",
          "Şemada başparmak parmakların içine hapsedilmeli mi?",
        ),
        answer: StudyText(
          "No. Label it outside; label an unclear detail as a teacher question. Do not verify the drawing by striking a target.",
          "Hayır. Dışarıda işaretle; belirsiz ayrıntıyı eğitmen sorusu olarak yaz. Çizimi hedefe vurarak doğrulama.",
        ),
      ),
      RecallLesson(
        id: "karate.2",
        title: StudyText("Name the arrangement", "Düzenlemeyi adlandır"),
        teaching: StudyText(
          "KA-P1 is the course’s bounded original written floor plan. Knowing its pauses does not establish acceptance of a traditional kata or physical turning technique.",
          "KA-P1 kursun sınırlı özgün yazılı yer planıdır. Duraklarını bilmek geleneksel kata kabulünü veya fiziksel dönüş tekniğini kanıtlamaz.",
        ),
        question: StudyText(
          "How should a learner label a recalled KA-P1 plan?",
          "Hatırlanan KA-P1 planı nasıl adlandırılmalı?",
        ),
        answer: StudyText(
          "A written recall of KA-P1, with unknown units named. A named traditional kata and physical execution remain separate.",
          "Bilinmeyen birimleri adlandırılmış KA-P1 yazılı hatırlaması. Geleneksel adlı kata ve fiziksel uygulama ayrı kalır.",
        ),
      ),
    ],
  ),
  StudyArea(
    id: "muaythai",
    title: StudyText("Muay Thai", "Muay Thai"),
    boundary: StudyText(
      "Reading and written recall only; no movement is needed. Demonstration, personal suitability and physical technique require separate review.",
      "Yalnız okuma ve yazılı hatırlama; hareket gerekmez. Gösterim, kişisel uygunluk ve fiziksel teknik ayrı inceleme gerektirir.",
    ),
    sourceRefs: <String>[
      "assets/content/muay_thai_a.v1.json#mt-04",
      "assets/content/muay_thai_a.v1.json#mt-14",
    ],
    lessons: <RecallLesson>[
      RecallLesson(
        id: "muaythai.1",
        title: StudyText("Read the guard boundary", "Gard sınırını oku"),
        teaching: StudyText(
          "The source guard preserves vision and a comfortable head position. Differences in source palm direction or height do not make one guard universal or impact-proof.",
          "Kaynak gardı görüşü ve rahat baş konumunu korur. Kaynaklardaki avuç yönü veya yüksekliği farkı tek gardı evrensel ya da darbe geçirmez yapmaz.",
        ),
        question: StudyText(
          "Does naming a guard position establish protection from impact?",
          "Gard konumunu adlandırmak darbeye karşı korunmayı kanıtlar mı?",
        ),
        answer: StudyText(
          "No. This is written understanding of one preparation. No contact test or physical approval follows.",
          "Hayır. Bu tek hazırlığın yazılı anlaşılmasıdır. Temas testi veya fiziksel onay çıkmaz.",
        ),
      ),
      RecallLesson(
        id: "muaythai.2",
        title: StudyText("Knowing versus performing", "Bilmek ve uygulamak"),
        teaching: StudyText(
          "The course distinguishes recognizing check/clinch concepts from performing them. Partner resistance, contact and clinch skill cannot be established through a solo written answer.",
          "Kurs check/clinch kavramlarını tanımayla uygulamayı ayırır. Eş direnci, temas ve clinch becerisi solo yazılı cevapla kurulamaz.",
        ),
        question: StudyText(
          "You explain a clinch concept. What remains unverified?",
          "Clinch kavramını açıklıyorsun. Ne doğrulanmamış kalır?",
        ),
        answer: StudyText(
          "Partner/contact execution and its safety. Keep those components unattempted and prepare a question for suitable instruction.",
          "Eşli/temaslı uygulama ve güvenliği. Bu bileşenleri denenmedi bırak, uygun öğretim için soru hazırla.",
        ),
      ),
    ],
  ),
];
