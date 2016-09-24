//
// The main chat logic that integrates with PullString's Web API
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "ViewController.h"
#import "PullStringLibrary.h"
#import <AVFoundation/AVFoundation.h>

// The API Key and Project ID for the sample PullString project
// Replace these with your own IDs to talk to your own content
static NSString *API_KEY    = @"9fd2a189-3d57-4c02-8a55-5f0159bff2cf";
static NSString *PROJECT_ID = @"e50b56df-95b7-4fa1-9061-83a7a9bea372";

@interface ViewController ()
{
    PSConversation *convo;
    AVAudioPlayer *audioPlayer;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // start a new conversation with the project when the app starts
    convo = [PSConversation new];
    PSRequest *request = [PSRequest new];
    request.apiKey = API_KEY;
    [convo start:PROJECT_ID withRequest:request withCompletion:^(PSResponse *response){
        [self processResponse: response];
    }];
}

- (void) textEntered: (NSString *)text
{
    // cancel time-based responses if user entered new text
    [self cancelTimer];
    
    // display the user's text in the message view
    [self addUserOutput: text];
    
    // send the text to the Web API to process
    [convo sendText:text
        withRequest:nil
     withCompletion:^(PSResponse *response){
         [self processResponse: response];
     }];
}

- (void) sendAudioFile: (NSString *)name
{
    // get the path to the audio file in the app bundle
    NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], name];

    // play the audio file so that the user hears it
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    audioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url
                   error:&error];
    if (! error) {
        [audioPlayer play];
    }

    // send the audio file to the Web API for ASR input
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    [convo sendAudio:data
          withFormat:PSFormatWAV16k
        withRequest:nil
     withCompletion:^(PSResponse *response){
         [self processResponse: response];
     }];
}

- (void) processResponse: (PSResponse *) response
{
    // invalidate any in-flight time-based responses
    [self cancelTimer];
 
    // we can get a nil response from checkForTimedResponse
    if (! response) {
        return;
    }
    
    // if the Web API request failed, display the error message
    if (! response.status.success) {
        [self addError: response.status.errorMessage];
        return;
    }
    
    // output each line of dialog from for the bot
    for (id output in response.outputs) {
        if ([output isMemberOfClass: [PSDialogOutput class]]) {
            PSDialogOutput *dialog = (PSDialogOutput *)output;
            [self addBotOutput:dialog.text];
        } else if ([output isMemberOfClass: [PSBehaviorOutput class]]) {
            PSBehaviorOutput *behavior = (PSBehaviorOutput *)output;
            NSLog(@"Behavior: %@", behavior.behavior);
        }
    }
    
    // do we have a new time-based response to schedule?
    // if so, call the Web API back that many secs in the future
    if (response.timedResponseInterval >= 0) {
        [self startTimer: response.timedResponseInterval];
    }
}

- (void) startTimer: (double) timeout
{
    NSLog(@"Starting timer for time-based response: %lf secs", timeout);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(timeBasedResponse) withObject:nil afterDelay:timeout];
    });
}

- (void) cancelTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
}

- (void) timeBasedResponse
{
    // ask the Web API if there's a time-based response ready
    [convo checkForTimedResponse:nil
                  withCompletion:^(PSResponse *response){
        [self processResponse: response];
    }];
}

@end
