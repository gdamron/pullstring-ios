//
// A text messaging view to show a two-way conversation
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "MessageView.h"

@interface MessageView ()
{
    NSMutableArray *lines;
}
@end

@implementation MessageView

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.textField becomeFirstResponder];
    lines = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(keyboardWillBeShown:)
               name:UIKeyboardWillShowNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(keyboardWillBeHidden:)
               name:UIKeyboardWillHideNotification
             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:self
                  name:UIKeyboardWillShowNotification
                object:nil];
    
    [nc removeObserver:self
                  name:UIKeyboardWillHideNotification
                object:nil];
    
    [super viewWillDisappear:animated];
    
}

- (void)keyboardWillBeShown:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.3];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - keyboardSize.height,
                                 self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.3];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + keyboardSize.height,
                                 self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        NSString *text = textField.text;
        textField.text = @"";
        [self textEntered: text];
    }
    return YES;
}

- (void) textEntered: (NSString *) text
{
    // override in subclass
}

- (void) addOutput: (NSString *) output asUser:(BOOL)user
{
    NSString *line = [NSString new];
    if (user) {
        line = [line stringByAppendingFormat:@"<div class=\"user\">%@</div>", output];
    } else {
        line = [line stringByAppendingFormat:@"<div class=\"bot\">%@</div>", output];
    }
    [lines addObject:line];
    [self refresh];
}

- (void) addUserOutput: (NSString *) output
{
    NSString *line = [NSString stringWithFormat:@"<div class=\"user\">%@</div>", output];
    [lines addObject:line];
    [self refresh];
}

- (void) addBotOutput: (NSString *) output
{
    NSString *line = [NSString stringWithFormat:@"<div class=\"bot\">%@</div>", output];
    [lines addObject:line];
    [self refresh];
}

- (void) addError: (NSString *) error
{
    [lines addObject: [NSString stringWithFormat:@"<div class=\"error\">%@</div>", error]];
    [self refresh];
}

- (void) refresh
{
    NSString *html = @"<html><head><style TYPE=\"text/css\">";
    html = [html stringByAppendingString: @".user { font-family: arial, helvetica, sans-serif; color: white; font-size: 2em; background-color: #1899ff; border: 1px solid #77b; border-radius: 0.5em; padding: 0.2em 0.5em 0.2em 0.5em; margin-left: 40%; margin-right: 1em; margin-top: 0.2em; margin-bottom: 0.2em; text-align: right; }"];
    html = [html stringByAppendingString: @".bot { font-family: arial, helvetica, sans-serif;color: black; font-size: 2em; background-color: #e4e4e4; border: 1px solid #bbb; border-radius: 0.5em; padding: 0.2em 0.5em 0.2em 0.5em; margin-left: 1em;margin-right: 40%; margin-top: 0.2em; margin-bottom: 0.2em; }"];
    html = [html stringByAppendingString: @".error { font-family: \"Courier New\", Courier, monospace; font-size: 1.5em; color: red; padding: 0.2em 0.5em 0.2em 0.5em; margin-left: 1em; margin-right: 1em; margin-top: 0.2em;margin-bottom: 0.2em; }"];
    html = [html stringByAppendingString: @"</style></head><body>"];
    html = [html stringByAppendingString: @"<div style=\"position: fixed; bottom: 0; width: 100%;\">"];
    for (id object in lines) {
        html = [html stringByAppendingString: (NSString *)object];
    }
    html = [html stringByAppendingString: @"</div></body></html>"];
    [self.webView loadHTMLString:html baseURL:nil];
}

@end
