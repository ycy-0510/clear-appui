# Components and composition

Import product APIs from `package:fossui/app_ui.dart`. The package also preserves
the existing `Foss*` APIs through `package:fossui/fossui.dart`.

## Product APIs

| Area | APIs | Implementation |
| --- | --- | --- |
| Theme | AppTheme, AppThemeData, AppDimensions, AppMotion, AppSheetStyle | [foundation.dart](../../lib/src/app_ui/foundation.dart) |
| Collapsing title | AppCollapsingTitle with AppScaffold/AppTopBar | [navigation.dart](../../lib/src/app_ui/navigation.dart) |
| Controls | AppButton, AppText, AppIcon, AppCard, AppBadge, AppTextField, AppCheckbox, AppSwitch, AppListTile, AppListGroup, AppSliverListGroup, AppEmptyState | [components.dart](../../lib/src/app_ui/components.dart) |
| Layout | AppLayoutEnvironment, AppAdaptiveLayout, AppConstrainedContent, AppAdaptiveGrid, AppFormLayout, AppFormBody | [layout.dart](../../lib/src/app_ui/layout.dart) |
| Navigation | AppScaffold, AppTopBar, AppTopBarAction, AppNavigationBar, AppNavigationItem, AppNavigationBody | [navigation.dart](../../lib/src/app_ui/navigation.dart) |
| Presentation | AppPresentationHost, AppSheet, AppSheetController, AppSheetDetent, AppPopover, showAppSheet | [presentation.dart](../../lib/src/app_ui/presentation.dart) |
| Drag and drop | AppDragCoordinator, AppDragScope, AppDraggable, AppDropTarget | [interaction.dart](../../lib/src/app_ui/interaction.dart) |
| Picker | AppDatePicker | [pickers.dart](../../lib/src/app_ui/pickers.dart) |
| Platform | AppPlatformCapabilities, AppHaptics, AppHaptic | [platform.dart](../../lib/src/app_ui/platform.dart) |

Read each linked constructor for its supported parameters. The product layer is
still evolving; the table lists implemented APIs rather than every planned API.

`AppButtonSize.large` provides centered, enlarged continuation labels and rounded
ends. `AppButton.expanded` defaults to following a tight parent width, so form
actions align; true fills a bounded loose layout and false opts into a compact
control. Variant controls emphasis independently of size. Dark secondary fills
adapt through the existing tokens. Pointer feedback is permanently cancelled
after tap slop or arena loss; keyboard and accessibility activation stay separate.

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
AppScaffold overlays top controls with a transparent-to-frosted scroll backdrop.
It advertises their measured height and device top inset through MediaQuery;
`reservedSpace` navigation mode also advertises bottom clearance. Default lists
consume both; explicit list/sliver padding must preserve leading and trailing
insets from a context inside the body. AppNavigationBody restores each retained
page's top material; nested/horizontal scrolling does not drive the backdrop.

AppNavigationBar activates destinations synchronously. A full destination cell
is interactive, and optional haptics run without delaying selection. Preserve
screen state with AppNavigationBody. Its page crossfades do not delay selection.
The bar uses one persistent moving indicator, with reduced-motion support.

AppListGroup supplies one continuous surface for small groups of AppListTile rows.
Interactive trailing controls retain their own accessibility action as well as
their pointer/keyboard target; a remove control does not activate the row.
Use AppSliverListGroup in CustomScrollView for lazy results below scrolling headers;
apply advertised bottom padding as trailing scroll content. Only group exterior
edges are rounded, with flat interior rows and dividers.

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

Top action grouping, typography and spacing follow [DESIGN_STYLE.md](DESIGN_STYLE.md).
