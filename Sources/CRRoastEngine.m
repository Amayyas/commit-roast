#import "CRRoastEngine.h"

#import "CRRuleBreakdown.h"

// At most this many example commits per rule in the breakdown.
static const NSUInteger kCRMaxExamplesPerRule = 3;

// Sorts breakdowns most-frequent first. A plain selector comparator would need
// CRRuleBreakdown to expose an NSNumber; a function keeps the ordering logic
// here, next to the engine that depends on it. Ties break on identifier so the
// order is fully determined and the output is reproducible.
static NSInteger CRBreakdownCompare(id a, id b, void *context)
{
    (void)context;
    NSUInteger ca = [(CRRuleBreakdown *)a matchCount];
    NSUInteger cb = [(CRRuleBreakdown *)b matchCount];
    if (ca > cb) {
        return NSOrderedAscending;   // more matches sorts earlier
    }
    if (ca < cb) {
        return NSOrderedDescending;
    }
    return [[(CRRuleBreakdown *)a identifier] compare:[(CRRuleBreakdown *)b identifier]];
}

@implementation CRRoastEngine

- (instancetype)initWithRules:(NSArray *)rules
{
    self = [super init];
    if (self) {
        _rules = [rules copy];
    }
    return self;
}

- (CRRoastReport *)analyzeCommits:(NSArray *)commits
{
    NSUInteger total = [commits count];

    // No commits: score 0, empty breakdown, and crucially no division by zero.
    if (total == 0) {
        return [[[CRRoastReport alloc] initWithTotalCommits:0
                                              guiltyCommits:0
                                                 shameScore:0.0
                                                  breakdown:[NSArray array]] autorelease];
    }

    // Global-context rules (duplicates) need the whole history first.
    NSEnumerator *prep = [_rules objectEnumerator];
    id<CRRoastRule> rule = nil;
    while ((rule = [prep nextObject]) != nil) {
        if ([rule respondsToSelector:@selector(prepareWithCommits:)]) {
            [rule prepareWithCommits:commits];
        }
    }

    // Per rule: how many commits it caught, and up to three to show.
    NSMutableDictionary *matchCounts = [NSMutableDictionary dictionary];   // id -> NSNumber
    NSMutableDictionary *examples = [NSMutableDictionary dictionary];       // id -> NSMutableArray
    NSUInteger guilty = 0;

    NSEnumerator *ce = [commits objectEnumerator];
    CRCommit *commit = nil;
    while ((commit = [ce nextObject]) != nil) {
        BOOL commitIsGuilty = NO;

        NSEnumerator *re = [_rules objectEnumerator];
        while ((rule = [re nextObject]) != nil) {
            if (![rule matchesCommit:commit]) {
                continue;
            }
            commitIsGuilty = YES;

            NSString *identifier = [rule identifier];
            NSNumber *count = [matchCounts objectForKey:identifier];
            [matchCounts setObject:[NSNumber numberWithUnsignedInteger:
                                       [count unsignedIntegerValue] + 1]
                            forKey:identifier];

            NSMutableArray *examplesForRule = [examples objectForKey:identifier];
            if (examplesForRule == nil) {
                examplesForRule = [NSMutableArray array];
                [examples setObject:examplesForRule forKey:identifier];
            }
            if ([examplesForRule count] < kCRMaxExamplesPerRule) {
                [examplesForRule addObject:commit];
            }
        }

        // The whole point: a commit tripping three rules is ONE guilty commit,
        // not three. Otherwise the score climbs past 100 and stops meaning
        // anything.
        if (commitIsGuilty) {
            guilty++;
        }
    }

    // Build a breakdown for every rule that fired at least once.
    NSMutableArray *breakdown = [NSMutableArray array];
    NSEnumerator *be = [_rules objectEnumerator];
    while ((rule = [be nextObject]) != nil) {
        NSString *identifier = [rule identifier];
        NSUInteger count = [[matchCounts objectForKey:identifier] unsignedIntegerValue];
        if (count == 0) {
            continue;
        }
        double percentage = 100.0 * (double)count / (double)total;
        CRRuleBreakdown *entry =
            [[[CRRuleBreakdown alloc] initWithRule:rule
                                        matchCount:count
                                        percentage:percentage
                                          examples:[examples objectForKey:identifier]] autorelease];
        [breakdown addObject:entry];
    }
    [breakdown sortUsingFunction:CRBreakdownCompare context:NULL];

    double shameScore = 100.0 * (double)guilty / (double)total;

    return [[[CRRoastReport alloc] initWithTotalCommits:total
                                          guiltyCommits:guilty
                                             shameScore:shameScore
                                              breakdown:breakdown] autorelease];
}

- (void)dealloc
{
    [_rules release];
    [super dealloc];
}

@end
