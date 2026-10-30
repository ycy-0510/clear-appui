import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

Widget host(Widget child, {bool reduced = false, double scale = 1}) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, route) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: route!,
      ),
      home: AppTheme(child: child),
    );

Widget page(ScrollController controller) => Builder(
  builder: (context) => ListView(
    controller: controller,
    padding: MediaQuery.paddingOf(context),
    children: const [
      AppCollapsingTitle(
        collapsed: Text('Compact brand'),
        child: SizedBox(height: 100, child: Text('Expanded brand')),
      ),
      SizedBox(height: 2000),
    ],
  ),
);

AppTopBar get bar => AppTopBar(
  actions: [
    AppTopBarAction(
      icon: const Text('⚙'),
      label: 'Settings',
      onPressed: () {},
    ),
  ],
);

double amount(WidgetTester tester) => tester
    .widget<Opacity>(
      find.byKey(const ValueKey('app-collapsed-title')),
    )
    .opacity;

void main() {
  testWidgets('nested scaffold scrolling only updates its own compact title', (
    tester,
  ) async {
    final outer = ScrollController();
    final inner = ScrollController();
    addTearDown(outer.dispose);
    addTearDown(inner.dispose);
    await tester.pumpWidget(
      host(
        AppScaffold(
          topBar: bar,
          body: Builder(
            builder: (context) => SingleChildScrollView(
              controller: outer,
              padding: MediaQuery.paddingOf(context),
              child: Column(
                children: [
                  const AppCollapsingTitle(
                    collapsed: Text('Outer compact'),
                    child: SizedBox(height: 100, child: Text('Outer expanded')),
                  ),
                  SizedBox(
                    height: 350,
                    child: AppScaffold(topBar: bar, body: page(inner)),
                  ),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    inner.jumpTo(200);
    await tester.pumpAndSettle();
    final compact = find.byKey(const ValueKey('app-collapsed-title'));
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Outer compact'),
              matching: compact,
            ),
          )
          .opacity,
      0,
    );
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Compact brand'),
              matching: compact,
            ),
          )
          .opacity,
      1,
    );
    expect(outer.offset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'measured occlusion reveals continuously and reverses without '
    'changing chrome height',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        host(AppScaffold(topBar: bar, body: page(scroll))),
      );
      await tester.pumpAndSettle();
      expect(amount(tester), 0);
      final bounds = tester.getRect(find.byType(AppTopBar));
      scroll.jumpTo(40);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(amount(tester), allOf(greaterThan(0), lessThan(1)));
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      expect(amount(tester), 1);
      expect(tester.getRect(find.byType(AppTopBar)), bounds);
      scroll.jumpTo(0);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(amount(tester), allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(amount(tester), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inactive retained destinations release the title and restore '
    'their scroll state',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      late StateSetter select;
      var index = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) {
              select = update;
              return AppScaffold(
                topBar: bar,
                body: AppNavigationBody(
                  index: index,
                  children: [
                    page(scroll),
                    const Center(child: Text('Other page')),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      expect(amount(tester), 1);
      select(() => index = 1);
      await tester.pumpAndSettle();
      expect(amount(tester), 0);
      select(() => index = 0);
      await tester.pumpAndSettle();
      expect(scroll.offset, 200);
      expect(amount(tester), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text and reduced motion keep actions reachable and '
    'only one title semantic',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        host(
          AppScaffold(topBar: bar, body: page(scroll)),
          reduced: true,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Expanded brand'), findsOneWidget);
      expect(find.bySemanticsLabel('Compact brand'), findsNothing);
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      expect(amount(tester), 1);
      expect(find.bySemanticsLabel('Expanded brand'), findsNothing);
      expect(find.bySemanticsLabel('Compact brand'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('app-top-action-Settings')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
