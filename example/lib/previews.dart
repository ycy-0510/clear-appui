import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/app_ui_showcase.dart';
import 'package:fossui_example/upstream_gallery.dart';

/// Floating groups and a transparent-to-frosted scroll edge.
@Preview(
  name: 'Floating top controls',
  group: 'AppUI / Navigation',
  size: Size(390, 844),
  wrapper: appPreviewWrapper,
)
Widget floatingTopControls() => AppTheme(
  data: AppThemeData.light,
  child: StatefulBuilder(
    builder: (context, update) => AppScaffold(
      topBar: AppTopBar(
        leading: AppTopBarAction(
          icon: const Text('‹'),
          label: 'Back',
          onPressed: () {},
        ),
        actions: [
          AppTopBarAction(
            icon: const Text('✎'),
            label: 'Edit',
            onPressed: () => update(() {}),
          ),
          AppTopBarAction(
            icon: const Text('⋯'),
            label: 'More',
            onPressed: () => update(() {}),
          ),
        ],
      ),
      body: Builder(
        builder: (context) => ListView(
          padding:
              MediaQuery.paddingOf(context) +
              context.appTheme.tokens.spacing.all(4),
          children: const [
            AppText('Library', role: AppTextRole.display),
            SizedBox(height: 16),
            AppCard(
              child: AppText(
                'Scroll behind the floating controls '
                'to reveal the frosted edge.',
              ),
            ),
            SizedBox(height: 1000),
          ],
        ),
      ),
    ),
  ),
);

/// Gives each preview an independent Navigator and its actual constrained size.
Widget appPreviewWrapper(Widget child) => WidgetsApp(
  debugShowCheckedModeBanner: false,
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: LayoutBuilder(
    builder: (context, limits) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(size: Size(limits.maxWidth, limits.maxHeight)),
      child: child,
    ),
  ),
);

/// Phone acceptance flow with interactive sheets, drag targets and pickers.
@Preview(
  name: '手機 · 淺色 · 390 × 844',
  group: 'AppUI / Course',
  size: Size(390, 844),
  wrapper: appPreviewWrapper,
)
Widget coursePhoneLight() => const AppCourseDemo(dark: false);

/// Dark phone acceptance flow.
@Preview(
  name: '手機 · 深色',
  group: 'AppUI / Course',
  size: Size(390, 844),
  wrapper: appPreviewWrapper,
)
Widget coursePhoneDark() => const AppCourseDemo(dark: true);

/// Tablet two-pane acceptance flow.
@Preview(
  name: '平板 · 雙欄',
  group: 'AppUI / Course',
  size: Size(1024, 768),
  wrapper: appPreviewWrapper,
)
Widget courseTablet() => const AppCourseDemo(dark: false);

/// Large text accessibility scenario.
@Preview(
  name: '手機 · 大字體',
  group: 'AppUI / Accessibility',
  size: Size(390, 844),
  textScaleFactor: 1.6,
  wrapper: appPreviewWrapper,
)
Widget courseLargeText() => const AppCourseDemo(dark: false);

/// Component states in light mode.
@Preview(
  name: '元件 · 淺色',
  group: 'AppUI / Components',
  size: Size(480, 760),
  wrapper: appPreviewWrapper,
)
Widget componentsLight() =>
    AppTheme(data: AppThemeData.light, child: const AppComponentGallery());

/// Component states in dark mode.
@Preview(
  name: '元件 · 深色',
  group: 'AppUI / Components',
  size: Size(480, 760),
  wrapper: appPreviewWrapper,
)
Widget componentsDark() =>
    AppTheme(data: AppThemeData.dark, child: const AppComponentGallery());

/// All 39 families remain selectable inside each independent preview.
@Preview(
  name: '完整元件庫 · 窄螢幕',
  group: 'AppUI / Full catalog',
  size: Size(320, 844),
  wrapper: appPreviewWrapper,
)
Widget catalogNarrow() => const ExampleApp(
  key: ValueKey('catalog-narrow'),
  initialComponent: 'tabs',
  dark: false,
);

/// Dark appearance with the same QA controls as the desktop gallery.
@Preview(
  name: '完整元件庫 · 深色',
  group: 'AppUI / Full catalog',
  size: Size(390, 844),
  wrapper: appPreviewWrapper,
)
Widget catalogDark() => const ExampleApp(
  key: ValueKey('catalog-dark'),
  initialComponent: 'otp_field',
  dark: true,
);

/// Wide catalog with searchable navigation and independent samples.
@Preview(
  name: '完整元件庫 · 桌面',
  group: 'AppUI / Full catalog',
  size: Size(1024, 768),
  wrapper: appPreviewWrapper,
)
Widget catalogDesktop() => const ExampleApp(
  key: ValueKey('catalog-desktop'),
  initialComponent: 'calendar',
  dark: false,
);
