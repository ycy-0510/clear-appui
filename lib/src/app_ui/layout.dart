import 'package:flutter/widgets.dart';
import 'package:fossui/src/app_ui/foundation.dart';

/// Width categories determined by available logical pixels.
enum AppSizeClass {
  /// Below 600 logical pixels.
  compact,

  /// From 600 through 839 logical pixels.
  medium,

  /// At least 840 logical pixels.
  expanded,
}

/// Shared measurements for a constrained content area.
@immutable
class AppLayoutEnvironment {
  /// Creates an immutable environment snapshot.
  const AppLayoutEnvironment({
    required this.size,
    this.safeArea = EdgeInsets.zero,
    this.keyboardInsets = EdgeInsets.zero,
  });

  /// Actual space allocated by the parent.
  final Size size;

  /// Operating-system safe regions.
  final EdgeInsets safeArea;

  /// Current keyboard occlusion.
  final EdgeInsets keyboardInsets;

  /// Size category based on available width rather than device model.
  AppSizeClass get sizeClass => size.width < 600
      ? AppSizeClass.compact
      : size.width < 840
      ? AppSizeClass.medium
      : AppSizeClass.expanded;
}

/// Explicit layout preference with a safe space-constrained fallback.
enum AppColumnMode {
  /// Choose based on usable width.
  automatic,

  /// Always use one pane.
  single,

  /// Prefer two panes when both can fit.
  two,
}

/// Constrains a page's maximum line length without identifying device types.
class AppConstrainedContent extends StatelessWidget {
  /// Creates bounded content.
  const AppConstrainedContent({required this.child, this.maxWidth, super.key});

  /// Content to constrain.
  final Widget child;

  /// Optional maximum width override.
  final double? maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? context.appTheme.dimensions.contentWidth,
      ),
      child: child,
    ),
  );
}

/// Placement of supplementary content when two usable panes cannot fit.
enum AppSecondaryPlacement {
  /// Leave detail navigation to the product.
  hidden,

  /// Put supplementary content before the primary content.
  before,

  /// Put supplementary content after the primary content.
  after,
}

/// Switches between one and two independently usable panes.
class AppAdaptiveLayout extends StatelessWidget {
  /// Creates a layout measured from its parent constraints.
  const AppAdaptiveLayout({
    required this.primary,
    this.secondary,
    this.mode = AppColumnMode.automatic,
    this.minColumnWidth,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.singleColumnSecondary = AppSecondaryPlacement.hidden,
    super.key,
  }) : assert(primaryFlex > 0, 'primaryFlex must be positive.'),
       assert(secondaryFlex > 0, 'secondaryFlex must be positive.');

  /// Always visible primary pane.
  final Widget primary;

  /// Secondary pane, shown only when enough space is available.
  final Widget? secondary;

  /// Explicit pane preference.
  final AppColumnMode mode;

  /// Minimum usable pane width override.
  final double? minColumnWidth;

  /// Primary pane width proportion.
  final int primaryFlex;

  /// Secondary pane width proportion.
  final int secondaryFlex;

  /// Single-column placement for intrinsically sized supplementary content.
  final AppSecondaryPlacement singleColumnSecondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limits) {
      final theme = context.appTheme;
      final gap = theme.tokens.spacing(4);
      final minWidth = minColumnWidth ?? theme.dimensions.minColumnWidth;
      final width = limits.hasBoundedWidth
          ? limits.maxWidth
          : MediaQuery.sizeOf(context).width;
      final smallestPane =
          (width - gap) *
          (primaryFlex < secondaryFlex ? primaryFlex : secondaryFlex) /
          (primaryFlex + secondaryFlex);
      final two =
          secondary != null &&
          mode != AppColumnMode.single &&
          smallestPane >= minWidth &&
          (mode == AppColumnMode.two || width >= 600);
      if (!two &&
          secondary != null &&
          singleColumnSecondary != AppSecondaryPlacement.hidden) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (singleColumnSecondary == AppSecondaryPlacement.before) ...[
              secondary!,
              SizedBox(height: gap),
            ],
            primary,
            if (singleColumnSecondary == AppSecondaryPlacement.after) ...[
              SizedBox(height: gap),
              secondary!,
            ],
          ],
        );
      }
      return two
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: primaryFlex, child: primary),
                SizedBox(width: gap),
                Expanded(flex: secondaryFlex, child: secondary!),
              ],
            )
          : primary;
    },
  );
}

/// A lazy grid that chooses its column count from the available width.
class AppAdaptiveGrid extends StatelessWidget {
  /// Creates a lazy content grid.
  const AppAdaptiveGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.maxItemWidth = 360,
    this.childAspectRatio = 1,
    super.key,
  });

  /// Number of items.
  final int itemCount;

  /// Builds visible items lazily.
  final IndexedWidgetBuilder itemBuilder;

  /// Desired maximum item width.
  final double maxItemWidth;

  /// Width divided by height for grid items.
  final double childAspectRatio;
  @override
  Widget build(BuildContext context) => GridView.builder(
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxItemWidth,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: context.appTheme.tokens.spacing(4),
      crossAxisSpacing: context.appTheme.tokens.spacing(4),
    ),
  );
}
