import 'package:flutter/material.dart';

import 'ui_language.dart';

/// Which first-release course a [CourseScopeNote] describes.
enum CourseScope { boxing, kickboxing, muayThai, karate, taikyoku, taiChi }

/// One short "not in this course" line under each course title (G3 narrow
/// closure, founder decision 2026-10-23: state missing beginner topics as out
/// of scope instead of adding new physical teaching). Literal EN/TR pairs so
/// the catalog collector binds every locale.
class CourseScopeNote extends StatelessWidget {
  const CourseScopeNote(this.scope, {super.key});

  final CourseScope scope;

  @override
  Widget build(BuildContext context) {
    final String scopeLine = switch (scope) {
      CourseScope.boxing => UiLanguage.text(
        context,
        en: 'Not in this course: sparring, partner or bag work, and a built-in round timer. Time rounds with your own clock and finish with a few minutes of easy walking and breathing.',
        tr: 'Bu kursta yok: sparring, partner veya torba çalışması ve uygulama içi raunt saati. Rauntları kendi saatinle tut; bitirirken birkaç dakika rahat yürü ve nefesini düzenle.',
      ),
      CourseScope.kickboxing => UiLanguage.text(
        context,
        en: 'Not in this course: roundhouse and side kicks, kick defence, blocking drills and timed rounds. The kick itself needs individual demonstration and feedback, which this app cannot give.',
        tr: 'Bu kursta yok: roundhouse ve yan tekme, tekme savunması, blok çalışmaları ve süreli rauntlar. Tekmenin kendisi bu uygulamanın veremeyeceği bireysel gösterim ve geri bildirim gerektirir.',
      ),
      CourseScope.muayThai => UiLanguage.text(
        context,
        en: 'Not in this course: roundhouse kicks, blocks and checks, clinch practice, pivots and angles, and timed rounds.',
        tr: 'Bu kursta yok: roundhouse tekme, blok ve check, klinç uygulaması, pivot ve açı çalışması ve süreli rauntlar.',
      ),
      CourseScope.karate => UiLanguage.text(
        context,
        en: 'This course is the first layer of kihon. Not in it: mae-geri, age-uke, soto-uke, uchi-uke, gyaku-zuki, kiba-dachi and kokutsu-dachi.',
        tr: 'Bu kurs kihon’un ilk katmanıdır. İçinde yok: mae-geri, age-uke, soto-uke, uchi-uke, gyaku-zuki, kiba-dachi ve kokutsu-dachi.',
      ),
      CourseScope.taikyoku => UiLanguage.text(
        context,
        en: 'This course covers only the beginner kata Taikyoku Shodan; other kata and partner applications are not in it.',
        tr: 'Bu kurs yalnız başlangıç katası Taikyoku Shodan’ı kapsar; diğer katalar ve partnerli uygulamalar içinde yok.',
      ),
      CourseScope.taiChi => UiLanguage.text(
        context,
        en: 'Not in this course: stepping, turning and the moving Yang Family 16 form. The written Yang 16 course describes the sequence; it does not teach its steps.',
        tr: 'Bu kursta yok: adım çalışması, dönüş ve hareket hâlinde Yang Family 16 formu. Yazılı Yang 16 kursu sırayı anlatır; adımlarını öğretmez.',
      ),
    };
    final bool warmUp = switch (scope) {
      CourseScope.muayThai ||
      CourseScope.karate ||
      CourseScope.taikyoku => true,
      _ => false,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scopeLine, key: Key('course-scope-${scope.name}')),
          if (warmUp)
            Text(
              UiLanguage.text(
                context,
                en: 'Before practice, walk slowly for a short time; finish with easy walking or seated rest.',
                tr: 'Pratikten önce kısa süre yavaşça yürü; rahat yürüyüş veya oturarak dinlenmeyle bitir.',
              ),
              key: Key('course-warm-up-${scope.name}'),
            ),
        ],
      ),
    );
  }
}
