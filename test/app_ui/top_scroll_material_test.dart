import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

Widget host(Widget child, {bool reduced = false, bool contrast = false}) =>
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
          highContrast: contrast,
        ),
        child: route!,
      ),
      home: AppTheme(child: child),
    );

final topBar = AppTopBar(
  actions: [
    AppTopBarAction(
      label: 'Settings',
      icon: const SizedBox.square(dimension: 20),
      onPressed: () {},
    ),
  ],
);

Finder get tint => find.byKey(const ValueKey('app-top-scroll-tint'));
double alpha(WidgetTester tester) => tester.widget<ColoredBox>(tint).color.a;
Widget page(ScrollController controller, {Key? headerKey}) => Builder(
  builder: (context) => ListView(
    controller: controller,
    padding: MediaQuery.paddingOf(context),
    children: [
      SizedBox(key: headerKey, height: 80, child: const Text('Heading')),
      const SizedBox(height: 2000),
    ],
  ),
);

void main() {
  testWidgets(
    'top viewport underlays controls with progressive reversible frost',
    (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      const heading = ValueKey('heading');
      await tester.pumpWidget(
        host(
          AppScaffold(
            topBar: topBar,
            body: page(controller, headerKey: heading),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(ListView)).top, 0);
      expect(tester.getRect(find.byKey(heading)).top, 47 + 64);
      expect(alpha(tester), 0);
      expect(find.byType(BackdropFilter), findsNothing);

      controller.jumpTo(24);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(alpha(tester), closeTo(0.42, 0.01));
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.getRect(find.byKey(heading)).top, 47 + 64 - 24);
      controller.jumpTo(48);
      await tester.pumpAndSettle();
      expect(alpha(tester), closeTo(0.84, 0.01));
      controller.jumpTo(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final middle = alpha(tester);
      expect(middle, greaterThan(0));
      expect(middle, lessThan(0.84));
      controller.jumpTo(48);
      await tester.pump();
      expect(alpha(tester), closeTo(middle, 0.01));
      await tester.pumpAndSettle();
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(alpha(tester), 0);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nested and horizontal scrolling do not frost the page edge', (
    tester,
  ) async {
    final horizontal = ScrollController();
    final nested = ScrollController();
    addTearDown(horizontal.dispose);
    addTearDown(nested.dispose);
    await tester.pumpWidget(
      host(
        AppScaffold(
          topBar: topBar,
          body: ListView(
            children: [
              SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  child: const SizedBox(width: 2000),
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView(
                  controller: nested,
                  children: const [SizedBox(height: 2000)],
                ),
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    horizontal.jumpTo(100);
    nested.jumpTo(100);
    await tester.pumpAndSettle();
    expect(alpha(tester), 0);
  });

  for (final contrast in [false, true]) {
    testWidgets(
      'reduced motion and contrast=$contrast have readable final state',
      (
        tester,
      ) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          host(
            AppScaffold(topBar: topBar, body: page(controller)),
            reduced: true,
            contrast: contrast,
          ),
        );
        await tester.pumpAndSettle();
        controller.jumpTo(48);
        await tester.pump();
        expect(alpha(tester), closeTo(contrast ? 1 : 0.84, 0.01));
        expect(
          find.byType(BackdropFilter),
          contrast ? findsNothing : findsOneWidget,
        );
        controller.jumpTo(0);
        await tester.pump();
        expect(alpha(tester), 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'restoring retained destinations restores their scroll material',
    (
      tester,
    ) async {
      var index = 0;
      late StateSetter change;
      final first = ScrollController();
      final second = ScrollController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) {
              change = update;
              return AppScaffold(
                topBar: topBar,
                body: AppNavigationBody(
                  index: index,
                  children: [page(first), page(second)],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      first.jumpTo(100);
      await tester.pumpAndSettle();
      expect(alpha(tester), closeTo(0.84, 0.01));
      change(() => index = 1);
      await tester.pumpAndSettle();
      expect(alpha(tester), 0);
      first.jumpTo(150); // An inactive page cannot alter the visible chrome.
      await tester.pumpAndSettle();
      expect(alpha(tester), 0);
      change(() => index = 0);
      await tester.pumpAndSettle();
      expect(first.offset, 150);
      expect(alpha(tester), closeTo(0.84, 0.01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('initial restored scroll position frosts without a new gesture', (
    tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 72);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(AppScaffold(topBar: topBar, body: page(controller))),
    );
    await tester.pumpAndSettle();
    expect(alpha(tester), closeTo(0.84, 0.01));
  });

  testWidgets('custom top content advertises its measured height', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        AppScaffold(
          topBar: const SizedBox(height: 93),
          body: page(controller, headerKey: const ValueKey('custom-heading')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('custom-heading'))).top,
      140,
    );
  });
}
