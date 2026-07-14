#import "CRCommitParser.h"

#import "CRGitLogReader.h"

// Field order in the --pretty format: %H %an %ae %aI %s %b
enum {
    kCRFieldSHA = 0,
    kCRFieldAuthorName = 1,
    kCRFieldAuthorEmail = 2,
    kCRFieldDate = 3,
    kCRFieldSubject = 4,
    kCRFieldBody = 5,
    kCRFieldCount = 6
};

@implementation CRCommitParser

// NSISO8601DateFormatter exists under GNUstep but returns nil — it is a stub.
// Testing for the class with NSClassFromString would say "present" and then
// silently produce nil dates. NSDateFormatter with a POSIX locale works on both
// platforms, so it is used unconditionally.
//
// Built once: instantiating a date formatter per commit is expensive, and a
// 12,000-commit repository would pay for it 12,000 times.
+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        NSLocale *posix =
            [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        [formatter setLocale:posix];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    }
    return formatter;
}

+ (CRCommit *)commitFromRecord:(NSString *)record
{
    NSArray *fields =
        [record componentsSeparatedByString:@CR_FIELD_SEPARATOR];

    // Fewer fields than expected means a truncated record. Skip it rather than
    // guess: a half-read commit is not worth crashing the whole run for.
    if ([fields count] < kCRFieldCount) {
        return nil;
    }

    NSString *sha = [fields objectAtIndex:kCRFieldSHA];
    if ([sha length] == 0) {
        return nil;
    }

    NSString *subject = [fields objectAtIndex:kCRFieldSubject];

    // A field separator is a legal (if deranged) character in a commit message.
    // If one shows up, the split produces extra fields; they belong to the body,
    // so glue them back together rather than dropping the tail of the message.
    NSString *body = nil;
    if ([fields count] > kCRFieldCount) {
        NSRange tail = NSMakeRange(kCRFieldBody, [fields count] - kCRFieldBody);
        body = [[fields subarrayWithRange:tail]
            componentsJoinedByString:@CR_FIELD_SEPARATOR];
    } else {
        body = [fields objectAtIndex:kCRFieldBody];
    }

    // %b ends with a newline, which is formatting, not content.
    body = [body stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSDate *date = [[self dateFormatter]
        dateFromString:[fields objectAtIndex:kCRFieldDate]];

    return [[[CRCommit alloc]
        initWithSHA:sha
         authorName:[fields objectAtIndex:kCRFieldAuthorName]
        authorEmail:[fields objectAtIndex:kCRFieldAuthorEmail]
               date:date
            subject:subject
               body:body] autorelease];
}

+ (NSArray *)parseRawLog:(NSString *)rawLog
{
    NSMutableArray *commits = [NSMutableArray array];
    if ([rawLog length] == 0) {
        return commits;
    }

    NSArray *records =
        [rawLog componentsSeparatedByString:@CR_RECORD_SEPARATOR];

    NSEnumerator *e = [records objectEnumerator];
    NSString *record = nil;
    while ((record = [e nextObject]) != nil) {
        // git writes a newline between records, so every record after the first
        // starts with one. Only leading newlines are stripped: whitespace inside
        // the fields is the user's, and the too-short rule needs it intact.
        NSString *trimmed = [record stringByTrimmingCharactersInSet:
                                        [NSCharacterSet newlineCharacterSet]];
        if ([trimmed length] == 0) {
            continue;   // trailing separator at the end of the log
        }

        CRCommit *commit = [self commitFromRecord:trimmed];
        if (commit != nil) {
            [commits addObject:commit];
        }
    }

    return commits;
}

@end
