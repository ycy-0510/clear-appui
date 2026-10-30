import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/app_ui_showcase.dart';
import 'package:fossui_example/upstream_gallery.dart';

/// Retained destinations, compact branding and two/four action transitions.
@Preview(
  name: 'Action capsule · 390',
  group: 'AppUI / Navigation',
  size: Size(390, 844),
  wrapper: appPreviewWrapper,
)
Widget crowdedTopControls() => const _ToolbarPreview();

/// The same shared controls at a smaller phone width.
@Preview(
  name: 'Action capsule · 320',
  group: 'AppUI / Navigation',
  size: Size(320, 844),
  wrapper: appPreviewWrapper,
)
Widget crowdedTopControlsNarrow() => const _ToolbarPreview();

/// Directional alignment and clipping during the same transitions.
@Preview(
  name: 'Action capsule · RTL',
  group: 'AppUI / Navigation',
  size: Size(390, 844),
  wrapper: appPreviewWrapper,
)
Widget crowdedTopControlsRtl() => const Directionality(
  textDirection: TextDirection.rtl,
  child: _ToolbarPreview(),
);

class _ToolbarPreview extends StatefulWidget {
  const _ToolbarPreview();

  @override
  State<_ToolbarPreview> createState() => _ToolbarPreviewState();
}

class _ToolbarPreviewState extends State<_ToolbarPreview> {
  int index = 0;
  int taps = 0;

  @override
  Widget build(BuildContext context) => AppTheme(
    child: AppScaffold(
      topBar: AppTopBar(
        actions: [
          for (var i = 0; i < (index == 0 ? 2 : 4); i++)
            AppTopBarAction(
              icon: SizedBox.square(
                dimension: 20,
                child: Center(child: Text(['↥', '+', '⌕', '⚙'][i])),
              ),
              label: 'Action ${i + 1}',
              onPressed: () => setState(() => taps++),
            ),
        ],
      ),
      body: AppNavigationBody(
        index: index,
        children: [
          _page(brand: true),
          _page(brand: false),
        ],
      ),
      navigation: AppNavigationBar(
        selectedIndex: index,
        onSelected: (value) => setState(() => index = value),
        items: const [
          AppNavigationItem(label: 'Home', icon: Text('A')),
          AppNavigationItem(label: 'Dictionary', icon: Text('B')),
        ],
      ),
    ),
  );

  Widget _page({required bool brand}) => Builder(
    builder: (context) => ListView(
      padding:
          MediaQuery.paddingOf(context) +
          context.appTheme.tokens.spacing.all(4),
      children: [
        if (brand)
          const AppCollapsingTitle(
            collapsed: AppText('Brand', role: AppTextRole.title),
            child: SizedBox(
              height: 100,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppText('Brand', role: AppTextRole.display),
              ),
            ),
          )
        else
          const AppText('Dictionary', role: AppTextRole.heading),
        AppText('Action taps: $taps'),
        const SizedBox(height: 16),
        for (var i = 0; i < 12; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(child: AppText('Item ${i + 1}')),
          ),
      ],
    ),
  );
}

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
