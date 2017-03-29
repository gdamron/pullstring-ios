//
// Encapsulate a request to the PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import <Foundation/Foundation.h>

/// The asset build type to request for Web API requests
typedef NS_ENUM(NSInteger, PSBuildType) {
    PSBuildTypeSandbox,
    PSBuildTypeStaging,
    PSBuildTypeProduction
};

typedef NS_ENUM(NSInteger, PSIfModifiedAction) {
    PSIfModifiedActionRestart,
    PSIfModifiedActionUpdate,
    PSIfModifiedActionNothing
};

/// Describe the parameters for a request to the PullString Web API
@interface PSRequest : NSObject

@property NSString              *apiKey;
@property NSString              *participantId;
@property PSIfModifiedAction    ifModifiedAction;
@property BOOL                  restartIfModified;
@property PSBuildType           buildType;
@property NSString              *conversationId;
@property NSString              *language;
@property NSString              *locale;
@property int                   timeZoneOffset;

@end
