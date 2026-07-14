# Contributing to commit-roast

commit-roast is written in Objective-C against **Foundation only** — no AppKit, no Cocoa. That is what lets the same source build on macOS with Apple's Foundation and on Linux with GNUstep.

## Building on macOS

Foundation is native. You need nothing but the Xcode command line tools:

```bash
xcode-select --install
make
./build/commit-roast
```

## Building on Linux

Reference environment: **Ubuntu 24.04 LTS** — the same one the CI runs on, so these instructions are actually exercised rather than merely written down.

```bash
sudo apt-get install -y clang make gnustep-make libgnustep-base-dev libblocksruntime-dev
make
./build/commit-roast
```

Check the toolchain is visible:

```bash
gnustep-config --base-libs   # should print -lgnustep-base -lobjc ...
```

Versions this was verified against:

| Component | Version |
|---|---|
| Ubuntu | 24.04.4 LTS |
| clang | 20.1.8 |
| gnustep-base | 1.29.0 |
| gnustep-make | 2.9.1 |
| Objective-C runtime | GCC runtime (`libobjc4`) |

## Make targets

| Target | What it does |
|---|---|
| `make` / `make build` | builds `build/commit-roast` |
| `make run` | builds, then runs it |
| `make test` | builds and runs the test suite |
| `make install` | installs into `$(PREFIX)/bin` (`PREFIX ?= /usr/local`) |
| `make uninstall` | removes it |
| `make clean` | deletes `build/` |

## Memory management: MRC, not ARC

**The project uses manual reference counting on both platforms.** Every class implements `-dealloc`, releases its ivars, and calls `[super dealloc]`. `CFLAGS` carries `-fno-objc-arc` everywhere.

This is not nostalgia, it is a portability constraint:

- ARC requires the **libobjc2** runtime (`-fobjc-runtime=gnustep-2.0`).
- Ubuntu and Debian **do not package libobjc2 at all**. Their `gnustep-base` is built against the older **GCC runtime** (`libobjc4`).
- So ARC simply is not available on Linux with distribution packages.
- Using ARC on macOS and MRC on Linux is not an option either: ARC *forbids* explicit `retain` / `release` calls, so the same source cannot compile both ways without `#if` noise in every class.

The alternative — building libobjc2 from source — would turn "install two packages" into "compile a runtime, then rebuild gnustep-base against it". That trade was refused: a one-line install on Linux is the entire point of the portability claim.

So, when writing code here:

```objc
- (instancetype)initWithSHA:(NSString *)sha {
    self = [super init];
    if (self) {
        _sha = [sha copy];       // we own it
    }
    return self;
}

- (void)dealloc {
    [_sha release];              // so we release it
    [super dealloc];
}
```

Convenience constructors return autoreleased objects. `@autoreleasepool` works fine under the GNU runtime and should be used in `main()`.

## Troubleshooting

### `fatal error: 'objc/objc.h' file not found`

Debian and Ubuntu install the Objective-C runtime headers inside **GCC's private directories**, which clang does not search by default. The Makefile already handles this by asking gcc where they live:

```make
GCC_OBJC_INC := $(shell gcc -print-file-name=include)
```

If you hit this error anyway, `libobjc-13-dev` (or whichever version matches your gcc) is probably missing:

```bash
sudo apt-get install -y libobjc-13-dev
```

### `/usr/bin/ld: cannot find -lobjc`

Same cause, other half: the `libobjc.so` development symlink also lives in GCC's directory, not in the standard library path. The Makefile resolves it with `gcc -print-file-name=libobjc.so`. Seeing this error usually means gcc itself is absent — install `gcc` even though the project builds with clang, because it is what tells us where those files are.

### `*** gnustep-config not found. Install the GNUstep toolchain`

The GNUstep toolchain is not installed. Run the `apt-get` line from the Linux section above.

### Selector or class errors that mention ARC

If you see complaints about `objc_retainAutoreleasedReturnValue` or similar, something is compiling with `-fobjc-arc`. It should not be — see the MRC section above. Check that no target overrides `CFLAGS`.

### Runtime 1.x versus 2.0

If you are reading GNUstep documentation online, most of it assumes **libobjc2** (the "runtime 2.0"), which supports ARC, blocks and modern syntax. Distribution packages ship the **GCC runtime** instead. When a snippet from the internet does not compile here, that mismatch is very often why.

## Pull requests

- One issue per pull request, with `Closes #N` in the commit message.
- `make` must build with no warnings under `-Wall -Wextra`.
- `make test` must pass on both platforms.
