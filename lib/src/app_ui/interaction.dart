import 'package:flutter/widgets.dart';
import 'package:fossui/src/app_ui/foundation.dart';

/// Lifecycle of an application-local drag session.
enum AppDragState {
  /// A pointer currently carries the payload.
  dragging,

  /// A target committed the move.
  accepted,

  /// No valid target committed the move.
  rejected,

  /// Explicit cancellation or application backgrounding.
  cancelled,
}

/// Immutable snapshot of a typed widget's shared drag session.
@immutable
class AppDragSession {
  /// Creates a session snapshot.
  const AppDragSession({
    required this.data,
    required this.source,
    required this.state,
  });

  /// Payload carried between containers.
  final Object data;

  /// Identity of the source widget.
  final Object source;

  /// Current lifecycle state.
  final AppDragState state;
}

/// Coordinates sheet gestures, overlay barriers and all AppUI drag sources.
class AppDragCoordinator extends ChangeNotifier {
  AppDragSession? _session;
  bool _disposed = false;

  /// Current or most recently completed session.
  AppDragSession? get session => _session;

  /// Whether a pointer is still carrying a payload.
  bool get isDragging => _session?.state == AppDragState.dragging;

  /// Begins one session, rejecting simultaneous drags.
  bool begin(Object data, {required Object source}) {
    if (_disposed || isDragging) return false;
    _session = AppDragSession(
      data: data,
      source: source,
      state: AppDragState.dragging,
    );
    notifyListeners();
    return true;
  }

  /// Marks a successful, committed drop.
  void accept() => _finish(AppDragState.accepted);

  /// Marks an invalid or failed drop.
  void reject() => _finish(AppDragState.rejected);

  /// Cancels the active session without committing data.
  void cancel() => _finish(AppDragState.cancelled);

  void _finish(AppDragState state) {
    final current = _session;
    if (_disposed || current == null || !isDragging) return;
    _session = AppDragSession(
      data: current.data,
      source: current.source,
      state: state,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Makes one coordinator available to all presentation layers.
class AppDragScope extends InheritedNotifier<AppDragCoordinator> {
  /// Creates a scope with an externally owned coordinator.
  const AppDragScope({
    required AppDragCoordinator coordinator,
    required super.child,
    super.key,
  }) : super(notifier: coordinator);

  /// Finds the shared coordinator, or throws when the host is missing.
  static AppDragCoordinator of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppDragScope>();
    if (scope == null) {
      throw FlutterError(
        'AppDraggable requires AppPresentationHost or AppDragScope.',
      );
    }
    return scope.notifier!;
  }
}

/// A root-overlay drag source that escapes sheet and source-container clipping.
class AppDraggable<T extends Object> extends StatefulWidget {
  /// Creates a drag source. Long press preserves normal list scrolling.
  const AppDraggable({
    required this.data,
    required this.child,
    required this.feedback,
    this.longPress = true,
    this.childWhenDragging,
    this.onCompleted,
    super.key,
  });

  /// Typed transferable value.
  final T data;

  /// Normal source content.
  final Widget child;

  /// Preview rendered above all sheets in the root overlay.
  final Widget feedback;

  /// Wait for a long press; false suits explicit desktop drag handles.
  final bool longPress;

  /// Optional source placeholder.
  final Widget? childWhenDragging;

  /// Called after a successful move.
  final VoidCallback? onCompleted;
  @override
  State<AppDraggable<T>> createState() => _AppDraggableState<T>();
}

class _AppDraggableState<T extends Object> extends State<AppDraggable<T>> {
  final Object _source = Object();
  AppDragCoordinator? _coordinator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coordinator = AppDragScope.of(context);
  }

  @override
  void dispose() {
    // Notifications cannot rebuild a parent while its children are unmounting.
    final coordinator = _coordinator;
    if (coordinator?.isDragging ?? false) {
      if (identical(coordinator!.session?.source, _source)) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => coordinator.cancel(),
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = AppDragScope.of(context);
    final feedback = ListenableBuilder(
      listenable: coordinator,
      child: AppTheme(data: context.appTheme, child: widget.feedback),
      builder: (context, child) =>
          coordinator.isDragging &&
              identical(coordinator.session?.source, _source)
          ? child!
          : const SizedBox.shrink(),
    );
    void start() => coordinator.begin(widget.data, source: _source);
    void complete() {
      coordinator.accept();
      widget.onCompleted?.call();
    }

    final max = coordinator.isDragging ? 0 : 1;
    final child = widget.longPress
        ? LongPressDraggable<T>(
            data: widget.data,
            rootOverlay: true,
            maxSimultaneousDrags: max,
            feedback: feedback,
            childWhenDragging: widget.childWhenDragging,
            onDragStarted: start,
            onDragCompleted: complete,
            onDraggableCanceled: (_, _) => coordinator.reject(),
            child: widget.child,
          )
        : Draggable<T>(
            data: widget.data,
            rootOverlay: true,
            maxSimultaneousDrags: max,
            feedback: feedback,
            childWhenDragging: widget.childWhenDragging,
            onDragStarted: start,
            onDragCompleted: complete,
            onDraggableCanceled: (_, _) => coordinator.reject(),
            child: widget.child,
          );
    return Listener(
      onPointerCancel: (_) {
        if (identical(coordinator.session?.source, _source)) {
          coordinator.cancel();
        }
      },
      child: child,
    );
  }
}

/// Visual acceptance state of a drop target.
enum AppDropState {
  /// No acceptable payload is hovering.
  idle,

  /// An acceptable payload is hovering.
  active,
}

/// A typed drop target with explicit acceptance and failure handling.
class AppDropTarget<T extends Object> extends StatelessWidget {
  /// Creates a target. Commit data only in [onAccept].
  const AppDropTarget({
    required this.onAccept,
    required this.builder,
    this.canAccept,
    this.onError,
    super.key,
  });

  /// Synchronously commits a valid payload.
  final ValueChanged<T> onAccept;

  /// Builds the target with a valid-hover flag.
  final Widget Function(BuildContext context, AppDropState state) builder;

  /// Optional business acceptance predicate.
  final bool Function(T data)? canAccept;

  /// Reports a failed commit.
  final void Function(Object error, StackTrace stack)? onError;
  @override
  Widget build(BuildContext context) {
    final coordinator = AppDragScope.of(context);
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) =>
          coordinator.isDragging && (canAccept?.call(details.data) ?? true),
      onAcceptWithDetails: (details) {
        try {
          onAccept(details.data);
          coordinator.accept();
        } on Object catch (error, stack) {
          coordinator.reject();
          if (onError case final handler?) {
            handler(error, stack);
          } else {
            FlutterError.reportError(
              FlutterErrorDetails(exception: error, stack: stack),
            );
          }
        }
      },
      builder: (context, candidates, rejected) => builder(
        context,
        candidates.isNotEmpty ? AppDropState.active : AppDropState.idle,
      ),
    );
  }
}
