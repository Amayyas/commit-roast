#import <Foundation/Foundation.h>

#import "CRCommit.h"

// Turns the raw output of CRGitLogReader into CRCommit objects.
//
// Never raises and never returns nil: bad input yields fewer commits, not a
// crash. The data comes from arbitrary commit messages written by strangers,
// which is about as hostile as input gets.
@interface CRCommitParser : NSObject

// Returns an empty array for empty or malformed input.
+ (NSArray *)parseRawLog:(NSString *)rawLog;

@end
