import 'package:flutter/gestures.dart';

/// Tracks immediate visual feedback without competing with scroll recognizers.
/// Activation still belongs to Flutter's tap recognizer and gesture arena.
class AppPointerPress {
  int? _pointer;
  Offset _origin = Offset.zero;
  double _slop = 0;

  /// Whether this pointer sequence permanently lost its tap candidacy.
  bool cancelled = false;

  /// Starts immediate feedback for a new primary pointer only.
  bool down(PointerDownEvent event, DeviceGestureSettings? settings) {
    if (_pointer != null || event.buttons != kPrimaryButton) return false;
    _pointer = event.pointer;
    _origin = event.position;
    _slop = computeHitSlop(event.kind, settings);
    cancelled = false;
    return true;
  }

  /// Returns true exactly when movement first cancels this press.
  bool move(PointerMoveEvent event) {
    if (event.pointer != _pointer || cancelled) return false;
    if ((event.position - _origin).distance > _slop ||
        event.buttons != kPrimaryButton) {
      cancel();
      return true;
    }
    return false;
  }

  /// Ends the tracked pointer and reports whether feedback may finish normally.
  bool up(PointerEvent event) {
    if (event.pointer != _pointer) return false;
    _pointer = null;
    return !cancelled;
  }

  /// Permanently cancels, including when another recognizer wins the arena.
  void cancel() => cancelled = true;

  /// Cancels only the pointer that began this press.
  bool cancelPointer(PointerCancelEvent event) {
    if (event.pointer != _pointer) return false;
    _pointer = null;
    cancel();
    return true;
  }
}
