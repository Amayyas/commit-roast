#import <Foundation/Foundation.h>

#import "CRGitLogOptions.h"

// What the user asked the program to do.
typedef NS_ENUM(NSInteger, CRAction) {
    CRActionRun,       // analyze a repository
    CRActionHelp,      // --help / -h
    CRActionVersion    // --version
};

// The parsed command line. Either it parsed (ok == YES) and the fields are
// meaningful, or it did not (ok == NO) and errorMessage says why.
@interface CRArguments : NSObject
{
    CRAction _action;
    CRGitLogOptions *_logOptions;
    BOOL _jsonOutput;
    BOOL _colorEnabled;
    BOOL _ok;
    NSString *_errorMessage;
}

@property (nonatomic, assign) CRAction action;

// repo / limit / since / author, ready to hand to CRGitLogReader.
@property (nonatomic, retain) CRGitLogOptions *logOptions;

// --format json.
@property (nonatomic, assign) BOOL jsonOutput;

// Final color decision, already accounting for --no-color, NO_COLOR and the TTY.
// The formatter just reads this.
@property (nonatomic, assign) BOOL colorEnabled;

@property (nonatomic, assign) BOOL ok;

// Human-readable reason the parse failed, or nil.
@property (nonatomic, copy) NSString *errorMessage;

@end
