#import <Foundation/Foundation.h>

extern NSString *const CRErrorDomain;

typedef enum {
    // `git` is not installed, or not on PATH.
    CRErrorGitNotFound = 1,

    // The path given with --repo does not exist, or is not a directory.
    CRErrorRepositoryNotFound = 2,

    // The path exists but is not inside a git repository.
    CRErrorNotAGitRepository = 3,

    // git ran and failed for some other reason; its stderr is in the
    // NSLocalizedDescriptionKey.
    CRErrorGitFailed = 4
} CRErrorCode;

// Builds an NSError in CRErrorDomain with `message` as its localized
// description.
NSError *CRMakeError(CRErrorCode code, NSString *message);
