#import "CRRoastLineGenerator.h"

#import "CRStringUtils.h"

// Injected commit subjects are truncated to this many graphemes so one long
// commit cannot blow up a terminal line.
static const NSUInteger kCRMaxMessageGraphemes = 40;

@implementation CRRoastLineGenerator

// Punchlines keyed by rule identifier. At least four per rule: on a 500-commit
// history a single line per rule would wear thin fast.
//
// Tokens: {message} {sha} {author} {count}. Every line aims at the commit, not
// the author.
+ (NSDictionary *)bank
{
    static NSDictionary *bank = nil;
    if (bank == nil) {
        bank = [[NSDictionary alloc] initWithObjectsAndKeys:

            [NSArray arrayWithObjects:
                @"“{message}” — thanks for that surgically precise description.",
                @"“{message}”. Riveting. I'm on the edge of my seat.",
                @"“{message}” tells me a change happened. Nothing else, but that.",
                @"Ah, “{message}”. The commit message equivalent of a shrug.",
                @"“{message}” — future-you is going to love bisecting through this one.",
                nil], @"generic-message",

            [NSArray arrayWithObjects:
                @"“{message}” — {count} characters brave enough to summarize the whole change.",
                @"“{message}”. Economical. Almost haiku, if haiku said nothing.",
                @"“{message}” — you were this close to typing a second word.",
                @"Short and sweet: “{message}”. Mostly short.",
                nil], @"too-short",

            [NSArray arrayWithObjects:
                @"“{message}” — we can hear you from here.",
                @"“{message}”. The caps lock key would like a rest.",
                @"No need to shout: “{message}”.",
                @"“{message}” — is the build okay? You seem tense.",
                nil], @"all-caps",

            [NSArray arrayWithObjects:
                @"“{message}” — a commit message with no words in it. Bold.",
                @"“{message}”. I'm sure the emoji means something to someone.",
                @"“{message}” — git blame is going to be a fun game of charades.",
                @"An emoji, “{message}”, standing in for an entire explanation.",
                nil], @"emoji-only",

            [NSArray arrayWithObjects:
                @"“{message}” — the convention is the imperative. Add, fix, remove; not this.",
                @"“{message}”. Reads like a diary entry, not a commit.",
                @"“{message}” — “Add”, not “Added”. The commit describes the change, present tense.",
                @"Grammar police, gently: “{message}” wants to be an imperative.",
                nil], @"no-imperative-verb",

            [NSArray arrayWithObjects:
                @"“{message}” — again. That's {count} times now. We get it.",
                @"“{message}”, {count} times over. Copy-paste has entered the chat.",
                @"{count}× “{message}”. At this point it's a chorus.",
                @"“{message}” appears {count} times. Variety is the spice of history.",
                nil], @"duplicate-message",

            nil];
    }
    return bank;
}

- (NSString *)fillTemplate:(NSString *)template
                    commit:(CRCommit *)commit
                     count:(NSUInteger)count
{
    NSString *message = CRTruncateToGraphemes([commit subject], kCRMaxMessageGraphemes);

    // Replace known tokens only. An unknown token is left untouched rather than
    // triggering anything — a stray "{foo}" in a line is a cosmetic slip, not a
    // crash.
    NSMutableString *result = [[template mutableCopy] autorelease];
    [result replaceOccurrencesOfString:@"{message}"
                            withString:message
                               options:0
                                 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"{sha}"
                            withString:[commit shortSHA]
                               options:0
                                 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"{author}"
                            withString:[commit authorName]
                               options:0
                                 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"{count}"
                            withString:[NSString stringWithFormat:@"%lu", (unsigned long)count]
                               options:0
                                 range:NSMakeRange(0, [result length])];
    return result;
}

- (NSString *)punchlineForRule:(id<CRRoastRule>)rule
                        commit:(CRCommit *)commit
                         count:(NSUInteger)count
{
    NSArray *variants = [[[self class] bank] objectForKey:[rule identifier]];
    if ([variants count] == 0) {
        // A rule with no punchlines still has to produce something.
        return [NSString stringWithFormat:@"“%@” — %@.",
                    CRTruncateToGraphemes([commit subject], kCRMaxMessageGraphemes),
                    [rule displayName]];
    }

    // Pick by a stable hash of the SHA: deterministic, so the output is testable
    // and a re-run does not reshuffle the roast, yet varied across commits.
    NSUInteger index = CRStableHash([commit sha]) % [variants count];
    return [self fillTemplate:[variants objectAtIndex:index] commit:commit count:count];
}

- (NSString *)punchlineForRule:(id<CRRoastRule>)rule commit:(CRCommit *)commit
{
    return [self punchlineForRule:rule commit:commit count:0];
}

@end
