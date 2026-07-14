#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// The subject is one word, and that word says nothing: "fix", "wip", "stuff".
//
// High severity: this is the purest form of the offense. The commit exists, and
// it tells you exactly nothing about what changed.
@interface CRGenericMessageRule : NSObject <CRRoastRule>
@end
