# Clear AppUI development

## Scope and status

The complete user plan is saved in [original-plan.txt](original-plan.txt).
[TODO.md](../../TODO.md) tracks each workstream. The first increment is the
course acceptance flow: phone list, multi-detent sheet, drag into the page's
date region, a two-pane tablet layout and adaptive date presentation.
Unchecked items remain work; a preview is not native-device acceptance.

The fork keeps FossUI's API, fonts, tests, MIT license and attribution. Product
code imports `package:fossui/app_ui.dart`. Showcase code is separately exported
from `package:fossui/app_ui_showcase.dart` and is not a runtime prerequisite.

## SDK and Preview

Use Flutter 3.47.8 / Dart 3.13.7, matching `.fvmrc`. With FVM installed, prefix
Flutter/Dart commands with `fvm`. An installed SDK with the same version also
works. Dependencies:

```bash
flutter pub get
```

Start interactive browser previews from the repository root:

```bash
bash scripts/dev/preview.sh
```

Open the printed local URL in a browser. Supported IDEs also discover the
annotations in `example/lib/previews.dart` in their Flutter Widget Preview tab.
The browser previews compile an isolated web scaffold, not an IPA or iOS Runner.
Source edits hot-reload; reset an individual preview to clear its sample data.
The generated `.widget_preview/` cache is ignored by Git and pub packaging.

The pinned SDK can initially return an empty workspace preview cache. After the
browser connects, the startup script checks for this case and queries the
preview source through the local DTD/LSP service. This triggers the SDK's normal
reload without modifying its installation or generated scaffold. This small
startup workaround requires Node.js 22 or later; the UI library has no Node
runtime dependency. Re-evaluate it when upgrading Flutter. The legacy detection
flag is not used because that path does not initialize the scaffold's DTD.

The ten previews cover phone light/dark, tablet, large text, AppUI states and
three complete-catalog configurations. Every catalog preview can select any of
the 39 component families. Each preview owns its Navigator and sample state.

Try long-pressing a course in its sheet, then drag it into the date area above
the sheet. The alternative “安排” action supports keyboard and screen
reader users. Selecting an already scheduled course is rejected by the target.

## macOS demonstration

The example also includes a macOS Runner. From the repository root:

```bash
bash scripts/dev/check-cpu.sh
cd example
flutter run -d macos
```

“完整元件庫” opens a searchable catalog of all 39 component families, with
independent samples and light/dark, 2× text, RTL and long-content controls.
Wide windows use a sidebar; narrow windows use a searchable component picker.
“課程互動” opens the course acceptance flow. Drag with a mouse on Mac;
long-press to drag on iOS/Android. The grabber cycles the resting heights and
supports Up/Down keyboard adjustment. Sheet materials and geometry follow
continuous height progress; see [Apple HIG notes](APPLE_HIG_NOTES.md).

## Composition contract

Use `AppTheme` below your app shell and put `AppPresentationHost` inside each
route that presents AppUI sheets. Theme values adapt the existing FossUI token
source; do not introduce a second color/spacing palette.

```dart
AppTheme(
  child: AppPresentationHost(
    child: Builder(builder: (context) => AppButton(
      onPressed: () => showAppSheet<void>(
        context: context,
        builder: (_) => AppSheet(
          title: const AppText('Details'),
          builder: (context, scroll) => ListView(
            controller: scroll,
            children: const [AppText('Scrollable content')],
          ),
        ),
      ),
      child: const Text('Open'),
    )),
  ),
)
```

Attach the sheet-provided ScrollController to its body ListView or
SingleChildScrollView; otherwise the list cannot hand scrolling over to sheet
resize. The header supports resize, fling snap, downward dismissal, semantics
increase/decrease and a close button. Fixed-pixel heights are re-resolved after
keyboard or window-size changes. Use `AppSheetController.snapTo` for commands.

AppDraggable uses the root Overlay so its preview escapes source clipping.
AppDropTarget validates before synchronously committing a transfer. A modal
sheet's barrier temporarily ignores hit testing during an active AppUI drag,
allowing the existing page targets to receive a drop. Escape cancels payload
transfer and hides the preview; releasing after cancellation cannot commit it.
Backgrounding the app cancels its session and resolves open sheets with null.

AppScaffold's `reservedSpace` mode advertises the floating navigation's extent
through MediaQuery.padding.bottom. A default ListView consumes it automatically;
a custom padding must include it, as the course example does. `overlay` mode
advertises no extra padding. The content can paint behind floating navigation.

AppNavigationBar uses full destination cells, synchronous activation and optional
selection haptics. It caps its width at 480 logical pixels, places labels beside
icons in wide environments, and grows for larger text. AppScaffold reserves the
computed bar height plus spacing. Its `navigationExtent` token is a minimum
reserve for other navigation implementations. Tab content in the course demo
stays mounted, preserving input when switching destinations.

AppThemeData.light/dark are cached product presets derived from FossThemeData
with the token engine. They use grouped surfaces, a blue action color and the
shared radius scale. The presets are final values; pass them to an ordinary
AppTheme constructor rather than a const expression. AppButton and AppTextField
use the product's 48-pixel target size, and AppCard uses one consistent content
inset without doubled header/footer padding.

## Resource limits and validation

The CPU guard refuses new compilation, tests or preview startup at 50% total
host CPU utilization. Do not run test/analyzer/preview compilers simultaneously.
At most one simulator may run, and only with the newest installed iOS runtime.
No simulator is needed for the preview or widget tests.

```bash
bash scripts/dev/check-cpu.sh
flutter analyze --no-pub
CI=true flutter test --no-pub --concurrency=1 test/app_ui
```

For the checked-in CI golden references, use
`CI=true flutter test --no-pub --concurrency=1 --tags golden` from the root.
The default local mode expects separate platform references, which this fork
does not regenerate as part of the CI baseline audit.

Run the example tests separately from `example/`:

```bash
flutter test --no-pub --concurrency=1
```

The per-component matrix and its limits are recorded in
[COMPONENT_QA.md](COMPONENT_QA.md). To regenerate individual light/dark images,
opened-overlay images and contact boards with real fonts:

```bash
APPUI_QA_CAPTURE_DIR=/private/tmp/appui-component-qa \
  flutter test --no-pub --concurrency=1 test/component_visual_qa_test.dart
```

The exporter is skipped unless that environment variable is set; these images
are inspection evidence, separate from committed golden regression baselines.
Preview verifies Flutter
layout and pointer/keyboard behavior. Actual iOS keyboard insets, native haptic
feedback, platform channels, native drag/drop and foldable posture require
device validation; capability-specific work remains in TODO.md.

## iOS encryption declaration

The example Runner references `ios/Runner/Info.plist`, which declares the Boolean
`ITSAppUsesNonExemptEncryption` as `false`, as requested. This means no encryption
or only exempt encryption, including linked libraries. See
[Apple's key definition](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption).
Every consuming application owns its own Info.plist declaration; a package
cannot set it for other apps. Reassess the declaration when adding encryption
libraries or changing app capabilities.

## Upstream maintenance

`origin` is `ycy-0510/clear-appui`; `upstream` is `fossui/fossui`. Fetch updates and
review their diff on a branch before merging. Keep new AppUI features in
`lib/src/app_ui/` and focused upstream fixes in separate commits. Retain
`LICENSE`, `NOTICE` and `fonts/OFL.txt` when distributing the fork.

The floating-top-controls preview demonstrates the shared style in [DESIGN_STYLE.md](DESIGN_STYLE.md).
