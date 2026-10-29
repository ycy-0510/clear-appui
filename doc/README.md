# Clear AppUI documentation

Start with [getting started](app_ui/GETTING_STARTED.md), then read the
[component and composition guide](app_ui/COMPONENTS.md) for the APIs needed by
your screen. The installed source is authoritative for constructor signatures.

| Guide | Purpose |
| --- | --- |
| [Getting started](app_ui/GETTING_STARTED.md) | Git installation, themes, and a runnable example. |
| [Components](app_ui/COMPONENTS.md) | Product API map and presentation contracts. |
| [Agent skill](app_ui/AGENT_SKILL.md) | Cross-agent installation and package compatibility checks. |
| [Development](app_ui/DEVELOPMENT.md) | SDK, Widget Preview, native demos, and verification commands. |
| [Design guidance](app_ui/APPLE_HIG_NOTES.md) | Apple references, implementation choices, and platform limits. |
| [Component QA](app_ui/COMPONENT_QA.md) | Per-component checks, evidence, fixes, and remaining gaps. |
| [Golden migration](app_ui/GOLDEN_SDK_MIGRATION.md) | SDK-specific reference changes. |

## Maintaining these docs

Update usage guides and the changelog when public APIs or observable behavior
change. Update the skill contract and integration instructions when its expected
APIs change. Keep examples compatible with the installed Git dependency.

Record implementation status in [TODO.md](../TODO.md) and verification evidence
in the QA guide. Passing widget tests, previews, and native-device acceptance
are separate forms of evidence. Keep unfinished checks explicitly pending.

The repository README introduces the library to users. Detailed setup,
implementation decisions, and maintenance records belong in these guides.
