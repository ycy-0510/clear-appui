import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'app_ui_test.dart' show host;

void main() {
  late BuildContext pageContext;
  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Future<void> open(
    WidgetTester tester, {
    AppSheetController? controller,
  }) async {
    unawaited(
      showAppSheet<void>(
        context: pageContext,
        builder: (_) => AppSheet(
          controller: controller,
          initialDetent: AppSheetDetent.large,
          builder: (_, scroll) => ListView(
            controller: scroll,
            children: const [
              SizedBox(height: 1200, child: Text('Sheet content')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'sheet enters and reverses from its current frame; future waits for exit',
    (tester) async {
      await boot(tester);
      var completed = false;
      String? returned;
      unawaited(
        showAppSheet<String>(
          context: pageContext,
          builder: (_) => AppSheet(
            builder: (_, scroll) => ListView(controller: scroll),
          ),
        ).then((result) {
          returned = result;
          completed = true;
        }),
      );
      await tester.pump();
      final finder = find.byKey(const ValueKey('app-sheet-presentation'));
      Offset position() =>
          tester.widget<SlideTransition>(finder).position.value;
      expect(position().dy, 1);
      await tester.pump(const Duration(milliseconds: 70));
      final middle = position().dy;
      expect(middle, inExclusiveRange(0, 1));
      AppPresentationHost.of(pageContext).close('saved');
      await tester.pump();
      expect(position().dy, closeTo(middle, .001));
      expect(completed, false);
      await tester.pumpAndSettle();
      expect(completed, true);
      expect(returned, 'saved');
      expect(find.byType(AppSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'first handle pull moves immediately and one continuous pull dismisses',
    (tester) async {
      final controller = AppSheetController();
      addTearDown(controller.dispose);
      await boot(tester);
      await open(tester, controller: controller);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('app-sheet-grabber'))),
      );
      await gesture.moveBy(const Offset(0, 130));
      await tester.pump();
      expect(controller.extent, lessThan(.95));
      await gesture.moveBy(const Offset(0, 500));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'first body pull resizes and dismisses in one gesture',
    (tester) async {
      final controller = AppSheetController();
      addTearDown(controller.dispose);
      await boot(tester);
      await open(tester, controller: controller);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(200, 130));
      await gesture.moveBy(const Offset(0, 130));
      await tester.pump();
      expect(controller.extent, lessThan(.95));
      await gesture.moveBy(const Offset(0, 500));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancelling a short first drag settles and still allows closing',
    (tester) async {
      await boot(tester);
      await open(tester);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('app-sheet-grabber'))),
      );
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsOneWidget);
      AppPresentationHost.of(pageContext).close();
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reduced motion opens and closes at final geometry', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await boot(tester);
    await open(tester);
    await tester.pump();
    expect(
      tester
          .widget<SlideTransition>(
            find.byKey(const ValueKey('app-sheet-presentation')),
          )
          .position
          .value,
      Offset.zero,
    );
    AppPresentationHost.of(pageContext).close();
    await tester.pumpAndSettle();
    expect(find.byType(AppSheet), findsNothing);
  });
}
