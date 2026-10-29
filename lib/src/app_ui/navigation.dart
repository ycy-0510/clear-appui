import 'dart:async';
import 'dart:math' as math;

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
/// content; this widget provides neither glass material nor backdrop blur.
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.appTheme.tokens.spacing(4),
      vertical: context.appTheme.tokens.spacing(2),
    ),
    child: Row(
      children: [
        if (leading case final action?)
          _group(context, const ValueKey('app-top-leading'), [action]),
        if (actions.isNotEmpty)
          Expanded(
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
        else
          const Spacer(),
      ],
    ),
  );
}

/// Shared page chrome, safe areas, keyboard handling and floating navigation.
class AppScaffold extends StatelessWidget {
  /// Creates a page. Scroll views should consume MediaQuery padding.
  const AppScaffold({
    required this.body,
    this.topBar,
    this.navigation,
    this.navigationMode = AppNavigationMode.reservedSpace,
    super.key,
  });

  /// Main content; may paint below the floating navigation.
  final Widget body;

  /// Optional fixed top content.
  final Widget? topBar;

  /// Floating bottom navigation.
  final Widget? navigation;

  /// Defines bottom-space behavior explicitly.
  final AppNavigationMode navigationMode;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final media = MediaQuery.of(context);
    final bottom =
        navigation != null &&
            media.viewInsets.bottom == 0 &&
            navigationMode == AppNavigationMode.reservedSpace
        ? math.max(
                theme.dimensions.navigationExtent,
                navigation is AppNavigationBar
                    ? AppNavigationBar.heightOf(context) +
                          theme.tokens.spacing(6)
                    : 0.0,
              ) +
              media.padding.bottom
        : media.viewInsets.bottom > 0
        ? 0.0
        : media.padding.bottom;
    final keyboard = media.viewInsets.bottom > 0;
    return ColoredBox(
      color: theme.tokens.colors.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: Column(
                children: [
                  ?topBar,
                  Expanded(
                    child: Builder(
                      builder: (context) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          padding: EdgeInsets.only(bottom: bottom),
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (navigation != null)
              Positioned(
                bottom: media.padding.bottom + theme.tokens.spacing(3),
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
                                child: navigation!,
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
                          curve: Curves.easeOutCubic,
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

  @override
  void didUpdateWidget(AppNavigationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
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
                    child: widget.children[i],
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

  void _press(bool value) {
    if (value != _pressed) setState(() => _pressed = value);
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
      onTap: widget.onActivate,
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
              widget.onActivate();
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
          onPointerUp: (_) => _press(false),
          onPointerCancel: (_) => _press(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onActivate,
            child: AnimatedContainer(
              duration: context.appMotion(context.appTheme.motion.press),
              decoration: ShapeDecoration(
                color: _pressed
                    ? t.colors.primary.withValues(alpha: 0.18)
                    : _hovered
                    ? t.colors.secondary
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
    );
  }
}
