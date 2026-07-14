#import <Foundation/Foundation.h>

// Number of user-perceived characters in a string.
//
// -[NSString length] counts UTF-16 code units, so an emoji outside the Basic
// Multilingual Plane counts as 2 and a flag counts as 4. Any rule that measures
// how long a commit message "is" must use this instead, or "🔥🔥🔥🔥🔥" would
// count as ten characters and escape the too-short rule.
NSUInteger CRGraphemeLength(NSString *string);
