#import <Foundation/Foundation.h>

#import "CRCommit.h"
#import "CRRoastRule.h"

// Turns "this commit tripped the generic-message rule" into an actual roast.
//
// Editorial line, enforced by the bank itself: aim at the message, never at the
// person. "This commit says nothing", not "you are bad at this". The tool may be
// run on a colleague's repository or in a public demo; anything that would be
// awkward there does not belong here.
@interface CRRoastLineGenerator : NSObject

// A punchline for `commit` under `rule`.
//
// Deterministic: the same commit yields the same line on every run, so the
// output is testable and re-running the tool does not reshuffle it. count is the
// occurrence count for the duplicate rule, ignored otherwise.
- (NSString *)punchlineForRule:(id<CRRoastRule>)rule
                        commit:(CRCommit *)commit
                         count:(NSUInteger)count;

- (NSString *)punchlineForRule:(id<CRRoastRule>)rule commit:(CRCommit *)commit;

@end
