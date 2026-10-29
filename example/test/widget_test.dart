import 'package:flutter_test/flutter_test.dart';
import 'package:fossui_example/app_ui_main.dart';

void main() {
  testWidgets('example opens the course acceptance page', (tester) async {
    await tester.pumpWidget(const AppUIExampleApp());
    expect(find.text('完整元件庫'), findsOneWidget);
    await tester.tap(find.text('課程互動'));
    await tester.pump();
    expect(find.text('課程工作台'), findsOneWidget);
    expect(find.text('安排課程'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
