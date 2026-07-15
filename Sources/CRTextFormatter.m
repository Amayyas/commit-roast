#import "CRTextFormatter.h"

#include <math.h>

#import "CRANSI.h"
#import "CRRuleBreakdown.h"
#import "CRStringUtils.h"

static const NSUInteger kCRGaugeWidth = 24;   // cells in the shame gauge
static const NSUInteger kCRBoxMaxInner = 68;   // widest the worst-commit box gets
static const NSUInteger kCRSubjectMax = 60;   // truncate example subjects to this

@implementation CRTextFormatter

- (instancetype)initWithColorEnabled:(BOOL)colorEnabled
{
    self = [super init];
    if (self) {
        _colorEnabled = colorEnabled;
    }
    return self;
}

// The single choke point for color. In no-color mode it returns the text
// untouched, so there is exactly one layout and no way for the two modes to
// drift apart.
- (NSString *)paint:(NSString *)text with:(const char *)ansi
{
    if (!_colorEnabled) {
        return text;
    }
    return [NSString stringWithFormat:@"%s%@%s", ansi, text, CR_ANSI_RESET];
}

- (const char *)ansiForScore:(double)score
{
    if (score < 30.0) {
        return CR_ANSI_GREEN;
    }
    if (score <= 60.0) {
        return CR_ANSI_YELLOW;
    }
    return CR_ANSI_RED;
}

// A bar of `width` cells, `filled` of them solid.
- (NSString *)barFilled:(NSUInteger)filled width:(NSUInteger)width
{
    NSMutableString *bar = [NSMutableString string];
    NSUInteger i;
    for (i = 0; i < width; i++) {
        [bar appendString:(i < filled) ? @"█" : @"░"];
    }
    return bar;
}

- (NSString *)spaces:(NSUInteger)count
{
    if (count == 0) {
        return @"";
    }
    return [@"" stringByPaddingToLength:count withString:@" " startingAtIndex:0];
}

#pragma mark - Sections

- (void)appendHeaderTo:(NSMutableString *)out
{
    [out appendFormat:@"%@\n\n", [self paint:@"commit-roast" with:CR_ANSI_BOLD CR_ANSI_CYAN]];
}

- (void)appendScoreTo:(NSMutableString *)out report:(CRRoastReport *)report
{
    double score = [report shameScore];
    const char *ansi = [self ansiForScore:score];
    NSUInteger filled = (NSUInteger)lround(score / 100.0 * (double)kCRGaugeWidth);
    NSString *gauge = [self barFilled:filled width:kCRGaugeWidth];
    NSString *number = [NSString stringWithFormat:@"%.0f/100", score];

    [out appendFormat:@"  Shame score  %@ %@\n",
        [self paint:gauge with:ansi],
        [self paint:number with:ansi]];
    [out appendFormat:@"  %@ of %lu commits could have tried harder.\n\n",
        [self paint:[NSString stringWithFormat:@"%lu", (unsigned long)[report guiltyCommits]]
               with:CR_ANSI_BOLD],
        (unsigned long)[report totalCommits]];
}

