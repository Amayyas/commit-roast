#import <Foundation/Foundation.h>

#import "CROutputFormatter.h"

// The terminal report. colorEnabled toggles ANSI on or off over one and the
// same layout — --no-color (#18) is this formatter with the flag set to NO, not
// a second renderer.
@interface CRTextFormatter : NSObject <CROutputFormatter>
{
    BOOL _colorEnabled;
}

- (instancetype)initWithColorEnabled:(BOOL)colorEnabled;

@end
