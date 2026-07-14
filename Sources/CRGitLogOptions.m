#import "CRGitLogOptions.h"

@implementation CRGitLogOptions

@synthesize repositoryPath = _repositoryPath;
@synthesize limit = _limit;
@synthesize since = _since;
@synthesize author = _author;

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
        _limit = CR_DEFAULT_LIMIT;
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

- (void)setSince:(NSString *)since
{
    if (since == _since) {
        return;
    }
    NSString *copied = [since copy];
    [_since release];
    _since = copied;
}

- (void)setAuthor:(NSString *)author
{
    if (author == _author) {
        return;
    }
    NSString *copied = [author copy];
    [_author release];
    _author = copied;
}

- (NSArray *)gitLogArguments
{
    NSMutableArray *arguments = [NSMutableArray array];

    if (_limit > 0) {
        [arguments addObject:@"-n"];
        [arguments addObject:[NSString stringWithFormat:@"%lu", (unsigned long)_limit]];
    }

    // --since=<value> and --author=<value> go in as ONE argument each, value
    // included. NSTask hands the array straight to execve, so nothing here is
    // ever parsed by a shell: an author of "$(rm -rf ~)" is matched literally
    // against author names, and matches nobody.
    if ([_since length] > 0) {
        [arguments addObject:[NSString stringWithFormat:@"--since=%@", _since]];
    }

    if ([_author length] > 0) {
        [arguments addObject:[NSString stringWithFormat:@"--author=%@", _author]];
    }

    return arguments;
}

- (void)dealloc
{
    [_repositoryPath release];
    [_since release];
    [_author release];
    [super dealloc];
}

@end
