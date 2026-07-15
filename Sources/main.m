#import <Foundation/Foundation.h>

#include <stdio.h>
#include <unistd.h>

#include "CRVersion.h"

#import "CRArgumentParser.h"
#import "CRExitCodes.h"
#import "CRUsage.h"

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

int main(int argc, char *argv[])
{
    @autoreleasepool {
        CRArgumentParser *parser = [[[CRArgumentParser alloc] init] autorelease];
        CRArguments *args = [parser parseArguments:argv
                                             count:argc
                                       stdoutIsTTY:isatty(STDOUT_FILENO) ? YES : NO];

        // A usage error is the user's, so it goes to stderr with a short reminder
        // (never the whole help, which would bury the message) and exit code 2.
        if (![args ok]) {
            fprintf(stderr, "commit-roast: %s\n", [[args errorMessage] UTF8String]);
            fprintf(stderr, "%s\n", [[CRUsage synopsis] UTF8String]);
            fprintf(stderr, "Try 'commit-roast --help' for more information.\n");
            return CRExitUsageError;
        }

        // --help and --version are deliberate requests, not errors: stdout, exit 0.
        if ([args action] == CRActionHelp) {
            fputs([[CRUsage helpText] UTF8String], stdout);
            return CRExitSuccess;
        }
        if ([args action] == CRActionVersion) {
            fprintf(stdout, "%s\n", [[CRUsage versionString] UTF8String]);
            return CRExitSuccess;
        }

        // The analysis pipeline is wired in with the formatters (#17-#19). For
        // now the run path prints the banner.
        CRPrintBanner();
    }

    return CRExitSuccess;
}
