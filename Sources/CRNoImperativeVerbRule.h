#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// The subject does not start with an imperative verb: "Added tests" instead of
// "Add tests", "Fixing the build" instead of "Fix the build".
//
// Deliberately a heuristic, deliberately LOW severity. There is no part-of-speech
// tagger here and there will be false positives; the severity reflects how much
// we trust it, and the worst-commit election (#14) weighs it accordingly.
@interface CRNoImperativeVerbRule : NSObject <CRRoastRule>
@end
