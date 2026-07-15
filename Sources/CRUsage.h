#import <Foundation/Foundation.h>

// Single source of truth for the help text and the version string.
//
// The flag table here is the same list the help renders from. A test asserts the
// parser accepts every flag documented here, so the two cannot drift: the classic
// way a hand-rolled CLI's --help ends up lying is by describing a flag the code
// no longer has, or missing one it grew.
@interface CRUsage : NSObject

// "commit-roast X.Y.Z", from CR_VERSION.
+ (NSString *)versionString;

// One line: "Usage: commit-roast [options]".
+ (NSString *)synopsis;

// The full --help text: synopsis, description, aligned options with defaults,
// examples, and the repository URL.
+ (NSString *)helpText;

// Every documented long-form flag, e.g. "--repo". Used by the drift test.
+ (NSArray *)documentedFlagNames;

@end
