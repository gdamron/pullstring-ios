//
// A text messaging view to show a two-way conversation
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import <UIKit/UIKit.h>

/// Visually present a text conversation between a user and a bot
@interface MessageView : UIViewController <UITextFieldDelegate>

@property IBOutlet UIWebView *webView;
@property IBOutlet UITextField *textField;

/// Display text entered by the user in the message view
- (void) addUserOutput: (NSString *) output;

/// Display text returned by the bot in the message view
- (void) addBotOutput: (NSString *) output;

/// Display an error message in the message view
- (void) addError: (NSString *) error;

/// Subclasses can override this to detect new user input
- (void) textEntered: (NSString *) text;

/// Subclasses can override this to send audio data
- (void) sendAudio: (NSString *) name;

@end

