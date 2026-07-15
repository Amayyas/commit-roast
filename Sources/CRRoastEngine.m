#import "CRRoastEngine.h"

#include <string.h>

#import "CRRoastLineGenerator.h"
#import "CRRuleBreakdown.h"
#import "CRStringUtils.h"

// At most this many example commits per rule in the breakdown.
static const NSUInteger kCRMaxExamplesPerRule = 3;

// Everything needed to rank a commit's badness, plus tie-breakers. Filled for
// each guilty commit and compared against the running worst.
typedef struct {
    NSInteger score;          // sum of triggered severities
    NSUInteger ruleCount;     // how many rules it tripped
    NSInteger maxSeverity;    // the harshest single rule
    NSUInteger subjectLength; // graphemes; shorter is worse
} CRBadness;

// Is `a` a worse commit than `b`? The chain is exhaustive down to the SHA, so
// two runs on the same history always elect the same commit — the output has to
// be reproducible, or it cannot be tested and re-runs would reshuffle it.
static BOOL CRBadnessIsWorse(CRBadness a, NSString *shaA, CRBadness b, NSString *shaB)
{
    if (a.score != b.score) {
        return a.score > b.score;
    }
    if (a.ruleCount != b.ruleCount) {
        return a.ruleCount > b.ruleCount;
    }
    if (a.maxSeverity != b.maxSeverity) {
        return a.maxSeverity > b.maxSeverity;
    }
    if (a.subjectLength != b.subjectLength) {
        return a.subjectLength < b.subjectLength;   // shorter subject is worse
    }
    return [shaA compare:shaB] == NSOrderedAscending;   // last resort, total order
}

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

    // The running worst commit, and the harshest rule it tripped (for its
    // punchline). Nil until some commit is actually guilty.
    CRCommit *worstCommit = nil;
    id<CRRoastRule> worstRule = nil;
    CRBadness worstBadness;
    memset(&worstBadness, 0, sizeof(worstBadness));

    NSEnumerator *ce = [commits objectEnumerator];
    CRCommit *commit = nil;
    while ((commit = [ce nextObject]) != nil) {
        CRBadness badness;
        memset(&badness, 0, sizeof(badness));
        id<CRRoastRule> harshestRule = nil;   // most severe rule this commit trips

        NSEnumerator *re = [_rules objectEnumerator];
        while ((rule = [re nextObject]) != nil) {
            if (![rule matchesCommit:commit]) {
                continue;
            }

            badness.score += [rule severity];
            badness.ruleCount += 1;
            if ((NSInteger)[rule severity] > badness.maxSeverity) {
                badness.maxSeverity = [rule severity];
                harshestRule = rule;
            }

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

        if (badness.ruleCount == 0) {
            continue;   // a clean commit
        }

        // The whole point: a commit tripping three rules is ONE guilty commit,
        // not three. Otherwise the score climbs past 100 and stops meaning
        // anything.
        guilty++;

        badness.subjectLength = CRGraphemeLength([commit subject]);
        if (worstCommit == nil
            || CRBadnessIsWorse(badness, [commit sha], worstBadness, [worstCommit sha])) {
            worstCommit = commit;
            worstRule = harshestRule;
            worstBadness = badness;
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

    CRRoastReport *report =
        [[[CRRoastReport alloc] initWithTotalCommits:total
                                       guiltyCommits:guilty
                                          shameScore:shameScore
                                           breakdown:breakdown] autorelease];

    // The finale: the single most roastable commit, with a punchline drawn from
    // its harshest rule — the one that best explains why it is the worst. Left
    // nil on a spotless history, so the formatter congratulates instead of
    // printing an empty box.
    if (worstCommit != nil) {
        NSUInteger count = 0;
        if ([worstRule respondsToSelector:@selector(countForCommit:)]) {
            count = [worstRule countForCommit:worstCommit];
        }
        CRRoastLineGenerator *generator =
            [[[CRRoastLineGenerator alloc] init] autorelease];
        [report setWorstCommit:worstCommit];
        [report setWorstPunchline:[generator punchlineForRule:worstRule
                                                       commit:worstCommit
                                                        count:count]];
    }

    return report;
}

- (void)dealloc
{
    [_rules release];
    [super dealloc];
}

@end
