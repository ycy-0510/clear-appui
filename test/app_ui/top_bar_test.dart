import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: Directionality(
        textDirection: direction,
        child: AppTheme(child: Center(child: child)),
      ),
    );

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('groups actions with a clear gap in $direction', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: AppTopBar(
              leading: AppTopBarAction(
                icon: const SizedBox.square(dimension: 20),
                label: 'Back',
                onPressed: () {},
              ),
              actions: [
                AppTopBarAction(
                  icon: const SizedBox.square(dimension: 20),
                  label: 'Edit',
                  onPressed: () => taps++,
                ),
                AppTopBarAction(
                  icon: const SizedBox.square(dimension: 20),
                  label: 'More',
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
          direction: direction,
        ),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey('app-top-leading')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey('app-top-trailing')),
      );
      expect(left.overlaps(right), isFalse);
      expect((left.center.dx - right.center.dx).abs(), greaterThan(70));
      expect(right.width, greaterThan(left.width));
      expect(left.height, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(const ValueKey('app-top-action-Edit')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('app-top-action-More')));
      await tester.pump();
      expect(taps, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancel and keyboard activation remain available', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        AppTopBar(
          actions: [
            AppTopBarAction(
              icon: const SizedBox.square(dimension: 20),
              label: 'Edit',
              onPressed: () => taps++,
            ),
          ],
        ),
      ),
    );
    final action = find.byKey(const ValueKey('app-top-action-Edit'));
    final press = await tester.startGesture(tester.getCenter(action));
    await press.cancel();
    await tester.pump();
    expect(taps, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  for (final direction in TextDirection.values) {
    testWidgets('narrow actions scroll without covering Back in $direction', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 240,
            child: AppTopBar(
              leading: AppTopBarAction(
                icon: const SizedBox.square(dimension: 20),
                label: 'Back',
                onPressed: () {},
              ),
              actions: [
                for (var i = 0; i < 4; i++)
                  AppTopBarAction(
                    icon: const SizedBox.square(dimension: 20),
                    label: 'Action $i',
                    onPressed: () => taps++,
                  ),
              ],
            ),
          ),
          direction: direction,
        ),
      );
      final surface = find.byKey(const ValueKey('app-top-trailing'));
      final back = tester.getRect(
        find.byKey(const ValueKey('app-top-leading')),
      );
      expect(back.overlaps(tester.getRect(surface)), isFalse);
      await tester.drag(
        find.descendant(
          of: surface,
          matching: find.byType(SingleChildScrollView),
        ),
        Offset(direction == TextDirection.ltr ? -200 : 200, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('app-top-action-Action 3')));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
