import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/app_ui/components.dart';
import 'package:fossui/src/app_ui/foundation.dart';
import 'package:fossui/src/app_ui/interaction.dart';
import 'package:fossui/src/app_ui/layout.dart';
import 'package:fossui/src/app_ui/navigation.dart';
import 'package:fossui/src/app_ui/pickers.dart';
import 'package:fossui/src/app_ui/presentation.dart';

/// A small typed payload for the course-management acceptance scenario.
@immutable
class AppDemoCourse {
  /// Creates a course payload.
  const AppDemoCourse(this.id, this.name);

  /// Stable identity used for duplicate rejection.
  final String id;

  /// Human-readable course name.
  final String name;
}

/// Interactive acceptance page for layout, sheet, drag and adaptive pickers.
class AppCourseDemo extends StatefulWidget {
  /// Creates a resettable preview. Null brightness follows the system.
  const AppCourseDemo({this.dark, super.key});

  /// Explicit initial brightness for preview matrices.
  final bool? dark;
  @override
  State<AppCourseDemo> createState() => _AppCourseDemoState();
}

class _AppCourseDemoState extends State<AppCourseDemo> {
  static const _courses = [
    AppDemoCourse('cs101', '程式設計'),
    AppDemoCourse('design', '互動設計'),
    AppDemoCourse('math', '線性代數'),
    AppDemoCourse('systems', '作業系統'),
  ];
  final _scheduled = ValueNotifier<List<AppDemoCourse>>([]);
  bool? _dark;
  DateTime? _date;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _dark = widget.dark;
  }

  @override
  void dispose() {
    _scheduled.dispose();
    super.dispose();
  }

  bool _accepts(AppDemoCourse course) =>
      !_scheduled.value.any((c) => c.id == course.id);

  void _schedule(AppDemoCourse course) {
    if (_accepts(course)) _scheduled.value = [..._scheduled.value, course];
  }

  Future<void> _open(BuildContext context) => showAppSheet<void>(
    context: context,
    modal: false,
    builder: (_) => AppSheet(
      title: const AppText('安排課程', role: AppTextRole.title),
      builder: (context, scroll) => ValueListenableBuilder(
        valueListenable: _scheduled,
        builder: (context, _, _) => ListView.separated(
          controller: scroll,
          padding: context.appTheme.tokens.spacing.all(4),
          itemCount: _courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _course(context, _courses[index]),
        ),
      ),
    ),
  );

  Widget _course(BuildContext context, AppDemoCourse course) {
    final t = context.appTheme.tokens;
    final scheduled = !_accepts(course);
    final detail = switch (course.id) {
      'cs101' => 'CS101 · 核心基礎',
      'design' => 'DES201 · 設計實作',
      'math' => 'MATH102 · 核心基礎',
      _ => 'CS204 · 系統原理',
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        spacing: 12,
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(
              color: t.colors.accent,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: IconTheme(
                data: IconThemeData(color: t.colors.primary),
                child: const _DemoSymbol(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  course.name,
                  style: t.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: t.typography.xs.copyWith(
                    color: t.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.ghost,
            semanticLabel: scheduled ? '${course.name}已安排' : '安排${course.name}',
            onPressed: scheduled ? null : () => _schedule(course),
            child: Text(scheduled ? '已安排' : '安排'),
          ),
        ],
      ),
    );
    return AppDraggable<AppDemoCourse>(
      data: course,
      longPress:
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android,
      feedback: SizedBox(
        width: 260,
        child: AppCard(child: AppText(course.name)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: row),
      child: row,
    );
  }

  Widget _dateTarget(BuildContext context) => AppDropTarget<AppDemoCourse>(
    canAccept: _accepts,
    onAccept: _schedule,
    builder: (context, state) {
      final hovering = state == AppDropState.active;
      final t = context.appTheme.tokens;
      return AnimatedContainer(
        key: const ValueKey('course-drop-target'),
        duration: context.appMotion(t.motion.overlay),
        decoration: ShapeDecoration(
          color: hovering ? t.colors.accent : t.colors.card,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(
              color: hovering ? t.colors.primary : const Color(0x00000000),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(t.radii.xl2),
          ),
        ),
        padding: t.spacing.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText('日期區', role: AppTextRole.title),
            const SizedBox(height: 6),
            Text(
              '為課程留一段專注的時間',
              style: t.typography.sm.copyWith(color: t.colors.mutedForeground),
            ),
            const SizedBox(height: 16),
            AppDatePicker(
              selected: _date,
              onChanged: (value) => setState(() => _date = value),
            ),
            const SizedBox(height: 16),
            if (_scheduled.value.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  spacing: 8,
                  children: [
                    Text(
                      hovering ? '放開以安排課程' : '尚未安排課程',
                      style: t.typography.sm.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '從課程庫拖入，或點一下「安排」。',
                      textAlign: TextAlign.center,
                      style: t.typography.xs.copyWith(
                        color: t.colors.mutedForeground,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            for (final course in _scheduled.value)
              Row(
                spacing: 8,
                children: [
                  Expanded(child: AppText(course.name)),
                  AppButton(
                    variant: AppButtonVariant.ghost,
                    semanticLabel: '移除${course.name}',
                    onPressed: () => _scheduled.value = _scheduled.value
                        .where((c) => c.id != course.id)
                        .toList(),
                    child: const Text('移除'),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );

  Widget _coursePage(BuildContext context) {
    final t = context.appTheme.tokens;
    return AppConstrainedContent(
      maxWidth: 1040,
      child: ListView(
        key: const PageStorageKey('course-list'),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          AppAdaptiveLayout(
            primaryFlex: 3,
            secondaryFlex: 2,
            singleColumnSecondary: AppSecondaryPlacement.before,
            primary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        const AppText('課程庫', role: AppTextRole.title),
                        Text(
                          '4 門課程 · 拖曳即可安排',
                          style: t.typography.xs.copyWith(
                            color: t.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    AppButton(
                      onPressed: () {
                        if (AppPresentationHost.of(context).presentationCount ==
                            0) {
                          unawaited(_open(context));
                        }
                      },
                      child: const Text('安排課程'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _courses.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 56,
                            ),
                            child: ColoredBox(
                              color: t.colors.border,
                              child: const SizedBox(
                                height: 0.5,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        _course(context, _courses[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            secondary: _dateTarget(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        _dark ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return AppTheme(
      data: dark ? AppThemeData.dark : AppThemeData.light,
      child: AppPresentationHost(
        child: Builder(
          builder: (context) {
            final t = context.appTheme.tokens;
            return ValueListenableBuilder(
              valueListenable: _scheduled,
              builder: (context, _, _) => AppScaffold(
                topBar: AppConstrainedContent(
                  maxWidth: 1040,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              const AppText('課程工作台', role: AppTextRole.display),
                              Text(
                                '整理課程，安排每一天。',
                                style: t.typography.sm.copyWith(
                                  color: t.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          variant: AppButtonVariant.ghost,
                          onPressed: () => setState(() => _dark = !dark),
                          child: Text(dark ? '淺色' : '深色'),
                        ),
                      ],
                    ),
                  ),
                ),
                navigation: AppNavigationBar(
                  selectedIndex: _tab,
                  onSelected: (i) => setState(() => _tab = i),
                  items: const [
                    AppNavigationItem(label: '課程', icon: _DemoSymbol()),
                    AppNavigationItem(
                      label: '元件',
                      icon: _DemoSymbol(grid: true),
                    ),
                  ],
                ),
                body: IndexedStack(
                  index: _tab,
                  children: [
                    Builder(builder: _coursePage),
                    const AppConstrainedContent(
                      maxWidth: 1040,
                      child: AppComponentGallery(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DemoSymbol extends StatelessWidget {
  const _DemoSymbol({this.grid = false});
  final bool grid;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 22,
    child: CustomPaint(
      painter: _DemoSymbolPainter(
        color:
            IconTheme.of(context).color ??
            context.appTheme.tokens.colors.foreground,
        grid: grid,
      ),
    ),
  );
}

class _DemoSymbolPainter extends CustomPainter {
  const _DemoSymbolPainter({required this.color, required this.grid});
  final Color color;
  final bool grid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (grid) {
      for (final x in [3.0, 14.0]) {
        for (final y in [3.0, 14.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, 7, 7),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    } else {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 3, 16, 18),
            const Radius.circular(3),
          ),
          paint,
        )
        ..drawLine(const Offset(8, 3), const Offset(8, 21), paint)
        ..drawLine(const Offset(12, 8), const Offset(16, 8), paint)
        ..drawLine(const Offset(12, 12), const Offset(16, 12), paint);
    }
  }

  @override
  bool shouldRepaint(_DemoSymbolPainter oldDelegate) =>
      color != oldDelegate.color || grid != oldDelegate.grid;
}

/// A compact gallery for the initial AppUI component states.
class AppComponentGallery extends StatelessWidget {
  /// Creates a state gallery.
  const AppComponentGallery({super.key});
  @override
  Widget build(BuildContext context) {
    final t = context.appTheme.tokens;
    return AppConstrainedContent(
      maxWidth: 680,
      child: ListView(
        key: const PageStorageKey('component-gallery'),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          const AppText('元件與狀態', role: AppTextRole.heading),
          SizedBox(height: t.spacing(4)),
          AppCard(
            title: const AppText('按鈕', role: AppTextRole.title),
            child: Wrap(
              spacing: t.spacing(3),
              runSpacing: t.spacing(3),
              children: [
                for (final variant in AppButtonVariant.values)
                  AppButton(
                    variant: variant,
                    onPressed: () {},
                    child: Text(variant.name),
                  ),
                const AppButton(child: Text('Disabled')),
                const AppButton(loading: true, child: Text('Loading')),
              ],
            ),
          ),
          SizedBox(height: t.spacing(5)),
          const AppCard(
            title: AppText('輸入與驗證', role: AppTextRole.title),
            child: Column(
              spacing: 24,
              children: [
                AppTextField(label: '課程名稱', placeholder: '輸入課程名稱'),
                AppTextField(label: '驗證錯誤', errorText: '請輸入課程名稱'),
              ],
            ),
          ),
          SizedBox(height: t.spacing(5)),
          const AppEmptyState(message: '這裡還沒有課程'),
        ],
      ),
    );
  }
}
