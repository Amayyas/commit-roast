#import "CRShortMessageRule.h"

#import "CRStringUtils.h"

static const NSUInteger kCRMinimumSubjectLength = 10;

@implementation CRShortMessageRule

- (NSString *)identifier { return @"too-short"; }
- (NSString *)displayName { return @"Message too short"; }
- (CRRuleSeverity)severity { return CRRuleSeverityMedium; }

- (BOOL)matchesCommit:(CRCommit *)commit
{
    NSString *subject = [[commit subject] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return CRGraphemeLength(subject) < kCRMinimumSubjectLength;
}

@end
