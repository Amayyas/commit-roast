#import "CRNoImperativeVerbRule.h"

@implementation CRNoImperativeVerbRule

- (NSString *)identifier { return @"no-imperative-verb"; }
- (NSString *)displayName { return @"Not in the imperative"; }
- (CRRuleSeverity)severity { return CRRuleSeverityLow; }

// Checked FIRST, so anything here is innocent whatever it looks like.
//
// It carries two kinds of word. The obvious ones (add, fix, remove) are the
// common imperative verbs. The rest — embed, feed, speed, bring, sing — are
// there because they are imperative verbs that happen to END in "ed" or "ing".
// Without them, "Embed the font" and "Bring back the dark theme" would be
// flagged as past tense, which is exactly the kind of stupidity that makes a
// linter lose its audience.
+ (NSSet *)imperativeVerbs
{
    static NSSet *verbs = nil;
    if (verbs == nil) {
        verbs = [[NSSet alloc] initWithObjects:
            @"add", @"allow", @"avoid", @"build", @"bump", @"change", @"check",
            @"clean", @"clarify", @"convert", @"correct", @"create", @"disable",
            @"document", @"drop", @"enable", @"ensure", @"expose", @"extract",
            @"fix", @"handle", @"hide", @"implement", @"improve", @"introduce",
            @"keep", @"make", @"merge", @"move", @"prevent", @"print", @"reduce",
            @"refactor", @"remove", @"rename", @"replace", @"restore", @"revert",
            @"rewrite", @"send", @"set", @"show", @"simplify", @"skip", @"split",
            @"stop", @"support", @"switch", @"test", @"throw", @"tidy", @"track",
            @"update", @"upgrade", @"use", @"wire", @"write",
            // Imperative verbs that end in "ed" / "ing" / "s" and would
            // otherwise be mistaken for past tense or third person:
            @"embed", @"feed", @"seed", @"speed", @"proceed", @"exceed",
            @"succeed", @"shed", @"bring", @"ring", @"sing", @"string",
            @"address", @"process", @"pass", @"compress", @"dismiss", @"express",
            nil];
    }
    return verbs;
}

- (BOOL)matchesCommit:(CRCommit *)commit
{
    NSString *subject = [[commit subject] stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([subject length] == 0) {
        return NO;
    }

    NSString *first = [[subject componentsSeparatedByCharactersInSet:
                           [NSCharacterSet whitespaceCharacterSet]] objectAtIndex:0];
    first = [[first lowercaseString] stringByTrimmingCharactersInSet:
                [NSCharacterSet punctuationCharacterSet]];

    // No letters at all (an emoji, a version number): not this rule's problem.
    if ([first rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location
        == NSNotFound) {
        return NO;
    }

    if ([[[self class] imperativeVerbs] containsObject:first]) {
        return NO;
    }

    // Only flag what actually LOOKS conjugated. Flagging every first word that is
    // simply absent from the list would flag most of the English language — no
    // whitelist is ever complete, and a rule that fires on everything says
    // nothing.
    if ([first hasSuffix:@"ed"] || [first hasSuffix:@"ing"]) {
        return YES;
    }

    // Third person: "Adds tests", "Fixes the build". Only when the stem is a verb
    // we know, so "Redis cache warming" (a noun ending in "s") stays innocent.
    if ([first hasSuffix:@"s"] && [first length] > 1) {
        NSString *stem = [first substringToIndex:[first length] - 1];
        if ([[[self class] imperativeVerbs] containsObject:stem]) {
            return YES;
        }
        if ([stem hasSuffix:@"e"] && [stem length] > 1) {   // "fixes" -> "fixe" -> "fix"
            NSString *shorter = [stem substringToIndex:[stem length] - 1];
            if ([[[self class] imperativeVerbs] containsObject:shorter]) {
                return YES;
            }
        }
    }

    return NO;
}

@end
