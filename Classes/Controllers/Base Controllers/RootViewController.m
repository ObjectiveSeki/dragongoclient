
#import "RootViewController.h"
#import "LoginViewController.h"

#ifdef CACHING
#import "CachingGameServer.h"
#endif

@implementation RootViewController
@synthesize tabViewController;
@synthesize spinnerView;
@synthesize gs;

- (void)viewDidLoad {
	self.gs = [[[NSClassFromString(SERVER_CLASS) alloc] init] autorelease];
    
#ifdef CACHING
    self.gs = [[CachingGameServer alloc] initWithGameServer:self.gs];
#endif
    
	self.gs.delegate = self;
}

- (void)hideSpinner:(BOOL)animated {
	[self.spinnerView dismiss:animated];
	self.spinnerView = nil;
}

- (void)showSpinner:(NSString *)message {
	[self showSpinnerInView:self.view message:message];
}

- (void)showSpinnerInView:(UIView *)view message:(NSString *)message {
	[self hideSpinner:NO];
	self.spinnerView = [SpinnerView showInView:view];
	self.spinnerView.label.text = message;
}

- (void)viewDidUnload {
	self.gs = nil;
	self.spinnerView = nil;
}

- (void)notLoggedIn {
	LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
	loginViewController.delegate = self;
	[self presentModalViewController:loginViewController animated:YES];
	[loginViewController notLoggedIn];
	[loginViewController release];
}

- (void)loggedIn {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)requestCancelled {
	[self hideSpinner:NO];
}

- (void)dealloc {
    [super dealloc];
}


@end
