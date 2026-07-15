#import <Foundation/Foundation.h>

#import "CRCommit.h"

// The result of judging a history: the score, the per-rule breakdown, and the
// single worst commit. This is what the text and JSON formatters render.
@interface CRRoastReport : NSObject
{
    NSUInteger _totalCommits;
    NSUInteger _guiltyCommits;
    double _shameScore;
    NSArray *_breakdown;
    CRCommit *_worstCommit;
    NSString *_worstPunchline;
    NSArray *_worstCommitRules;
}

@property (nonatomic, readonly) NSUInteger totalCommits;

// Commits tripping at least one rule. A commit that trips three still counts
// once here — that is what keeps the score meaningful.
@property (nonatomic, readonly) NSUInteger guiltyCommits;

// guiltyCommits as a percentage of totalCommits, 0-100.
@property (nonatomic, readonly) double shameScore;

// CRRuleBreakdown objects, most-frequent rule first.
@property (nonatomic, readonly) NSArray *breakdown;

// The most roastable commit, or nil for a spotless history. Filled in by #14.
@property (nonatomic, retain) CRCommit *worstCommit;
@property (nonatomic, copy) NSString *worstPunchline;

// Identifiers of every rule the worst commit tripped, for the JSON output.
@property (nonatomic, copy) NSArray *worstCommitRules;

- (instancetype)initWithTotalCommits:(NSUInteger)totalCommits
                       guiltyCommits:(NSUInteger)guiltyCommits
                          shameScore:(double)shameScore
                           breakdown:(NSArray *)breakdown;

@end
