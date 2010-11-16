//
// The modal view used to display and reply to messages
// on the game view screen.
//

#import <UIKit/UIKit.h>


@interface MessageView : UIView {
	IBOutlet UITextView *messageTextView;
	IBOutlet UITextField *messageField;
	IBOutlet UIView *messageDisplayView;
	IBOutlet UIView *messageInputView;
	NSString *message;
	NSString *reply;
}

@property(nonatomic, retain) IBOutlet UITextView *messageTextView;
@property(nonatomic, retain) IBOutlet UITextField *messageField;
@property(nonatomic, retain) IBOutlet UIView *messageDisplayView;
@property(nonatomic, retain) IBOutlet UIView *messageInputView;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, copy) NSString *reply;

- (void)show;
- (void)hide;

- (BOOL)hasMessage;

@end
