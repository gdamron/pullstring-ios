//
// Encapsulate a request to the PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "PSRequest.h"

@implementation PSRequest
- (id) init
{
    if ( self = [super init] ) {
        self.apiKey = [NSString new];
        self.participantId = [NSString new];
        self.restartIfModified = YES;
        self.buildType = PSBuildTypeProduction;
        self.language = [NSString new];
        self.locale = [NSString new];
        self.timeZoneOffset = 0;
    }
    return self;
}
@end
