#ifndef CR_TEST_H
#define CR_TEST_H

#import <Foundation/Foundation.h>

// A minimal, portable assertion harness.
//
// Not XCTest: XCTest is not reliably available under GNUstep, and two test
// chains would mean maintaining the same tests twice and risking drift between
// the platforms. Thirty lines that compile everywhere buy us one suite that runs
// identically on macOS and Linux.

void CRTestPass(void);
void CRTestFail(NSString *reason, const char *file, int line);

// Prints the summary and returns a process exit code: 0 if every assertion
// passed, 1 otherwise — so `make test` goes red on a red suite.
int CRTestSummary(void);

#define CR_ASSERT(cond, msg) \
    do { \
        if (cond) { \
            CRTestPass(); \
        } else { \
            CRTestFail([NSString stringWithFormat:@"%s — %s", #cond, msg], \
                       __FILE__, __LINE__); \
        } \
    } while (0)

#define CR_ASSERT_EQ_STR(a, b, msg) \
    do { \
        NSString *_va = (a); \
        NSString *_vb = (b); \
        if ((_va == nil && _vb == nil) || [_va isEqual:_vb]) { \
            CRTestPass(); \
        } else { \
            CRTestFail([NSString stringWithFormat:@"%s: expected \"%@\", got \"%@\"", \
                        msg, _vb, _va], __FILE__, __LINE__); \
        } \
    } while (0)

#define CR_ASSERT_EQ_INT(a, b, msg) \
    do { \
        long _va = (long)(a); \
        long _vb = (long)(b); \
        if (_va == _vb) { \
            CRTestPass(); \
        } else { \
            CRTestFail([NSString stringWithFormat:@"%s: expected %ld, got %ld", \
                        msg, _vb, _va], __FILE__, __LINE__); \
        } \
    } while (0)

#endif /* CR_TEST_H */
