import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/app_ui/foundation.dart';
import 'package:fossui/src/app_ui/platform.dart';

// Keep grouped content distinct from a white canvas, using FossUI's existing
// subtle-fill role. Resolve it once against the card so adjacent rows stay
// opaque and continuous, including when placed inside another surface.
Color _groupedSurface(FossThemeData tokens) =>
    Color.alphaBlend(tokens.colors.secondary, tokens.colors.card);

/// Product button appearances, independent of the backend enum.
enum AppButtonVariant {
  /// Filled primary action.
  primary,

  /// Secondary action.
  secondary,

  /// Bordered action.
  outline,

  /// Minimal action.
  ghost,

  /// Destructive action.
  destructive,
}

/// A themed button that gates asynchronous re-entry and handles press cancel.
class AppButton extends StatefulWidget {
  /// Creates an action. A null callback disables it.
  const AppButton({
    required this.child,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leading,
    this.loading = false,
    this.semanticLabel,
    this.onError,
    this.haptic = false,
    this.contentPadding,
    super.key,
  });

  /// Button content.
  final Widget child;

  /// Synchronous or asynchronous action.
  final FutureOr<void> Function()? onPressed;

  /// Semantic visual variant.
  final AppButtonVariant variant;

  /// Optional leading icon.
  final Widget? leading;

  /// Externally controlled loading state.
  final bool loading;

  /// Accessible name, required for icon-only content.
  final String? semanticLabel;

  /// Handles action errors; absent handlers report through FlutterError.
  final void Function(Object error, StackTrace stack)? onError;

  /// Requests selection feedback through the platform adapter when activated.
  final bool haptic;

  /// Optional content inset; the shared minimum touch target remains in force.
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _busy = false;
  bool _pending = false;
  bool _pressed = false;
  Timer? _release;
  Timer? _loadingDelay;
  DateTime? _pressedAt;