- (void)appendBreakdownTo:(NSMutableString *)out report:(CRRoastReport *)report
{
    if ([[report breakdown] count] == 0) {
        return;
    }
    [out appendFormat:@"%@\n", [self paint:@"What we found" with:CR_ANSI_BOLD]];

    NSEnumerator *e = [[report breakdown] objectEnumerator];
    CRRuleBreakdown *entry = nil;
    while ((entry = [e nextObject]) != nil) {
        NSUInteger filled = (NSUInteger)lround([entry percentage] / 100.0 * 12.0);
        NSString *bar = [self barFilled:filled width:12];
        // Severity as a word, not only a color, so --no-color keeps the meaning.
        NSString *sev = [NSString stringWithFormat:@"[%@]",
                            CRRuleSeverityName([entry severity])];
        const char *sevAnsi = ([entry severity] == CRRuleSeverityHigh) ? CR_ANSI_RED
                            : ([entry severity] == CRRuleSeverityMedium) ? CR_ANSI_YELLOW
                            : CR_ANSI_GRAY;

        [out appendFormat:@"  %@  %@  %-22@ %@ (%.0f%%)\n",
            [self paint:bar with:CR_ANSI_RED],
            [self paint:sev with:sevAnsi],
            [entry displayName],
            [self paint:[NSString stringWithFormat:@"%lu", (unsigned long)[entry matchCount]]
                   with:CR_ANSI_BOLD],
            [entry percentage]];

        NSEnumerator *xe = [[entry examples] objectEnumerator];
        CRCommit *example = nil;
        while ((example = [xe nextObject]) != nil) {
            NSString *subject = CRTruncateToGraphemes([example subject], kCRSubjectMax);
            NSString *line = [NSString stringWithFormat:@"      %@  %@",
                                [example shortSHA], subject];
            [out appendFormat:@"%@\n", [self paint:line with:CR_ANSI_GRAY]];
        }
    }
    [out appendString:@"\n"];
}

// A box whose borders match the DISPLAY width of the content, so an emoji or an
// accent in the subject does not push the right edge out of alignment.
//
// visibleWidth is passed separately from the painted text: in color mode the
// painted string carries escape codes that occupy zero columns, so measuring it
// directly would over-pad. Width is always taken from the uncolored content.
- (void)appendBoxContent:(NSString *)painted
             visibleWidth:(NSUInteger)visibleWidth
                       to:(NSMutableString *)out
                    inner:(NSUInteger)inner
{
    NSUInteger pad = (visibleWidth < inner) ? inner - visibleWidth : 0;
    [out appendFormat:@"  │ %@%@ │\n", painted, [self spaces:pad]];
}

- (void)appendWorstTo:(NSMutableString *)out report:(CRRoastReport *)report
{
    if ([report worstCommit] == nil) {
        // Nothing to crown. Congratulate rather than draw an empty box.
        [out appendFormat:@"%@\n",
            [self paint:@"  Spotless history. We found nothing to roast — almost disappointing."
                   with:CR_ANSI_GREEN]];
        return;
    }

    NSString *subject = CRTruncateToGraphemes([[report worstCommit] subject], kCRSubjectMax);
    NSString *sha = [[report worstCommit] shortSHA];
    NSString *punchline = CRTruncateToGraphemes([report worstPunchline], kCRBoxMaxInner);

    NSString *header = [NSString stringWithFormat:@"%@  %@", sha, subject];
    NSUInteger inner = CRDisplayWidth(header);
    if (CRDisplayWidth(punchline) > inner) {
        inner = CRDisplayWidth(punchline);
    }
    if (inner > kCRBoxMaxInner) {
        inner = kCRBoxMaxInner;
    }

    [out appendFormat:@"%@\n", [self paint:@"Worst offender" with:CR_ANSI_BOLD]];

    NSString *top = [@"" stringByPaddingToLength:inner + 2 withString:@"─" startingAtIndex:0];
    [out appendFormat:@"  ┌%@┐\n", top];
    [self appendBoxContent:[self paint:header with:CR_ANSI_RED]
              visibleWidth:CRDisplayWidth(header) to:out inner:inner];
    [self appendBoxContent:punchline
              visibleWidth:CRDisplayWidth(punchline) to:out inner:inner];
    [out appendFormat:@"  └%@┘\n", top];
}

#pragma mark - CROutputFormatter

- (NSString *)formatReport:(CRRoastReport *)report
{
    NSMutableString *out = [NSMutableString string];
    [self appendHeaderTo:out];

    if ([report totalCommits] == 0) {
        [out appendString:@"  No commits to roast. Is this an empty repository?\n"];
        return out;
    }

    [self appendScoreTo:out report:report];
    [self appendBreakdownTo:out report:report];
    [self appendWorstTo:out report:report];
    return out;
}

@end
