#import "CRError.h"

NSString *const CRErrorDomain = @"com.amayyas.commit-roast";

NSError *CRMakeError(CRErrorCode code, NSString *message)
{
    NSDictionary *info = [NSDictionary dictionaryWithObject:(message ?: @"Unknown error")
                                                     forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:CRErrorDomain code:code userInfo:info];
}
