//
// Encapsulate a response from the PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "PSResponse.h"

@implementation PSPhoneme
- (id) init
{
    if ( self = [super init] ) {
        self.name = [NSString new];
        self.secondsSinceStart = 0.0;
    }
    return self;
}
@end

@implementation PSEntity
- (id) init
{
    if (self = [super init]) {
        self.name = [NSString new];
        self.type = PSEntityLabel;
    }
    return self;
}
- (id) initWithName: (NSString *) entityName
{
    self = [self init];
    if (self) {
        self.name = entityName;
    }
    return self;
}
@end

@implementation PSLabelEntity
- (id) init
{
    if ( self = [super init] ) {
        self.type = PSEntityLabel;
        self.value = [NSString new];
    }
    return self;
}
- (id) initWithName: (NSString *) entityName andValue: (NSString *)value
{
    self = [self initWithName: entityName];
    if (self) {
        self.value = value;
    }
    return self;
}
@end

@implementation PSCounterEntity
- (id) init
{
    if ( self = [super init] ) {
        self.type = PSEntityCounter;
       self.value = 0.0;
    }
    return self;
}
- (id) initWithName: (NSString *) entityName andValue: (double)value
{
    self = [self initWithName: entityName];
    if (self) {
        self.value = value;
    }
    return self;
}
@end

@implementation PSFlagEntity
- (id) init
{
    if ( self = [super init] ) {
        self.type = PSEntityFlag;
        self.value = NO;
    }
    return self;
}
- (id) initWithName: (NSString *) entityName andValue: (BOOL)value
{
    self = [self initWithName: entityName];
    if (self) {
        self.value = value;
    }
    return self;
}
@end

@implementation PSOutput
- (id) init
{
    if ( self = [super init] ) {
        self.guid = [NSString new];
        self.type = PSOutputDialog;
    }
    return self;
}
@end

@implementation PSDialogOutput
- (id) init
{
    if ( self = [super init] ) {
        self.type = PSOutputDialog;
        self.text = [NSString new];
        self.uri = [NSString new];
        self.character = [NSString new];
        self.userData = [NSString new];
        self.phonemes = [NSMutableArray new];
        self.duration = 0.0;
    }
    return self;
}
@end

@implementation PSBehaviorOutput
- (id) init
{
    if ( self = [super init] ) {
        self.type = PSOutputBehavior;
        self.behavior = [NSString new];
        self.parameters = [NSMutableDictionary new];
    }
    return self;
}
@end

@implementation PSStatus
- (id) init
{
    if ( self = [super init] ) {
        self.statusCode = 200;
        self.errorMessage = [NSString new];
        self.success = true;
    }
    return self;
}
@end

@implementation PSResponse
- (id) init
{
    if ( self = [super init] ) {
        self.outputs = [NSMutableArray new];
        self.entities = [NSMutableArray new];
        self.status = [PSStatus new];
        self.conversationEndpoint = [NSString new];
        self.lastModified = [NSString new];
        self.conversationId = [NSString new];
        self.stateId = [NSString new];
        self.timedResponseInterval = -1.0;
        self.asrHypothesis = [NSString new];
    }
    return self;
}
@end
