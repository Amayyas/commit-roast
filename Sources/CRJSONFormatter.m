#import "CRJSONFormatter.h"

#include <math.h>

#import "CRRuleBreakdown.h"

// Scores and percentages are emitted as rounded integers, matching what the text
// output shows ("67/100", "67%"). A double would serialize as noise like
// "66.666666666666671", and consumers wanting the exact ratio have `count` and
// `analyzed_commits` right there in the JSON.

// Bumped only when the shape changes, so consumers can pin to it. Not the tool's
// version — the schema and the tool evolve on different clocks.
static NSString *const kCRSchemaVersion = @"1.0";

@implementation CRJSONFormatter

- (instancetype)initWithRepositoryPath:(NSString *)repositoryPath
{
    self = [super init];
    if (self) {
        _repositoryPath = [repositoryPath copy];
    }
    return self;
}

// Built once. Same reasoning as the parser: a formatter per commit would be paid
// for on every example.
+ (NSDateFormatter *)iso8601Formatter
{
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:
            [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    }
    return formatter;
}

// A commit as a JSON-ready dictionary. NSNull for a missing date, never nil,
// which NSJSONSerialization would reject.
- (NSDictionary *)commitDictionary:(CRCommit *)commit
{
    id date = [commit date] != nil
        ? (id)[[[self class] iso8601Formatter] stringFromDate:[commit date]]
        : (id)[NSNull null];

    return [NSDictionary dictionaryWithObjectsAndKeys:
        [commit shortSHA], @"sha",
        [commit authorName], @"author",
        date, @"date",
        [commit subject], @"message",
        nil];
}

- (NSDictionary *)reportDictionary:(CRRoastReport *)report
{
    NSMutableArray *breakdown = [NSMutableArray array];
    NSEnumerator *be = [[report breakdown] objectEnumerator];
    CRRuleBreakdown *entry = nil;
    while ((entry = [be nextObject]) != nil) {
        NSMutableArray *examples = [NSMutableArray array];
        NSEnumerator *xe = [[entry examples] objectEnumerator];
        CRCommit *example = nil;
        while ((example = [xe nextObject]) != nil) {
            [examples addObject:[self commitDictionary:example]];
        }

        [breakdown addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [entry identifier], @"rule",
            [entry displayName], @"display_name",
            CRRuleSeverityName([entry severity]), @"severity",
            [NSNumber numberWithUnsignedInteger:[entry matchCount]], @"count",
            [NSNumber numberWithInteger:(NSInteger)lround([entry percentage])], @"percentage",
            examples, @"examples",
            nil]];
    }

    // null, not an empty object, when the history is spotless: absence is the
    // honest representation of "no worst commit".
    id worst = [NSNull null];
    if ([report worstCommit] != nil) {
        NSMutableDictionary *w = [NSMutableDictionary dictionaryWithDictionary:
            [self commitDictionary:[report worstCommit]]];
        [w setObject:([report worstPunchline] ?: @"") forKey:@"punchline"];
        [w setObject:([report worstCommitRules] ?: [NSArray array]) forKey:@"rules"];
        worst = w;
    }

    return [NSDictionary dictionaryWithObjectsAndKeys:
        kCRSchemaVersion, @"version",
        (_repositoryPath ?: @""), @"repository",
        [NSNumber numberWithUnsignedInteger:[report totalCommits]], @"analyzed_commits",
        [NSNumber numberWithUnsignedInteger:[report guiltyCommits]], @"guilty_commits",
        [NSNumber numberWithInteger:(NSInteger)lround([report shameScore])], @"shame_score",
        breakdown, @"breakdown",
        worst, @"worst_commit",
        nil];
}

- (NSString *)formatReport:(CRRoastReport *)report
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self reportDictionary:report]
                                                  options:NSJSONWritingPrettyPrinted
                                                    error:&error];
    if (data == nil) {
        // Should not happen: everything in the dictionary is a JSON type. If it
        // somehow did, emit valid JSON rather than a truncated stream.
        return @"{\"error\": \"failed to serialize report\"}\n";
    }
    NSString *json = [[[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding] autorelease];
    return [json stringByAppendingString:@"\n"];
}

- (void)dealloc
{
    [_repositoryPath release];
    [super dealloc];
}

@end
