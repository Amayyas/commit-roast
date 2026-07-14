#import "CREmojiOnlyRule.h"

@implementation CREmojiOnlyRule

- (NSString *)identifier { return @"emoji-only"; }
- (NSString *)displayName { return @"Emoji only"; }
- (CRRuleSeverity)severity { return CRRuleSeverityHigh; }

- (BOOL)matchesCommit:(CRCommit *)commit
{
    NSString *subject = [[commit subject] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([subject length] == 0) {
        return NO;
    }

    // Any letter or digit disqualifies: "🔥 Add cache warming" is a normal
    // commit that happens to be wearing a hat.
    if ([subject rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location
        != NSNotFound) {
        return NO;
    }

    // "No alphanumerics" alone is not enough: "..." and "---" would qualify as
    // emoji, which they are not. Strip whitespace and punctuation too, and
    // require something to actually be left — that remainder is the emoji.
    NSMutableCharacterSet *ignored =
        [[[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy] autorelease];
    [ignored formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

    NSString *remainder = [[subject componentsSeparatedByCharactersInSet:ignored]
        componentsJoinedByString:@""];

    return [remainder length] > 0;
}

@end
