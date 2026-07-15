#import "CREngineTests.h"

#import "CRTest.h"

#import "CRCommit.h"
#import "CRRoastEngine.h"
#import "CRRoastLineGenerator.h"
#import "CRRoastRuleRegistry.h"
#import "CRRuleBreakdown.h"

static CRCommit *CRCm(NSString *sha, NSString *subject)
{
    return [[[CRCommit alloc] initWithSHA:sha authorName:@"X" authorEmail:@"x@y"
                                     date:nil subject:subject body:@""] autorelease];
}

// The set of rule identifiers that fire on one commit, given the whole history
// the global-context rules need. Mirrors what the engine does.
static NSSet *CRRulesFiring(CRCommit *commit, NSArray *history)
{
    NSMutableSet *fired = [NSMutableSet set];
    NSArray *rules = [CRRoastRuleRegistry defaultRules];
    NSEnumerator *pe = [rules objectEnumerator];
    id<CRRoastRule> rule = nil;
    while ((rule = [pe nextObject]) != nil) {
        if ([rule respondsToSelector:@selector(prepareWithCommits:)]) {
            [rule prepareWithCommits:history];
        }
    }
    NSEnumerator *re = [rules objectEnumerator];
    while ((rule = [re nextObject]) != nil) {
        if ([rule matchesCommit:commit]) {
            [fired addObject:[rule identifier]];
        }
    }
    return fired;
}

static BOOL CRFires(NSString *identifier, NSString *subject)
{
    CRCommit *c = CRCm(@"deadbeef", subject);
    return [CRRulesFiring(c, [NSArray arrayWithObject:c]) containsObject:identifier];
}

// A parameterizable rule, so scoring and tie-breaks can be tested in isolation.
@interface CRFakeRule : NSObject <CRRoastRule>
{
    NSString *_ident;
    CRRuleSeverity _sev;
    NSSet *_match;
}
- (id)initWithId:(NSString *)i severity:(CRRuleSeverity)s match:(NSArray *)m;
@end

@implementation CRFakeRule
- (id)initWithId:(NSString *)i severity:(CRRuleSeverity)s match:(NSArray *)m
{
    self = [super init];
    if (self) { _ident = [i copy]; _sev = s; _match = [[NSSet setWithArray:m] retain]; }
    return self;
}
- (NSString *)identifier { return _ident; }
- (NSString *)displayName { return _ident; }
- (CRRuleSeverity)severity { return _sev; }
- (BOOL)matchesCommit:(CRCommit *)c { return [_match containsObject:[c subject]]; }
- (void)dealloc { [_ident release]; [_match release]; [super dealloc]; }
@end

static void CRTestRulePositiveNegative(void)
{
    // Each rule must fire on a known offender AND stay quiet on a clean commit.
    // The negative case is the important one: it is what catches false positives.
    CR_ASSERT(CRFires(@"generic-message", @"fix"), "generic fires on 'fix'");
    CR_ASSERT(!CRFires(@"generic-message", @"fix login redirect on Safari"),
              "generic quiet on a real sentence starting with fix");

    CR_ASSERT(CRFires(@"too-short", @"typo"), "too-short fires on 'typo'");
    CR_ASSERT(!CRFires(@"too-short", @"Add retry logic"), "too-short quiet on a full subject");

    CR_ASSERT(CRFires(@"all-caps", @"FIX THE BUILD"), "all-caps fires on shouting");
    CR_ASSERT(!CRFires(@"all-caps", @"Fix the build"), "all-caps quiet on normal case");
    CR_ASSERT(!CRFires(@"all-caps", @"1.2.0"), "all-caps quiet on a letterless version");

    CR_ASSERT(CRFires(@"emoji-only", @"🔥🔥"), "emoji-only fires on pure emoji");
    CR_ASSERT(!CRFires(@"emoji-only", @"🔥 Add cache warming"), "emoji-only quiet on emoji + text");

    CR_ASSERT(CRFires(@"no-imperative-verb", @"Added tests"), "no-imperative fires on past tense");
    CR_ASSERT(!CRFires(@"no-imperative-verb", @"Add tests"), "no-imperative quiet on the imperative");
    CR_ASSERT(!CRFires(@"no-imperative-verb", @"Embed the font"),
              "no-imperative quiet on an imperative ending in -ed");

    // Duplicate rule needs the whole history.
    CRCommit *dup = CRCm(@"a", @"wip");
    NSArray *dupHistory = [NSArray arrayWithObjects:dup, CRCm(@"b", @"wip"), CRCm(@"c", @"wip"), nil];
    CR_ASSERT([CRRulesFiring(dup, dupHistory) containsObject:@"duplicate-message"],
              "duplicate fires when a subject repeats");
    CRCommit *uniq = CRCm(@"a", @"Add retry logic here");
    NSArray *uniqHistory = [NSArray arrayWithObjects:uniq, CRCm(@"b", @"Improve caching"), nil];
    CR_ASSERT(![CRRulesFiring(uniq, uniqHistory) containsObject:@"duplicate-message"],
              "duplicate quiet when every subject is distinct");

    // A genuinely good commit trips nothing at all.
    CRCommit *clean = CRCm(@"z", @"Add retry logic to the HTTP client");
    CR_ASSERT_EQ_INT([CRRulesFiring(clean, [NSArray arrayWithObject:clean]) count], 0,
                     "a clean commit trips no rule");
}

