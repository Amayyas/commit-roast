#import "CRAllCapsRule.h"

#import "CRStringUtils.h"

// Below this, an all-caps subject is an acronym ("CI", "API"), not shouting.
static const NSUInteger kCRMinimumShoutLength = 5;

@implementation CRAllCapsRule

- (NSString *)identifier { return @"all-caps"; }
- (NSString *)displayName { return @"ALL CAPS"; }
- (CRRuleSeverity)severity { return CRRuleSeverityMedium; }

- (BOOL)matchesCommit:(CRCommit *)commit
{
    NSString *subject = [[commit subject] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (CRGraphemeLength(subject) < kCRMinimumShoutLength) {
        return NO;
    }

    // Without this, "1.2.0" and "🔥 🔥" are "all caps" — they simply contain no
    // lowercase to differ from. A subject must have letters to be shouting them.
    if ([subject rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location
        == NSNotFound) {
        return NO;
    }

    return [[subject uppercaseString] isEqualToString:subject];
}

@end
