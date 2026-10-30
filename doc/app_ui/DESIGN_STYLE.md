# Product design style

These defaults belong to Clear AppUI and its matching skill. Update this package
first, then upgrade consuming apps. Do not duplicate a token palette or build
app-specific replacements for shared navigation and presentation components.

## Host branding

The preset blue palette is a fallback. During migration, preserve the host's
maintained brand colors, logos, functional icons, launcher icon and launch screen.
Keep the brand mapping in one application theme adapter. Start with the product
preset so shared typography, spacing, shapes and interaction behavior survive:

```dart
final base = AppThemeData.light;
final branded = base.copyWith(
  tokens: base.tokens.retheme(
    const FossThemeSpec(
      primary: brandPrimary,
      primaryForeground: onBrandPrimary,
      ring: brandPrimary,
    ),
  ),
);
```

Import `FossThemeSpec` from `package:fossui/fossui.dart`. Keep neutral background, content,
surface and border roles unless a branded canvas is explicitly requested.
The light default preserves FossUI's white canvas and neutral secondary fills;
brand emphasis normally overrides primary, on-primary and focus roles only. Feed the
same tokens into the Cupertino/Material shell. Product artwork belongs to the
host app; shared component styling belongs to this package. Check logo contrast
without recoloring supplied artwork, and verify native launch resources separately
from Widget Preview.

## Floating top controls

Use `AppTopBar` inside `AppScaffold.topBar`. A leading Back/Close action has its
own floating surface. Trailing actions share a single capsule. The gap between
them is transparent at the top of the page. Place the page title in scrolling content.

The action capsules retain FossUI's opaque themed surface, subtle border and
shadow. AppScaffold overlays them above the page: content can scroll behind them.
The surrounding top area starts transparent and smoothly gains a frosted, tinted
backdrop over the first 48 logical pixels of vertical page scrolling. Returning
to the top clears it again. The blur is clipped to the measured top area, including
the device's top inset. This is a restrained backdrop, without refraction or
Liquid Glass simulation. High Contrast replaces blur with an opaque final tint;
Reduce Motion applies the scroll state directly. These values are product choices.
Trailing icons belong to one surface, not separate floating tiles.
Each action retains its own accessible label, keyboard focus and touch target.
When space is constrained, the trailing group scrolls instead of overlapping Back.

```dart
AppTopBar(
  leading: AppTopBarAction(icon: backIcon, label: 'Back', onPressed: goBack),
  actions: [
    AppTopBarAction(icon: editIcon, label: 'Edit', onPressed: edit),
    AppTopBarAction(icon: moreIcon, label: 'More', onPressed: more),
  ],
)
```

Use the existing `AppNavigationBar` for floating bottom destinations. Top action
groups and bottom destinations serve different purposes.

## Motion and continuity

HIG informs interaction behavior; it does not require an iOS visual clone.
Keep FossUI's token-based surfaces, button depth and short press feedback.
Product buttons compress to 0.95 and navigation content to 0.88 over 100ms,
returning over 160ms with a restrained spring. On a 22-point icon the previous
0.97 scale changed less than one point, making feedback hard to see. These are
configurable AppMotion values. The touch region and sliding selection fill stay
fixed while content compresses; Reduce Motion keeps final geometry.
AppCard.onTap uses the same guarded action/feedback path while keeping the card's
single 16-point content inset. Its body text still wraps and nested footer
buttons activate independently. Use it for existing actionable summary cards.
AppButton maintains visible feedback for a quick tap and keyboard activation;
it gates pending work immediately and only shows a loading state for sustained
work, avoiding flashes for quick local actions. Activation never waits for motion.

AppNavigationBar owns one persistent selection surface. It slides and resizes
instead of toggling separate selected backgrounds. Destinations briefly scale
on quick tap or keyboard activation, retaining FossUI's press feedback. Pressing
does not paint another selection-colored background at the target: the existing
selection surface moves there using the same easing as FossTabs. AppTopBar groups
and bottom chrome animate geometry changes. Keyboard visibility fades navigation out/in
while immediately disabling hidden controls. Rapid changes retarget motion.
AppNavigationBody crossfades stable destinations and excludes outgoing pages
from input, focus and semantics. Reduce Motion lays out final geometry directly.

## Scrolling and groups

Preserve the host app's destinations, settings entry points, search modes and
scroll boundaries during migration. Do not move settings into bottom navigation
or pin an originally scrolling search/filter area without an explicit redesign.