static void CRTestScoring(void)
{
    // 10 commits, 5 clearly guilty, 5 clean and distinct -> score exactly 50.
    NSArray *commits = [NSArray arrayWithObjects:
        CRCm(@"1", @"wip"), CRCm(@"2", @"fix"), CRCm(@"3", @"asdf"),
        CRCm(@"4", @"FIX THE BUILD"), CRCm(@"5", @"Added tests"),
        CRCm(@"6", @"Add retry logic to the client"),
        CRCm(@"7", @"Improve the caching layer greatly"),
        CRCm(@"8", @"Refactor the parser into modules"),
        CRCm(@"9", @"Document the public interface here"),
        CRCm(@"10", @"Handle the null pointer gracefully"),
        nil];
    CRRoastEngine *engine =
        [[[CRRoastEngine alloc] initWithRules:[CRRoastRuleRegistry defaultRules]] autorelease];
    CRRoastReport *r = [engine analyzeCommits:commits];
    CR_ASSERT_EQ_INT([r guiltyCommits], 5, "5 of 10 commits guilty");
    CR_ASSERT([r shameScore] == 50.0, "shame score is exactly 50");

    // A commit tripping several rules counts once. Three fake High rules all
    // matching one commit -> score 100, not 300.
    CRFakeRule *a = [[[CRFakeRule alloc] initWithId:@"a" severity:CRRuleSeverityHigh
                       match:[NSArray arrayWithObject:@"bad"]] autorelease];
    CRFakeRule *b = [[[CRFakeRule alloc] initWithId:@"b" severity:CRRuleSeverityHigh
                       match:[NSArray arrayWithObject:@"bad"]] autorelease];
    CRFakeRule *c = [[[CRFakeRule alloc] initWithId:@"c" severity:CRRuleSeverityHigh
                       match:[NSArray arrayWithObject:@"bad"]] autorelease];
    CRRoastEngine *multi = [[[CRRoastEngine alloc]
        initWithRules:[NSArray arrayWithObjects:a, b, c, nil]] autorelease];
    CRRoastReport *rm = [multi analyzeCommits:[NSArray arrayWithObject:CRCm(@"x", @"bad")]];
    CR_ASSERT([rm shameScore] == 100.0, "one commit, three rules -> score 100 not 300");
    CR_ASSERT_EQ_INT([rm guiltyCommits], 1, "a multi-offense commit counts once");

    // Empty history: score 0, no division by zero.
    CRRoastReport *empty = [engine analyzeCommits:[NSArray array]];
    CR_ASSERT([empty shameScore] == 0.0, "empty history: score 0, no crash");
    CR_ASSERT_EQ_INT([empty totalCommits], 0, "empty history: total 0");
    CR_ASSERT_EQ_INT([[empty breakdown] count], 0, "empty history: empty breakdown");

    // Breakdown sorted most-frequent first.
    CR_ASSERT([[[r breakdown] objectAtIndex:0] matchCount]
              >= [[[r breakdown] lastObject] matchCount],
              "breakdown sorted by count descending");
}

