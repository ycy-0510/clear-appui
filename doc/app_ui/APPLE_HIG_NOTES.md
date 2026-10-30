# Apple HIG reference — Sheet update

## Button hierarchy and appearance — 2026-10-31

Reviewed Apple's [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
and [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode).
Use a prominent accent treatment for the most likely action and less prominent
styles for alternatives. Distinguish a coherent set by style rather than by
making one option larger. Custom buttons need a press state. Dark appearance
uses adaptive semantic colors and elevated surfaces; it is not a literal
inversion of light appearance. Check at least 4.5:1 text contrast in both modes.
HIG does not mandate a particular light-gray secondary fill in dark appearance.
AppUI's elevated neutral secondary fill and centered large continuation style
are product choices implementing that hierarchy, without a glass effect.

Tap cancellation follows Flutter's gesture arena and device-specific slop. After
a drag cancels a tap, neither activation nor feedback may revive on reentry.
This is a gesture contract, independent of the chosen color or corner radius.

Apple's [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
guidance recommends one sheet at a time from the main interface and an internal
Back step or a full-screen flow for longer editing. Native page-sheet stacks can
preserve context, but this is not a reason to add a hierarchy of modal editors.
AppUI keeps unavoidable parent layers slightly recessed, with only the top layer
interactive/focusable. The 0.965 scale and 12-point offset are product values.
Fast downward flings bypass intermediate detents; slow/held pulls settle and only
dismiss after deliberate travel past the smallest height. Dismissal vetoes apply.

Reviewed 2026-10-29 from Apple's official documentation:

- [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [WWDC25: Build a UIKit app with the new design, Presentations at 13:31](https://developer.apple.com/videos/play/wwdc2025/284/)

The official Markdown pages were downloaded for local inspection to
`/private/tmp/appui-apple-hig-sheets.md` and
`/private/tmp/appui-apple-hig-materials.md`. These temporary files are reference
copies; the repository records the implementation decisions here.

## Guidance applied

Resizable sheets use resting heights and a visible grabber. The grabber should
also support tapping to cycle heights and accessible adjustment. A contextual
sheet affecting the underlying task can be nonmodal on iOS/iPadOS. The course
demo uses that presentation; ordinary confirmation sheets can remain modal.
Apple recommends a single sheet from the main interface and appropriate
dismiss/cancel affordances.

Apple's iOS 26 presentation session describes adaptive sheet materials at
different sizes. Larger glass regions become more opaque for readability.
The Flutter implementation approximates the material with clipped background
blur and a theme-colored surface; it does not claim to implement UIGlassEffect's
native refraction or vibrancy.

## Implementation and calibration

The sheet uses actual available height and its smallest configured detent as
the interpolation range. Insets diminish and opacity increases continuously;
there is no fixed half-height cutoff. Floating bottom corners flatten as the
surface fills the available area. High contrast uses an opaque surface.

The default inset, radius, blur and minimum alpha are tunable AppThemeData.sheet
tokens, not measurements specified by HIG. The user's earlier numbers were
illustrative and have not been retained as requirements. The usual initial
detent remains medium; smaller custom detents are available when appropriate.

Also reviewed Apple's [Get to know the new design system](https://developer.apple.com/videos/play/wwdc2025/356/):
as a sheet grows, its material recedes and becomes more opaque to support
focused interaction. iPad/Mac geometry should relate to the window rather than
copying phone metrics blindly.

## Navigation, spacing and corners

The October 29 navigation review found that the old expanded destination
only hit-tested the small central painted button. FossButton now uses opaque
hit testing for its whole advertised target. AppNavigationBar has dedicated
synchronous destination controls, with no asynchronous loading gate. Pointer,
keyboard and accessibility actions share the same callback. Selection feedback
does not delay the destination change; cancelled presses do not select.

Apple lists 44 × 44 pt as the default iOS/iPadOS control size, and also asks for
appropriate space between controls. AppUI uses 48 logical pixels for action
and field heights; each navigation cell is at least 56 pixels high. The full
rectangular destination is interactive, including its unpainted space. The
selected state includes a visible shape and accessibility state, not color
alone. Labels remain visible and scale with system text settings. Wide layouts
put icons and labels side by side. Navigation remains mounted between tabs,
preserving form input and scroll state.

HIG does not give one universal corner radius for every component. Apple's
adoption guide emphasizes concentric shapes and appropriate spacing. The
floating bar and its inset selection use stadium shapes, so their radii change
with their heights and six-pixel inset. Cards, fields and sheets have different
roles and use the shared radius scale. Product colors, radii and spacing are
still derived through FossThemeData; the upstream gallery retains its own
appearance. The course example uses grouped rows, one explanatory caption,
aligned 20-pixel page insets and a bounded floating bar instead of repeated
oversized cards. These are product design choices informed by HIG, not Apple's
certification or exact native metrics. The Mac window demonstrates iOS-style
components; it is not a native AppKit tab view or native Liquid Glass renderer.

## Continuous interaction and scrolling

The motion review applies brief, purposeful feedback and predictable transitions,
while preserving FossUI's visual language. One moving navigation indicator and
animated control-group geometry preserve visual identity across changes; Reduce
Motion removes travel. Quick actions do not flash loading states or wait for
animation. These implementation choices follow HIG principles, not a prescribed
Apple animation duration or native material.

The scroll review avoids nested same-direction scroll views. A page whose header,
search and results scroll together uses one sliver viewport. The viewport can
extend under floating controls; trailing scroll padding lets the last row clear
both controls and device insets. Grouped lists round only exterior group corners.
HIG references do not authorize changing the host app's information architecture.


## Top scroll backdrop

AppScaffold keeps the scroll viewport behind top controls. Leading content
padding includes the measured controls and system top inset. The top area is
transparent at rest and progressively gains a clipped frosted tint as the page
scrolls, preserving context without moving or replacing the controls. High
Contrast uses an opaque final tint; Reduce Motion removes temporal interpolation.
The 48-point transition distance, 12-point blur and tint opacity are product
implementation choices in the shared component, not Apple-prescribed metrics.
See [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views)
for scroll-edge context and content visibility guidance.

## Compact navigation and scroll titles

Compact iOS navigation now uses an 8-point screen-edge gap rather than adding
the full bottom safe inset. This is a Clear AppUI product choice, not an Apple
prescribed value. Keep the selection surface concentric with the capsule and
verify Home indicator/gesture clearance on a real phone. Trailing scroll content
still clears the actual floating bar; the viewport is not cropped by a SafeArea.

`AppCollapsingTitle` follows the title's measured occlusion under top chrome.
The compact version appears and shrinks continuously, reverses when returning
to the top and excludes duplicate semantics. Inactive retained destinations and
nested scaffolds have separate title ownership. Reduce Motion retains the
current scroll position without an extra timed transition. Use this for a
host-provided logo as well as a textual title; do not recolor the source artwork.
