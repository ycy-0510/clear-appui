import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

void main() {
  testWidgets('headings and adjacent actions have separate semantic nodes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: AppTheme(
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppText('Vocabulary', role: AppTextRole.heading),
                  AppButton(onPressed: () {}, child: const Text('Reveal')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final heading = find.bySemanticsLabel('Vocabulary');
    final action = find.bySemanticsLabel('Reveal');
    expect(heading, findsOneWidget);
    expect(action, findsOneWidget);
    final headingNode = tester.getSemantics(heading);
    final actionNode = tester.getSemantics(action);
    expect(headingNode.id, isNot(actionNode.id));
    expect(headingNode.flagsCollection.isHeader, isTrue);
    expect(
      headingNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(actionNode.flagsCollection.isButton, isTrue);
    expect(actionNode.flagsCollection.isHeader, isFalse);
    expect(
      actionNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });
}
