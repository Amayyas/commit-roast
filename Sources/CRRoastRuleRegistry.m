#import "CRRoastRuleRegistry.h"

#import "CRAllCapsRule.h"
#import "CREmojiOnlyRule.h"
#import "CRGenericMessageRule.h"
#import "CRNoImperativeVerbRule.h"
#import "CRShortMessageRule.h"

@implementation CRRoastRuleRegistry

+ (NSArray *)defaultRules
{
    // Adding a rule is one line here and nothing else. The engine never learns
    // any rule's name.
    return [NSArray arrayWithObjects:
        [[[CRGenericMessageRule alloc] init] autorelease],
        [[[CRShortMessageRule alloc] init] autorelease],
        [[[CRAllCapsRule alloc] init] autorelease],
        [[[CREmojiOnlyRule alloc] init] autorelease],
        [[[CRNoImperativeVerbRule alloc] init] autorelease],
        nil];
}

@end
