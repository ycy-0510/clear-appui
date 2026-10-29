import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart'
    show DragStartBehavior, kMinFlingVelocity;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/app_ui/components.dart';
import 'package:fossui/src/app_ui/foundation.dart';
import 'package:fossui/src/app_ui/interaction.dart';

/// Hosts presentations and drag coordination in one route-owned subtree.
///
/// Place inside a Navigator route and below AppTheme. Disposing the route or
/// backgrounding the app completes outstanding presentations without a result.
class AppPresentationHost extends StatefulWidget {
  /// Creates a shared presentation host.
  const AppPresentationHost({required this.child, super.key});

  /// Main route content.
  final Widget child;

  /// Finds the host shared by the page and its sheets.
  static AppPresentationHostState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PresentationScope>();
    if (scope == null) {
      throw FlutterError('Add AppPresentationHost inside your route.');
    }
    return scope.host;
  }

  @override
  State<AppPresentationHost> createState() => AppPresentationHostState();
}

/// Controller owned by an AppPresentationHost.
class AppPresentationHostState extends State<AppPresentationHost>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _entries = <_Presentation>[];
  final _drag = AppDragCoordinator();

  /// Number of currently open presentations.
  int get presentationCount => _entries.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Opens a presentation above the page, preserving typed results.
  Future<T?> show<T>({
    required WidgetBuilder builder,
    bool modal = true,
    bool dismissible = true,
    String barrierLabel = '關閉面板',
  }) {
    final entry = _Presentation(
      builder: builder,
      modal: modal,
      dismissible: dismissible,
      barrierLabel: barrierLabel,
      previousFocus: FocusManager.instance.primaryFocus,
      animation: AnimationController(
        vsync: this,
        duration: context.appMotion(context.appTheme.tokens.motion.overlay),
      ),
    );
    entry.history = LocalHistoryEntry(onRemove: () => _close(entry));
    ModalRoute.of(context)?.addLocalHistoryEntry(entry.history!);
    setState(() => _entries.add(entry));
    entry.animation.forward();
    return entry.result.future.then((value) => value as T?);
  }

  /// Closes the top presentation and resolves its future.
  void close([Object? result]) {
    if (_entries.isNotEmpty) _close(_entries.last, result);
  }

  void _close(_Presentation entry, [Object? result]) {
    if (!_entries.contains(entry) || entry.closing) return;
    _drag.cancel();
    setState(() => entry.closing = true);
    entry.history?.remove();
    unawaited(_finishClosing(entry, result));
  }

  Future<void> _finishClosing(_Presentation entry, Object? result) async {
    try {
      await entry.animation.reverse().orCancel;
    } on TickerCanceled {
      return; // Route disposal or backgrounding already completed the result.
    }
    if (mounted && _entries.contains(entry)) _remove(entry, result);
  }

  void _remove(_Presentation entry, [Object? result]) {
    if (!_entries.contains(entry)) return;
    final wasTop = identical(_entries.last, entry);
    setState(() => _entries.remove(entry));
    entry.animation.dispose();
    entry.history?.remove();
    if (!entry.result.isCompleted) entry.result.complete(result);
    final focus = entry.previousFocus;
    if (mounted && wasTop && focus?.context != null) focus!.requestFocus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _drag.cancel();
      _entries.toList().reversed.forEach(_remove);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Complete before history callbacks can try to modify an unmounting host.
    final entries = _entries.toList();
    _entries.clear();
    for (final entry in entries) {
      entry.animation.dispose();
      entry.history?.remove();
      if (!entry.result.isCompleted) entry.result.complete();
    }
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDragScope(
    coordinator: _drag,
    child: _PresentationScope(
      host: this,
      child: ListenableBuilder(
        listenable: _drag,
        builder: (context, _) {
          final modal = _entries.any((entry) => entry.modal);
          return Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) {
                    if (_drag.isDragging) {
                      _drag.cancel();
                    } else if (_entries.isNotEmpty &&
                        _entries.last.dismissible) {
                      close();
                    }
                    return null;
                  },
                ),
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    excluding: modal,
                    child: ExcludeFocus(excluding: modal, child: widget.child),
                  ),
                  for (final entry in _entries) ...[
                    if (entry.modal)
                      Positioned.fill(
                        child: IgnorePointer(
                          // Carried payloads must reach the page's targets.
                          ignoring: _drag.isDragging,
                          child: Semantics(
                            label: entry.barrierLabel,
                            button: entry.dismissible,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: entry.dismissible
                                  ? () => _close(entry)
                                  : null,
                              child: FadeTransition(
                                opacity: entry.animation,
                                child: const ColoredBox(
                                  color: Color(0x52000000),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      key: entry.key,
                      child: IgnorePointer(
                        ignoring: entry.closing,
                        child: ExcludeSemantics(
                          excluding: entry.closing,
                          child: _PresentationEntryScope(
                            animation: entry.animation,
                            child: FocusScope(
                              autofocus: true,
                              child: Builder(builder: entry.builder),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Presentation {
  _Presentation({
    required this.builder,
    required this.modal,
    required this.dismissible,
    required this.barrierLabel,
    required this.previousFocus,
    required this.animation,
  });
  final WidgetBuilder builder;
  final bool modal;
  final bool dismissible;
  final String barrierLabel;
  final FocusNode? previousFocus;
  final AnimationController animation;
  bool closing = false;
  final key = UniqueKey();
  final result = Completer<Object?>();
  LocalHistoryEntry? history;
}

class _PresentationEntryScope extends InheritedWidget {
  const _PresentationEntryScope({
    required this.animation,
    required super.child,
  });
  final Animation<double> animation;
  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PresentationEntryScope>()
      ?.animation;
  @override
  bool updateShouldNotify(_PresentationEntryScope oldWidget) =>
      animation != oldWidget.animation;
}

class _PresentationScope extends InheritedWidget {
  const _PresentationScope({required this.host, required super.child});
  final AppPresentationHostState host;
  @override
  bool updateShouldNotify(_PresentationScope oldWidget) =>
      host != oldWidget.host;
}

/// A sheet height expressed as a fraction or a fixed logical-pixel value.
@immutable
class AppSheetDetent {
  /// Uses a proportion of the keyboard-adjusted available height.
  const AppSheetDetent.fraction(double fraction)
    : assert(fraction > 0 && fraction <= 1, 'Fraction must be in (0, 1].'),
      _fraction = fraction,
      _pixels = null;

  /// Uses a fixed height, clamped to the available area.
  const AppSheetDetent.pixels(double pixels)
    : assert(pixels > 0, 'Pixel height must be positive.'),
      _pixels = pixels,
      _fraction = null;

  /// Half of the available area.
  static const medium = AppSheetDetent.fraction(0.5);

  /// All of the available area below the top safe area.
  static const large = AppSheetDetent.fraction(1);
  final double? _fraction;
  final double? _pixels;

  /// Resolves this height against a finite, positive available height.
  double resolve(double availableHeight) {
    if (!availableHeight.isFinite || availableHeight <= 0) {
      throw ArgumentError.value(availableHeight, 'availableHeight');
    }
    return (_fraction ?? _pixels! / availableHeight).clamp(0.01, 1.0);
  }
}

/// Public phases of the sheet's handle interaction.
enum AppSheetPhase {
  /// Waiting for input.
  idle,

  /// Pointer-controlled resize.
  dragging,

  /// Snapping toward a configured height.
  settling,
}

/// Programmatic height and state for an AppSheet.
class AppSheetController extends ChangeNotifier {
  /// Creates an unattached controller; dispose externally supplied instances.
  AppSheetController() {
    _controller.addListener(notifyListeners);
  }
  final _controller = DraggableScrollableController();
  double _height = 1;
  double _min = 0.01;
  double _max = 1;
  Duration _duration = const Duration(milliseconds: 220);
  AppSheetPhase _phase = AppSheetPhase.idle;
  int _generation = 0;
  bool _disposed = false;
  AnimationController? _animation;

  /// Whether a mounted sheet owns this controller.
  bool get isAttached => _controller.isAttached;

  /// Current fraction of available height, or zero before attachment.
  double get extent => isAttached ? _controller.size : 0;

  /// Current handle interaction phase.
  AppSheetPhase get phase => _phase;

  /// Animates to one of the sheet's usable heights.
  Future<void> snapTo(AppSheetDetent detent) async {
    if (!isAttached || _disposed) return;
    final generation = ++_generation;
    final target = detent.resolve(_height).clamp(_min, _max);
    _phase = AppSheetPhase.settling;
    notifyListeners();
    try {
      final animation = _animation;
      if (_duration == Duration.zero || animation == null) {
        _controller.jumpTo(target);
      } else {
        // Drive geometry independently from ScrollPosition's viewport
        // correction activity so a shrinking body cannot cancel the detent.
        animation.value = extent;
        await animation
            .animateTo(target, duration: _duration, curve: Curves.easeOutCubic)
            .orCancel;
      }
    } on TickerCanceled {
      // A new pointer gesture, a newer command or unmounting won ownership.
    } finally {
      if (!_disposed && generation == _generation) {
        _phase = AppSheetPhase.idle;
        notifyListeners();
      }
    }
  }

  void _interrupt() {
    _generation++;
    _animation?.stop();
    _phase = AppSheetPhase.dragging;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _animation?.stop();
    _animation = null;
    _controller
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}

/// Opens a sheet in the route's shared presentation host.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool modal = true,
  bool dismissible = true,
}) => AppPresentationHost.of(context).show<T>(
  builder: builder,
  modal: modal,
  dismissible: dismissible,
);

/// A resizable sheet that coordinates its scrollable body with drag sessions.
class AppSheet extends StatefulWidget {
  /// Creates a sheet. Attach the provided ScrollController to its body list.
  const AppSheet({
    required this.builder,
    this.title,
    this.detents = const [
      AppSheetDetent.fraction(0.3),
      AppSheetDetent.medium,
      AppSheetDetent.large,
    ],
    this.initialDetent = AppSheetDetent.medium,
    this.controller,
    this.dismissible = true,
    super.key,
  });

  /// Builds scrollable content using the sheet's shared scroll controller.
  final Widget Function(BuildContext context, ScrollController scrollController)
  builder;

  /// Optional header content.
  final Widget? title;

  /// Snap heights. Duplicates after clamping are removed.
  final List<AppSheetDetent> detents;

  /// Initial height, clamped to the configured range.
  final AppSheetDetent initialDetent;

  /// Optional externally owned controller.
  final AppSheetController? controller;

  /// Allows the handle to dismiss and displays a close action.
  final bool dismissible;
  @override
  State<AppSheet> createState() => _AppSheetState();
}

class _AppSheetState extends State<AppSheet>
    with SingleTickerProviderStateMixin {
  late AppSheetController _sheet;
  late final AnimationController _animation;
  double _dismissTravel = 0;
  double _bodyTravel = 0;
  bool _bodyDragging = false;
  @override
  void initState() {
    super.initState();
    _sheet = widget.controller ?? AppSheetController();
    _animation = AnimationController(vsync: this)
      ..addListener(() {
        if (_sheet.isAttached) _sheet._controller.jumpTo(_animation.value);
      });
    _sheet._animation = _animation;
  }

  @override
  void didUpdateWidget(AppSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _sheet
        .._interrupt()
        .._animation = null;
      if (oldWidget.controller == null) _sheet.dispose();
      _sheet = widget.controller ?? AppSheetController();
      _sheet._animation = _animation;
    }
  }

  @override
  void dispose() {
    _sheet
      .._interrupt()
      .._animation = null;
    _animation.dispose();
    if (widget.controller == null) _sheet.dispose();
    super.dispose();
  }

  Future<void> _snap(List<double> sizes, {double velocity = 0}) async {
    if (!_sheet.isAttached) return;
    final size = _sheet.extent;
    var target = sizes.reduce(
      (a, b) => (a - size).abs() < (b - size).abs() ? a : b,
    );
    if (velocity.abs() > kMinFlingVelocity) {
      final options = sizes.where(
        (s) => velocity < 0 ? s > size + 0.01 : s < size - 0.01,
      );
      if (options.isNotEmpty) {
        target = velocity < 0 ? options.first : options.last;
      }
    }
    await _sheet.snapTo(AppSheetDetent.fraction(target));
  }

  Widget _surface(
    BuildContext context,
    ScrollController scroll,
    List<double> sizes,
    double height,
  ) {
    final theme = context.appTheme;
    final style = theme.sheet;
    final initial = widget.initialDetent
        .resolve(height)
        .clamp(sizes.first, sizes.last);
    final dragging = AppDragScope.of(context).isDragging;
    return ListenableBuilder(
      listenable: _sheet,
      child: widget.builder(context, scroll),
      builder: (context, body) {
        final extent = _sheet.isAttached ? _sheet.extent : initial;
        final margin = style.marginAt(extent, minimumExtent: sizes.first);
        final opaque = MediaQuery.highContrastOf(context);
        final opacity = opaque
            ? 1.0
            : style.opacityAt(extent, minimumExtent: sizes.first);
        final bottomRadius = style.floatingMargin == 0
            ? 0.0
            : style.radius * margin / style.floatingMargin;
        final corners = BorderRadius.vertical(
          top: Radius.circular(style.radius),
          bottom: Radius.circular(bottomRadius),
        );
        String percent(double value) => '${(value * 100).round()}%';
        final increased = sizes.firstWhere(
          (value) => value > extent + 0.01,
          orElse: () => sizes.last,
        );
        final decreased = sizes.lastWhere(
          (value) => value < extent - 0.01,
          orElse: () => sizes.first,
        );
        void cycle() => unawaited(
          _sheet.snapTo(
            AppSheetDetent.fraction(
              extent >= sizes.last - 0.01 ? sizes.first : increased,
            ),
          ),
        );
        final content = DecoratedBox(
          key: const ValueKey('app-sheet-surface'),
          decoration: BoxDecoration(
            color: theme.tokens.colors.popover.withValues(alpha: opacity),
            borderRadius: corners,
            border: Border.all(color: theme.tokens.colors.border),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragStart: dragging
                      ? null
                      : (_) {
                          _dismissTravel = 0;
                          _sheet._interrupt();
                        },
                  onVerticalDragUpdate: dragging
                      ? null
                      : (event) {
                          if (!_sheet.isAttached) return;
                          final next = _sheet.extent - event.delta.dy / height;
                          _dismissTravel = math.max(
                            0,
                            _dismissTravel + event.delta.dy,
                          );
                          _sheet._controller.jumpTo(
                            next.clamp(sizes.first, sizes.last),
                          );
                        },
                  onVerticalDragCancel: dragging
                      ? null
                      : () => unawaited(_snap(sizes)),
                  onVerticalDragEnd: dragging
                      ? null
                      : (event) {
                          if (widget.dismissible &&
                              _sheet.extent <= sizes.first + 0.01 &&
                              (_dismissTravel > theme.dimensions.touchTarget ||
                                  (event.primaryVelocity ?? 0) > 700)) {
                            AppPresentationHost.of(context).close();
                          } else {
                            unawaited(
                              _snap(
                                sizes,
                                velocity: event.primaryVelocity ?? 0,
                              ),
                            );
                          }
                        },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: '面板高度',
                        value: percent(extent),
                        increasedValue: percent(increased),
                        decreasedValue: percent(decreased),
                        onIncrease: dragging
                            ? null
                            : () => unawaited(_snap(sizes, velocity: -800)),
                        onDecrease: dragging
                            ? null
                            : () => unawaited(_snap(sizes, velocity: 800)),
                        button: true,
                        onTap: dragging ? null : cycle,
                        child: FocusableActionDetector(
                          shortcuts: const {
                            SingleActivator(LogicalKeyboardKey.enter):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.space):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowUp):
                                _IncreaseSheetIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowDown):
                                _DecreaseSheetIntent(),
                          },
                          actions: {
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (_) {
                                if (!dragging) cycle();
                                return null;
                              },
                            ),
                            _IncreaseSheetIntent:
                                CallbackAction<_IncreaseSheetIntent>(
                                  onInvoke: (_) {
                                    if (!dragging) {
                                      unawaited(_snap(sizes, velocity: -800));
                                    }
                                    return null;
                                  },
                                ),
                            _DecreaseSheetIntent:
                                CallbackAction<_DecreaseSheetIntent>(
                                  onInvoke: (_) {
                                    if (!dragging) {
                                      unawaited(_snap(sizes, velocity: 800));
                                    }
                                    return null;
                                  },
                                ),
                          },
                          child: GestureDetector(
                            key: const ValueKey('app-sheet-grabber'),
                            behavior: HitTestBehavior.opaque,
                            onTap: dragging ? null : cycle,
                            child: SizedBox(
                              height: 32,
                              width: double.infinity,
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.tokens.colors.mutedForeground
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(
                                      style.radius,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: theme.dimensions.touchTarget,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: theme.tokens.spacing(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child:
                                    widget.title ??
                                    const AppText(
                                      '面板',
                                      role: AppTextRole.label,
                                    ),
                              ),
                              if (widget.dismissible)
                                AppButton(
                                  variant: AppButtonVariant.ghost,
                                  onPressed: () =>
                                      AppPresentationHost.of(context).close(),
                                  child: const Text('關閉'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) {
                      _bodyTravel = 0;
                      _bodyDragging = true;
                    },
                    onPointerUp: (_) => _bodyDragging = false,
                    onPointerMove: (event) =>
                        _bodyTravel = math.max(0, _bodyTravel + event.delta.dy),
                    onPointerCancel: (_) => _bodyDragging = false,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.depth != 0) return false;
                        if (notification is ScrollStartNotification &&
                            notification.dragDetails != null) {
                          _bodyDragging = true;
                          _sheet._interrupt();
                        }
                        if (notification is OverscrollNotification &&
                            notification.dragDetails != null &&
                            notification.overscroll < 0 &&
                            _sheet.extent <= sizes.first + 0.01 &&
                            _bodyTravel > theme.dimensions.touchTarget &&
                            widget.dismissible) {
                          AppPresentationHost.of(context).close();
                        }
                        return false;
                      },
                      child: body!,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return Padding(
          key: const ValueKey('app-sheet-margin'),
          padding: EdgeInsets.only(left: margin, right: margin, bottom: margin),
          child: ClipRSuperellipse(
            borderRadius: corners,
            // Keep the gesture subtree mounted when a full-height opaque panel
            // becomes translucent. Inserting a new filter parent here cancels
            // the first active drag as soon as the panel leaves full height.
            child: BackdropFilter(
              enabled: opacity < 1 && style.blurSigma > 0,
              filter: ImageFilter.blur(
                sigmaX: style.blurSigma,
                sigmaY: style.blurSigma,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.detents.isEmpty) {
      throw ArgumentError('AppSheet requires at least one detent.');
    }
    final theme = context.appTheme;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: media.padding.top,
        bottom: media.viewInsets.bottom,
      ),
      child: LayoutBuilder(
        builder: (context, limits) {
          final height = math.max<double>(1, limits.maxHeight);
          final sizes =
              widget.detents.map((d) => d.resolve(height)).toSet().toList()
                ..sort();
          _sheet
            .._height = height
            .._min = sizes.first
            .._max = sizes.last
            .._duration = context.appMotion(theme.tokens.motion.drawer);
          final panel = NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if (_bodyDragging &&
                  widget.dismissible &&
                  _bodyTravel > theme.dimensions.touchTarget &&
                  notification.extent <= sizes.first + 0.01) {
                AppPresentationHost.of(context).close();
              }
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheet._controller,
              initialChildSize: widget.initialDetent
                  .resolve(height)
                  .clamp(sizes.first, sizes.last),
              minChildSize: sizes.first,
              maxChildSize: sizes.last,
              expand: false,
              snap: sizes.length > 1,
              snapSizes: sizes,
              shouldCloseOnMinExtent: false,
              builder: (context, scroll) =>
                  _surface(context, scroll, sizes, height),
            ),
          );
          final animation = _PresentationEntryScope.maybeOf(context);
          return Align(
            alignment: Alignment.bottomCenter,
            child: animation == null
                ? panel
                : SlideTransition(
                    key: const ValueKey('app-sheet-presentation'),
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurveTween(
                            curve: Curves.easeOutCubic,
                          ).animate(animation),
                        ),
                    child: panel,
                  ),
          );
        },
      ),
    );
  }
}

class _IncreaseSheetIntent extends Intent {
  const _IncreaseSheetIntent();
}

class _DecreaseSheetIntent extends Intent {
  const _DecreaseSheetIntent();
}

/// Anchored content that falls back to a sheet in compact windows.
class AppPopover extends StatefulWidget {
  /// Creates an adaptive popover. Content should size itself vertically.
  const AppPopover({
    required this.child,
    required this.builder,
    this.title,
    super.key,
  });

  /// Trigger content, usually a non-actionable AppButton.
  final Widget child;

  /// Popup content, built only while open.
  final WidgetBuilder builder;

  /// Sheet fallback header.
  final Widget? title;

  /// Closes the popover or its adaptive sheet from inside its content.
  static void close(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PopoverScope>()?.close();
  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover> {
  final _controller = FossPopoverController();
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 600) {
      return FossPopover(
        controller: _controller,
        builder: (_) => _PopoverScope(
          close: _controller.close,
          child: Builder(builder: widget.builder),
        ),
        child: widget.child,
      );
    }
    void open() => unawaited(
      showAppSheet<void>(
        context: context,
        builder: (_) => AppSheet(
          title: widget.title,
          builder: (context, scroll) => SingleChildScrollView(
            controller: scroll,
            child: _PopoverScope(
              close: () => AppPresentationHost.of(context).close(),
              child: Builder(builder: widget.builder),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: '開啟選單',
      child: FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              open();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PopoverScope extends InheritedWidget {
  const _PopoverScope({required this.close, required super.child});
  final VoidCallback close;
  @override
  bool updateShouldNotify(_PopoverScope oldWidget) => close != oldWidget.close;
}
