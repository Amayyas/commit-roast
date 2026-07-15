#import "CRTest.h"

#include <stdio.h>

static NSUInteger gPassed = 0;
static NSUInteger gFailed = 0;

void CRTestPass(void)
{
    gPassed++;
}

void CRTestFail(NSString *reason, const char *file, int line)
{
    gFailed++;
    // Relative path keeps the line short and clickable.
    const char *base = strrchr(file, '/');
    fprintf(stderr, "  [FAIL] %s:%d  %s\n",
            base ? base + 1 : file, line, [reason UTF8String]);
}

int CRTestSummary(void)
{
    NSUInteger total = gPassed + gFailed;
    if (gFailed == 0) {
        printf("\n  %lu assertions, all passed.\n", (unsigned long)total);
        return 0;
    }
    printf("\n  %lu assertions, %lu FAILED.\n",
           (unsigned long)total, (unsigned long)gFailed);
    return 1;
}
