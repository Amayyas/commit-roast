#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// The same subject, over and over. One mediocre message is a slip; the same one
// fourteen times is a habit.
//
// The only rule that cannot judge a commit on its own: "wip" is a duplicate only
// because other commits also say "wip". It is why CRRoastRule carries an
// optional -prepareWithCommits:.
@interface CRDuplicateMessageRule : NSObject <CRRoastRule>
{
    NSMutableDictionary *_counts;
}

// How many times this commit's subject appears in the history. 0 before
// -prepareWithCommits: has run. The punchlines say "repeated 14 times", so a
// bare YES/NO would not be enough.
- (NSUInteger)occurrenceCountForCommit:(CRCommit *)commit;

@end
