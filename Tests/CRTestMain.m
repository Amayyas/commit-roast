#import <Foundation/Foundation.h>

#import "CRTest.h"

#import "CRParserTests.h"

// The single entry point of the test binary. Each suite is a function; add a
// line here to register a new one. (#21 appends the engine suite.)
int main(void)
{
    @autoreleasepool {
        printf("commit-roast tests\n");
        CRRunParserTests();
        return CRTestSummary();
    }
}
