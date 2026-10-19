import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jablab/app/design_tokens.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final scale in [1.0, 2.0]) {
      for (final tooltip in ['Back', 'Geri']) {
        testWidgets(
          'GlassIconButton has a labeled 48dp target: '
          '${platform.name}/$scale/$tooltip',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            try {
              var taps = 0;
              await tester.pumpWidget(
                MaterialApp(
                  theme: ThemeData(platform: platform),
                  home: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Scaffold(
                        body: SafeArea(
                          child: Center(
                            child: GlassIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              tooltip: tooltip,
                              onTap: () => taps++,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              final button = find.byType(IconButton);
              expect(button, findsOneWidget);
              final bounds = tester.getRect(button);
              expect(bounds.size, const Size(48, 48));
              final android = await androidTapTargetGuideline.evaluate(tester);
              final ios = await iOSTapTargetGuideline.evaluate(tester);
              final label = await labeledTapTargetGuideline.evaluate(tester);
              expect(android.passed, isTrue, reason: android.reason);
              expect(ios.passed, isTrue, reason: ios.reason);
              expect(label.passed, isTrue, reason: label.reason);

              // This point lies beyond a centered 44dp target's old left edge.
              await tester.tapAt(bounds.centerLeft + const Offset(1, 0));
              await tester.pumpAndSettle();
              expect(taps, 1);
              await tester.tap(find.byTooltip(tooltip));
              await tester.pumpAndSettle();
              expect(taps, 2);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }
}
