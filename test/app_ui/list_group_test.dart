import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/fossui.dart';

Widget host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: AppTheme(child: child),
  ),
);

void main() {
  testWidgets('a group has only exterior corners and plain flush rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Center(
          child: AppListGroup(
            children: [
              for (var i = 0; i < 3; i++) AppListTile(title: Text('Row $i')),
            ],
          ),
        ),
      ),
    );
    final clips = tester
        .widgetList<ClipRSuperellipse>(find.byType(ClipRSuperellipse))
        .toList();
    expect(
      clips[0].borderRadius.resolve(TextDirection.ltr).topLeft.x,
      greaterThan(0),
    );
    expect(
      clips[0].borderRadius.resolve(TextDirection.ltr).bottomLeft,
      Radius.zero,
    );
    expect(clips[1].borderRadius, BorderRadius.zero);
    expect(
      clips[2].borderRadius.resolve(TextDirection.ltr).topLeft,
      Radius.zero,
    );
    expect(
      clips[2].borderRadius.resolve(TextDirection.ltr).bottomLeft.x,
      greaterThan(0),
    );
    for (final row in tester.widgetList<FossListTile>(
      find.byType(FossListTile),
    )) {
      expect(row.variant, FossListTileVariant.plain);
      expect(row.style!.borderRadius, 0);
    }
    final a = tester.getRect(find.byType(AppListTile).at(0));
    final b = tester.getRect(find.byType(AppListTile).at(1));
    expect(b.top - a.bottom, 1); // Only the divider, no card gaps.
  });

  testWidgets('a single grouped row keeps both exterior corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Center(
          child: AppListGroup(children: [AppListTile(title: Text('Only'))]),
        ),
      ),
    );
    final clip = tester.widget<ClipRSuperellipse>(
      find.byType(ClipRSuperellipse),
    );
    expect(
      clip.borderRadius.resolve(TextDirection.ltr).topLeft.x,
      greaterThan(0),
    );
    expect(
      clip.borderRadius.resolve(TextDirection.ltr).bottomLeft.x,
      greaterThan(0),
    );
  });

  testWidgets('sliver groups build lazily while the header scrolls away', (
    tester,
  ) async {
    var built = 0;
    await tester.pumpWidget(
      host(
        CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: Text('Scrolling search')),
            AppSliverListGroup(
              itemCount: 5000,
              itemBuilder: (context, index) {
                built++;
                return AppListTile(title: Text('Row $index'));
              },
            ),
          ],
        ),
      ),
    );
    expect(built, lessThan(60));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Scrolling search'), findsNothing);
    expect(built, lessThan(100));
    expect(tester.takeException(), isNull);
  });
}
