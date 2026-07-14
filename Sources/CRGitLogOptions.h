#import <Foundation/Foundation.h>

// What to ask `git log` for. Filtering happens git-side rather than in memory:
// on a 50,000-commit repository, loading everything and then discarding it
// would be wasteful.
//
// This object grows in #8, which adds --limit, --since and --author.
@interface CRGitLogOptions : NSObject
{
    NSString *_repositoryPath;
}

// Defaults to the current directory.
@property (nonatomic, copy) NSString *repositoryPath;

+ (instancetype)optionsWithRepositoryPath:(NSString *)path;

@end
