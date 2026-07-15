#import "CRArguments.h"

@implementation CRArguments

@synthesize action = _action;
@synthesize logOptions = _logOptions;
@synthesize jsonOutput = _jsonOutput;
@synthesize colorEnabled = _colorEnabled;
@synthesize ok = _ok;
@synthesize errorMessage = _errorMessage;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _action = CRActionRun;
        _logOptions = [[CRGitLogOptions alloc] init];
        _jsonOutput = NO;
        _colorEnabled = YES;
        _ok = YES;
        _errorMessage = nil;
    }
    return self;
}

- (void)setLogOptions:(CRGitLogOptions *)options
{
    if (options == _logOptions) {
        return;
    }
    [options retain];
    [_logOptions release];
    _logOptions = options;
}

- (void)setErrorMessage:(NSString *)message
{
    if (message == _errorMessage) {
        return;
    }
    NSString *copied = [message copy];
    [_errorMessage release];
    _errorMessage = copied;
}

- (void)dealloc
{
    [_logOptions release];
    [_errorMessage release];
    [super dealloc];
}

@end
