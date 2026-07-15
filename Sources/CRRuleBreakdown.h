#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// One rule's tally across the whole history: how many commits tripped it, what
// share that is, and a few commits to show for it.
@interface CRRuleBreakdown : NSObject
{
    NSString *_identifier;
    NSString *_displayName;
    CRRuleSeverity _severity;
    NSUInteger _matchCount;
    double _percentage;
    NSArray *_examples;
}

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) CRRuleSeverity severity;
@property (nonatomic, readonly) NSUInteger matchCount;
@property (nonatomic, readonly) double percentage;

// 2-3 CRCommit objects illustrating this rule, for the report.
@property (nonatomic, readonly) NSArray *examples;

- (instancetype)initWithRule:(id<CRRoastRule>)rule
                  matchCount:(NSUInteger)matchCount
                  percentage:(double)percentage
                    examples:(NSArray *)examples;

@end
