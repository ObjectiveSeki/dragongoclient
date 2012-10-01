//
// Holds information necessary for the sub-controllers of the main 
// tabviewcontroller.
//

#import <UIKit/UIKit.h>
#import "SpinnerView.h"
#import "GameServerProtocol.h"
#import "LoginProtocol.h"

@interface RootViewController : UIViewController <LoginProtocol> {
	UIViewController *__weak tabViewController;
	SpinnerView *spinnerView;
	id<GameServerProtocol> gs;
}

@property(nonatomic, weak) UIViewController *tabViewController;
@property(nonatomic, strong) SpinnerView *spinnerView;
@property(nonatomic, strong) id<GameServerProtocol> gs;

- (void)showSpinnerInView:(UIView *)view message:(NSString *)message;
- (void)showSpinner:(NSString *)message;
- (void)hideSpinner:(BOOL)animated;

- (void)notLoggedIn;
- (void)loggedIn;
- (void)requestCancelled;

@end
