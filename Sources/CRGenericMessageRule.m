#import "CRGenericMessageRule.h"

@implementation CRGenericMessageRule

- (NSString *)identifier { return @"generic-message"; }
- (NSString *)displayName { return @"Generic message"; }
- (CRRuleSeverity)severity { return CRRuleSeverityHigh; }

+ (NSSet *)genericWords
{
    static NSSet *words = nil;
    if (words == nil) {
        words = [[NSSet alloc] initWithObjects:
            @"fix", @"fixes", @"fixed",
            @"wip", @"update", @"updates", @"updated",
            @"test", @"tests", @"asdf", @"stuff", @"changes",
            @"misc", @"tmp", @"temp", @"minor", @"oops",
            @"cleanup", @"refactor", @"final", @"done", @".", nil];
    }
    return words;
}

- (BOOL)matchesCommit:(CRCommit *)commit
{
    NSString *subject = [[commit subject] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([subject length] == 0) {
        return NO;   // an empty subject is the too-short rule's business
    }

    NSString *word = [subject lowercaseString];

    // "Fix." and "fix" are the same commit wearing a different hat. Strip
    // trailing punctuation before comparing — but keep the bare "." itself,
    // which is a genuine (and glorious) commit message.
    if (![word isEqualToString:@"."]) {
        word = [word stringByTrimmingCharactersInSet:
                    [NSCharacterSet punctuationCharacterSet]];
    }

    // The word must BE the whole message. "fix login redirect on Safari" is a
    // perfectly good commit and must not be caught here.
    return [[[self class] genericWords] containsObject:word];
}

@end
