#import <Foundation/Foundation.h>

#include <stdio.h>
#include <unistd.h>

#import "CRArgumentParser.h"
#import "CRCommitParser.h"
#import "CRExitCodes.h"
#import "CRGitLogReader.h"
#import "CRRoastEngine.h"
#import "CRRoastRuleRegistry.h"
#import "CRTextFormatter.h"
#import "CRUsage.h"

// Foundation only — importing AppKit or Cocoa here would break the Linux build,
// since GNUstep only provides gnustep-base.

// Reads the repository, roasts it, and prints the report. Returns a process exit
// code.
static int CRRun(CRArguments *args)
{
    NSError *error = nil;
    CRGitLogReader *reader = [[[CRGitLogReader alloc] init] autorelease];
    NSString *rawLog = [reader rawLogWithOptions:[args logOptions] error:&error];

    // A missing repo or a missing git is the environment's fault, not the user's
    // syntax: stderr, exit 1 (runtime), distinct from the exit 2 of a bad flag.
    if (rawLog == nil) {
        fprintf(stderr, "commit-roast: %s\n", [[error localizedDescription] UTF8String]);
        return CRExitRuntimeError;
    }

    NSArray *commits = [CRCommitParser parseRawLog:rawLog];
    CRRoastEngine *engine =
        [[[CRRoastEngine alloc] initWithRules:[CRRoastRuleRegistry defaultRules]] autorelease];
    CRRoastReport *report = [engine analyzeCommits:commits];

    // Text for now; --format json swaps the formatter in #19. main never branches
    // on the format beyond this line — both conform to CROutputFormatter.
    id<CROutputFormatter> formatter =
        [[[CRTextFormatter alloc] initWithColorEnabled:[args colorEnabled]] autorelease];
    fputs([[formatter formatReport:report] UTF8String], stdout);

    return CRExitSuccess;
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

        return CRRun(args);
    }
}
