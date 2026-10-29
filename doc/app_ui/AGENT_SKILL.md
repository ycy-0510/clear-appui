# Agent skill integration

The `clear-appui` skill uses the portable Agent Skills format. Its instructions
are coupled to the actual installed Clear AppUI sources.

## Install

From the consuming repository, run:

```bash
npx skills add ycy-0510/clear-appui --skill clear-appui
```

The Skills CLI offers agent and installation-scope selection. For a local,
noninteractive Codex installation:

```bash
npx skills add ycy-0510/clear-appui --skill clear-appui --agent codex --yes
```

Use a Node.js version supported by the current
[Skills CLI](https://github.com/vercel-labs/skills). Skill installation copies
instructions and supporting scripts. Add the Dart dependency separately as
described in [getting started](GETTING_STARTED.md).

## Resolve the package

After `flutter pub get`, run the installed skill's doctor, for example:

```bash
node .agents/skills/clear-appui/scripts/doctor.mjs Flutter
```

Pass the Flutter project directory; use `.` if the application lives at the
repository root. The doctor resolves `fossui` through package_config.json and
reports the package root, public entrypoints, source directory, bundled skill,
API contract and resolved Git SHA. It rejects the upstream package and an
incompatible API contract.

If the installed skill differs from the one bundled with the resolved package,
read the bundled skill before editing. This keeps agent instructions aligned
with a pinned dependency even after the distribution repository changes.

## Maintaining the integration

Keep the public API map and examples in sync with implementation. Change
`doc/app_ui/agent-contract.json` and the skill's expected contract together when
introducing an incompatible contract. Verify the doctor against a real consuming
project after changing installation or resolution behavior.

The skill tells an agent to inspect real constructors, compose existing
components, use shared tokens, and verify interaction. It cannot guarantee that
an agent follows instructions; application tests and review remain necessary.
