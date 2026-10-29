import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

import 'app_ui_test.dart' show host;

void main() {
  test(
    'margins and opacity change smoothly without a half-height cutoff',
    () {
      const style = AppSheetStyle();
      expect(style.marginAt(0.3, minimumExtent: 0.3), 16);
      expect(style.marginAt(0.5, minimumExtent: 0.3), greaterThan(0));
      expect(style.marginAt(0.8, minimumExtent: 0.3), greaterThan(0));
      expect(style.marginAt(1, minimumExtent: 0.3), 0);
      expect(style.opacityAt(0.3, minimumExtent: 0.3), 0.72);
      var previousMargin = double.infinity;
      var previousOpacity = 0.0;
      for (var step = 0; step <= 70; step++) {
        final height = 0.3 + step / 100;
        final margin = style.marginAt(height, minimumExtent: 0.3);
        final opacity = style.opacityAt(height, minimumExtent: 0.3);
        expect(margin, lessThanOrEqualTo(previousMargin));
        expect(opacity, greaterThanOrEqualTo(previousOpacity));
        previousMargin = margin;
        previousOpacity = opacity;
      }
      expect(style.opacityAt(1, minimumExtent: 0.3), 1);
    },
  );

  testWidgets(
    'grabber cycles floating, edge-attached and fully opaque states',
    (tester) async {
      final controller = AppSheetController();
      addTearDown(controller.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(
        showAppSheet<void>(
          context: context,
          builder: (_) => AppSheet(
            controller: controller,
            initialDetent: const AppSheetDetent.fraction(0.3),
            builder: (_, scroll) =>
                ListView(controller: scroll, children: const [Text('Body')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('app-sheet-surface'));
      final grabber = find.byKey(const ValueKey('app-sheet-grabber'));
      BoxDecoration decoration() =>
          tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
      expect(controller.extent, closeTo(0.3, 0.001));
      expect(tester.getTopLeft(surface).dx, 16);
      expect(decoration().color!.a, closeTo(0.72, 0.001));
      await tester.tap(grabber);
      await tester.pumpAndSettle();
      expect(controller.extent, closeTo(0.5, 0.001));
      expect(tester.getTopLeft(surface).dx, greaterThan(0));
      expect(tester.getTopLeft(surface).dx, lessThan(16));
      expect(decoration().color!.a, greaterThan(0.72));
      expect(decoration().color!.a, lessThan(1));
      await tester.tap(grabber);
      await tester.pumpAndSettle();
      expect(controller.extent, closeTo(1, 0.001));
      expect(decoration().color!.a, 1);
      await tester.tap(grabber);
      await tester.pumpAndSettle();
      expect(controller.extent, closeTo(0.3, 0.001));
      expect(tester.getTopLeft(surface).dx, 16);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('high contrast makes even a small sheet opaque', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
    unawaited(
      showAppSheet<void>(
        context: context,
        builder: (ctx) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(highContrast: true),
          child: AppSheet(builder: (_, scroll) => ListView(controller: scroll)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final box = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('app-sheet-surface')),
    );
    expect((box.decoration as BoxDecoration).color!.a, 1);
  });
}
