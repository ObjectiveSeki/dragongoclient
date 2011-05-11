//
// Holds information necessary for the sub-controllers of the main 
// tabviewcontroller.
//

#import <UIKit/UIKit.h>
#import "SpinnerView.h"
#import "GameServerProtocol.h"
#import "LoginProtocol.h"

@interface RootViewController : UIViewController <LoginProtocol> {
	UIViewController *tabViewController;
	SpinnerView *spinnerView;
	id<GameServerProtocol> gs;
}

@property(nonatomic, assign) UIViewController *tabViewController;
@property(nonatomic, retain) SpinnerView *spinnerView;
@property(nonatomic, retain) id<GameServerProtocol> gs;

- (void)showSpinner:(NSString *)message;
- (void)hideSpinner:(BOOL)animated;

- (void)notLoggedIn;
- (void)loggedIn;
- (void)requestCancelled;

@end
