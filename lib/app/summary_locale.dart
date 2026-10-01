import 'package:flutter/widgets.dart';

import 'ui_language.dart';

// Keys and stored measurements stay in English. Only the source-matched
// presentation labels change; unknown labels remain visible for review.
const Map<String, String> _componentLabelsTr = <String, String>{
  'Stance': 'Duruş',
  'Balance': 'Denge',
  'Guard discipline': 'Gard disiplini',
  'Footwork': 'Ayak çalışması',
  'Punch mechanics': 'Yumruk mekaniği',
  'Combination accuracy': 'Kombinasyon doğruluğu',
  'Recovery': 'Geri dönüş',
  'Timing': 'Zamanlama',
  'Tracking confidence': 'Takip güveni',
  'Lead hip position': 'Öndeki kalçanın konumu',
  'Lead knee position': 'Öndeki dizin konumu',
  'Rear knee position': 'Arkadaki dizin konumu',
  'Lead thigh placement': 'Öndeki üst bacağın yerleşimi',
  'Rear shin angle': 'Arkadaki kaval kemiğinin açısı',
  'Lead shoulder position': 'Öndeki omzun konumu',
  'Lead shin angle': 'Öndeki kaval kemiğinin açısı',
  'Rear shoulder position': 'Arkadaki omzun konumu',
  'Rear hip position': 'Arkadaki kalçanın konumu',
  'Rear thigh placement': 'Arkadaki üst bacağın yerleşimi',
  'Lead elbow angle': 'Öndeki dirseğin açısı',
  'Rear elbow angle': 'Arkadaki dirseğin açısı',
  'Lead upper arm angle': 'Öndeki üst kolun açısı',
  'Rear upper arm angle': 'Arkadaki üst kolun açısı',
  'Lead forearm': 'Öndeki ön kol',
  'Rear forearm': 'Arkadaki ön kol',
  'Lead guard hand position': 'Öndeki gard elinin konumu',
  'Rear guard hand position': 'Arkadaki gard elinin konumu',
  'Torso lean': 'Gövde eğimi',
};

const Map<String, String> _tempoBandsTr = <String, String>{
  'controlled': 'kontrollü',
  'brisk': 'tempolu',
  'fast': 'hızlı',
};

String componentLabel(BuildContext context, String source) =>
    UiLanguage.isTurkish(context)
    ? _componentLabelsTr[source] ?? source
    : source;

String? tempoBandLabel(BuildContext context, String? source) => source == null
    ? null
    : UiLanguage.isTurkish(context)
    ? _tempoBandsTr[source] ?? source
    : source;