AppScaffold lets the body extend behind top and bottom controls to the device
edges. Its MediaQuery top padding includes the measured top controls and device
inset; consume it as leading scroll content. Bottom padding represents navigation
and the device inset; consume it as trailing scroll content. Default ListView
padding does this automatically. Explicit padding and slivers must retain both.
AppNavigationBody restores the top material for each retained page's scroll offset;
nested and horizontal scrolling do not drive the page's top edge. Do not use a bottom SafeArea to reduce
the viewport above the floating bar. The final row must scroll fully above it.
For a page that scrolls as one unit, use CustomScrollView, SliverToBoxAdapter
for headers/filters and AppSliverListGroup for lazy results. Avoid nested vertical
scroll views and eager building of an entire dictionary.

AppListGroup composes a small group; AppSliverListGroup builds a long group lazily.
Use AppListTile inside them: the group supplies one continuous card surface,
only the first/last exterior corners and interior dividers. Standalone tiles
retain FossUI's independent filled-row appearance. Use FossTabs for segmented
search modes; it already provides a continuous moving indicator.

A white canvas still needs visible grouping. AppCard and both list-group variants
resolve their opaque fill by compositing FossUI's secondary fill over its card
color. This gives the default light theme a subtle neutral gray group and keeps
dark groups distinct, without tinting the page or changing floating controls.
Do not flatten grouped content into the canvas when removing a brand tint.
AppCheckbox inside either list group inherits 16-point horizontal and 4-point
vertical insets in addition to its existing 48-point target. Standalone filter
checkboxes keep their surrounding layout's spacing; avoid double-insetting them.

## Typography and spacing

AppTheme adapts FossTheme's existing typography tokens. Its default logical sizes
are 12 caption, 13 label, 15 body, 17 title, 20 heading and 22 display. Use one
clear page heading; reserve display text for an actual content hierarchy rather
than applying it to every label, count or repeated heading. Preserve operating
system text scaling, including accessibility sizes.

Use 16-point content insets (`tokens.spacing(4)`), 16-point card padding and a
consistent 8/12/16/24 spacing rhythm. Do not combine a padded card with a padded
row when a single grouped list surface is sufficient. Keep titles, lists and
forms on the same outer alignment and consume AppScaffold's bottom padding so
floating navigation cannot cover the last control. Keep action targets at the
shared 48-point minimum even when icon and text sizes are compact.

Short sheet forms use `AppFormBody(controller: scroll, children: [...])` for
16-point outer insets and sibling gaps. Fields, errors and action buttons are
separate children; an entire `AppListGroup` stays one child so internal rows
remain contiguous. `AppFormLayout` provides the same gaps inside an existing
padded/sliver container. Remove manual spacer children when adopting either.
Controls do not carry implicit outer margins. Verify field-to-action and
action-to-action gaps as well as internal padding. The sheet owns keyboard
resizing; form bodies consume bottom safe padding without adding the keyboard
height a second time.

These are configurable product decisions, not Apple-prescribed typography or
padding values. [HIG notes](APPLE_HIG_NOTES.md) separate guidance from choices.

## Preview acceptance

Keep normal light/dark previews at ordinary text scaling. Label larger-text tests
separately. Verify floating controls, narrow/wide layouts, keyboard/cancel,
error/retry, title alignment and last-item reachability. A browser preview does
not establish native VoiceOver, gesture or performance acceptance.
Check animation midpoints, quick reversals, resizing, reduced motion, grouped
middle-row edges, header scrolling and the last result above navigation.


## Sheet continuity

The route's presentation host animates sheet entry and exit with a matching
barrier transition. Results complete after exit; interruption reverses the
current animation. Reduced Motion uses final geometry. Backgrounding and route
disposal complete outstanding results immediately. Sheet surfaces keep a stable
BackdropFilter parent, toggling its enabled state as opacity changes; replacing
that parent at full height disposes the active gesture and causes a failed first
pull. A continuous downward pull can resize and dismiss from the handle or body.


## Deferred presentation coordination

Incoming work must respect an active editor or route transition. Observe the
route host's read-only presentationCountListenable, which includes exiting
presentations until their animations finish. Schedule follow-up UI after the
frame once the current host reaches zero. Unsubscribe within the host's route
lifecycle; do not poll its stack or create a second presentation host for the
same route.

Use showAppSheet.onBeforeDismiss for an asynchronous null-result dismissal
check. False leaves the sheet open, and repeated Back/Close cannot run concurrent
checks. Return non-null explicit results for actions that intentionally bypass
this guard. Backgrounding or route disposal cancels immediately; durable work
must remain recoverable outside the presentation.
