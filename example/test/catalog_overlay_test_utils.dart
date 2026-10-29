import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

const catalogOverlayIds = [
  'select',
  'multi_select',
  'combobox',
  'multi_combobox',
  'autocomplete',
  'date_picker',
  'time_picker',
  'popover',
  'dialog',
  'alert_dialog',
  'drawer',
  'tooltip',
  'toast',
];

/// Opens the real overlay and verifies its content, not only its trigger.
Future<void> openCatalogOverlay(WidgetTester tester, String id) async {
  final trigger = switch (id) {
    'popover' => 'Open popover',
    'dialog' => 'Open dialog',
    'alert_dialog' => 'Open alert dialog',
    'drawer' => 'Open bottom drawer',
    'toast' => 'Show success toast',
    _ => '',
  };
  if (id == 'tooltip') {
    await tester.longPress(find.byType(FossButton));
  } else if (trigger.isNotEmpty) {
    await tester.tap(find.text(trigger));
  } else {
    final field = find
        .byWidgetPredicate(
          (w) => switch (id) {
            'select' => w is FossSelect<String>,
            'multi_select' => w is FossMultiSelect<String>,
            'combobox' => w is FossCombobox<String>,
            'multi_combobox' => w is FossMultiCombobox<String>,
            'autocomplete' => w is FossAutocomplete,
            'date_picker' => w is FossDatePicker,
            'time_picker' => w is FossTimePicker,
            _ => false,
          },
        )
        .first;
    final target = switch (id) {
      'select' || 'multi_select' =>
        find
            .descendant(
              of: field,
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.button == true,
              ),
            )
            .first,
      'combobox' || 'multi_combobox' || 'autocomplete' =>
        find
            .descendant(
              of: field,
              matching: find.byType(EditableText),
            )
            .first,
      _ => field,
    };
    await tester.tap(target);
    if (id == 'autocomplete') {
      await tester.enterText(find.byType(EditableText).first, 'De');
    }
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  switch (id) {
    case 'select' || 'multi_select' || 'combobox' || 'multi_combobox':
      expect(find.text('Engineering'), findsOneWidget);
    case 'autocomplete':
      expect(find.text('Design'), findsOneWidget);
    case 'date_picker':
      expect(find.byType(FossCalendar), findsOneWidget);
    case 'time_picker':
      expect(find.byType(FossDialog), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNWidgets(2));
    case 'dialog':
      expect(find.byType(FossDialog), findsOneWidget);
    case 'alert_dialog':
      expect(find.byType(FossAlertDialog), findsOneWidget);
    case 'drawer':
      expect(find.byType(FossDrawer), findsOneWidget);
    case 'popover':
      expect(find.text('Done'), findsOneWidget);
    case 'tooltip':
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ((w.data?.startsWith('Reusable components') ?? false) ||
                  (w.data?.startsWith('Long supporting content') ?? false)),
        ),
        findsOneWidget,
      );
    case 'toast':
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ((w.data?.startsWith('Reusable components') ?? false) ||
                  (w.data?.startsWith('Long supporting content') ?? false)),
        ),
        findsOneWidget,
      );
  }
}
