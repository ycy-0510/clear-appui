# Product design style

These defaults belong to Clear AppUI and its matching skill. Update this package
first, then upgrade consuming apps. Do not duplicate a token palette or build
app-specific replacements for shared navigation and presentation components.

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
