# commit-roast

[![CI](https://github.com/Amayyas/commit-roast/actions/workflows/ci.yml/badge.svg)](https://github.com/Amayyas/commit-roast/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A command-line tool that reads a git history and roasts the lazy commit messages in it — the `wip`s, the `fix`es, the ALL CAPS, the fourteenth `wip` in a row — with a shame score out of 100 and a breakdown by offense.

Written in Objective-C with **Foundation only** (no AppKit, no Cocoa), so it builds on macOS with the system Foundation and on Linux with GNUstep.

```
commit-roast

  Shame score  █████████████░░░░░░░░░░░ 56/100
  14 of 25 commits could have tried harder.

What we found
  █████░░░░░░░  [medium]  Message too short      11 (44%)
      0e4c1b7  fix
      fd16f9a  update
      0eb8d35  wip
  █████░░░░░░░  [high]  Generic message        10 (40%)
      0e4c1b7  fix
      fd16f9a  update
      0eb8d35  wip
  ███░░░░░░░░░  [medium]  Duplicated message     7 (28%)
      0e4c1b7  fix
      0eb8d35  wip
      677243f  fix
  █░░░░░░░░░░░  [low]  Not in the imperative  2 (8%)
      29e1a7f  Fixing the flaky retry test
      41eb234  Added tests for the parser
  ░░░░░░░░░░░░  [medium]  ALL CAPS               1 (4%)
      1f65e66  FIX THE BUILD
  ░░░░░░░░░░░░  [high]  Emoji only             1 (4%)
      53e57ac  🔥

Worst offender
  ┌───────────────────────────────────────────────────────────┐
  │ 0e4c1b7  fix                                              │
  │ "fix" tells me a change happened. Nothing else, but that. │
  └───────────────────────────────────────────────────────────┘
```

Full sample: [`Examples/sample-output.txt`](Examples/sample-output.txt).

## Features

- **Six detection rules** — generic messages, too-short subjects, ALL CAPS, emoji-only, non-imperative verbs, and duplicated messages.
- **A shame score** out of 100: the share of commits that trip at least one rule.
- **A breakdown** per rule, with the worst offenders as examples.
- **The single worst commit** of the whole history, picked deterministically, with a punchline.
- **Colored terminal output** that turns itself off when piped, plus a `--no-color` flag and `NO_COLOR` support.
- **JSON output** for pipelines and dashboards.
- **Sharp but never mean** — it roasts the message, never the person.

## Installation

### macOS

Foundation is native, so all you need is the Xcode command line tools:

```sh
xcode-select --install
make
sudo make install        # installs to /usr/local/bin
```

### Linux

Needs the GNUstep toolchain. On Ubuntu / Debian:

```sh
sudo apt-get install -y clang make gobjc gnustep-make libgnustep-base-dev
make
sudo make install
```

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full toolchain notes and troubleshooting.

## Usage

```
Usage: commit-roast [options]

Options:
  --repo <path>     Repository to roast (default: current directory)
  --limit <n>       Commits to analyze; 0 for all (default: 500)
  --since <date>    Only commits since <date> (e.g. "2 weeks ago")
  --author <name>   Only commits by <name>
  --format <fmt>    Output format: text or json (default: text)
  --no-color        Disable ANSI colors
  -h, --help        Show this help and exit
  --version         Show the version and exit
```

```sh
commit-roast                                          # the current repo
commit-roast --repo ~/code/myproject --limit 100      # a specific repo, last 100 commits
commit-roast --author "Ada" --since "1 month ago"     # filter by author and date
commit-roast --format json --no-color > report.json   # machine-readable
```

`--since` is passed straight to `git log`, so it accepts everything git does (`2 weeks ago`, `2024-01-01`, `yesterday`). The 500-commit default is a performance cap; pass `--limit 0` to analyze the entire history.

## Detection rules

| Rule | Severity | Fires on |
|---|---|---|
| Generic message | High | `fix`, `wip`, `update`, `asdf`, `stuff`, `.` |
| Emoji only | High | `🔥`, `🎉` |
| Message too short | Medium | a subject under 10 characters |
| ALL CAPS | Medium | `FIX THE BUILD` |
| Duplicated message | Medium | the same subject repeated across the history |
| Not in the imperative | Low | `Added tests`, `Fixing the build` |

A commit that trips several rules still counts once toward the score. Merge commits are excluded from the duplicate check — nobody wrote them.

## JSON output

`--format json` emits a single JSON object; stdout carries nothing else, so `commit-roast --format json | jq .` just works.

```json
{
  "version": "1.0",
  "repository": "/path/to/repo",
  "analyzed_commits": 25,
  "guilty_commits": 14,
  "shame_score": 56,
  "breakdown": [
    {
      "rule": "generic-message",
      "display_name": "Generic message",
      "severity": "high",
      "count": 10,
      "percentage": 40,
      "examples": [
        { "sha": "0e4c1b7", "author": "Dev", "date": "2026-01-06T10:00:00+01:00", "message": "fix" }
      ]
    }
  ],
  "worst_commit": {
    "sha": "0e4c1b7",
    "message": "fix",
    "punchline": "\"fix\" tells me a change happened. Nothing else, but that.",
    "rules": ["too-short", "generic-message", "duplicate-message"]
  }
}
```

`version` versions the **schema**, not the tool. `worst_commit` is `null` for a spotless history.

## Why Objective-C?

A commit-message linter does not need Objective-C. The point is the opposite: it is a small, self-contained program that exercises a runtime and a standard library which do not hold your hand.

- **Foundation without Cocoa.** Everything runs on `NSString`, `NSArray`, `NSTask`, `NSJSONSerialization` — no application framework. That is what lets the same source compile on macOS's native Foundation and on Linux's GNUstep.
- **Manual reference counting.** GNUstep on Debian/Ubuntu ships the GCC runtime, which has no ARC, so the project uses `retain`/`release` throughout — and the memory is verified under valgrind, not assumed.
- **`NSTask` around `git`.** No git library is embedded; the tool shells out and parses `git log`, handling the environment errors (no git, not a repo, empty repo) that come with that.
- **Protocol-oriented rules.** Each detection rule conforms to one protocol, so adding a rule touches neither the engine nor the other rules. The one rule that needs global context (duplicates) uses an optional protocol method rather than a special case in the engine.

Cross-platform portability is verified in CI on both macOS and Linux on every push.

## Sibling projects

Part of a small family of "roast" tools:

- [focus-roast](https://github.com/Amayyas/focus-roast)
- [repo-roast](https://github.com/Amayyas/repo-roast)

## Contributing

Build notes, the memory-management conventions, and GNUstep troubleshooting live in [`CONTRIBUTING.md`](CONTRIBUTING.md). `make test` runs the suite on both platforms.

## License

MIT — see [`LICENSE`](LICENSE).
