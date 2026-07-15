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

// The Unicode scalar at the start of a grapheme cluster, decoding a surrogate
// pair when there is one.
static uint32_t CRFirstScalar(NSString *cluster)
{
    if ([cluster length] == 0) {
        return 0;
    }
    unichar high = [cluster characterAtIndex:0];
    if (high >= 0xD800 && high <= 0xDBFF && [cluster length] >= 2) {
        unichar low = [cluster characterAtIndex:1];
        if (low >= 0xDC00 && low <= 0xDFFF) {
            return 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
        }
    }
    return high;
}

// Two columns for East Asian wide characters and emoji, one for everything else.
// A pragmatic wcwidth: the ranges below cover CJK and the emoji blocks a commit
// subject realistically contains.
static NSUInteger CRScalarWidth(uint32_t c)
{
    if ((c >= 0x1100 && c <= 0x115F)   // Hangul Jamo
        || (c >= 0x2E80 && c <= 0x303E)   // CJK radicals, Kangxi
        || (c >= 0x3041 && c <= 0x33FF)   // Hiragana .. CJK compatibility
        || (c >= 0x3400 && c <= 0x4DBF)   // CJK Extension A
        || (c >= 0x4E00 && c <= 0x9FFF)   // CJK Unified Ideographs
        || (c >= 0xA000 && c <= 0xA4CF)   // Yi
        || (c >= 0xAC00 && c <= 0xD7A3)   // Hangul Syllables
        || (c >= 0xF900 && c <= 0xFAFF)   // CJK compatibility ideographs
        || (c >= 0xFE30 && c <= 0xFE4F)   // CJK compatibility forms
        || (c >= 0xFF00 && c <= 0xFF60)   // Fullwidth forms
        || (c >= 0xFFE0 && c <= 0xFFE6)
        || (c >= 0x1F300 && c <= 0x1FAFF) // emoji, symbols and pictographs
        || (c >= 0x2600 && c <= 0x27BF)   // misc symbols and dingbats
        || (c >= 0x1F000 && c <= 0x1F0FF) // mahjong, dominoes, playing cards
        || (c >= 0x1F1E6 && c <= 0x1F1FF)) { // regional indicators (flags)
        return 2;
    }
    return 1;
}

NSUInteger CRDisplayWidth(NSString *string)
{
    NSUInteger length = [string length];
    NSUInteger index = 0;
    NSUInteger width = 0;

    while (index < length) {
        NSRange range = [string rangeOfComposedCharacterSequenceAtIndex:index];
        NSString *cluster = [string substringWithRange:range];
        // Width of the whole grapheme is the width of its base scalar: any
        // combining marks that follow add nothing.
        width += CRScalarWidth(CRFirstScalar(cluster));
        index = NSMaxRange(range);
    }

    return width;
}
