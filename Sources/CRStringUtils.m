#import "CRStringUtils.h"

// Deliberately written without blocks. Blocks would need -fblocks and a link
// against libBlocksRuntime, i.e. one more shared library to ship with the Linux
// binaries. -rangeOfComposedCharacterSequenceAtIndex: does the same job with
// nothing extra, so the whole project stays block-free.
NSUInteger CRGraphemeLength(NSString *string)
{
    NSUInteger length = [string length];
    NSUInteger index = 0;
    NSUInteger count = 0;

    while (index < length) {
        NSRange range = [string rangeOfComposedCharacterSequenceAtIndex:index];
        index = NSMaxRange(range);
        count++;
    }

    return count;
}
