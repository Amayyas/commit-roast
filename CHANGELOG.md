# Changelog

## v1.0.0

First release.

A command-line tool that reads a git history and roasts its lazy commit messages, with a shame score out of 100 and a per-rule breakdown.

- **Six detection rules**: generic messages, too-short subjects, ALL CAPS, emoji-only, non-imperative verbs, and duplicated messages.
- **Shame score** out of 100, a per-rule breakdown with example commits, and the single worst commit of the history picked deterministically with a punchline.
- **Filters**: `--repo`, `--limit`, `--since`, `--author`, passed git-side.
- **Output**: colored terminal text that disables itself when piped, `--no-color`, `NO_COLOR` support, and `--format json` for pipelines.
- **Portable**: Objective-C with Foundation only, building on macOS (native Foundation) and Linux (GNUstep), verified in CI on both.
