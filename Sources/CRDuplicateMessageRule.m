#import "CRDuplicateMessageRule.h"

@implementation CRDuplicateMessageRule

- (NSString *)identifier { return @"duplicate-message"; }
- (NSString *)displayName { return @"Duplicated message"; }
- (CRRuleSeverity)severity { return CRRuleSeverityMedium; }

// "Fix"  and "fix" and "fix " are the same message. Comparing raw subjects would
// miss most real duplicates, which is the whole point of the rule.
+ (NSString *)normalizedSubject:(NSString *)subject
{
    NSString *trimmed = [[subject lowercaseString] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Collapse inner runs of whitespace: "add   tests" == "add tests".
    NSArray *words = [trimmed componentsSeparatedByCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *kept = [NSMutableArray array];
    NSEnumerator *e = [words objectEnumerator];
    NSString *word = nil;
    while ((word = [e nextObject]) != nil) {
        if ([word length] > 0) {
            [kept addObject:word];
        }
    }
    return [kept componentsJoinedByString:@" "];
}

// Merge commits are written by git, not by a human. On any repository that uses
// pull requests they are both numerous and near-identical, so counting them
// would bury every real duplicate under "Merge branch 'main'" and make the tool
// look broken.
+ (BOOL)isMergeSubject:(NSString *)subject
{
    NSString *lower = [[self normalizedSubject:subject] lowercaseString];
    return [lower hasPrefix:@"merge branch"]
        || [lower hasPrefix:@"merge pull request"]
        || [lower hasPrefix:@"merge remote-tracking"]
        || [lower hasPrefix:@"merge tag"];
}

- (void)prepareWithCommits:(NSArray *)commits
{
    // One pass, hash table: O(n). Comparing every commit against every other
    // would be O(n²) and would start hurting at a few thousand commits.
    [_counts release];
    _counts = [[NSMutableDictionary alloc] init];

    NSEnumerator *e = [commits objectEnumerator];
    CRCommit *commit = nil;
    while ((commit = [e nextObject]) != nil) {
        NSString *subject = [commit subject];
        if ([[self class] isMergeSubject:subject]) {
            continue;
        }

        NSString *key = [[self class] normalizedSubject:subject];
        if ([key length] == 0) {
            continue;
        }

        NSNumber *seen = [_counts objectForKey:key];
        [_counts setObject:[NSNumber numberWithUnsignedInteger:[seen unsignedIntegerValue] + 1]
                    forKey:key];
    }
}

- (NSUInteger)occurrenceCountForCommit:(CRCommit *)commit
{
    NSString *key = [[self class] normalizedSubject:[commit subject]];
    return [[_counts objectForKey:key] unsignedIntegerValue];
}

- (BOOL)matchesCommit:(CRCommit *)commit
{
    // Without -prepareWithCommits: the table is empty and nothing matches, which
    // is the honest answer: this rule genuinely cannot know yet.
    return [self occurrenceCountForCommit:commit] > 1;
}

// The {count} in "repeated 14 times".
- (NSUInteger)countForCommit:(CRCommit *)commit
{
    return [self occurrenceCountForCommit:commit];
}

- (void)dealloc
{
    [_counts release];
    [super dealloc];
}

@end
