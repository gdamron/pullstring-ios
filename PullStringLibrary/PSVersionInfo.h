//
// Encapsulate version information for PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import <Foundation/Foundation.h>

/// A parameter for hasFeature: to define if audio streaming is supported
extern NSString *const PS_FEATURE_STREAMING_ASR;

/// A class to provide version information about this implementation of the SDK
@interface PSVersionInfo : NSObject
+ (NSString *) getApiBaseUrl;
+ (void) setApiBaseUrl: (NSString *) url;
+ (bool) hasFeature: (NSString *) featureName;
@end
