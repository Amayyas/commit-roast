#import <Foundation/Foundation.h>

#import "CROutputFormatter.h"

// Serializes the report as JSON. The repository path is passed in because the
// report itself does not carry it — the text formatter never needed it.
@interface CRJSONFormatter : NSObject <CROutputFormatter>
{
    NSString *_repositoryPath;
}

- (instancetype)initWithRepositoryPath:(NSString *)repositoryPath;

@end
