#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// The subject is emoji and nothing else: "🔥🔥", "🎉".
//
// High severity: it is a commit message with no words in it.
@interface CREmojiOnlyRule : NSObject <CRRoastRule>
@end
