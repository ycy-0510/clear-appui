# Clear AppUI

A Flutter UI library for product interfaces, built on [FossUI](https://github.com/fossui/fossui).

- 39 core component families, with additional `App*` APIs for product screens.
- Shared theme tokens, light and dark themes, and adaptive layouts.
- Floating navigation, resizable sheets, popovers, and coordinated drag and drop.
- An interactive component catalog and Flutter Widget Previews.

The library is under active development. See the [roadmap](TODO.md) for current scope.

## Install

Add the GitHub dependency to your `pubspec.yaml`:

```yaml
dependencies:
  fossui:
    git:
      url: https://github.com/ycy-0510/clear-appui.git
      ref: main
```

Run `flutter pub get`. The Dart package name remains `fossui` for compatibility.
Pin `ref` to a commit SHA when you need a reproducible version.

## Quick start

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

Use `package:fossui/app_ui.dart` for product components and
`package:fossui/fossui.dart` for the underlying `Foss*` components.

## Preview

Use Flutter **3.47.8**, as pinned in `.fvmrc`:

```bash
flutter pub get
cd example
flutter pub get
cd ..
bash scripts/dev/preview.sh
```

Open the URL printed by the launcher. The catalog covers all 39 component
families, including light/dark, large-text, RTL, and long-content scenarios.
The launcher also uses Node.js 22+ for preview initialization.

## Agent skill

Install the component-aware skill into your preferred coding agents:

```bash
npx skills add ycy-0510/clear-appui --skill clear-appui
```

The skill resolves the installed library and reads its actual APIs before
composing UI. Install the Dart dependency separately using the instructions above.
See [agent integration](doc/app_ui/AGENT_SKILL.md) for version checks and setup.

## Documentation

- [Getting started](doc/app_ui/GETTING_STARTED.md)
- [Components and composition](doc/app_ui/COMPONENTS.md)
- [Development and previews](doc/app_ui/DEVELOPMENT.md)
- [Design guidance](doc/app_ui/APPLE_HIG_NOTES.md)
- [Component QA](doc/app_ui/COMPONENT_QA.md)
- [Changelog](CHANGELOG.md)

## License

MIT. This fork preserves FossUI attribution and the bundled Geist font license.
See [LICENSE](LICENSE), [NOTICE](NOTICE), and [fonts/OFL.txt](fonts/OFL.txt).