  Future<void> _run() async {
    if (_pending || widget.loading || widget.onPressed == null) return;
    _pending = true;
    _press(true);
    _finishPress();
    try {
      if (widget.haptic) {
        unawaited(context.appTheme.haptics.perform(AppHaptic.selection));
      }
      final result = widget.onPressed!();
      if (result is Future<void>) {
        // Fast route changes and local saves must not flash a loading surface.
        _loadingDelay = Timer(context.appTheme.tokens.motion.overlay, () {
          if (mounted && _pending) setState(() => _busy = true);
        });
        await result;
      }
    } on Object catch (error, stack) {
      if (widget.onError case final handler?) {
        handler(error, stack);
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
    } finally {
      _pending = false;
      _loadingDelay?.cancel();
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  void _press(bool value) {
    _release?.cancel();
    if (value && !_pressed) _pressedAt = DateTime.now();
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _finishPress() {
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

  @override
  void dispose() {
    _release?.cancel();
    _loadingDelay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !_busy && !widget.loading;
    return Listener(
      onPointerDown: enabled ? (_) => _press(true) : null,
      onPointerMove: enabled
          ? (event) {
              final box = context.findRenderObject()! as RenderBox;
              _press((Offset.zero & box.size).contains(event.localPosition));
            }
          : null,
      onPointerUp: (_) => _finishPress(),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale:
            _pressed &&
                widget.onPressed != null &&
                !widget.loading &&
                !MediaQuery.disableAnimationsOf(context)
            ? context.appTheme.motion.pressedScale
            : 1,
        duration: context.appMotion(
          _pressed
              ? context.appTheme.motion.press
              : context.appTheme.motion.release,
        ),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: FossButton(
          style: FossButtonStyle(
            minHeight: context.appTheme.dimensions.touchTarget,
            padding: widget.contentPadding,
          ),
          onPressed: enabled ? _run : null,
          loading: _busy || widget.loading,
          variant: switch (widget.variant) {
            AppButtonVariant.primary => FossButtonVariant.primary,
            AppButtonVariant.secondary => FossButtonVariant.secondary,
            AppButtonVariant.outline => FossButtonVariant.outline,
            AppButtonVariant.ghost => FossButtonVariant.ghost,
            AppButtonVariant.destructive => FossButtonVariant.destructive,
          },
          leading: widget.leading,
          semanticLabel: widget.semanticLabel,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Product typography roles.
enum AppTextRole {
  /// Large display title.
  display,

  /// Section heading.
  heading,

  /// Smaller title.
  title,

  /// Normal body text.
  body,

  /// Control label.
  label,

  /// Supporting caption.
  caption,
}

/// Text that follows the theme and the operating system's text scaling.
class AppText extends StatelessWidget {
  /// Creates semantic text.
  const AppText(
    this.data, {
    this.role = AppTextRole.body,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Content to display.
  final String data;

  /// Typography role.
  final AppTextRole role;

  /// Optional maximum lines.
  final int? maxLines;

  /// Overflow behavior.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme.tokens.typography;
    return Semantics(
      container: true,
      header: role == AppTextRole.heading || role == AppTextRole.display,
      child: Text(
        data,
        maxLines: maxLines,
        overflow: overflow,
        style: switch (role) {
          AppTextRole.display => t.xl2.semibold,
          AppTextRole.heading => t.xl.semibold,
          AppTextRole.title => t.lg.semibold,
          AppTextRole.body => t.base,
          AppTextRole.label => t.sm.medium,
          AppTextRole.caption => t.xs,
        },
      ),
    );
  }
}

/// A composable card using the shared shape and surface tokens.
class AppCard extends StatelessWidget {
  /// Creates a card containing arbitrary widgets.
  const AppCard({
    required this.child,
    this.title,
    this.footer,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  /// Arbitrary body content.
  final Widget child;

  /// Optional header.
  final Widget? title;

  /// Optional footer.
  final Widget? footer;

  /// Optional card activation with the same feedback as product buttons.
  final FutureOr<void> Function()? onTap;

  /// Accessible activation name for an interactive card.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme.tokens;
    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: _groupedSurface(t),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radii.xl2),
        ),
      ),
      child: Padding(
        padding: t.spacing.all(4),
        child: DefaultTextStyle(
          style: t.typography.base.copyWith(color: t.colors.cardForeground),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: t.spacing(4),
            children: [?title, child, ?footer],
          ),
        ),
      ),
    );
    if (onTap == null) return surface;
    return AppButton(
      variant: AppButtonVariant.ghost,
      contentPadding: EdgeInsets.zero,
      semanticLabel: semanticLabel,
      onPressed: onTap,
      child: surface,
    );
  }
}

/// A product text field with explicit error and disabled state.
class AppTextField extends StatelessWidget {
  /// Creates a single or multiline field.
  const AppTextField({
    this.controller,
    this.focusNode,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Text controller; internally owned when absent.
  final TextEditingController? controller;

  /// Focus controller; internally owned when absent.
  final FocusNode? focusNode;

  /// Visible accessible field label.
  final String? label;

  /// Empty-field hint.
  final String? placeholder;

  /// Supporting text.
  final String? helperText;

  /// Validation error, taking priority over helper text.
  final String? errorText;

  /// Whether editing is allowed.
  final bool enabled;

  /// Masks a password field.
  final bool obscureText;

  /// Maximum lines, or null for unrestricted multiline content.
  final int? maxLines;

  /// Requested keyboard type.
  final TextInputType? keyboardType;

  /// Called after editing.
  final ValueChanged<String>? onChanged;

  /// Called on keyboard submit.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => FossTextField(
    style: FossTextFieldStyle(
      minHeight: context.appTheme.dimensions.touchTarget,
      shadow: const [],
    ),
    controller: controller,
    focusNode: focusNode,
    label: label,
    hintText: placeholder,
    helperText: helperText,
    errorText: errorText,
    enabled: enabled,
    obscureText: obscureText,
    maxLines: maxLines,
    keyboardType: keyboardType,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

/// Accessible empty or error content, optionally offering recovery.
class AppEmptyState extends StatelessWidget {
  /// Creates a state panel.
  const AppEmptyState({required this.message, this.action, super.key});

  /// Explanation of the current state.
  final String message;

  /// Optional retry or creation action.
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [AppText(message), ?action],
      ),
    ),
  );
}

/// Semantic status colors for product badges.
enum AppStatus {
  /// Neutral metadata.
  neutral,

  /// Informational status.
  info,

  /// Successful status.
  success,

  /// Warning status.
  warning,

  /// Error status.
  error,
}

/// A semantic badge backed by the existing token system.
class AppBadge extends StatelessWidget {
  /// Creates a status badge.
  const AppBadge({
    required this.label,
    this.status = AppStatus.neutral,
    super.key,
  });

  /// Visible and accessible label.
  final String label;

  /// Semantic status color.
  final AppStatus status;
  @override
  Widget build(BuildContext context) => FossBadge(
    label: Text(label),
    variant: switch (status) {
      AppStatus.neutral => FossBadgeVariant.secondary,
      AppStatus.info => FossBadgeVariant.info,
      AppStatus.success => FossBadgeVariant.success,
      AppStatus.warning => FossBadgeVariant.warning,
      AppStatus.error => FossBadgeVariant.error,
    },
  );
}

/// An icon using the product's selected icon family and current theme.
class AppIcon extends StatelessWidget {
  /// Creates an icon with an optional accessible name.
  const AppIcon(this.icon, {this.semanticLabel, super.key});

  /// Icon supplied by the product's icon set.
  final IconData icon;

  /// Accessible label; null means decorative.
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) =>
      Icon(icon, semanticLabel: semanticLabel);
}

/// Controlled checkbox with an optional visible label.
class AppCheckbox extends StatelessWidget {
  /// Creates a checkbox; a null callback disables it.
  const AppCheckbox({
    required this.value,
    this.onChanged,
    this.label,
    super.key,
  });

  /// Checked, unchecked or mixed state.
  final bool? value;

  /// Requests a new value.
  final ValueChanged<bool>? onChanged;

  /// Optional visible label.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final control = FossCheckbox(
      value: value,
      onChanged: onChanged,
      label: label,
    );
    if (!_AppListGroupScope.maybeOf(context)) return control;
    final spacing = context.appTheme.tokens.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing(4),
        vertical: spacing(1),
      ),
      child: control,
    );
  }
}

/// Controlled switch with an explicit accessible label.
class AppSwitch extends StatelessWidget {
  /// Creates a switch; a null callback disables it.
  const AppSwitch({
    required this.value,
    required this.label,
    this.onChanged,
    super.key,
  });

