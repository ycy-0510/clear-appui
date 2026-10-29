import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Capabilities available without assuming a particular device model.
@immutable
class AppPlatformCapabilities {
  /// Creates a capability snapshot.
  const AppPlatformCapabilities({
    required this.haptics,
    required this.displayFeatures,
    this.nativeDragDrop = false,
    this.foldablePosture = false,
  });

  /// Detects only capabilities exposed by the currently installed adapters.
  factory AppPlatformCapabilities.of(BuildContext context) =>
      AppPlatformCapabilities(
        haptics:
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.android),
        displayFeatures: MediaQuery.of(context).displayFeatures.isNotEmpty,
      );

  /// Flutter can request basic platform haptic feedback.
  final bool haptics;

  /// Actual display occlusions are supplied through MediaQuery.
  final bool displayFeatures;

  /// A native cross-application drag adapter is installed.
  final bool nativeDragDrop;

  /// A posture-event adapter is installed.
  final bool foldablePosture;
}

/// Basic haptic requests supported by Flutter itself.
enum AppHaptic {
  /// Selection change.
  selection,

  /// Light impact.
  light,

  /// Medium impact.
  medium,

  /// Heavy impact.
  heavy,
}

/// Injectable platform boundary, with an explicit web/preview no-op.
class AppHaptics {
  /// Creates a system adapter. Disable for deterministic previews and tests.
  const AppHaptics({this.enabled = true});

  /// Whether requests should reach the platform.
  final bool enabled;

  /// Performs a basic haptic, or gracefully degrades when no plugin exists.
  Future<void> perform(AppHaptic kind) async {
    if (!enabled || kIsWeb) return;
    try {
      await switch (kind) {
        AppHaptic.selection => HapticFeedback.selectionClick(),
        AppHaptic.light => HapticFeedback.lightImpact(),
        AppHaptic.medium => HapticFeedback.mediumImpact(),
        AppHaptic.heavy => HapticFeedback.heavyImpact(),
      };
    } on MissingPluginException {
      // Rendering and interaction must work when the platform has no haptics.
    }
  }
}
