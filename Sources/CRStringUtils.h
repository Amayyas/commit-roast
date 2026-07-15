#import <Foundation/Foundation.h>

// Number of user-perceived characters in a string.
//
// -[NSString length] counts UTF-16 code units, so an emoji outside the Basic
// Multilingual Plane counts as 2 and a flag counts as 4. Any rule that measures
// how long a commit message "is" must use this instead, or "🔥🔥🔥🔥🔥" would
// count as ten characters and escape the too-short rule.
NSUInteger CRGraphemeLength(NSString *string);

// Truncates to at most maxGraphemes user-perceived characters, appending "…"
// when it actually cut something. Counts and cuts on grapheme boundaries, so an
// emoji is never sliced in half into a replacement character.
NSString *CRTruncateToGraphemes(NSString *string, NSUInteger maxGraphemes);

// A stable 32-bit hash (FNV-1a) of the string's UTF-8 bytes.
//
// Used to pick a punchline variant deterministically. -[NSString hash] is not
// guaranteed stable across GNUstep versions or platforms, and the whole point is
// that the same commit yields the same punchline on every run and every machine.
uint32_t CRStableHash(NSString *string);

// How many terminal columns the string occupies.
//
// Not its -length (UTF-16 code units) and not its grapheme count either: a CJK
// ideograph and an emoji each take two columns, a composed accent's combining
// mark takes zero. Box borders and padding sized from -length break the moment a
// commit subject contains any of these.
NSUInteger CRDisplayWidth(NSString *string);
