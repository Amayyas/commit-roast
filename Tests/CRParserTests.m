#import "CRParserTests.h"

#import "CRTest.h"

#import "CRCommit.h"
#import "CRCommitParser.h"
#import "CRGitLogReader.h"   // for the field/record separators
#import "CRStringUtils.h"

#define FS @CR_FIELD_SEPARATOR
#define RS @CR_RECORD_SEPARATOR

// Builds one raw record with the same layout git produces:
// %H FS %an FS %ae FS %aI FS %s FS %b RS
static NSString *CRRecord(NSString *sha, NSString *subject, NSString *body)
{
    return [NSString stringWithFormat:@"%@%@Amayyas%@a@b.c%@2026-01-04T10:22:31+01:00%@%@%@%@%@",
            sha, FS, FS, FS, FS, subject, FS, body, RS];
}

void CRRunParserTests(void)
{
    // --- empty / degenerate input ---
    CR_ASSERT_EQ_INT([[CRCommitParser parseRawLog:nil] count], 0, "nil -> empty array");
    CR_ASSERT_EQ_INT([[CRCommitParser parseRawLog:@""] count], 0, "empty string -> empty array");

    // --- one commit ---
    NSArray *one = [CRCommitParser parseRawLog:CRRecord(@"abc1234def", @"Add retry logic", @"")];
    CR_ASSERT_EQ_INT([one count], 1, "one record -> one commit");
    CRCommit *c = [one objectAtIndex:0];
    CR_ASSERT_EQ_STR([c sha], @"abc1234def", "sha parsed");
    CR_ASSERT_EQ_STR([c shortSHA], @"abc1234", "shortSHA is 7 chars");
    CR_ASSERT_EQ_STR([c subject], @"Add retry logic", "subject parsed");
    CR_ASSERT_EQ_STR([c authorName], @"Amayyas", "author parsed");
    CR_ASSERT([c date] != nil, "ISO 8601 date parsed to non-nil NSDate");

    // --- N commits, separated by the newline git writes between records ---
    NSString *multi = [NSString stringWithFormat:@"%@\n%@\n%@",
                       CRRecord(@"a1", @"fix", @""),
                       CRRecord(@"b2", @"wip", @""),
                       CRRecord(@"c3", @"Add tests", @"")];
    NSArray *three = [CRCommitParser parseRawLog:multi];
    CR_ASSERT_EQ_INT([three count], 3, "three records despite newlines between them");
    CR_ASSERT_EQ_STR([[three objectAtIndex:1] subject], @"wip", "second commit's subject");

    // --- multi-line message: subject / body split ---
    NSArray *ml = [CRCommitParser parseRawLog:
                      CRRecord(@"d4", @"Fix the cache", @"Line one.\nLine two.\n")];
    CRCommit *m = [ml objectAtIndex:0];
    CR_ASSERT_EQ_STR([m body], @"Line one.\nLine two.", "multi-line body kept, trailing newline trimmed");
    CR_ASSERT_EQ_STR([m fullMessage], @"Fix the cache\n\nLine one.\nLine two.",
                     "fullMessage joins subject and body");

    // --- empty message ---
    NSArray *empty = [CRCommitParser parseRawLog:CRRecord(@"e5", @"", @"")];
    CR_ASSERT_EQ_INT([empty count], 1, "empty subject: commit kept, no crash");
    CR_ASSERT_EQ_STR([[empty objectAtIndex:0] subject], @"", "empty subject is empty string");

    // --- UTF-8: emoji and accents survive intact ---
    NSArray *utf = [CRCommitParser parseRawLog:CRRecord(@"f6", @"🔥 Réparé le café ☕", @"")];
    CR_ASSERT_EQ_STR([[utf objectAtIndex:0] subject], @"🔥 Réparé le café ☕",
                     "emoji and accents preserved");

    // --- a field separator inside the body is legal and must not lose data ---
    NSString *weird = [NSString stringWithFormat:@"h8%@A%@a@b%@2026-01-04T10:22:31+01:00%@Subject%@body%@tail%@",
                       FS, FS, FS, FS, FS, FS, RS];
    NSArray *w = [CRCommitParser parseRawLog:weird];
    CR_ASSERT_EQ_INT([w count], 1, "separator inside body: still one commit");
    CR_ASSERT([[[w objectAtIndex:0] body] rangeOfString:@"tail"].location != NSNotFound,
              "separator inside body: the tail is not dropped");

    // --- malformed record skipped, valid ones around it survive ---
    NSString *bad = [NSString stringWithFormat:@"deadbeef%@onlytwo%@\n%@",
                     FS, RS, CRRecord(@"g7", @"Add x", @"")];
    NSArray *mixed = [CRCommitParser parseRawLog:bad];
    CR_ASSERT_EQ_INT([mixed count], 1, "truncated record skipped, valid one survives");
    CR_ASSERT_EQ_STR([[mixed objectAtIndex:0] subject], @"Add x", "the surviving commit is the valid one");

    // --- grapheme length underpins the too-short rule ---
    CR_ASSERT_EQ_INT(CRGraphemeLength(@"🔥🔥🔥🔥🔥"), 5, "five emoji count as 5 graphemes, not 10");
    CR_ASSERT_EQ_INT([@"🔥🔥🔥🔥🔥" length], 10, "...while -length counts 10 UTF-16 units");
}
