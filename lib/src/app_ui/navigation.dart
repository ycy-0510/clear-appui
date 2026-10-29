import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/app_ui/components.dart';
import 'package:fossui/src/app_ui/foundation.dart';
import 'package:fossui/src/app_ui/platform.dart';

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
                ? AppNavigationBar.heightOf(context) + theme.tokens.spacing(6)
                : 0.0,
          )
        : 0.0;
    return ColoredBox(
      color: theme.tokens.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
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
              if (navigation != null && media.viewInsets.bottom == 0)
                Positioned(
                  bottom: theme.tokens.spacing(3),
                  left: theme.tokens.spacing(4),
                  right: theme.tokens.spacing(4),
                  child: navigation!,
                ),
            ],
          ),
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
    final highContrast = MediaQuery.highContrastOf(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final height = heightOf(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: StadiumBorder()),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: highContrast ? 0 : 20,
                sigmaY: highContrast ? 0 : 20,
              ),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: t.colors.card.withValues(
                    alpha: highContrast ? 1 : 0.94,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(color: t.colors.border),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    height: height - 12,
                    child: Row(
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
                    : widget.selected
                    ? t.colors.accent
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
