---
name: clear-appui
description: Build, migrate, or review Flutter product interfaces using the Clear AppUI component library. Resolve the installed package, reuse its real App* and Foss* APIs, and apply Apple HIG principles through shared themes, layouts, and presentation hosts.
---

# Clear AppUI

Use the installed Clear AppUI library to compose the requested interface.
The repository is `ycy-0510/clear-appui`; its Dart package identifier is `fossui`.
Product imports use `package:fossui/app_ui.dart`; lower-level components use
`package:fossui/fossui.dart`. Preserve the project's behavior, data, and local
instructions when migrating an existing application.

## Resolve the implementation first

Run `node <this-skill>/scripts/doctor.mjs <flutter-project>` after dependency
resolution. It locates the actual package through `.dart_tool/package_config.json`,
checks the API contract, and prints the matching source paths, design guide and Git revision.
If dependencies are missing, install the Git dependency shown in
[the integration reference](references/integration.md), then run the doctor again.

Read the returned entrypoint and the constructors for the components needed by
the task. Parameter names, enum values, controllers, and behavior must come from
those installed files or their examples. Check existing components before writing
a replacement. Read `lib/src/components/` when an App* wrapper does not exist.

The package carries its matching skill. If `skillMatchesPackage` is false, read
the `bundledSkill` reported by the doctor before editing UI. A different API
contract is an error: use the package's bundled skill rather than guessing.

## Compose with the library

- Put `AppTheme` below the application's shell. Read semantic values from
  `context.appTheme.tokens`; use `dimensions`, `motion`, and `sheet` for product
  overrides. AppTheme adapts FossTheme; keep this single token source.
- Use AppButton, AppText, AppCard, AppTextField, AppBadge, AppCheckbox,
  AppSwitch and AppListTile where they fit. Use existing Foss* variants for
  lower-level selection, dialogs, menus, progress, or feedback.
- Read the package's `doc/app_ui/DESIGN_STYLE.md` before styling. Shared design
  changes belong in the package and this skill, followed by upgrading consumers;
  do not fork typography, spacing or navigation materials inside each app.
- Use AppTopBar for top navigation: Back/Close has one floating leading surface;
  all trailing actions share one floating capsule. Keep titles in page content,
  leave the space between groups unpainted, and use the opaque library surface.
  Do not create a separate floating tile for every trailing icon or add glass/blur.
- Use AppScaffold and AppNavigationBar for product page chrome. Preserve bottom
  content reachability using the scaffold's advertised MediaQuery padding.
- Put AppPresentationHost inside the relevant route. Present sheets through
  showAppSheet; connect the supplied ScrollController to the sheet body. Share
  that host's drag coordinator across page and sheet. Read the implementation
  before adding nested presentations or drag behaviors.
- Prefer AppAdaptiveLayout, AppAdaptiveGrid and AppConstrainedContent for
  constrained layouts. Base adaptation on available space.
- Keep feedback purposeful. FossToaster owns toast queues: only the front shows
  content; rear surfaces are previews of queued messages. Use an inline error
  when the user needs to resolve a form problem.

## Apply interface guidance

Consult the installed `doc/app_ui/APPLE_HIG_NOTES.md` for implemented decisions
and the official sources linked there. Use HIG for hierarchy, readable content,
safe areas, keyboard access, touch targets, motion and accessibility. Product
token values are configurable choices, not Apple-prescribed metrics.

Use the package's compact product type scale (15 body, 17 title, 20 heading,
22 display) and 16-point content/card insets. These are product defaults, not HIG
mandates. Preserve system text scaling; keep intentionally enlarged preview
cases separate and label them. Avoid double padding from nested cards and rows.
Maintain consistent spacing and concentric shapes. Avoid rebuilding the library's
navigation, sheet material or gesture handling in individual screens. The Flutter
sheet is an approximation of Apple's materials; verify platform-specific behavior
on the actual target when needed.

## Verify the requested behavior

Use interactive Widget Preview with injected sample repositories and no native
side effects. Verify narrow/wide layouts, light/dark, larger text, error/retry,
cancellation, keyboard/focus and the interactions changed by the task. Follow
the host project's CPU, SDK, simulator and release rules. Record device-only
checks as pending until they have actually run.

Read [integration.md](references/integration.md) for dependency, API-location and
preview commands. The skill provides instructions and source inspection; the
project separately installs the Dart dependency.
