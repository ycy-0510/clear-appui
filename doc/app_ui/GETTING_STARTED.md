# Getting started

Clear AppUI is distributed from GitHub. Its Dart package identifier is `fossui`.

```yaml
dependencies:
  flutter:
    sdk: flutter
  fossui:
    git:
      url: https://github.com/ycy-0510/clear-appui.git
      ref: main
```

Run `flutter pub get`. Commit the application's lockfile, and use a reviewed
commit SHA in `ref` when pinning a library revision. Run
`flutter pub upgrade fossui` to resolve newer commits from a moving branch.

The pub.dev package named `fossui` is the upstream library. Use the Git source
above to get this fork's product APIs. Local development can use a path
dependency pointing to a checkout instead.

## Theme and first control

```dart
import 'package:flutter/cupertino.dart';
import 'package:fossui/app_ui.dart';

void main() => runApp(
  CupertinoApp(
    home: AppTheme(
      child: CupertinoPageScaffold(
        child: Center(
          child: AppButton(
            onPressed: () {},
            child: const AppText('Get started'),
          ),
        ),
      ),
    ),
  ),
);
```

AppTheme follows system brightness by default. Set `data: AppThemeData.light`
or `data: AppThemeData.dark` to choose a preset explicitly. Presets are static
final objects, so do not place them in a const expression.

Inside the theme, use `context.appTheme.tokens` for colors, typography, spacing
and radii. `dimensions`, `motion`, and `sheet` contain additional product values.
AppTheme adapts the existing FossTheme token source.

Use `package:fossui/fossui.dart` for lower-level components that have no App*
wrapper. Read [components and composition](COMPONENTS.md) before adding sheets,
navigation, or coordinated drag and drop.

## Explore the examples

Clone the repository and use Flutter 3.47.8 from `.fvmrc`. Resolve dependencies
in both the root and `example/`, then run `bash scripts/dev/preview.sh` from
the root. This compiles a web preview scaffold and does not build an iOS App.
The launcher uses Node.js 22+ for its preview initialization workaround.

The macOS runner includes the complete component catalog and a course-management
example. From `example/`, run `flutter run -d macos` after checking host CPU
availability. See [development](DEVELOPMENT.md) for the complete workflow.
