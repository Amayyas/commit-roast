#import <Foundation/Foundation.h>

#import "CRRoastReport.h"

// Renders a report to a string. Text and JSON both conform, so main() picks one
// by --format and never branches on the format again.
@protocol CROutputFormatter <NSObject>
- (NSString *)formatReport:(CRRoastReport *)report;
@end
