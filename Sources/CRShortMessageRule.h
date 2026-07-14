#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// Fewer than 10 characters of subject.
//
// Length is counted in grapheme clusters, not UTF-16 code units: otherwise
// "🔥🔥🔥🔥🔥" measures ten and escapes the rule entirely.
@interface CRShortMessageRule : NSObject <CRRoastRule>
@end
