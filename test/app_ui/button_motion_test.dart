import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/fossui.dart';

Widget host(Widget child, {bool reduced = false}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, route) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: route!,
  ),
  home: AppTheme(child: Center(child: child)),
);

void main() {
  testWidgets(
    'a quick tap gives visible continuous feedback without a loading flash',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(AppButton(onPressed: () => calls++, child: const Text('Open'))),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final scale = tester
          .widget<ScaleTransition>(find.byType(ScaleTransition))
          .scale
          .value;
      expect(scale, lessThan(1));
      expect(scale, greaterThanOrEqualTo(0.97));
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).isLoading,
        isFalse,
      );
      expect(calls, 1); // Action never waits for motion.
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ScaleTransition>(find.byType(ScaleTransition))
            .scale
            .value,
        1,
      );
    },
  );

  testWidgets(
    'async work is gated immediately; only sustained work shows loading',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        host(
          AppButton(
            onPressed: () {
              calls++;
              return pending.future;
            },
            child: const Text('Save'),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 40));
      expect(calls, 1);
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).isLoading,
        isFalse,
      );
      await tester.pump(const Duration(milliseconds: 220));
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).isLoading,
        isTrue,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).isLoading,
        isFalse,
      );
    },
  );

  testWidgets('keyboard activation pulses; reduced motion stays still', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        host(
          AppButton(onPressed: () {}, child: const Text('Go')),
          reduced: reduced,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final scale = tester
          .widget<ScaleTransition>(find.byType(ScaleTransition))
          .scale
          .value;
      expect(scale, reduced ? equals(1) : lessThan(1));
      await tester.pumpAndSettle();
    }
  });
}