  /// Selected state.
  final bool value;

  /// Accessible action name.
  final String label;

  /// Requests a new value.
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) =>
      FossSwitch(value: value, semanticLabel: label, onChanged: onChanged);
}

/// Composable list row with optional leading and trailing content.
class AppListTile extends StatelessWidget {
  /// Creates a list row.
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// Primary content.
  final Widget title;

  /// Supporting content.
  final Widget? subtitle;

  /// Leading content.
  final Widget? leading;

  /// Trailing content.
  final Widget? trailing;

  /// Row activation action.
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => FossListTile(
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    onTap: onTap,
    variant: _AppListGroupScope.maybeOf(context)
        ? FossListTileVariant.plain
        : FossListTileVariant.filled,
    style: _AppListGroupScope.maybeOf(context)
        ? const FossListTileStyle(borderRadius: 0)
        : null,
  );
}

/// One surface for related rows, rounded only at the group's outer edges.
class AppListGroup extends StatelessWidget {
  /// Creates a small, eagerly laid out group. Use AppSliverListGroup for lists.
  const AppListGroup({required this.children, super.key});

  /// Related rows, normally AppListTile widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++)
        _AppGroupedRow(
          first: i == 0,
          last: i == children.length - 1,
          child: children[i],
        ),
    ],
  );
}

/// Lazy grouped rows for a single CustomScrollView with scrolling headers.
class AppSliverListGroup extends StatelessWidget {
  /// Creates lazily built rows with continuous interior edges.
  const AppSliverListGroup({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  /// Number of rows in this group.
  final int itemCount;

  /// Builds a row on demand.
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: itemCount,
    itemBuilder: (context, index) => _AppGroupedRow(
      first: index == 0,
      last: index == itemCount - 1,
      child: itemBuilder(context, index),
    ),
  );
}

class _AppGroupedRow extends StatelessWidget {
  const _AppGroupedRow({
    required this.first,
    required this.last,
    required this.child,
  });
  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme.tokens;
    final radius = Radius.circular(t.radii.lg);
    return ClipRSuperellipse(
      borderRadius: BorderRadius.vertical(
        top: first ? radius : Radius.zero,
        bottom: last ? radius : Radius.zero,
      ),
      child: ColoredBox(
        color: _groupedSurface(t),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!first)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.spacing(4)),
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(color: t.colors.border),
                ),
              ),
            _AppListGroupScope(child: child),
          ],
        ),
      ),
    );
  }
}

class _AppListGroupScope extends InheritedWidget {
  const _AppListGroupScope({required super.child});
  static bool maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppListGroupScope>() != null;
  @override
  bool updateShouldNotify(_AppListGroupScope oldWidget) => false;
}
