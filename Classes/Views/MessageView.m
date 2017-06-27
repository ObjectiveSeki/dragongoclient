//
//  Implementation for the message view
//

#import "MessageView.h"


@implementation MessageView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        self.showInputView = YES;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.showInputView = YES;
}

- (void)keyboardWillBeShown:(NSNotification *)aNotification {
	CGSize kbSize = [[aNotification userInfo][UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[aNotification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[aNotification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    // see the discussion here: http://stackoverflow.com/questions/7327249/ios-how-to-convert-uiviewanimationcurve-to-uiviewanimationoptions#7327374
    UIViewAnimationOptions options = curve << 16;

	[UIView animateWithDuration:duration delay:0 options:options animations:^(void) {
        self.messageInputView.frame = CGRectOffset(self.messageInputView.frame, 0, -kbSize.height);
	} completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    CGSize kbSize = [[aNotification userInfo][UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[aNotification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[aNotification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    // see the discussion here: http://stackoverflow.com/questions/7327249/ios-how-to-convert-uiviewanimationcurve-to-uiviewanimationoptions#7327374
    UIViewAnimationOptions options = curve << 16;

	[UIView animateWithDuration:duration delay:0 options:options animations:^(void) {
        self.messageInputView.frame = CGRectOffset(self.messageInputView.frame, 0, kbSize.height);
	} completion:nil];
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeShown:)
												 name:UIKeyboardWillShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
	
}

// Call this method somewhere in your view controller setup code.
- (void)removeKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillHideNotification object:nil];
	
}

- (BOOL)hasMessageOrReply {
	return (self.message.length > 0 || self.reply.length > 0);
}

- (void)show:(void (^)(void))onHide {
    self.frame = self.superview.frame;
    
    if (self.showInputView) {
        self.messageInputView.hidden = NO;
        [self registerForKeyboardNotifications];
        [self.messageField becomeFirstResponder];
    } else {
        self.messageInputView.hidden = YES;
    }
    
	self.onHide = onHide;
	if (self.message) {
		self.messageTextView.text = self.message;
	} else {
		self.messageDisplayView.hidden = YES;
	}
	
	[UIView animateWithDuration:0.3 animations:^(void) {
		self.alpha = 1.0;
	}];
}

- (IBAction)hide {
	self.reply = self.messageField.text;
	self.onHide();
	[self.messageField resignFirstResponder];
	[self removeKeyboardNotifications];
	
	[UIView animateWithDuration:0.3 animations:^(void) {
		self.alpha = 0.0;
	} completion:^(BOOL completion) {
		[self removeFromSuperview];
	}];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self hide];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


@end
