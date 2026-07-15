#import <Foundation/Foundation.h>

#import "CRCommit.h"

// How bad a given offense is. The values are weights, not just labels: the worst
// commit of a history (#14) is elected by summing the severities of the rules it
// trips, so a "FIX" (generic + too short + all caps) outranks an "Added tests".
typedef NS_ENUM(NSInteger, CRRuleSeverity) {
    CRRuleSeverityLow = 1,
    CRRuleSeverityMedium = 2,
    CRRuleSeverityHigh = 3
};

// "low" / "medium" / "high" — the JSON output (#19) speaks this, not integers.
NSString *CRRuleSeverityName(CRRuleSeverity severity);

// A single way for a commit message to be disappointing.
//
// Adding a rule must never require touching the engine or any other rule: write
// a class conforming to this, register it in CRRoastRuleRegistry, done.
@protocol CRRoastRule <NSObject>

// Stable, machine-readable, kebab-case: "generic-message".
//
// It keys both the JSON output and the punchline bank, so it is API. Renaming
// one after v1 breaks consumers and silently orphans its punchlines.
@property (nonatomic, readonly) NSString *identifier;

// Human-facing: "Generic message".
@property (nonatomic, readonly) NSString *displayName;

@property (nonatomic, readonly) CRRuleSeverity severity;

// Does this commit trip the rule?
- (BOOL)matchesCommit:(CRCommit *)commit;

@optional

// Handed the whole history before any matching happens.
//
// This exists for duplicate detection (#11), which cannot judge a commit in
// isolation: "wip" is only a duplicate because fourteen other commits also say
// "wip". Without this hook the engine would need to special-case that one rule.
// With it, duplicates stay a rule like any other and the engine just asks
// respondsToSelector:.
- (void)prepareWithCommits:(NSArray *)commits;

// A contextual count for this commit, fed to the punchline's {count} token.
//
// The duplicate rule returns how many times the subject appears ("repeated 14
// times"). Rules that have no such number simply do not implement this, and the
// engine passes 0. Keeps the engine from having to know the duplicate rule by
// name to fill in its punchline.
- (NSUInteger)countForCommit:(CRCommit *)commit;

@end
