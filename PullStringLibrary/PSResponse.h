//
// Encapsulate a response from the PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import <Foundation/Foundation.h>

/// Define the set of outputs that can be returned in a response.
typedef NS_ENUM(NSInteger, PSOutputType) {
    PSOutputDialog,
    PSOutputBehavior
};

/// Define the list of entity types
typedef NS_ENUM(NSInteger, PSEntityType) {
    PSEntityLabel,
    PSEntityCounter,
    PSEntityFlag
};

/// Describe a single phoneme for an audio response, e.g., to drive automatic lip sync.
@interface PSPhoneme : NSObject
@property NSString *name;
@property double   secondsSinceStart;
@end

/// Base class to describe a single entity, such as a label, counter, or flag
@interface PSEntity : NSObject
@property NSString     *name;
@property PSEntityType type;
- (id) initWithName: (NSString *) entityName;
@end

/// Subclass of Entity to describe a single Label
@interface PSLabel : PSEntity
@property NSString *value;
- (id) initWithName: (NSString *) entityName andValue: (NSString *)value;
@end

/// Subclass of Entity to describe a single Counter
@interface PSCounter : PSEntity
@property double value;
- (id) initWithName: (NSString *) entityName andValue: (double)value;
@end

/// Subclass of Entity to describe a single Flag
@interface PSFlag : PSEntity
@property BOOL value;
- (id) initWithName: (NSString *) entityName andValue: (BOOL)value;
@end

/// Base class for outputs that are of type dialog or behavior
@interface PSOutput : NSObject
@property NSString     *guid;
@property PSOutputType type;
@end

/// Subclass of Output that represents a dialog response
@interface PSDialogOutput : PSOutput
@property NSString *text;
@property NSString *uri;
@property NSString *character;
@property NSString *userData;
@property NSArray  *phonemes;
@property double   duration;
@end

/// Subclass of Output that represents a behavior response
@interface PSBehaviorOutput : PSOutput
@property NSString *behavior;
@property NSDictionary *parameters;
@end

/// Describe the status and any errors from a Web API response
@interface PSStatus : NSObject
@property int      statusCode;
@property NSString *errorMessage;
@property bool     success;
@end

/// Describe a single response from the PullString Web API
@interface PSResponse : NSObject
@property NSArray  *outputs;
@property NSArray  *entities;
@property PSStatus *status;
@property NSString *conversationEndpoint;
@property NSString *lastModified;
@property NSString *etag;
@property NSString *conversationId;
@property NSString *participantId;
@property double   timedResponseInterval;
@property NSString *asrHypothesis;
@end
