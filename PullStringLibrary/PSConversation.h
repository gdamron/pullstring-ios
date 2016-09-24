//
// Encapsulate a conversation thread for PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import <Foundation/Foundation.h>
#import "PSRequest.h"
#import "PSResponse.h"

/// The copyright string for this library.
extern NSString * const PSCopyright;
/// The version number for this library.
extern NSString * const PSVersion;
/// The name of the license that this library is distributed under.
extern NSString * const PSLicense;

/// Define the audio formats for sending audio to the server
typedef NS_ENUM(NSInteger, PSAudioFormat) {
    PSFormatRawPCM16k,
    PSFormatWAV16k
};

///
/// The PSConversation object lets you interface with PullString's Web API.
///
/// To initiate a conversation, you call the start: method, providing
/// the PullString project ID and a PSRequest object that must specify
/// your API Key. The API Key will be remembered for future requests to
/// the same PSConversation instance.
///
/// The response from the Web API is returned as a PSResponse object,
/// which can contain zero or more outputs, including lines of dialog
/// or behaviors. You provide a completion block to receive the PSResponse
/// from the server when it is available.
///
/// You can send input to the Web API using the various sendXXX:
/// methods, e.g., use sendText: to send a text input string or
/// sendAudio: to send 16-bit LinearPCM audio data.
///
@interface PSConversation : NSObject

///
/// Start a new conversation with the Web API and return the response.
/// You must specify the PullString project name and a Request
/// object that specifies your valid API key.
///
- (void) start: (NSString *) projectName
   withRequest: (PSRequest *) request
withCompletion: (void (^)(PSResponse *response))block;

///
/// Send user input text to the Web API and return the response.
///
- (void) sendText: (NSString *) text
      withRequest: (PSRequest *) request
   withCompletion: (void (^)(PSResponse *response))block;

///
/// Send an activity name or ID to the Web API and return the response.
///
- (void) sendActivity: (NSString *) activity
          withRequest: (PSRequest *) request
       withCompletion: (void (^)(PSResponse *response))block;

///
/// Send a named event to the Web API and return the response.
///
- (void) sendEvent: (NSString *) event
        withParams: (NSDictionary *) parameters
       withRequest: (PSRequest *) request
    withCompletion: (void (^)(PSResponse *response))block;

///
/// Send an entire audio sample of the user speaking to the Web
/// API. The default format of the audio (PSFormatRawPCM16k)
/// must be mono 16-bit LinearPCM audio data at a sample rate of
/// 16000 samples per second. Alternatively, you can provide a WAV
/// file with mono 16-bit LinearPCM audio at 16000 sample rate.
/// The block may receive a nil pointer if the audio is invalid.
///
- (void) sendAudio: (NSData *) bytes
        withFormat: (PSAudioFormat) format
       withRequest: (PSRequest *) request
    withCompletion: (void (^)(PSResponse *response))block;

///
/// Initiate a progressive (chunked) streaming of audio data, where supported.
///
/// Note, chunked streaming is not currently implemented, so this will
/// batch up all audio and send it all at once when end_audio() is called.
///
- (void) startAudio: (PSRequest *) request;

///
/// Add a chunk of audio. You must call start_audio() first.  The
/// format of the audio must be mono 16-bit LinearPCM audio data
/// at a sample rate of 16000 samples per second.
///
- (void) addAudio: (NSData *) bytes;

///
/// Signal that all audio has been provided via add_audio() calls.
/// This will complete the audio request and return the Web API response.
///
- (void) endAudio: (void (^)(PSResponse *response))block;

///
/// Jump the conversation directly to the response with the specified GUID.
///
- (void) goTo: (NSString *) responseId
  withRequest: (PSRequest *) request
withCompletion: (void (^)(PSResponse *response))block;

///
/// Call the Web API to see if there is a time-based response to process.
/// You only need to call this if the previous response returned a value
/// for timedResponseInterval >= 0. In which case, you should set a timer
/// for that number of seconds and then call this function.
/// This function will return nil if there is no time-based response.
///
- (void) checkForTimedResponse: (PSRequest *) request
                withCompletion: (void (^)(PSResponse *response))block;

///
/// Request the value of the specified entities from the Web API.
///
- (void) getEntities: (NSArray *) entities
         withRequest: (PSRequest *) request
      withCompletion: (void (^)(PSResponse *response))block;

///
/// Change the value of the specified entities via the Web API.
///
- (void) setEntities: (NSArray *) entities
         withRequest: (PSRequest *) request
      withCompletion: (void (^)(PSResponse *response))block;

///
/// Return the current conversation ID for clients to persist across sessions if desired.
///
- (NSString *) getConversationId;

///
/// Return the current state ID for clients to persist across sessions if desired.
///
- (NSString *) getStateId;

@end
