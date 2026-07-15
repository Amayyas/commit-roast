#import "CRRoastReport.h"

@implementation CRRoastReport

@synthesize totalCommits = _totalCommits;
@synthesize guiltyCommits = _guiltyCommits;
@synthesize shameScore = _shameScore;
@synthesize breakdown = _breakdown;
@synthesize worstCommit = _worstCommit;
@synthesize worstPunchline = _worstPunchline;
@synthesize worstCommitRules = _worstCommitRules;

- (instancetype)initWithTotalCommits:(NSUInteger)totalCommits
                       guiltyCommits:(NSUInteger)guiltyCommits
                          shameScore:(double)shameScore
                           breakdown:(NSArray *)breakdown
{
    self = [super init];
    if (self) {
        _totalCommits = totalCommits;
        _guiltyCommits = guiltyCommits;
        _shameScore = shameScore;
        _breakdown = [breakdown copy];
    }
    return self;
}

- (void)setWorstCommit:(CRCommit *)commit
{
    if (commit == _worstCommit) {
        return;
    }
    [commit retain];
    [_worstCommit release];
    _worstCommit = commit;
}

- (void)setWorstPunchline:(NSString *)punchline
{
    if (punchline == _worstPunchline) {
        return;
    }
    NSString *copied = [punchline copy];
    [_worstPunchline release];
    _worstPunchline = copied;
}

- (void)setWorstCommitRules:(NSArray *)rules
{
    if (rules == _worstCommitRules) {
        return;
    }
    NSArray *copied = [rules copy];
    [_worstCommitRules release];
    _worstCommitRules = copied;
}

- (void)dealloc
{
    [_breakdown release];
    [_worstCommit release];
    [_worstPunchline release];
    [_worstCommitRules release];
    [super dealloc];
}

@end
