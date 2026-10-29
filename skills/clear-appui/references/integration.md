# Package integration

Install from GitHub in the Flutter application's pubspec:

```yaml
dependencies:
  fossui:
    git:
      url: https://github.com/ycy-0510/clear-appui.git
      ref: main
```

Run `flutter pub get` using the host project's pinned SDK. Use a reviewed full
commit SHA in `ref` when reproducible revisions are needed. The lockfile records
the resolved Git commit. `flutter pub add fossui` installs the upstream pub.dev
package instead of Clear AppUI.

After resolution, run `node <skill>/scripts/doctor.mjs <project>`.

Read these installed sources when composing the corresponding feature:

| Feature | Source |
| --- | --- |
| Exports | `lib/app_ui.dart`, `lib/fossui.dart` |
| Theme and tokens | `lib/src/app_ui/foundation.dart` |
| Product controls | `lib/src/app_ui/components.dart` |
| Responsive panes | `lib/src/app_ui/layout.dart` |
| Shared design rules | `doc/app_ui/DESIGN_STYLE.md` |
| Scaffold and navigation | `lib/src/app_ui/navigation.dart` |
| Sheets and popovers | `lib/src/app_ui/presentation.dart` |
| Drag coordination | `lib/src/app_ui/interaction.dart` |
| Adaptive date picker | `lib/src/app_ui/pickers.dart` |
| Platform capabilities | `lib/src/app_ui/platform.dart` |
| Base components | `lib/src/components/<component>/` |
| Runnable composition | `lib/src/app_ui/showcase.dart`, `example/lib/` |

Flutter 3.47.8 is this library repository's development SDK. Follow the consuming
project's pinned compatible SDK. Preview functions import
`package:flutter/widget_previews.dart` and use `@Preview` on top-level functions
returning a widget. Inject preview-only repositories and platform adapters.
Start from the consuming project with `flutter widget-preview start --web-server`.
The library's own `scripts/dev/preview.sh` additionally handles the pinned SDK's
initial empty-preview cache; inspect that script if the issue recurs.

Use `AppTheme(child: ...)` or `AppTheme(data: AppThemeData.dark, child: ...)`.
The preset theme values are static final objects, so do not use them in a const
constructor expression. Construct controls using their installed definitions;
do not infer parameter names from another UI framework.
