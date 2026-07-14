#import "CRRoastRuleRegistry.h"

@implementation CRRoastRuleRegistry

+ (NSArray *)defaultRules
{
    // Empty until #10 and #11 land: this is the seam they plug into, not an
    // oversight. The engine (#12) must already behave sanely with no rules —
    // every commit innocent, score 0 — and it is tested that way.
    return [NSArray array];
}

@end
