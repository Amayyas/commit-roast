#import <Foundation/Foundation.h>

#import "CRCommit.h"
#import "CRRoastReport.h"
#import "CRRoastRule.h"

// Applies the rules to a history and produces a CRRoastReport.
//
// Rules are injected, not hardcoded, so a test can hand the engine a single rule
// in isolation. The CLI passes CRRoastRuleRegistry defaultRules.
@interface CRRoastEngine : NSObject
{
    NSArray *_rules;
}

- (instancetype)initWithRules:(NSArray *)rules;

- (CRRoastReport *)analyzeCommits:(NSArray *)commits;

@end
