import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

Widget _host(Widget child, {double scale = 1, bool reduced = false}) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, route) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: route!,
      ),
      home: AppTheme(child: child),
    );

const _items = [
  AppNavigationItem(label: 'Courses', icon: SizedBox.square(dimension: 22)),
  AppNavigationItem(label: 'Components', icon: SizedBox.square(dimension: 22)),
];

void main() {
  testWidgets(
    'custom navigation retains its declared reserve and system inset',
    (tester) async {
      double? inset;
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 34),
            ),
            child: AppScaffold(
              navigation: const SizedBox(height: 56),
              body: Builder(
                builder: (context) {
                  inset = MediaQuery.paddingOf(context).bottom;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(inset, 88 + 34);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('compact iOS gap survives rotation and large labels at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(bottom: 34),
              textScaler: const TextScaler.linear(2),
            ),
            child: AppScaffold(
              body: const SizedBox(),
              navigation: AppNavigationBar(
                items: _items,
                selectedIndex: 0,
                haptic: false,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        size.height - tester.getRect(find.byType(AppNavigationBar)).bottom,
        8,
      );
      expect(
        tester.getRect(find.text('Components')).bottom,
        lessThan(size.height - 16),
      );
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.iOS}));
  }

  testWidgets(
    'compact iOS capsule uses the screen-edge gap and reserves '
    'reachable scroll content',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: AppScaffold(
              navigation: AppNavigationBar(
                items: _items,
                selectedIndex: 0,
                haptic: false,
                onSelected: (_) => calls++,
              ),
              body: Builder(
                builder: (context) => ListView(
                  padding: MediaQuery.paddingOf(context),
                  children: [
                    const SizedBox(height: 1500),
                    AppButton(
                      onPressed: () {},
                      child: const Text('Final action'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final capsule = tester.getRect(find.byType(AppNavigationBar));
      expect(844 - capsule.bottom, 8);
      final destination = find.byKey(
        const ValueKey('app-navigation-press-Components'),
      );
      expect(tester.getRect(destination).height, greaterThanOrEqualTo(48));
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Final action')).bottom,
        lessThan(capsule.top),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'quick navigation tap shrinks while one selection surface slides',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, update) => Align(
              alignment: Alignment.bottomCenter,
              child: AppNavigationBar(
                items: _items,
                selectedIndex: selected,
                haptic: false,
                onSelected: (value) => update(() => selected = value),
              ),
            ),
          ),
        ),
      );
      final indicator = find.byKey(
        const ValueKey('app-navigation-indicator-surface'),
      );
      final destination = find.byKey(
        const ValueKey('app-navigation-press-Components'),
      );
      double scale() => tester
          .widget<ScaleTransition>(
            find.descendant(
              of: destination,
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
      final start = tester.getRect(indicator);
      await tester.tap(find.text('Components'));
      expect(selected, 1); // Navigation never waits for visual feedback.
      await tester.pump();
      expect(tester.getRect(indicator), start);
      await tester.pump(const Duration(milliseconds: 50));
      expect(scale(), lessThan(1));
      expect(scale(), lessThan(0.94)); // A 22px icon visibly changes size.
      final middle = tester.getRect(indicator);
      expect(middle.left, greaterThan(start.left));
      expect(middle.left, lessThan(start.left + start.width));
      expect(indicator, findsOneWidget);
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(
        tester.getRect(indicator).left,
        closeTo(start.left + start.width, 0.01),
      );
    },
  );

  testWidgets('keyboard navigation pulses and reduced motion stays still', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.bottomCenter,
            child: AppNavigationBar(
              key: ValueKey(reduced),
              items: _items,
              selectedIndex: 0,
              haptic: false,
              onSelected: (_) => calls++,
            ),
          ),
          reduced: reduced,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final scales = tester
          .widgetList<ScaleTransition>(find.byType(ScaleTransition))
          .map((widget) => widget.scale.value);
      expect(calls, 1);
      expect(scales, reduced ? everyElement(1.0) : contains(lessThan(1.0)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the entire destination responds, including its empty edges', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var selected = 0;
    var activations = 0;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, update) => Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 390,
              child: AppNavigationBar(
                items: _items,
                selectedIndex: selected,
                haptic: false,
                onSelected: (value) {
                  activations++;
                  update(() => selected = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
    final destination = find.bySemanticsLabel('Components');
    final bounds = tester.getRect(destination);
    expect(bounds.height, greaterThanOrEqualTo(44));
    expect(bounds.width, greaterThan(150));
    for (final point in [
      bounds.centerLeft + const Offset(2, 0),
      bounds.centerRight - const Offset(2, 0),
      bounds.topCenter + const Offset(0, 2),
      bounds.bottomCenter - const Offset(0, 2),
    ]) {
      await tester.tapAt(point);
      await tester.pump();
    }
    expect(selected, 1);
    expect(activations, 4);
    expect(
      tester.getSemantics(destination),
      matchesSemantics(
        label: 'Components',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    // A second destination can be activated during selection feedback.
    await tester.tap(find.bySemanticsLabel('Courses'));
    await tester.pump();
    await tester.tap(destination);
    await tester.pump();
    expect(activations, 6);
    expect(selected, 1);
    semantics.dispose();
  });

  testWidgets('cancelled presses do not select; keyboard remains available', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.bottomCenter,
          child: AppNavigationBar(
            items: _items,
            selectedIndex: 0,
            haptic: false,
            onSelected: (_) => calls++,
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Components')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(0, -200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large labels fit and the final list item clears navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        AppScaffold(
          navigation: AppNavigationBar(
            items: _items,
            selectedIndex: 0,
            haptic: false,
            onSelected: (_) {},
          ),
          body: Builder(
            builder: (context) => ListView(
              padding: MediaQuery.paddingOf(context),
              children: [
                const SizedBox(height: 1200),
                AppButton(onPressed: () {}, child: const Text('Last item')),
              ],
            ),
          ),
        ),
        scale: 2,
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.text('Last item'));
    final bar = tester.getRect(find.byType(AppNavigationBar));
    expect(last.bottom, lessThan(bar.top));
    expect(tester.takeException(), isNull);
  });
  testWidgets('hidden navigation leaves no reserved gap above the keyboard', (
    tester,
  ) async {
    final bottoms = <double>[];
    await tester.pumpWidget(
      _host(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: AppScaffold(
            navigation: AppNavigationBar(
              items: _items,
              selectedIndex: 0,
              haptic: false,
              onSelected: (_) {},
            ),
            body: Builder(
              builder: (context) {
                bottoms.add(MediaQuery.paddingOf(context).bottom);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AppNavigationBar), findsNothing);
    expect(bottoms, everyElement(0));
    expect(tester.takeException(), isNull);
  });
}
