import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/app_ui/platform.dart';

/// Height-driven floating sheet materials, inspired by iOS 26 presentations.
@immutable
class AppSheetStyle {
  /// Creates configurable product values; these are not Apple's fixed metrics.
  const AppSheetStyle({
    this.floatingMargin = 16,
    this.radius = 28,
    this.minimumOpacity = 0.72,
    this.blurSigma = 20,
    this.transitionCurve = Curves.easeInOutCubic,
  }) : assert(floatingMargin >= 0, 'Margin cannot be negative.'),
       assert(radius >= 0, 'Radius cannot be negative.'),
       assert(
         minimumOpacity >= 0 && minimumOpacity <= 1,
         'Opacity must be in [0, 1].',
       ),
       assert(blurSigma >= 0, 'Blur cannot be negative.');

  /// Floating inset at the smallest configured detent.
  final double floatingMargin;

  /// Continuous corner radius while floating.
  final double radius;

  /// Surface opacity at the smallest height.
  final double minimumOpacity;

  /// Frosted background blur before the panel becomes opaque.
  final double blurSigma;

  /// Smooth material and geometry interpolation across the available height.
  final Curve transitionCurve;

  double _progress(double extent, double minimumExtent) => minimumExtent >= 1
      ? 1
      : transitionCurve.transform(
          ((extent - minimumExtent) / (1 - minimumExtent)).clamp(0.0, 1.0),
        );

  /// Insets diminish smoothly through expansion, reaching zero at full height.
  double marginAt(double extent, {required double minimumExtent}) =>
      floatingMargin * (1 - _progress(extent, minimumExtent));

  /// Larger surfaces become more opaque to support reading and focused work.
  double opacityAt(double extent, {required double minimumExtent}) =>
      minimumOpacity + (1 - minimumOpacity) * _progress(extent, minimumExtent);
}

/// Product-specific motion tokens extending the existing overlay durations.
@immutable
class AppMotion {
  /// Creates a motion scale.
  const AppMotion({
    this.press = const Duration(milliseconds: 100),
    this.pressedScale = 0.97,
  });

  /// Short press feedback duration.
  final Duration press;

  /// Scale while a pointer remains over an enabled action.
  final double pressedScale;
}

/// Shared layout and interaction dimensions, in logical pixels.
@immutable
class AppDimensions {
  /// Creates an overridable dimension scale.
  const AppDimensions({
    this.touchTarget = 48,
    this.contentWidth = 1200,
    this.minColumnWidth = 280,
    this.navigationExtent = 88,
  });

  /// Smallest interactive target.
  final double touchTarget;

  /// Maximum readable page width.
  final double contentWidth;

  /// Smallest usable pane width.
  final double minColumnWidth;

  /// Space reserved at the bottom for floating navigation.
  final double navigationExtent;
}

// Product density is adapted through FossTheme's existing token engine.
FossThemeData _productTokens(FossThemeData base) {
  final t = base.typography;
  return base.copyWith(
    typography: t.copyWith(
      xs: t.xs.copyWith(fontSize: 12, height: 16 / 12),
      sm: t.sm.copyWith(fontSize: 13, height: 18 / 13),
      base: t.base.copyWith(fontSize: 15, height: 22 / 15),
      lg: t.lg.copyWith(fontSize: 17, height: 24 / 17),
      xl: t.xl.copyWith(fontSize: 20, height: 26 / 20),
      xl2: t.xl2.copyWith(fontSize: 22, height: 28 / 22),
    ),
  );
}

/// One source for product tokens and their FossUI adapter.
@immutable
class AppThemeData {
  /// Creates a theme from the existing token engine.
  const AppThemeData({
    required this.tokens,
    this.dimensions = const AppDimensions(),
    this.motion = const AppMotion(),
    this.haptics = const AppHaptics(),
    this.sheet = const AppSheetStyle(),
  });

  /// Light product palette, derived through the shared FossUI token engine.
  static final light = AppThemeData(
    tokens: _productTokens(
      FossThemeData.light.retheme(
        const FossThemeSpec(
          primary: Color(0xFF0060D6),
          primaryForeground: Color(0xFFFFFFFF),
          ring: Color(0xFF0060D6),
          radius: 14,
        ),
      ),
    ),
  );

  /// Dark product palette, with separate content and floating surfaces.
  static final dark = AppThemeData(
    tokens: _productTokens(
      FossThemeData.dark.retheme(
        const FossThemeSpec(
          background: Color(0xFF101012),
          card: Color(0xFF1C1C1E),
          popover: Color(0xFF2C2C2E),
          primary: Color(0xFF80B8FF),
          primaryForeground: Color(0xFF071B36),
          ring: Color(0xFF80B8FF),
          mutedForeground: Color(0xFF98989F),
          radius: 14,
        ),
      ),
    ),
  );

  /// The fork's shared token source; no duplicated color palette.
  final FossThemeData tokens;

  /// Product layout dimensions.
  final AppDimensions dimensions;

  /// Product-specific motion values.
  final AppMotion motion;

  /// Injectable platform feedback adapter.
  final AppHaptics haptics;

  /// Height-driven sheet margins, shape and translucent surface.
  final AppSheetStyle sheet;

  /// Returns a locally overridable theme.
  AppThemeData copyWith({
    FossThemeData? tokens,
    AppDimensions? dimensions,
    AppMotion? motion,
    AppHaptics? haptics,
    AppSheetStyle? sheet,
  }) => AppThemeData(
    tokens: tokens ?? this.tokens,
    dimensions: dimensions ?? this.dimensions,
    motion: motion ?? this.motion,
    haptics: haptics ?? this.haptics,
    sheet: sheet ?? this.sheet,
  );
}

/// Provides AppUI and FossUI with the same theme.
class AppTheme extends StatelessWidget {
  /// Creates a theme scope. Null [data] follows system brightness.
  const AppTheme({required this.child, this.data, super.key});

  /// Theme override, or the system-selected theme.
  final AppThemeData? data;

  /// The themed subtree.
  final Widget child;

  /// Reads the nearest product theme.
  static AppThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppThemeScope>()?.data ??
      (MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
          ? AppThemeData.dark
          : AppThemeData.light);

  @override
  Widget build(BuildContext context) {
    final resolved =
        data ??
        (MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
            ? AppThemeData.dark
            : AppThemeData.light);
    return _AppThemeScope(
      data: resolved,
      child: FossTheme(
        data: resolved.tokens,
        child: DefaultTextStyle(
          style: resolved.tokens.typography.base.copyWith(
            color: resolved.tokens.colors.foreground,
            decoration: TextDecoration.none,
          ),
          child: IconTheme(
            data: IconThemeData(color: resolved.tokens.colors.foreground),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppThemeScope extends InheritedWidget {
  const _AppThemeScope({required this.data, required super.child});
  final AppThemeData data;

  @override
  bool updateShouldNotify(_AppThemeScope oldWidget) => data != oldWidget.data;
}

/// Product accessors for tokens and motion preferences.
extension AppUIContext on BuildContext {
  /// Current product theme.
  AppThemeData get appTheme => AppTheme.of(this);

  /// Suppresses optional motion when requested by the operating system.
  Duration appMotion(Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false
      ? Duration.zero
      : duration;
}
