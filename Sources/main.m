#import <Foundation/Foundation.h>

#include <stdio.h>

#include "CRVersion.h"

// Foundation only — importing AppKit or Cocoa here would break the Linux build,
// since GNUstep only provides gnustep-base.

static const char *const kBanner =
    "                               _ _                            _\n"
    "  ___ ___  _ __ ___  _ __ ___ (_) |_      _ __ ___   __ _ ___| |_\n"
    " / __/ _ \\| '_ ` _ \\| '_ ` _ \\| | __|____| '__/ _ \\ / _` / __| __|\n"
    "| (_| (_) | | | | | | | | | | | | ||_____| | | (_) | (_| \\__ \\ |_\n"
    " \\___\\___/|_| |_| |_|_| |_| |_|_|\\__|    |_|  \\___/ \\__,_|___/\\__|\n";

static void CRPrintBanner(void)
{
    // fputs rather than NSLog: NSLog writes to stderr and prefixes every line
    // with a timestamp and the process name, which is not what a CLI banner is.
    fputs(kBanner, stdout);
    fprintf(stdout, "\n  Roasting your commit messages since 2026.  v%s\n\n",
            CR_VERSION);
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    @autoreleasepool {
        CRPrintBanner();
    }

    return 0;
}
