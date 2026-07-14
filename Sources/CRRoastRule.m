#import "CRRoastRule.h"

NSString *CRRuleSeverityName(CRRuleSeverity severity)
{
    switch (severity) {
        case CRRuleSeverityLow:
            return @"low";
        case CRRuleSeverityMedium:
            return @"medium";
        case CRRuleSeverityHigh:
            return @"high";
    }
    return @"unknown";
}
