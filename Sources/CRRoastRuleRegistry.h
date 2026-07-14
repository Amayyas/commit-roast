#import <Foundation/Foundation.h>

#import "CRRoastRule.h"

// The one place that knows which rules exist.
//
// The engine takes its rules by injection, so tests can hand it a single rule in
// isolation; this registry is simply what the CLI passes in production. Adding a
// rule means adding one line here and nothing else.
@interface CRRoastRuleRegistry : NSObject

// Every rule enabled by default, in no particular order — the engine sorts the
// report by how often each one fires, not by declaration order.
+ (NSArray *)defaultRules;

@end
