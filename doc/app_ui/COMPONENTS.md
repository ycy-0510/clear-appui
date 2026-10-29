# Components and composition

Import product APIs from `package:fossui/app_ui.dart`. The package also preserves
the existing `Foss*` APIs through `package:fossui/fossui.dart`.

## Product APIs

| Area | APIs | Implementation |
| --- | --- | --- |
| Theme | AppTheme, AppThemeData, AppDimensions, AppMotion, AppSheetStyle | [foundation.dart](../../lib/src/app_ui/foundation.dart) |
| Controls | AppButton, AppText, AppIcon, AppCard, AppBadge, AppTextField, AppCheckbox, AppSwitch, AppListTile, AppEmptyState | [components.dart](../../lib/src/app_ui/components.dart) |
| Layout | AppLayoutEnvironment, AppAdaptiveLayout, AppConstrainedContent, AppAdaptiveGrid | [layout.dart](../../lib/src/app_ui/layout.dart) |
| Navigation | AppScaffold, AppNavigationBar, AppNavigationItem | [navigation.dart](../../lib/src/app_ui/navigation.dart) |
| Presentation | AppPresentationHost, AppSheet, AppSheetController, AppSheetDetent, AppPopover, showAppSheet | [presentation.dart](../../lib/src/app_ui/presentation.dart) |
| Drag and drop | AppDragCoordinator, AppDragScope, AppDraggable, AppDropTarget | [interaction.dart](../../lib/src/app_ui/interaction.dart) |
| Picker | AppDatePicker | [pickers.dart](../../lib/src/app_ui/pickers.dart) |
| Platform | AppPlatformCapabilities, AppHaptics, AppHaptic | [platform.dart](../../lib/src/app_ui/platform.dart) |

Read each linked constructor for its supported parameters. The product layer is
still evolving; the table lists implemented APIs rather than every planned API.

## Presentation and drag ownership

Place AppPresentationHost inside each presenting route, below AppTheme. Use
showAppSheet with a context under the host. Connect the sheet's supplied
ScrollController to its ListView or SingleChildScrollView so scrolling and
resizing can coordinate. A full example is in the
[composition contract](DEVELOPMENT.md#composition-contract).

Use the host's shared drag coordination for transfers between a sheet and page.
The root-overlay drag preview escapes source clipping. Targets validate before
committing a transfer; cancellation must leave source data intact.

## Layout and navigation

AppAdaptiveLayout measures available space rather than identifying device models.
It falls back to one pane when the requested columns cannot fit.
AppScaffold's `reservedSpace` navigation mode advertises bottom padding through
MediaQuery. Default lists consume it; custom list padding must preserve it.

AppNavigationBar activates destinations synchronously. A full destination cell
is interactive, and optional haptics run without delaying selection. Preserve
screen state when composing tab contents.

## Lower-level components

The 39 component families are listed with source links in
[the component QA record](COMPONENT_QA.md). The interactive catalog in
[`example/lib/component_catalog.dart`](../../example/lib/component_catalog.dart)
provides runnable variants and states.

### Toasts

Mount FossToaster above the subtree that calls showFossToast. A returned handle
can update or dismiss the notification.

The newest toast displays its content; older notifications appear as smaller,
blank rear surfaces. The entire pile uses the same width constraint. Rear
notifications pause their timers until their messages reach the front, so they
cannot expire without being readable. Swiping the front left, right or down
dismisses it and reveals the next notification.

Use inline feedback for an actionable form error. Loading notifications persist
until updated or dismissed. See the [toast source](../../lib/src/components/toast/)
for available variants, duration and per-instance styling.
