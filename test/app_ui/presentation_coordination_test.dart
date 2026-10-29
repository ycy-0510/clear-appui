import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

import 'app_ui_test.dart' show host;

void main() {
  late BuildContext page;
  Future<void> boot(WidgetTester tester) => tester.pumpWidget(
    host(
      Builder(
        builder: (context) {
          page = context;
          return const SizedBox();
        },
      ),
    ),
  );
  Future<void> open() => showAppSheet<void>(
    context: page,
    builder: (_) => AppSheet(
      builder: (_, scroll) =>
          ListView(controller: scroll, children: const [Text('Editor')]),
    ),
  );

  testWidgets(
    'host count retains exiting containers and keyboard cancellation',
    (tester) async {
      await boot(tester);
      final controller = AppPresentationHost.of(page);
      final changes = <int>[];
      void listen() =>
          changes.add(controller.presentationCountListenable.value);
      controller.presentationCountListenable.addListener(listen);
      unawaited(open());
      await tester.pumpAndSettle();
      unawaited(open());
      await tester.pumpAndSettle();
      expect(changes, [1, 2]);
      controller.close();
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.presentationCountListenable.value, 2);
      await tester.pumpAndSettle();
      expect(controller.presentationCountListenable.value, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(changes, [1, 2, 1, 0]);
      controller.presentationCountListenable.removeListener(listen);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'background and disposal complete outstanding results',
    (tester) async {
      await boot(tester);
      final controller = AppPresentationHost.of(page);
      final result = open();
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(controller.presentationCountListenable.value, 0);
      await result;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final next = open();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await next;
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('asynchronous dismissal veto handles repeated Back and retry', (
    tester,
  ) async {
    await boot(tester);
    final controller = AppPresentationHost.of(page);
    var calls = 0;
    final pending = Completer<bool>();
    final result = showAppSheet<void>(
      context: page,
      onBeforeDismiss: () {
        calls++;
        return calls == 1 ? pending.future : Future.value(true);
      },
      builder: (_) =>
          AppSheet(builder: (_, scroll) => ListView(controller: scroll)),
    );
    await tester.pumpAndSettle();
    controller
      ..close()
      ..close();
    await Navigator.of(page).maybePop();
    await Navigator.of(page).maybePop();
    expect(calls, 1);
    expect(controller.presentationCount, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(controller.presentationCount, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await result;
    expect(calls, 2);
    expect(controller.presentationCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dismissal errors retain editors; disposal cancels pending checks',
    (tester) async {
      await boot(tester);
      final controller = AppPresentationHost.of(page);
      var fail = true;
      final pending = Completer<bool>();
      final result = showAppSheet<String>(
        context: page,
        onBeforeDismiss: () {
          if (fail) throw StateError('retry');
          return pending.future;
        },
        builder: (_) =>
            AppSheet(builder: (_, scroll) => ListView(controller: scroll)),
      );
      await tester.pumpAndSettle();
      controller.close();
      await tester.pump();
      expect(tester.takeException(), isStateError);
      expect(controller.presentationCount, 1);
      fail = false;
      controller.close();
      await tester.pumpWidget(const SizedBox());
      expect(await result, isNull);
      pending.complete(true);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
