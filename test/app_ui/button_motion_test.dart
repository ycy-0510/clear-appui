import 'dart:async';
import 'dart:ui' show SemanticsAction, SemanticsActionEvent;
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
  testWidgets('grouped row exposes an independent trailing action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var opens = 0;
      var removals = 0;
      await tester.pumpWidget(
        host(
          AppListGroup(
            children: [
              AppListTile(
                title: const Text('Biology'),
                onTap: () => opens++,
                trailing: AppButton(
                  onPressed: () => removals++,
                  semanticLabel: 'Remove Biology',
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ),
      );
      final row = tester.getSemantics(find.byType(AppListTile));
      final remove = tester.getSemantics(find.byType(AppButton));
      expect(remove.id, isNot(row.id));
      expect(remove.label, contains('Remove Biology'));
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          nodeId: remove.id,
          viewId: tester.view.viewId,
          type: SemanticsAction.tap,
        ),
      );
      await tester.pumpAndSettle();
      expect(removals, 1);
      expect(opens, 0);
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          nodeId: row.id,
          viewId: tester.view.viewId,
          type: SemanticsAction.tap,
        ),
      );
      await tester.pumpAndSettle();
      expect(opens, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('an action card wraps text and keeps its child action separate', (
    tester,
  ) async {
    var opens = 0;
    var continues = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 240,
          child: AppCard(
            onTap: () => opens++,
            title: const AppText('Open group'),
            footer: AppButton(
              onPressed: () => continues++,
              child: const Text('Continue'),
            ),
            child: const AppText(
              'A longer group description wraps within the card surface.',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(continues, 1);
    expect(opens, 0);
    await tester.tap(find.text('Open group'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(tester.takeException(), isNull);
  });

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
      expect(
        scale,
        greaterThanOrEqualTo(AppThemeData.light.motion.pressedScale),
      );
      expect(scale, lessThan(0.98));
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
