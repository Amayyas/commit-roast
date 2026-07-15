#import <Foundation/Foundation.h>

#import "CRArguments.h"

// Hand-rolled argv parsing — no getopt, no external dependency, so the same code
// builds under GNUstep.
@interface CRArgumentParser : NSObject

// stdoutIsTTY is injected rather than probed here so the parser stays a pure
// function of its inputs and the tests are deterministic. main() passes
// isatty(STDOUT_FILENO); tests pass whatever they need.
- (CRArguments *)parseArguments:(char **)argv
                          count:(int)argc
                    stdoutIsTTY:(BOOL)stdoutIsTTY;

@end
