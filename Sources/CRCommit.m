#import "CRCommit.h"

static const NSUInteger kCRShortSHALength = 7;

@implementation CRCommit

@synthesize sha = _sha;
@synthesize authorName = _authorName;
@synthesize authorEmail = _authorEmail;
@synthesize date = _date;
@synthesize subject = _subject;
@synthesize body = _body;
@synthesize changedFileCount = _changedFileCount;

- (instancetype)initWithSHA:(NSString *)sha
                 authorName:(NSString *)authorName
                authorEmail:(NSString *)authorEmail
                       date:(NSDate *)date
                    subject:(NSString *)subject
                       body:(NSString *)body
           changedFileCount:(NSUInteger)changedFileCount
{
    self = [super init];
    if (self) {
        // Copy rather than retain: the parser hands us substrings of one huge
        // git-log string, and an NSString substring can keep its whole parent
        // alive. Copying also protects against a mutable string changing later.
        //
        // Defaulting to @"" rather than nil keeps every caller free of nil
        // checks: a commit with no body is normal, not exceptional.
        _sha = [(sha ?: @"") copy];
        _authorName = [(authorName ?: @"") copy];
        _authorEmail = [(authorEmail ?: @"") copy];
        _date = [date retain];
        _subject = [(subject ?: @"") copy];
        _body = [(body ?: @"") copy];
        _changedFileCount = changedFileCount;
    }
    return self;
}

- (instancetype)initWithSHA:(NSString *)sha
                 authorName:(NSString *)authorName
                authorEmail:(NSString *)authorEmail
                       date:(NSDate *)date
                    subject:(NSString *)subject
                       body:(NSString *)body
{
    return [self initWithSHA:sha
                  authorName:authorName
                 authorEmail:authorEmail
                        date:date
                     subject:subject
                        body:body
            changedFileCount:0];
}

- (void)dealloc
{
    [_sha release];
    [_authorName release];
    [_authorEmail release];
    [_date release];
    [_subject release];
    [_body release];
    [super dealloc];
}

- (NSString *)shortSHA
{
    if ([_sha length] <= kCRShortSHALength) {
        return _sha;
    }
    return [_sha substringToIndex:kCRShortSHALength];
}

- (NSString *)fullMessage
{
    if ([_body length] == 0) {
        return _subject;
    }
    return [NSString stringWithFormat:@"%@\n\n%@", _subject, _body];
}

// Identity is the SHA: it is what git itself uses, and two CRCommit objects
// parsed from the same commit must land in the same slot of an NSSet.
- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CRCommit class]]) {
        return NO;
    }
    return [_sha isEqualToString:[(CRCommit *)object sha]];
}

- (NSUInteger)hash
{
    return [_sha hash];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %@ %@: \"%@\">",
                                      NSStringFromClass([self class]),
                                      [self shortSHA],
                                      _authorName,
                                      _subject];
}

@end
