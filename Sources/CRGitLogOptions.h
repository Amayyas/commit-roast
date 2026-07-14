#import <Foundation/Foundation.h>

// Default number of commits analyzed. Bounded for performance: a 50,000-commit
// repository would otherwise be read and parsed in full to print one score.
// Users who want everything pass --limit 0.
#define CR_DEFAULT_LIMIT 500

// What to ask `git log` for.
//
// Filtering happens git-side rather than in memory: asking git for one author's
// commits is free, whereas loading 50,000 commits to throw away 49,000 is not.
@interface CRGitLogOptions : NSObject
{
    NSString *_repositoryPath;
    NSUInteger _limit;
    NSString *_since;
    NSString *_author;
}

// Defaults to the current directory.
@property (nonatomic, copy) NSString *repositoryPath;

// Maximum number of commits to read. 0 means no limit.
@property (nonatomic, assign) NSUInteger limit;

// Passed verbatim to `git log --since=`. git accepts "2 weeks ago" as happily as
// "2024-01-01", and validating it ourselves would only reduce what works.
@property (nonatomic, copy) NSString *since;

// Passed verbatim to `git log --author=`.
@property (nonatomic, copy) NSString *author;

+ (instancetype)optionsWithRepositoryPath:(NSString *)path;

// The `git log` arguments these options translate to.
//
// Returns an array, never a command line: every user-supplied value stays a
// separate element handed to NSTask, so it can never be interpreted as shell
// syntax. See -[CRGitLogReader rawLogWithOptions:error:].
- (NSArray *)gitLogArguments;

@end