static void CRTestWorstCommit(void)
{
    NSArray *rules = [CRRoastRuleRegistry defaultRules];
    // "FIX" trips generic + too-short + all-caps; "typo" only too-short.
    NSArray *commits = [NSArray arrayWithObjects:
        CRCm(@"c1", @"typo"), CRCm(@"c2", @"FIX"),
        CRCm(@"c3", @"Add retry logic to the client"), nil];
    CRRoastEngine *engine = [[[CRRoastEngine alloc] initWithRules:rules] autorelease];
    CRRoastReport *r1 = [engine analyzeCommits:commits];
    CRRoastReport *r2 = [engine analyzeCommits:commits];

    CR_ASSERT_EQ_STR([[r1 worstCommit] subject], @"FIX", "worst commit is the most-offending one");
    CR_ASSERT([r1 worstPunchline] != nil, "worst commit has a punchline");
    CR_ASSERT_EQ_STR([[r1 worstCommit] sha], [[r2 worstCommit] sha],
                     "worst commit is deterministic across runs");
    CR_ASSERT_EQ_STR([r1 worstPunchline], [r2 worstPunchline],
                     "worst punchline is deterministic across runs");

    // Total tie -> the tie-break falls through to the smallest SHA.
    CRFakeRule *one = [[[CRFakeRule alloc] initWithId:@"generic-message" severity:CRRuleSeverityHigh
                        match:[NSArray arrayWithObjects:@"aaa", @"bbb", nil]] autorelease];
    CRRoastEngine *tie = [[[CRRoastEngine alloc]
        initWithRules:[NSArray arrayWithObject:one]] autorelease];
    CRRoastReport *rt = [tie analyzeCommits:
        [NSArray arrayWithObjects:CRCm(@"zzz9", @"bbb"), CRCm(@"aaa1", @"aaa"), nil]];
    CR_ASSERT_EQ_STR([[rt worstCommit] sha], @"aaa1",
                     "perfect tie resolves to the lexicographically smallest SHA");

    // Spotless history: no worst commit at all.
    CRRoastReport *clean = [engine analyzeCommits:[NSArray arrayWithObjects:
        CRCm(@"a", @"Add retry logic here now"),
        CRCm(@"b", @"Improve the caching layer"), nil]];
    CR_ASSERT([clean worstCommit] == nil, "spotless history: worstCommit is nil");
    CR_ASSERT([clean worstPunchline] == nil, "spotless history: worstPunchline is nil");
}

static void CRTestPunchlines(void)
{
    CRRoastLineGenerator *g = [[[CRRoastLineGenerator alloc] init] autorelease];
    CRFakeRule *dup = [[[CRFakeRule alloc] initWithId:@"duplicate-message"
                        severity:CRRuleSeverityMedium match:[NSArray array]] autorelease];

    // Token substitution.
    NSString *p = [g punchlineForRule:dup commit:CRCm(@"deadbeef1", @"wip") count:14];
    CR_ASSERT([p rangeOfString:@"wip"].location != NSNotFound, "{message} substituted");
    CR_ASSERT([p rangeOfString:@"14"].location != NSNotFound, "{count} substituted");
    CR_ASSERT([p rangeOfString:@"{"].location == NSNotFound, "no unresolved token remains");

    // Determinism.
    CRCommit *c = CRCm(@"stable42", @"fix");
    CRFakeRule *gen = [[[CRFakeRule alloc] initWithId:@"generic-message"
                        severity:CRRuleSeverityHigh match:[NSArray array]] autorelease];
    CR_ASSERT_EQ_STR([g punchlineForRule:gen commit:c], [g punchlineForRule:gen commit:c],
                     "same commit yields the same punchline");

    // At least four distinct variants across different SHAs (behavioral check
    // that the bank is not a single line).
    NSMutableSet *seen = [NSMutableSet set];
    NSArray *shas = [NSArray arrayWithObjects:@"h1", @"h2", @"h3", @"h4", @"h5",
                     @"h6", @"h7", @"h8", @"h9", @"h10", nil];
    NSEnumerator *e = [shas objectEnumerator];
    NSString *sha = nil;
    while ((sha = [e nextObject]) != nil) {
        [seen addObject:[g punchlineForRule:gen commit:CRCm(sha, @"fix")]];
    }
    CR_ASSERT([seen count] >= 4, "at least four distinct punchline variants per rule");

    // An unknown token must not crash — a rule with no bank entry falls back.
    CRFakeRule *unknown = [[[CRFakeRule alloc] initWithId:@"no-such-rule"
                            severity:CRRuleSeverityLow match:[NSArray array]] autorelease];
    CR_ASSERT([g punchlineForRule:unknown commit:CRCm(@"z", @"hi")] != nil,
              "a rule with no punchlines still produces something, no crash");
}

void CRRunEngineTests(void)
{
    CRTestRulePositiveNegative();
    CRTestScoring();
    CRTestWorstCommit();
    CRTestPunchlines();
}
