#import "CRRuleBreakdown.h"

@implementation CRRuleBreakdown

@synthesize identifier = _identifier;
@synthesize displayName = _displayName;
@synthesize severity = _severity;
@synthesize matchCount = _matchCount;
@synthesize percentage = _percentage;
@synthesize examples = _examples;

- (instancetype)initWithRule:(id<CRRoastRule>)rule
                  matchCount:(NSUInteger)matchCount
                  percentage:(double)percentage
                    examples:(NSArray *)examples
{
    self = [super init];
    if (self) {
        _identifier = [[rule identifier] copy];
        _displayName = [[rule displayName] copy];
        _severity = [rule severity];
        _matchCount = matchCount;
        _percentage = percentage;
        _examples = [examples copy];
    }
    return self;
}

- (void)dealloc
{
    [_identifier release];
    [_displayName release];
    [_examples release];
    [super dealloc];
}

@end
