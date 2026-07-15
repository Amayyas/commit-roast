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

NSString *CRTruncateToGraphemes(NSString *string, NSUInteger maxGraphemes)
{
    NSUInteger length = [string length];
    NSUInteger index = 0;
    NSUInteger count = 0;

    while (index < length) {
        if (count == maxGraphemes) {
            // There is at least one more grapheme, so we really are cutting.
            return [[string substringToIndex:index] stringByAppendingString:@"…"];
        }
        NSRange range = [string rangeOfComposedCharacterSequenceAtIndex:index];
        index = NSMaxRange(range);
        count++;
    }

    return string;
}

uint32_t CRStableHash(NSString *string)
{
    const char *bytes = [string UTF8String];
    uint32_t hash = 2166136261u;   // FNV-1a offset basis
    if (bytes == NULL) {
        return hash;
    }
    while (*bytes) {
        hash ^= (uint32_t)(unsigned char)(*bytes);
        hash *= 16777619u;         // FNV prime
        bytes++;
    }
    return hash;
}
