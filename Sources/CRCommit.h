#import <Foundation/Foundation.h>

// An immutable single commit, as read from `git log`.
//
// Ivars are declared here rather than auto-synthesized: with the GCC runtime
// used by GNUstep on Linux, clang uses the fragile ABI and does not synthesize
// backing ivars. Declaring them explicitly is what builds on both platforms.
@interface CRCommit : NSObject
{
    NSString *_sha;
    NSString *_authorName;
    NSString *_authorEmail;
    NSDate   *_date;
    NSString *_subject;
    NSString *_body;
    NSUInteger _changedFileCount;
}

// Not named `hash`: NSObject already declares -(NSUInteger)hash, and shadowing
// it with an NSString would break every NSSet and NSDictionary holding a commit.
@property (nonatomic, readonly, copy) NSString *sha;

// First 7 characters of the SHA, or the whole thing if it is shorter.
@property (nonatomic, readonly) NSString *shortSHA;

@property (nonatomic, readonly, copy) NSString *authorName;
@property (nonatomic, readonly, copy) NSString *authorEmail;
@property (nonatomic, readonly, retain) NSDate *date;

// First line of the commit message. This is what the roast rules judge.
@property (nonatomic, readonly, copy) NSString *subject;

// Everything after the first line. Empty for a single-line message.
@property (nonatomic, readonly, copy) NSString *body;

// subject, plus body separated by a blank line when there is one.
@property (nonatomic, readonly) NSString *fullMessage;

// 0 when unavailable: the current `git log` format does not ask for it.
@property (nonatomic, readonly) NSUInteger changedFileCount;

// Designated initializer.
- (instancetype)initWithSHA:(NSString *)sha
                 authorName:(NSString *)authorName
                authorEmail:(NSString *)authorEmail
                       date:(NSDate *)date
                    subject:(NSString *)subject
                       body:(NSString *)body
           changedFileCount:(NSUInteger)changedFileCount;

// Convenience: same thing with changedFileCount at 0.
- (instancetype)initWithSHA:(NSString *)sha
                 authorName:(NSString *)authorName
                authorEmail:(NSString *)authorEmail
                       date:(NSDate *)date
                    subject:(NSString *)subject
                       body:(NSString *)body;

@end
