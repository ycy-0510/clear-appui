import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/app_ui_showcase.dart';

Widget host(Widget child, {AppThemeData? data}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: AppTheme(
    data: data,
    child: AppPresentationHost(child: child),
  ),
);

void main() {
  test('size classes use available width and exact boundaries', () {
    for (final (width, expected) in [
      (599.0, AppSizeClass.compact),
      (600.0, AppSizeClass.medium),
      (839.0, AppSizeClass.medium),
      (840.0, AppSizeClass.expanded),
    ]) {
      expect(AppLayoutEnvironment(size: Size(width, 800)).sizeClass, expected);
    }
  });

  test('detents clamp fixed heights and reject unusable environments', () {
    expect(const AppSheetDetent.pixels(200).resolve(800), 0.25);
    expect(const AppSheetDetent.pixels(900).resolve(800), 1);
    expect(AppSheetDetent.medium.resolve(400), 0.5);
    expect(() => AppSheetDetent.large.resolve(0), throwsArgumentError);
    expect(
      () => AppSheetDetent.large.resolve(double.infinity),
      throwsArgumentError,
    );
  });

  test('drag sessions reject overlap and do not overwrite cancellation', () {
    final drag = AppDragCoordinator();
    addTearDown(drag.dispose);
    expect(drag.begin('course', source: 'source'), isTrue);
    expect(drag.begin('other', source: 'second'), isFalse);
    drag
      ..cancel()
      ..accept();
    expect(drag.session!.state, AppDragState.cancelled);
    expect(drag.begin('next', source: 'source'), isTrue);
    drag.accept();
    expect(drag.session!.state, AppDragState.accepted);
  });

  testWidgets(
    'async button prevents duplicate submission and recovers from error',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      Object? error;
      await tester.pumpWidget(
        host(
          Center(
            child: AppButton(
              onPressed: () {
                calls++;
                return pending.future;
              },
              onError: (value, _) => error = value,
              child: const Text('Save'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Save'));
      expect(calls, 1);
      await tester.pump();
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(error, isA<StateError>());
      expect(find.text('Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'press moving outside restores scale without triggering the action',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          Center(
            child: AppButton(
              onPressed: () => calls++,
              child: const Text('Press'),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Press')),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        AppThemeData.light.motion.pressedScale,
      );
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(calls, 0);
    },
  );

  testWidgets('layout uses parent width and protects the smaller ratio pane', (
    tester,
  ) async {
    Widget layout(double width, {int ratio = 1}) => host(
      Center(
        child: SizedBox(
          width: width,
          child: AppAdaptiveLayout(
            primaryFlex: ratio,
            primary: const Text('Primary'),
            secondary: const Text('Secondary'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(layout(390));
    expect(find.text('Secondary'), findsNothing);
    await tester.pumpWidget(layout(700));
    expect(find.text('Secondary'), findsOneWidget);
    await tester.pumpWidget(layout(700, ratio: 3));
    expect(find.text('Secondary'), findsNothing);
  });

  testWidgets(
    'sheet supports initial height, programmatic snap and typed result',
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
      final result = showAppSheet<String>(
        context: context,
        builder: (_) => AppSheet(
          controller: controller,
          builder: (_, scroll) => ListView(
            controller: scroll,
            children: const [Text('Sheet content')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.extent, closeTo(0.5, 0.01));
      unawaited(controller.snapTo(AppSheetDetent.large));
      await tester.pumpAndSettle();
      expect(controller.extent, closeTo(1, 0.01));
      AppPresentationHost.of(context).close('done');
      await tester.pumpAndSettle();
      expect(await result, 'done');
      expect(find.text('Sheet content'), findsNothing);
    },
  );

  testWidgets('modal sheet payload reaches a target behind its barrier', (
    tester,
  ) async {
    String? received;
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (ctx) {
            context = ctx;
            return Align(
              alignment: Alignment.topCenter,
              child: AppDropTarget<String>(
                onAccept: (value) => received = value,
                builder: (_, hovering) => const SizedBox(
                  width: 250,
                  height: 100,
                  child: Text('Destination'),
                ),
              ),
            );
          },
        ),
      ),
    );
    unawaited(
      showAppSheet<void>(
        context: context,
        builder: (_) => AppSheet(
          builder: (_, scroll) => ListView(
            controller: scroll,
            children: const [
              AppDraggable<String>(
                data: 'course-1',
                longPress: false,
                feedback: Text('Floating preview'),
                child: SizedBox(height: 60, child: Text('Drag source')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Drag source')),
    );
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Destination')));
    await tester.pump();
    expect(find.text('Floating preview'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(received, 'course-1');
    expect(find.byType(AppSheet), findsOneWidget);
    expect(AppDragScope.of(context).session!.state, AppDragState.accepted);
  });

  testWidgets('Escape cancels a drag and prevents a later drop', (
    tester,
  ) async {
    String? received;
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (ctx) {
            context = ctx;
            return Column(
              children: [
                AppDropTarget<String>(
                  onAccept: (value) => received = value,
                  builder: (_, _) => const SizedBox(
                    height: 100,
                    width: 200,
                    child: Text('Target'),
                  ),
                ),
                const AppDraggable<String>(
                  data: 'item',
                  longPress: false,
                  feedback: Text('Preview'),
                  child: SizedBox(
                    height: 100,
                    width: 200,
                    child: Text('Source'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Source')),
    );
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    Actions.invoke(
      tester.element(find.byType(AppDraggable<String>)),
      const DismissIntent(),
    );
    await tester.pump();
    expect(find.text('Preview'), findsNothing);
    await gesture.moveTo(tester.getCenter(find.text('Target')));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(received, isNull);
    expect(AppDragScope.of(context).session!.state, AppDragState.cancelled);
  });

  testWidgets('backgrounding completes sheets and clears their local history', (
    tester,
  ) async {
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
    final future = showAppSheet<void>(
      context: context,
      builder: (_) => AppSheet(
        builder: (_, scroll) =>
            ListView(controller: scroll, children: const [Text('Open sheet')]),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(AppPresentationHost.of(context).presentationCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await future;
    expect(find.text('Open sheet'), findsNothing);
    expect(AppPresentationHost.of(context).presentationCount, 0);
  });

  testWidgets('compact picker opens a sheet and keyboard Escape closes it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(Center(child: AppDatePicker(selected: null, onChanged: (_) {}))),
    );
    await tester.tap(find.text('選擇日期'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSheet), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AppSheet), findsNothing);
  });

  testWidgets('course acceptance page fits phone, tablet and large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(390, 844),
      const Size(600, 844),
      const Size(607, 844),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(host(const AppCourseDemo()));
      expect(find.text('日期區'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.6),
          ),
          child: const AppCourseDemo(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination switching preserves in-progress form input', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AppCourseDemo()));
    await tester.tap(find.text('元件'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, '保留內容');
    await tester.tap(find.text('課程'));
    await tester.pump();
    expect(find.text('日期區'), findsOneWidget);
    await tester.tap(find.text('元件'));
    await tester.pump();
    expect(find.text('保留內容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
