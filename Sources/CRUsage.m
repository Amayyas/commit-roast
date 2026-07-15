#import "CRUsage.h"

#include <string.h>

#import "CRVersion.h"

// One documented flag: how it is invoked, and what it does. The help renders
// straight from this array, so editing help means editing data, not prose.
typedef struct {
    const char *invocation;   // "--repo <path>"
    const char *flagName;     // "--repo", for the drift test
    const char *description;
} CRFlagSpec;

static const CRFlagSpec kCRFlags[] = {
    { "--repo <path>",     "--repo",     "Repository to roast (default: current directory)" },
    { "--limit <n>",       "--limit",    "Commits to analyze; 0 for all (default: 500)" },
    { "--since <date>",    "--since",    "Only commits since <date> (e.g. \"2 weeks ago\")" },
    { "--author <name>",   "--author",   "Only commits by <name>" },
    { "--format <fmt>",    "--format",   "Output format: text or json (default: text)" },
    { "--no-color",        "--no-color", "Disable ANSI colors" },
    { "-h, --help",        "--help",     "Show this help and exit" },
    { "--version",         "--version",  "Show the version and exit" },
};

static const NSUInteger kCRFlagCount = sizeof(kCRFlags) / sizeof(kCRFlags[0]);

@implementation CRUsage

+ (NSString *)versionString
{
    return [NSString stringWithFormat:@"commit-roast %s", CR_VERSION];
}

+ (NSString *)synopsis
{
    return @"Usage: commit-roast [options]";
}

+ (NSArray *)documentedFlagNames
{
    NSMutableArray *names = [NSMutableArray array];
    NSUInteger i;
    for (i = 0; i < kCRFlagCount; i++) {
        [names addObject:[NSString stringWithUTF8String:kCRFlags[i].flagName]];
    }
    return names;
}

+ (NSString *)helpText
{
    NSMutableString *help = [NSMutableString string];
    [help appendFormat:@"%@\n\n", [self synopsis]];
    [help appendString:@"Roast the lazy commit messages in a git history.\n\n"];
    [help appendString:@"Options:\n"];

    // Align descriptions in one column. The width is computed from the data, so
    // adding a longer flag never has to be matched by hand-counted spaces.
    NSUInteger widest = 0;
    NSUInteger i;
    for (i = 0; i < kCRFlagCount; i++) {
        NSUInteger length = strlen(kCRFlags[i].invocation);
        if (length > widest) {
            widest = length;
        }
    }

    for (i = 0; i < kCRFlagCount; i++) {
        NSString *invocation = [NSString stringWithUTF8String:kCRFlags[i].invocation];
        NSString *padded = [invocation stringByPaddingToLength:widest
                                                    withString:@" "
                                               startingAtIndex:0];
        [help appendFormat:@"  %@   %s\n", padded, kCRFlags[i].description];
    }

    [help appendString:@"\nExamples:\n"];
    [help appendString:@"  commit-roast\n"];
    [help appendString:@"  commit-roast --repo ~/code/myproject --limit 100\n"];
    [help appendString:@"  commit-roast --author \"Ada\" --since \"1 month ago\"\n"];
    [help appendString:@"  commit-roast --format json --no-color > report.json\n"];

    [help appendString:@"\nhttps://github.com/Amayyas/commit-roast\n"];
    return help;
}

@end
