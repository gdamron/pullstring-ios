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
@property (weak, nonatomic) IBOutlet UITextField *entryField;

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
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [self ensureTextFieldVisible:self.entryField keyboardSize:keyboardSize];
}

-(void)keyboardWillBeHidden:(NSNotification *)notification
{
    [self resetToInitialView];
}

-(void) ensureTextFieldVisible:(UITextField *)textField keyboardSize:(CGSize)keyboardSize;
{
    if (textField == nil) {
        return;
    }
    
    // are we obscuring the field?
    CGRect viewRect = self.view.bounds;
    viewRect.size.height -= keyboardSize.height;
    CGPoint pointInView = [textField convertPoint:CGPointMake(
                                                              0,textField.frame.size.height) toView:self.view];
    
    if (!CGRectContainsPoint(viewRect, pointInView)) {
        float spacing = 10;
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            spacing = 3;
        }
        
        float moveBy = keyboardSize.height + spacing;
        [UIView animateWithDuration:0.3 animations:^{
            UIView *viewToMove = self.view;
            
            CGRect f = viewToMove.frame;
            f.origin.y = -moveBy;
            viewToMove.frame = f;
        }];
    }
}

-(void) resetToInitialView
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0;
        self.view.frame = f;
    }];
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

- (void) sendAudio: (NSString *) name
{
    // override in subclass
}

- (IBAction) sendPressed: (id) sender
{
    [self textEntered:self.textField.text];
}

- (IBAction) yesPressed: (id) sender
{
    [self sendAudio:@"yes.wav"];
}

- (IBAction) noPressed: (id) sender
{
    [self sendAudio:@"no.wav"];
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
