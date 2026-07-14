#import <Foundation/Foundation.h>

#import "CRGitLogOptions.h"

// Field separator (ASCII unit separator) and record separator (ASCII record
// separator) used in the --pretty format. They are chosen precisely because no
// sane commit message contains them, unlike '|' which appears in real subjects.
#define CR_FIELD_SEPARATOR  "\x1f"
#define CR_RECORD_SEPARATOR "\x1e"

// Runs `git log` and hands back its raw output. Parsing it is #7's job.
@interface CRGitLogReader : NSObject
{
    NSString *_gitPath;
}

// Returns the raw log, or nil with *error set.
//
// A repository with no commits is not a failure: it yields an empty string.
- (NSString *)rawLogWithOptions:(CRGitLogOptions *)options error:(NSError **)error;

@end
