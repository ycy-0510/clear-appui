import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

Widget host(
  Widget child, {
  bool reduced = false,
  EdgeInsets padding = EdgeInsets.zero,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, route) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: reduced, padding: padding),
    child: route!,
  ),
  home: AppTheme(child: child),
);

const items = [
  AppNavigationItem(label: 'A', icon: SizedBox.square(dimension: 22)),
  AppNavigationItem(label: 'B', icon: SizedBox.square(dimension: 22)),
  AppNavigationItem(label: 'C', icon: SizedBox.square(dimension: 22)),
];

void main() {
  for (final rtl in [false, true]) {
    testWidgets('one indicator travels continuously and reverses in RTL=$rtl', (
      tester,
    ) async {
      late StateSetter change;
      var index = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) {
              change = update;
              return Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: Center(
                  child: SizedBox(
                    width: 390,
                    child: AppNavigationBar(
                      items: items,
                      selectedIndex: index,
                      haptic: false,
                      onSelected: (next) => update(() => index = next),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      final indicator = find.byKey(
        const ValueKey('app-navigation-indicator-surface'),
      );
      final start = tester.getRect(indicator);
      change(() => index = 2);
      await tester.pump();
      expect(tester.getRect(indicator), start);
      await tester.pump(const Duration(milliseconds: 70));
      final middle = tester.getRect(indicator);
      expect((middle.left - start.left).abs(), greaterThan(5));
      expect((middle.left - start.left).abs(), lessThan(start.width * 2));
      change(() => index = 0);
      await tester.pump();
      expect(tester.getRect(indicator).left, closeTo(middle.left, 0.01));
      await tester.pumpAndSettle();
      expect(tester.getRect(indicator).left, closeTo(start.left, 0.01));
      expect(indicator, findsOneWidget);
    });
  }

  testWidgets('reduced motion selects without travelling', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, update) => Center(
            child: SizedBox(
              width: 390,
              child: AppNavigationBar(
                items: items,
                selectedIndex: index,
                haptic: false,
                onSelected: (next) => update(() => index = next),
              ),
            ),
          ),
        ),
        reduced: true,
      ),
    );
    final indicator = find.byKey(
      const ValueKey('app-navigation-indicator-surface'),
    );
    final start = tester.getRect(indicator);
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(
      tester.getRect(indicator).left - start.left,
      closeTo(start.width * 2, 0.01),
    );
  });

  testWidgets('floating action surface grows through intermediate sizes', (
    tester,
  ) async {
    late StateSetter change;
    var count = 1;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, update) {
            change = update;
            return Center(
              child: AppTopBar(
                actions: [
                  for (var i = 0; i < count; i++)
                    AppTopBarAction(
                      icon: const SizedBox.square(dimension: 20),
                      label: '$i',
                      onPressed: () {},
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
    final surface = find.byKey(const ValueKey('app-top-trailing'));
    final start = tester.getSize(surface).width;
    change(() => count = 3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final middle = tester.getSize(surface).width;
    expect(
      tester.getRect(
        find.descendant(of: surface, matching: find.byType(ClipRSuperellipse)),
      ),
      tester.getRect(surface),
      reason: 'The rounded clip must follow the animated visible capsule.',
    );
    await tester.pumpAndSettle();
    final end = tester.getSize(surface).width;
    expect(middle, greaterThan(start));
    expect(middle, lessThan(end));
  });

  testWidgets(
    'scroll viewport extends beneath navigation and device bottom inset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          AppScaffold(
            navigation: AppNavigationBar(
              items: items,
              selectedIndex: 0,
              haptic: false,
              onSelected: (_) {},
            ),
            body: Builder(
              builder: (context) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 1200)),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 70, child: Text('Last row')),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
      );
      expect(tester.getRect(find.byType(CustomScrollView)).bottom, 844);
      final bar = tester.getRect(find.byType(AppNavigationBar));
      expect(bar.bottom, lessThanOrEqualTo(844 - 34));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Last row')).bottom, lessThan(bar.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard dismissal fades chrome and disables it immediately', (
    tester,
  ) async {
    late StateSetter change;
    var keyboard = false;
    var taps = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, update) {
            change = update;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: EdgeInsets.only(bottom: keyboard ? 300 : 0),
              ),
              child: AppScaffold(
                body: const SizedBox(),
                navigation: AppNavigationBar(
                  items: items,
                  selectedIndex: 0,
                  haptic: false,
                  onSelected: (_) => taps++,
                ),
              ),
            );
          },
        ),
      ),
    );
    change(() => keyboard = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.byType(AppNavigationBar), findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(AppNavigationBar),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, greaterThan(0));
    expect(fade.opacity.value, lessThan(1));
    expect(find.text('B').hitTestable(), findsNothing);
    expect(taps, 0);
    await tester.pumpAndSettle();
    expect(find.byType(AppNavigationBar), findsNothing);
    change(() => keyboard = false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    expect(taps, 1);
  });

  testWidgets(
    'rapid destination changes retain state and exclude outgoing semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var index = 0;
      late StateSetter change;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) {
              change = update;
              return AppNavigationBody(
                index: index,
                children: const [
                  Center(child: _Counter()),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                ],
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Counter 0'));
      await tester.pump();
      change(() => index = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      final labels = <String>[];
      void collect(SemanticsNode node) {
        labels.add(node.getSemanticsData().label);
        node.visitChildren((child) {
          collect(child);
          return true;
        });
      }

      collect(tester.getSemantics(find.byType(AppNavigationBody)));
      expect(labels.join(' '), isNot(contains('Counter 1')));
      expect(labels.join(' '), contains('Page B'));
      change(() => index = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      change(() => index = 0);
      await tester.pumpAndSettle();
      expect(find.text('Counter 1'), findsOneWidget);
      expect(find.text('Page B'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => count++),
    child: Text('Counter $count'),
  );
}
