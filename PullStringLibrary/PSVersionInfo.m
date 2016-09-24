//
// Encapsulate version information for PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "PSVersionInfo.h"

NSString *const PS_FEATURE_STREAMING_ASR = @"streaming-asr";

static NSString *sApiBaseUrl = @"https://conversation.pullstring.ai/v1";

@implementation PSVersionInfo

+ (void) setApiBaseUrl: (NSString *) url
{
    sApiBaseUrl = url;
}

+ (NSString*) getApiBaseUrl
{
    return sApiBaseUrl;
}


+ (bool) hasFeature: (NSString *) featureName
{
    if ([featureName isEqualToString: PS_FEATURE_STREAMING_ASR]) {
        // we don't support streaming audio in this implementation yet
        return false;
    }
    return false;
}

@end
