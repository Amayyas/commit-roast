#import "CRGitLogOptions.h"

@implementation CRGitLogOptions

@synthesize repositoryPath = _repositoryPath;

+ (instancetype)optionsWithRepositoryPath:(NSString *)path
{
    CRGitLogOptions *options = [[[self alloc] init] autorelease];
    [options setRepositoryPath:path];
    return options;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _repositoryPath = [[[NSFileManager defaultManager] currentDirectoryPath] copy];
    }
    return self;
}

- (void)setRepositoryPath:(NSString *)path
{
    if (path == _repositoryPath) {
        return;
    }
    NSString *copied = [path copy];
    [_repositoryPath release];
    _repositoryPath = copied;
}

- (void)dealloc
{
    [_repositoryPath release];
    [super dealloc];
}

@end
