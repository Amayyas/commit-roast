#import "CRArgumentParser.h"

#include <stdlib.h>

@implementation CRArgumentParser

// Fails the parse with a message. Returned so callers can `return [self fail...]`.
- (CRArguments *)failArguments:(CRArguments *)args withMessage:(NSString *)message
{
    [args setOk:NO];
    [args setErrorMessage:message];
    return args;
}

// Parses a non-negative integer that consumes the WHOLE string. "abc" and
// "5things" and "-3" all fail, rather than silently becoming 0.
- (BOOL)parseLimit:(NSString *)value into:(NSUInteger *)out
{
    NSScanner *scanner = [NSScanner scannerWithString:value];
    NSInteger parsed = 0;
    if (![scanner scanInteger:&parsed] || ![scanner isAtEnd] || parsed < 0) {
        return NO;
    }
    *out = (NSUInteger)parsed;
    return YES;
}

- (CRArguments *)parseArguments:(char **)argv
                          count:(int)argc
                    stdoutIsTTY:(BOOL)stdoutIsTTY
{
    CRArguments *args = [[[CRArguments alloc] init] autorelease];
    BOOL noColorFlag = NO;

    int i = 1;
    while (i < argc) {
        NSString *arg = [NSString stringWithUTF8String:argv[i]];

        // Split --flag=value once, so the two forms share all the logic below.
        NSString *name = arg;
        NSString *inlineValue = nil;
        if ([arg hasPrefix:@"--"]) {
            NSRange eq = [arg rangeOfString:@"="];
            if (eq.location != NSNotFound) {
                name = [arg substringToIndex:eq.location];
                inlineValue = [arg substringFromIndex:eq.location + 1];
            }
        }

        // Valueless flags first.
        if ([name isEqualToString:@"--help"] || [name isEqualToString:@"-h"]) {
            [args setAction:CRActionHelp];
            return args;   // help wins over everything else on the line
        }
        if ([name isEqualToString:@"--version"]) {
            [args setAction:CRActionVersion];
            return args;
        }
        if ([name isEqualToString:@"--no-color"]) {
            noColorFlag = YES;
            i += 1;
            continue;
        }

        // Value-taking flags. Pull the value from --flag=value or the next arg.
        if ([name isEqualToString:@"--repo"] || [name isEqualToString:@"--limit"]
            || [name isEqualToString:@"--since"] || [name isEqualToString:@"--author"]
            || [name isEqualToString:@"--format"]) {

            NSString *value = inlineValue;
            if (value == nil) {
                if (i + 1 >= argc) {
                    return [self failArguments:args
                                   withMessage:[NSString stringWithFormat:
                                       @"%@ requires a value.", name]];
                }
                value = [NSString stringWithUTF8String:argv[i + 1]];
                i += 1;
            }

            if ([name isEqualToString:@"--repo"]) {
                [[args logOptions] setRepositoryPath:value];
            } else if ([name isEqualToString:@"--since"]) {
                [[args logOptions] setSince:value];
            } else if ([name isEqualToString:@"--author"]) {
                [[args logOptions] setAuthor:value];
            } else if ([name isEqualToString:@"--limit"]) {
                NSUInteger limit = 0;
                if (![self parseLimit:value into:&limit]) {
                    return [self failArguments:args
                                   withMessage:[NSString stringWithFormat:
                                       @"--limit expects a non-negative integer, got \"%@\".", value]];
                }
                [[args logOptions] setLimit:limit];
            } else {   // --format
                if ([value isEqualToString:@"text"]) {
                    [args setJsonOutput:NO];
                } else if ([value isEqualToString:@"json"]) {
                    [args setJsonOutput:YES];
                } else {
                    return [self failArguments:args
                                   withMessage:[NSString stringWithFormat:
                                       @"--format must be \"text\" or \"json\", got \"%@\".", value]];
                }
            }

            i += 1;
            continue;
        }

        // Anything else is a mistake we should name, not ignore.
        return [self failArguments:args
                       withMessage:[NSString stringWithFormat:@"Unknown option: %@", arg]];
    }

    // Final color decision, all three sources folded into one boolean the
    // formatter can trust: an explicit --no-color, the NO_COLOR convention
    // (https://no-color.org), or output that is not a terminal.
    BOOL noColorEnv = (getenv("NO_COLOR") != NULL);
    [args setColorEnabled:(!noColorFlag && !noColorEnv && stdoutIsTTY)];

    return args;
}

@end
