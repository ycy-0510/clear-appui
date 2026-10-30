import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/fossui.dart';

Widget host(Widget child, {AppThemeData? theme, double scale = 1}) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, route) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          gestureSettings: const DeviceGestureSettings(touchSlop: 12),
        ),
        child: route!,
      ),
      home: AppTheme(
        data: theme,
        child: Center(child: child),
      ),
    );

void main() {
  testWidgets('direct form actions share their full surface width', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: AppFormLayout(
            children: [
              AppButton(onPressed: () {}, child: const Text('Save')),
              AppButton(
                onPressed: () {},
                variant: AppButtonVariant.secondary,
                child: const Text('Keep editing'),
              ),
            ],
          ),
        ),
      ),
    );
    final surfaces = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox && widget.decoration is ShapeDecoration,
    );
    expect(surfaces, findsNWidgets(2));
    expect(tester.getSize(surfaces.at(0)).width, 300);
    expect(tester.getSize(surfaces.at(1)).width, 300);
  });
  for (final navigation in [false, true]) {
    testWidgets(
      '${navigation ? 'navigation' : 'button'} cannot revive a dragged tap',
      (tester) async {
        var calls = 0;
        final control = navigation
            ? AppNavigationBar(
                items: const [
                  AppNavigationItem(
                    label: 'Home',
                    icon: SizedBox.square(dimension: 22),
                  ),
                  AppNavigationItem(
                    label: 'Library',
                    icon: SizedBox.square(dimension: 22),
                  ),
                ],
                selectedIndex: 0,
                haptic: false,
                onSelected: (_) => calls++,
              )
            : AppButton(onPressed: () => calls++, child: const Text('Library'));
        await tester.pumpWidget(host(SizedBox(width: 360, child: control)));
        final target = find.text('Library');
        final scaleFinder = navigation
            ? find.byKey(const ValueKey('app-navigation-press-Library'))
            : find.byType(AnimatedScale);
        double targetScale() => tester.widget<AnimatedScale>(scaleFinder).scale;
        final origin = tester.getCenter(target);
        final gesture = await tester.startGesture(origin);
        await tester.pump(const Duration(milliseconds: 60));
        expect(targetScale(), lessThan(1));
        // Stay inside a wide control but exceed the device's 12-point slop.
        await gesture.moveTo(origin + const Offset(-16, 0));
        await tester.pump();
        expect(targetScale(), 1);
        await gesture.moveTo(origin);
        await tester.pump(const Duration(milliseconds: 180));
        expect(targetScale(), 1);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(calls, 0);
        await tester.tap(target);
        await tester.pump();
        expect(calls, 1);
        expect(targetScale(), lessThan(1));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'scrolling owns the gesture after a button press; keyboard still works',
    (tester) async {
      var calls = 0;
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              controller: scroll,
              children: [
                AppButton(
                  onPressed: () => calls++,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      );
      final origin = tester.getCenter(find.text('Continue'));
      final gesture = await tester.startGesture(origin);
      await tester.pump(const Duration(milliseconds: 120));
      await gesture.moveBy(const Offset(0, -80));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      expect(scroll.offset, greaterThan(0));
      await gesture.moveTo(origin);
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(calls, 0);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );

  testWidgets('pointer cancel and unrelated secondary pointer never re-press', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(AppButton(onPressed: () => calls++, child: const Text('Continue'))),
    );
    final origin = tester.getCenter(find.text('Continue'));
    final gesture = await tester.startGesture(origin, pointer: 1);
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(calls, 0);
    final first = await tester.startGesture(origin, pointer: 2);
    await first.moveBy(const Offset(40, 0));
    final second = await tester.startGesture(origin, pointer: 3);
    await second.up();
    await first.moveTo(origin);
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await first.up();
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets(
    'large continuation centers its scalable label; '
    'secondary adapts without changing cards',
    (tester) async {
      for (final theme in [AppThemeData.light, AppThemeData.dark]) {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 320,
              child: AppButton(
                size: AppButtonSize.large,
                expanded: true,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
                child: const Text('Continue learning'),
              ),
            ),
            theme: theme,
            scale: 1.5,
          ),
        );
        final label = tester.getRect(find.text('Continue learning'));
        final control = tester.getRect(find.byType(AppButton));
        expect(label.center.dx, closeTo(control.center.dx, 0.1));
        expect(control.height, greaterThanOrEqualTo(56));
        final style = tester.widget<FossButton>(find.byType(FossButton)).style!;
        expect(style.textStyle!.fontSize, 17);
        expect(style.borderRadius, 999);
        if (theme == AppThemeData.dark) {
          final fill = style.backgroundColor!.resolve({});
          expect(
            fill.computeLuminance(),
            greaterThan(theme.tokens.colors.popover.computeLuminance()),
          );
          final text = theme.tokens.colors.secondaryForeground
              .computeLuminance();
          expect(
            (text + .05) / (fill.computeLuminance() + .05),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
}
