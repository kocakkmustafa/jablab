import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jablab/main.dart' as production;
import 'package:jablab/app/jablab_app.dart';
import 'package:jablab/app/onboarding_page.dart';
import 'package:jablab/app/course_page.dart';
import 'package:jablab/app/select_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('production main guest boot reaches usable jablab screen', (tester) async {
    await production.main();
    bool ready() => find.byType(OnboardingPage).evaluate().isNotEmpty ||
        find.byType(CoursePage).evaluate().isNotEmpty ||
        find.byType(SelectPage).evaluate().isNotEmpty;
    for (var i = 0; i < 600 && !ready(); i++) {
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(JabLabApp), findsOneWidget);
    expect(ready(), isTrue,
        reason: 'Production main must reach interactive onboarding or content');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    debugPrint('MOTION_MAIN_BOOT_READY_jablab');
    await Future<void>.delayed(const Duration(seconds: 3));
  });
}
