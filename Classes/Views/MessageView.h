//
// The modal view used to display and reply to messages
// on the game view screen.
//

#import <UIKit/UIKit.h>


@interface MessageView : UIView {
}

@property(nonatomic, strong) IBOutlet UITextView *messageTextView;
@property(nonatomic, strong) IBOutlet UITextField *messageField;
@property(nonatomic, strong) IBOutlet UIView *messageDisplayView;
@property(nonatomic, strong) IBOutlet UIView *messageInputView;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, copy) NSString *reply;
@property(nonatomic, copy) void (^onHide)(BOOL hasMessage);
@property(nonatomic) BOOL showInputView;

- (void)show:(void (^)(BOOL hasMessage))onHide;
- (IBAction)hide;

@end
