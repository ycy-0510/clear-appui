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
      accent: brandSelectionSurface,
      accentForeground: brandPrimary,
      ring: brandPrimary,
    ),
  ),
);
```

Import `FossThemeSpec` from `package:fossui/fossui.dart`. Map background, content,
surface and border roles as needed, with a corresponding dark palette. Feed the
same tokens into the Cupertino/Material shell. Product artwork belongs to the
host app; shared component styling belongs to this package. Check logo contrast
without recoloring supplied artwork, and verify native launch resources separately
from Widget Preview.

## Floating top controls

Use `AppTopBar` inside `AppScaffold.topBar`. A leading Back/Close action has its
own floating surface. Trailing actions share a single capsule. The gap between
them has no bar background. Place the page title in the content below the controls.

The arrangement takes cues from modern iOS control grouping. It uses an opaque
surface, a subtle border and shadow; there is no glass material, transparency or
backdrop blur. Trailing icons belong to one surface, not separate floating tiles.
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
AppButton maintains visible feedback for a quick tap and keyboard activation;
it gates pending work immediately and only shows a loading state for sustained
work, avoiding flashes for quick local actions. Activation never waits for motion.

AppNavigationBar owns one persistent selection surface. It slides and resizes
instead of toggling separate selected backgrounds. AppTopBar groups and bottom
chrome animate geometry changes. Keyboard visibility fades navigation out/in
while immediately disabling hidden controls. Rapid changes retarget motion.
AppNavigationBody crossfades stable destinations and excludes outgoing pages
from input, focus and semantics. Reduce Motion lays out final geometry directly.

## Scrolling and groups

Preserve the host app's destinations, settings entry points, search modes and
scroll boundaries during migration. Do not move settings into bottom navigation
or pin an originally scrolling search/filter area without an explicit redesign.

AppScaffold lets the body extend behind floating bottom controls to the device
edge. Its MediaQuery bottom padding represents the navigation and device inset;
consume it as trailing scroll content. Do not use a bottom SafeArea to reduce
the viewport above the floating bar. The final row must scroll fully above it.
For a page that scrolls as one unit, use CustomScrollView, SliverToBoxAdapter
for headers/filters and AppSliverListGroup for lazy results. Avoid nested vertical
scroll views and eager building of an entire dictionary.

AppListGroup composes a small group; AppSliverListGroup builds a long group lazily.
Use AppListTile inside them: the group supplies one continuous card surface,
only the first/last exterior corners and interior dividers. Standalone tiles
retain FossUI's independent filled-row appearance. Use FossTabs for segmented
search modes; it already provides a continuous moving indicator.

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

These are configurable product decisions, not Apple-prescribed typography or
padding values. [HIG notes](APPLE_HIG_NOTES.md) separate guidance from choices.

## Preview acceptance

Keep normal light/dark previews at ordinary text scaling. Label larger-text tests
separately. Verify floating controls, narrow/wide layouts, keyboard/cancel,
error/retry, title alignment and last-item reachability. A browser preview does
not establish native VoiceOver, gesture or performance acceptance.
Check animation midpoints, quick reversals, resizing, reduced motion, grouped
middle-row edges, header scrolling and the last result above navigation.
