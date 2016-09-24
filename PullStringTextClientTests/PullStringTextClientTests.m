//
// Automated tests for the PullString iOS SDK
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "PullStringLibrary.h"
#import <XCTest/XCTest.h>

static NSString *API_KEY    = @"9fd2a189-3d57-4c02-8a55-5f0159bff2cf";
static NSString *PROJECT_ID = @"e50b56df-95b7-4fa1-9061-83a7a9bea372";

@interface PullStringTextClientTests : XCTestCase
{
    PSConversation *conv;
    PSRequest *request;
    dispatch_semaphore_t sem;
}
@end

@implementation PullStringTextClientTests

- (void) setUp
{
    [super setUp];
    conv = [PSConversation new];
    request = [PSRequest new];
    request.apiKey = API_KEY;
    sem = dispatch_semaphore_create(0);
}

- (bool) checkContains: (PSResponse *) response text: (NSString *) text
{
    if (response) {
        NSLog(@"Checking dialog resonses for '%@'...", text);
        for (PSOutput *output in response.outputs) {
            if (output.type == PSOutputDialog) {
                PSDialogOutput *dialog = (PSDialogOutput *) output;
                NSLog(@"  Found '%@'", dialog.text);
                if ([dialog.text rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    NSLog(@"    MATCH!");
                    return true;
                }
            }
        }
    }
    NSLog(@"    NO MATCH FOUND!");
    return false;
}

- (void) assertContains: (PSResponse *) response text: (NSString *) text
{
    XCTAssert(response != nil);
    if (! [self checkContains:response text:text]) {
        XCTFail(@"Cannot find '%@' in response outputs", text);
    }
}

- (void) signalThatTestIsFinished
{
    dispatch_semaphore_signal(sem);
}

- (void) waitForTestToFinish
{
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

- (void) testRockPaperScissors
{
    // start a new conversation
    [conv start:PROJECT_ID withRequest:request withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"Do you want to play"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];
    
    // say that we don't want to play to start with
    [conv sendText:@"no" withRequest:nil withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"was that a yes"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];

    // now concede and accept to play
    [conv sendText:@"yes" withRequest:nil withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"great"];
        [self assertContains:response text:@"rock, paper or scissors?"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];

    // ask how to play the game to get some information
    [conv sendText:@"how do I play this game?" withRequest:nil withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"a game of chance"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];

    // query the current value of the Player Score counter (it's 4 at the start)
    NSMutableArray *entities = [NSMutableArray new];
    [entities addObject:[[PSCounterEntity alloc] initWithName:@"Player Score"]];
    [conv getEntities:entities withRequest:nil withCompletion:^(PSResponse *response){
        XCTAssert(response != nil);
        int num_entities = (int)[response.entities count];
        XCTAssertEqual(num_entities, 1);
        if (num_entities > 0) {
            PSEntity *entity = [response.entities objectAtIndex:0];
            XCTAssert(entity != nil && entity.type == PSEntityCounter);
            PSCounterEntity *counter = (PSCounterEntity *) entity;
            XCTAssert(counter.value == 4);
        }
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];
    
    // let's start playing... keep choosing until we win or lose
    NSArray *choices = [[NSArray alloc] initWithObjects: @"paper", @"rock", @"scissors", @"paper", nil];
    __block bool finished = false;
    for (NSString *choice in choices) {
        [conv sendText:choice withRequest:nil withCompletion:^(PSResponse *response){
            if ([self checkContains:response text:@"lost"] ||
                [self checkContains:response text:@"won"] ||
                [self checkContains:response text:@"good game"]) {
                finished = true;
            }
            [self signalThatTestIsFinished];
        }];
        [self waitForTestToFinish];
        if (finished) {
            break;
        }
    }
    if (! finished) {
        XCTFail(@"Game didn't finish after %lu iterations", [choices count]);
    }
    
    // set the Name label and confirm that we can get back the new value
    entities = [NSMutableArray new];
    [entities addObject:[[PSLabelEntity alloc] initWithName:@"NAME" andValue:@"Jack"]];
    [conv setEntities:entities withRequest:nil withCompletion:^(PSResponse *response){
        XCTAssert(response != nil);
        int num_entities = (int)[response.entities count];
        XCTAssertEqual(num_entities, 1);
        if (num_entities > 0) {
            PSEntity *entity = [response.entities objectAtIndex:0];
            XCTAssert(entity != nil && entity.type == PSEntityLabel);
            PSLabelEntity *label = (PSLabelEntity *) entity;
            XCTAssert([label.value isEqualToString:@"Jack"]);
        }
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];
    
    [conv getEntities:entities withRequest:nil withCompletion:^(PSResponse *response){
        XCTAssert(response != nil);
        int num_entities = (int)[response.entities count];
        XCTAssertEqual(num_entities, 1);
        if (num_entities > 0) {
            PSEntity *entity = [response.entities objectAtIndex:0];
            XCTAssert(entity != nil && entity.type == PSEntityLabel);
            PSLabelEntity *label = (PSLabelEntity *) entity;
            XCTAssert([label.value isEqualToString:@"Jack"]);
        }
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];
    
    // trigger a custom event to restart the experience
    [conv sendEvent:@"restart_game" withParams:nil withRequest:nil withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"Do you want to play"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];

    // start a new conversation but carry over the state from above
    PSRequest *newRequest = [PSRequest new];
    newRequest.apiKey = API_KEY;
    newRequest.stateId = [conv getStateId];
    [conv start:PROJECT_ID withRequest:newRequest withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"Do you want to play"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];

    // because we preserved state, the Name label should be the same as above
    [conv getEntities:entities withRequest:nil withCompletion:^(PSResponse *response){
        XCTAssert(response != nil);
        int num_entities = (int)[response.entities count];
        XCTAssertEqual(num_entities, 1);
        if (num_entities > 0) {
            PSEntity *entity = [response.entities objectAtIndex:0];
            XCTAssert(entity != nil && entity.type == PSEntityLabel);
            PSLabelEntity *label = (PSLabelEntity *) entity;
            XCTAssert([label.value isEqualToString:@"Jack"]);
        }
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];

    // say that we're done
    [conv sendText:@"quit" withRequest:nil withCompletion:^(PSResponse *response){
        [self assertContains:response text:@"start over"];
        [self signalThatTestIsFinished];
    }];
    [self waitForTestToFinish];
}

@end
