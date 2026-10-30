# Interaction changes — 2026-10-31

Source checkpoint; final validation is deferred at the owner's request.

- Tap slop and arena cancellation permanently retire a pointer press, including
  its scale feedback. Return-to-origin cannot revive it. Keyboard/accessibility
  activation remain independent. FossButton's existing API is preserved with
  additive pointer-activation and cancellation callbacks.
- Large continuation labels are centered and use shared rounded geometry.
  Tight-width parents align direct form actions. Variants retain hierarchy;
  secondary dark fills use existing foreground/popover tokens.
- Fast downward sheet flings bypass detents. Slow pulls settle; reaching a
  smaller height while held never closes the sheet. Host dismissal protection
  and asynchronous vetoes remain in force.
- Unavoidable nested presentations recess their parent continuously, isolate
  focus/input, and hide deeper visual layers. Prefer a single sheet/internal
  step rather than adding nested editors. Focus restores after the parent mounts.
- The portable Skill records toolbar/form roles and visible contextual feedback.

The first 14 gesture/sheet tests passed before the final auto-width, nested
layer and dismissal-protection changes. An initial strict analysis reported
documentation/style issues; these were edited but have not been rerun.
Additional nested/protected-dismissal/form tests are authored and unexecuted.

Pending: final strict analysis, all AppUI/upstream button tests, expected dark
button golden review, Skill validation/doctor, cross-container/keyboard/error
regressions and physical phone acceptance. Existing golden baselines are
intentionally preserved until their differences can be rendered and reviewed.
No new native build, install, simulator, preview or Hot Restart is part of this
source checkpoint.
