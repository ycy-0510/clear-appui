import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/app_ui/components.dart';
import 'package:fossui/src/app_ui/foundation.dart';
import 'package:fossui/src/app_ui/platform.dart';

// Duration.zero AnimatedSize can dirty layout in the pinned SDK. Reduced motion
// lays out the final geometry directly instead of running a zero-length ticker.
Widget _animateChromeSize(
  BuildContext context, {
  required Widget child,
  required AlignmentGeometry alignment,
}) {
  final duration = context.appMotion(context.appTheme.tokens.motion.overlay);
  return duration == Duration.zero
      ? child
      : AnimatedSize(
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: alignment,
          child: child,
        );
}

/// Whether navigation reserves reachable scroll space or covers content.
enum AppNavigationMode {
  /// Advertises bottom padding through MediaQuery for scrollable content.
  reservedSpace,

  /// Covers content without advertising extra padding.
  overlay,
}

/// A labelled action in a floating top control group.
@immutable
class AppTopBarAction {
  /// Creates an icon action. A null callback disables it.
  const AppTopBarAction({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  /// Decorative icon; [label] names its action for assistive technology.
  final Widget icon;

  /// Accessible action name.
  final String label;

  /// Guarded action callback.
  final FutureOr<void> Function()? onPressed;
}

/// Separate floating leading and trailing controls with an unpainted gap.
///
/// The trailing actions share one opaque capsule. Place the page title in its
/// content. AppScaffold supplies the scroll-driven frosted backdrop behind it.
class AppTopBar extends StatelessWidget {
  /// Creates route-level floating controls.
  const AppTopBar({this.leading, this.actions = const [], super.key});

  /// Optional leading action, usually Back or Close.
  final AppTopBarAction? leading;

  /// Trailing actions sharing a single floating surface.
  final List<AppTopBarAction> actions;

  Widget _button(AppTopBarAction action) => AppButton(
    key: ValueKey('app-top-action-${action.label}'),
    variant: AppButtonVariant.ghost,
    semanticLabel: action.label,
    onPressed: action.onPressed,
    child: action.icon,
  );

  Widget _group(BuildContext context, Key key, List<AppTopBarAction> items) {
    final t = context.appTheme.tokens;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: key,
        decoration: ShapeDecoration(
          color: t.colors.card,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: t.colors.border),
          ),
          shadows: [
            BoxShadow(
              color: t.colors.foreground.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _animateChromeSize(
          context,
          alignment: AlignmentDirectional.centerEnd,
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(999),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IconTheme.merge(
                data: const IconThemeData(size: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map(_button).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = context.findAncestorStateOfType<_AppScaffoldState>();
    if (scaffold == null) return _build(context, null);
    return ValueListenableBuilder<_CollapsedTitle?>(
      valueListenable: scaffold._collapsedTitle,
      builder: (context, title, _) => _build(context, title),
    );
  }

  Widget _build(BuildContext context, _CollapsedTitle? title) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.appTheme.tokens.spacing(4),
      vertical: context.appTheme.tokens.spacing(2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (leading case final action?)
          _group(context, const ValueKey('app-top-leading'), [action]),
        if (title != null)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: leading == null ? 0 : context.appTheme.tokens.spacing(3),
                end: context.appTheme.tokens.spacing(3),
              ),
              child: SizedBox(
                height: context.appTheme.dimensions.touchTarget,
                child: ClipRect(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: title.amount),
                    duration: context.appMotion(context.appTheme.motion.press),
                    builder: (context, amount, child) => IgnorePointer(
                      child: ExcludeFocus(
                        child: ExcludeSemantics(
                          excluding: title.amount < .5,
                          child: Opacity(
                            key: const ValueKey('app-collapsed-title'),
                            opacity: amount,
                            alwaysIncludeSemantics: true,
                            child: Transform.scale(
                              scale: 1.15 - .15 * amount,
                              alignment: AlignmentDirectional.centerStart,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: title.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (actions.isNotEmpty)
          Flexible(
            fit: title == null ? FlexFit.tight : FlexFit.loose,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: context.appTheme.tokens.spacing(3),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _group(
                  context,
                  const ValueKey('app-top-trailing'),
                  actions,
                ),
              ),
            ),
          )
        else if (title == null)
          const Spacer(),
      ],
    ),
  );
}

/// A scrolling title or brandmark that gains a compact copy in [AppTopBar]
/// as its expanded content passes behind the measured top chrome.
///
/// Keep both widgets noninteractive. The nearest [AppScaffold] owns geometry,
/// motion and semantics; retained, inactive navigation pages do not contribute.
class AppCollapsingTitle extends StatefulWidget {
  /// Creates the expanded content and its compact navigation representation.
  const AppCollapsingTitle({
    required this.child,
    required this.collapsed,
    super.key,
  });

  /// Original title in the page's scroll content.
  final Widget child;

  /// Compact title or artwork for the top bar, without another surface/inset.
  final Widget collapsed;

  @override
  State<AppCollapsingTitle> createState() => _AppCollapsingTitleState();
}

class _AppCollapsingTitleState extends State<AppCollapsingTitle> {
  _AppScaffoldState? _host;
  bool _active = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = context.findAncestorStateOfType<_AppScaffoldState>();
    if (_host != host) {
      _host?._titles.remove(this);
      _host?._scheduleTitleUpdate();
      _host = host;
      host?._titles.add(this);
    }
    _active = TickerMode.valuesOf(context).enabled;
    host?._scheduleTitleUpdate();
  }

  @override
  void didUpdateWidget(AppCollapsingTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _host?._scheduleTitleUpdate();
  }

  @override
  void dispose() {
    _host?._titles.remove(this);
    _host?._scheduleTitleUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = _host;
    if (host == null) return widget.child;
    return ValueListenableBuilder<_CollapsedTitle?>(
      valueListenable: host._collapsedTitle,
      child: widget.child,
      builder: (context, title, child) => ExcludeSemantics(
        excluding: identical(title?.source, this) && title!.amount >= .5,
        child: child,
      ),
    );
  }
}

class _CollapsedTitle {
  const _CollapsedTitle(this.source, this.child, this.amount);
  final _AppCollapsingTitleState? source;
  final Widget child;
  final double amount;
}

/// Shared page chrome, safe areas, keyboard handling and floating navigation.
class AppScaffold extends StatefulWidget {
  /// Creates a page. Scroll views should consume MediaQuery padding.
  const AppScaffold({
    required this.body,
    this.topBar,
    this.navigation,
    this.navigationMode = AppNavigationMode.reservedSpace,
    super.key,
  });

  /// Main content; may paint behind both top and bottom controls.
  final Widget body;

  /// Floating top content with a transparent-to-frosted scroll edge.
  final Widget? topBar;

  /// Floating bottom navigation.
  final Widget? navigation;

  /// Defines bottom-space behavior explicitly.
  final AppNavigationMode navigationMode;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _scrollOffset = ValueNotifier<double>(0);
  final _collapsedTitle = ValueNotifier<_CollapsedTitle?>(null);
  final _titles = <_AppCollapsingTitleState>{};
  bool _titleUpdateScheduled = false;
  double _topHeight = 0;

  void _scheduleTitleUpdate() {
    if (!mounted || _titleUpdateScheduled) return;
    _titleUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleUpdateScheduled = false;
      if (!mounted) return;
      final host = context.findRenderObject();
      if (host is! RenderBox || !host.hasSize) return;
      final edge = MediaQuery.paddingOf(context).top + _topHeight;
      final active = _titles.where((title) => title.mounted && title._active);
      final title = active.firstOrNull;
      final previous = _collapsedTitle.value;
      if (title == null || widget.topBar == null) {
        if (previous != null && previous.amount != 0) {
          _collapsedTitle.value = _CollapsedTitle(null, previous.child, 0);
        }
        return;
      }
      final box = title.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || box.size.height <= 0) return;
      final top = box.localToGlobal(Offset.zero, ancestor: host).dy;
      final amount = ((edge - top) / box.size.height).clamp(0.0, 1.0);
      if (previous?.source != title ||
          previous?.child != title.widget.collapsed ||
          previous?.amount != amount) {
        _collapsedTitle.value = _CollapsedTitle(
          title,
          title.widget.collapsed,
          amount,
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _setScrollOffset(double offset) {
    _scrollOffset.value = math.max(0, offset);
    _scheduleTitleUpdate();
  }

  bool _observeScroll(ScrollNotification notification) {
    final source = notification.context;
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical &&
        source != null &&
        source.findAncestorStateOfType<_AppScaffoldState>() == this &&
        TickerMode.getValuesNotifier(source).value.enabled) {
      _setScrollOffset(
        notification.metrics.pixels - notification.metrics.minScrollExtent,
      );
    }
    return false;
  }

  bool _observeMetrics(ScrollMetricsNotification notification) {
    final source = notification.context;
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical &&
        source.findAncestorStateOfType<_AppScaffoldState>() == this &&
        TickerMode.getValuesNotifier(source).value.enabled) {
      _setScrollOffset(
        notification.metrics.pixels - notification.metrics.minScrollExtent,
      );
    }
    return false;
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _collapsedTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final media = MediaQuery.of(context);
    final navigation = widget.navigation;
    final keyboard = media.viewInsets.bottom > 0;
    final compactIOS =
        navigation is AppNavigationBar &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        media.size.shortestSide < 600;
    final navigationBottom = compactIOS
        ? theme.dimensions.compactNavigationBottomMargin
        : media.padding.bottom + theme.tokens.spacing(3);
    final bottom =
        navigation != null &&
            !keyboard &&
            widget.navigationMode == AppNavigationMode.reservedSpace
        ? navigation is AppNavigationBar
              ? math.max(
                  theme.dimensions.navigationExtent,
                  AppNavigationBar.heightOf(context) +
                      navigationBottom +
                      theme.tokens.spacing(3),
                )
              : theme.dimensions.navigationExtent + media.padding.bottom
        : keyboard
        ? 0.0
        : media.padding.bottom;
    return ColoredBox(
      color: theme.tokens.colors.background,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: NotificationListener<_AppPageScrollNotification>(
                onNotification: (notification) {
                  _setScrollOffset(notification.offset);
                  return true;
                },
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: _observeMetrics,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _observeScroll,
                    child: MediaQuery(
                      data: media.copyWith(
                        padding: EdgeInsets.only(
                          top:
                              media.padding.top +
                              (widget.topBar == null ? 0 : _topHeight),
                          bottom: bottom,
                        ),
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: widget.body,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.topBar case final topBar?)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ValueListenableBuilder<double>(
                            valueListenable: _scrollOffset,
                            builder: (context, offset, _) =>
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    end: (offset / theme.tokens.spacing(12))
                                        .clamp(0.0, 1.0),
                                  ),
                                  duration: context.appMotion(
                                    theme.motion.press,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, amount, _) {
                                    final highContrast = media.highContrast;
                                    final tint = ColoredBox(
                                      key: const ValueKey(
                                        'app-top-scroll-tint',
                                      ),
                                      color: theme.tokens.colors.background
                                          .withValues(
                                            alpha:
                                                amount *
                                                (highContrast ? 1 : 0.84),
                                          ),
                                    );
                                    return amount == 0 || highContrast
                                        ? tint
                                        : BackdropFilter(
                                            filter: ui.ImageFilter.blur(
                                              sigmaX: 12 * amount,
                                              sigmaY: 12 * amount,
                                            ),
                                            child: tint,
                                          );
                                  },
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: media.padding.top),
                        child: _ChromeSizeReporter(
                          onSize: (size) {
                            if (mounted && size.height != _topHeight) {
                              setState(() => _topHeight = size.height);
                              _scheduleTitleUpdate();
                            }
                          },
                          child: topBar,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (navigation != null)
              Positioned(
                bottom: navigationBottom,
                left: theme.tokens.spacing(4),
                right: theme.tokens.spacing(4),
                child: IgnorePointer(
                  ignoring: keyboard,
                  child: ExcludeFocus(
                    excluding: keyboard,
                    child: ExcludeSemantics(
                      excluding: keyboard,
                      child: AnimatedSwitcher(
                        duration: context.appMotion(
                          theme.tokens.motion.overlay,
                        ),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: keyboard
                            ? const SizedBox.shrink(
                                key: ValueKey('navigation-hidden'),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('navigation-visible'),
                                child: navigation,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Measure arbitrary top content rather than assuming a fixed toolbar height.
class _ChromeSizeReporter extends SingleChildRenderObjectWidget {
  const _ChromeSizeReporter({required this.onSize, required super.child});
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderChromeSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderChromeSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderChromeSizeReporter extends RenderProxyBox {
  _RenderChromeSizeReporter(this.onSize);
  ValueChanged<Size> onSize;
  Size? _reportedSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reportedSize) return;
    _reportedSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(size);
    });
  }
}

// Retained destinations report their stored position when selection changes,
// even when restoring a page does not generate a new scroll notification.
class _AppPageScrollNotification extends Notification {
  _AppPageScrollNotification(this.offset);
  final double offset;
}

/// A named destination with an icon and optional status badge.
@immutable
class AppNavigationItem {
  /// Creates a destination.
  const AppNavigationItem({
    required this.label,
    required this.icon,
    this.badge,
  });

  /// Visible and accessible destination name.
  final String label;

  /// Icon from the product's chosen icon family.
  final Widget icon;

  /// Optional status/count content.
  final Widget? badge;
}

/// Floating destination navigation with full-cell touch and keyboard targets.
class AppNavigationBar extends StatelessWidget {
  /// Creates controlled destination navigation.
  const AppNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.haptic = true,
    this.maxWidth = 480,
    super.key,
  }) : assert(items.length > 1, 'Provide at least two destinations.'),
       assert(
         selectedIndex >= 0 && selectedIndex < items.length,
         'Selected index must be in range.',
       );

  /// Available destinations.
  final List<AppNavigationItem> items;

  /// Currently selected destination.
  final int selectedIndex;

  /// Called synchronously for pointer, keyboard and accessibility activation.
  final ValueChanged<int> onSelected;

  /// Requests feedback on selection changes without delaying navigation.
  final bool haptic;

  /// Maximum width of the floating surface in a large window.
  final double maxWidth;

  /// Height including the surface inset; labels respect system text scaling.
  static double heightOf(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final label = MediaQuery.textScalerOf(context).scale(wide ? 14 : 12);
    return math.max(56, (wide ? 0 : 25) + label * 1.25 + 12) + 12;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme.tokens;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final duration = context.appMotion(t.motion.overlay);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: t.colors.card,
            shape: StadiumBorder(side: BorderSide(color: t.colors.border)),
            shadows: [
              BoxShadow(
                color: t.colors.foreground.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _animateChromeSize(
            context,
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                height: heightOf(context) - 12,
                child: LayoutBuilder(
                  builder: (context, limits) {
                    final cellWidth = limits.maxWidth / items.length;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedPositionedDirectional(
                          key: const ValueKey('app-navigation-indicator'),
                          duration: duration,
                          curve: Curves.easeInOut,
                          start: cellWidth * selectedIndex,
                          width: cellWidth,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              key: const ValueKey(
                                'app-navigation-indicator-surface',
                              ),
                              decoration: ShapeDecoration(
                                color: t.colors.accent,
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(
                                child: _NavigationDestination(
                                  item: items[i],
                                  selected: selectedIndex == i,
                                  horizontal: wide,
                                  onActivate: () {
                                    onSelected(i);
                                    if (haptic && i != selectedIndex) {
                                      unawaited(
                                        context.appTheme.haptics.perform(
                                          AppHaptic.selection,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Crossfades persistent destinations. Only the active page accepts input.
class AppNavigationBody extends StatefulWidget {
  /// Creates a persistent page stack for [index].
  const AppNavigationBody({
    required this.index,
    required this.children,
    super.key,
  }) : assert(
         index >= 0 && index < children.length,
         'Index must name a child.',
       );

  /// Active destination.
  final int index;

  /// Stable destination widgets, in navigation order.
  final List<Widget> children;

  @override
  State<AppNavigationBody> createState() => _AppNavigationBodyState();
}

class _AppNavigationBodyState extends State<AppNavigationBody> {
  Timer? _settle;
  bool _transitioning = false;
  final _scrollOffsets = <int, double>{};

  bool _rememberOffset(int index, ScrollMetrics metrics, int depth) {
    if (depth == 0 && metrics.axis == Axis.vertical) {
      _scrollOffsets[index] = metrics.pixels - metrics.minScrollExtent;
    }
    return false;
  }

  void _reportPageOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _AppPageScrollNotification(
          _scrollOffsets[widget.index] ?? 0,
        ).dispatch(context);
      }
    });
  }

  @override
  void didUpdateWidget(AppNavigationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _reportPageOffset();
    _settle?.cancel();
    final duration = context.appMotion(context.appTheme.tokens.motion.overlay);
    _transitioning = duration > Duration.zero;
    if (_transitioning) {
      _settle = Timer(duration, () {
        if (mounted) setState(() => _transitioning = false);
      });
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < widget.children.length; i++)
        Offstage(
          key: ValueKey(i),
          offstage: i != widget.index && !_transitioning,
          child: AnimatedOpacity(
            opacity: i == widget.index ? 1 : 0,
            duration: context.appMotion(context.appTheme.tokens.motion.overlay),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: i != widget.index,
              child: ExcludeSemantics(
                excluding: i != widget.index,
                child: ExcludeFocus(
                  excluding: i != widget.index,
                  child: TickerMode(
                    enabled: i == widget.index,
                    child: NotificationListener<ScrollMetricsNotification>(
                      onNotification: (notification) => _rememberOffset(
                        i,
                        notification.metrics,
                        notification.depth,
                      ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) => _rememberOffset(
                          i,
                          notification.metrics,
                          notification.depth,
                        ),
                        child: widget.children[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _NavigationDestination extends StatefulWidget {
  const _NavigationDestination({
    required this.item,
    required this.selected,
    required this.horizontal,
    required this.onActivate,
  });

  final AppNavigationItem item;
  final bool selected;
  final bool horizontal;
  final VoidCallback onActivate;

  @override
  State<_NavigationDestination> createState() => _NavigationDestinationState();
}

class _NavigationDestinationState extends State<_NavigationDestination> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;
  Timer? _release;
  DateTime? _pressedAt;

  void _press(bool value) {
    _release?.cancel();
    if (value && !_pressed) _pressedAt = DateTime.now();
    if (value != _pressed) setState(() => _pressed = value);
  }

  void _finishPress() {
    if (!_pressed) return;
    final elapsed = DateTime.now().difference(_pressedAt ?? DateTime.now());
    final remaining =
        context.appMotion(context.appTheme.motion.press) - elapsed;
    _release?.cancel();
    if (remaining > Duration.zero) {
      _release = Timer(remaining, () {
        if (mounted) _press(false);
      });
    } else {
      _press(false);
    }
  }

  void _activate() {
    _press(true);
    _finishPress();
    widget.onActivate();
  }

  @override
  void dispose() {
    _release?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme.tokens;
    final color = widget.selected ? t.colors.primary : t.colors.foreground;
    final content = [
      Stack(
        clipBehavior: Clip.none,
        children: [
          IconTheme(
            data: IconThemeData(color: color, size: 22),
            child: SizedBox.square(
              dimension: 22,
              child: ExcludeSemantics(child: widget.item.icon),
            ),
          ),
          if (widget.item.badge != null)
            PositionedDirectional(
              top: -5,
              end: -10,
              child: widget.item.badge!,
            ),
        ],
      ),
      Flexible(
        child: Text(
          widget.item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.typography.sm.copyWith(
            fontSize: widget.horizontal ? 14 : 12,
            height: 1.25,
            color: color,
            fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    ];
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      onTap: _activate,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _press(true),
          onPointerMove: (event) {
            final box = context.findRenderObject()! as RenderBox;
            _press((Offset.zero & box.size).contains(event.localPosition));
          },
          onPointerUp: (_) => _finishPress(),
          onPointerCancel: (_) => _press(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _activate,
            onTapCancel: () => _press(false),
            child: AnimatedScale(
              key: ValueKey('app-navigation-press-${widget.item.label}'),
              scale: _pressed && !MediaQuery.disableAnimationsOf(context)
                  ? context.appTheme.motion.navigationPressedScale
                  : 1,
              duration: context.appMotion(
                _pressed
                    ? context.appTheme.motion.press
                    : context.appTheme.motion.release,
              ),
              curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
              child: AnimatedContainer(
                duration: context.appMotion(context.appTheme.motion.press),
                decoration: ShapeDecoration(
                  color: _hovered
                      ? t.colors.foreground.withValues(alpha: 0.035)
                      : const Color(0x00000000),
                  shape: StadiumBorder(
                    side: _focused
                        ? BorderSide(color: t.colors.ring, width: 2)
                        : BorderSide.none,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: widget.horizontal
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: content,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 3,
                        children: content,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
