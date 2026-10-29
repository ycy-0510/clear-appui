import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui_example/component_catalog.dart';
import 'package:fossui_example/upstream_gallery.dart';

import 'catalog_overlay_test_utils.dart';

Widget _host(
  Widget child, {
  required Size size,
  double scale = 1,
  bool dark = false,
  bool rtl = false,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: AppTheme(
        data: dark ? AppThemeData.dark : AppThemeData.light,
        child: FossToaster(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  test('the catalog covers every component family without duplicate ids', () {
    expect(componentCatalog, hasLength(39));
    expect(componentCatalog.map((c) => c.id).toSet(), hasLength(39));
  });
  for (final entry in componentCatalog) {
    for (final (name, width, scale, dark, rtl, stress) in [
      ('320 light', 320.0, 1.0, false, false, false),
      ('320 dark', 320.0, 1.0, true, false, false),
      ('320 large long content', 320.0, 2.0, false, false, true),
      ('320 large RTL long content', 320.0, 2.0, true, true, true),
      ('1024 long content', 1024.0, 1.0, false, false, true),
      ('1024 large RTL', 1024.0, 2.0, true, true, true),
    ]) {
      testWidgets('${entry.id}: $name', (tester) async {
        final size = Size(width, 900);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _host(
            ComponentSample(id: entry.id, stress: stress),
            size: size,
            scale: scale,
            dark: dark,
            rtl: rtl,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${entry.name} / $name');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (final id in catalogOverlayIds) {
    for (final width in [320.0, 1024.0]) {
      testWidgets('$id: open at $width, 2x text and long content', (
        tester,
      ) async {
        final size = Size(width, 900);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _host(ComponentSample(id: id, stress: true), size: size, scale: 2),
        );
        await openCatalogOverlay(tester, id);
        expect(tester.takeException(), isNull, reason: '$id open / $width');
        if (id == 'alert_dialog') {
          await tester.tap(find.text('Cancel'));
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '$id close / $width');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final id in [
    'button',
    'checkbox',
    'radio',
    'switch',
    'toggle',
    'toggle_group',
    'select',
    'multi_select',
    'combobox',
    'multi_combobox',
    'autocomplete',
    'number_field',
    'chip',
    'tabs',
    'accordion',
    'list_tile',
    'pagination',
    'date_picker',
    'time_picker',
    'popover',
    'dialog',
    'alert_dialog',
    'drawer',
    'tooltip',
    'toast',
  ]) {
    testWidgets('$id: labeled touch targets meet iOS guideline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(ComponentSample(id: id), size: const Size(390, 1200)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      } finally {
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets('the narrow catalog picker reaches an individual component', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('完整元件庫 · 39'), findsOneWidget);
    await tester.tap(find.byType(FossCombobox<String>).first);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.enterText(find.byType(EditableText).first, 'Pagination');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Pagination').last);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(FossPagination), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
