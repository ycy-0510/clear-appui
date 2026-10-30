import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';

import 'app_ui_test.dart' show host;

void main() {
  testWidgets('form fields, errors and actions retain visible sibling gaps', (
    tester,
  ) async {
    final failed = ValueNotifier(false);
    addTearDown(failed.dispose);
    await tester.pumpWidget(
      host(
        ValueListenableBuilder(
          valueListenable: failed,
          builder: (_, error, _) => AppFormBody(
            children: [
              const AppTextField(key: ValueKey('name'), label: 'Name'),
              if (error)
                const AppText(key: ValueKey('error'), 'Please try again.'),
              AppButton(
                key: const ValueKey('secondary'),
                variant: AppButtonVariant.secondary,
                onPressed: () {},
                child: const Text('Add'),
              ),
              AppButton(
                key: const ValueKey('primary'),
                onPressed: () {},
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
    void verify(List<String> keys) {
      final rects = keys
          .map((key) => tester.getRect(find.byKey(ValueKey(key))))
          .toList();
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].top - rects[i - 1].bottom, 16);
        expect(rects[i].left, rects[0].left);
        expect(rects[i].right, rects[0].right);
      }
    }

    verify(['name', 'secondary', 'primary']);
    failed.value = true;
    await tester.pump();
    verify(['name', 'error', 'secondary', 'primary']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet form scrolls above keyboard at large text and cancels', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 520)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BuildContext page;
    ScrollController? supplied;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox();
          },
        ),
      ),
    );
    Future<bool?> open() => showAppSheet<bool>(
      context: page,
      builder: (_) => MediaQuery(
        data: MediaQuery.of(page).copyWith(
          viewInsets: const EdgeInsets.only(bottom: 180),
          textScaler: TextScaler.linear(1.8),
        ),
        child: AppSheet(
          initialDetent: AppSheetDetent.large,
          builder: (context, scroll) {
            supplied = scroll;
            return AppFormBody(
              controller: scroll,
              children: [
                for (var i = 0; i < 3; i++) AppTextField(label: 'Field $i'),
                const AppText(
                  'The draft is retained. Please correct the name.',
                ),
                AppButton(
                  key: const ValueKey('save'),
                  onPressed: () => AppPresentationHost.of(context).close(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      ),
    );
    final result = open();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save')));
    await tester.pumpAndSettle();
    expect(supplied!.offset, greaterThan(0));
    expect(
      tester.getRect(find.byKey(const ValueKey('save'))).bottom,
      lessThanOrEqualTo(520 - 180 - 16),
    );
    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.pumpAndSettle();
    expect(await result, true);
    final cancelled = open();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await cancelled, isNull);
    expect(tester.takeException(), isNull);
  });
}
