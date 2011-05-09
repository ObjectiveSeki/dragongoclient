
#import "RootViewController.h"

@implementation RootViewController
@synthesize tabViewController;
@synthesize spinnerView;
@synthesize gs;

- (void)viewDidLoad {
	self.gs = [[[NSClassFromString(SERVER_CLASS) alloc] init] autorelease];
	self.gs.delegate = self;
}

- (void)hideSpinner:(BOOL)animated {
	[self.spinnerView dismiss:animated];
	self.spinnerView = nil;
}

- (void)showSpinner:(NSString *)message {
	[self hideSpinner:NO];
	self.spinnerView = [SpinnerView showInView:self.navigationController.view];
	self.spinnerView.label.text = message;
}

- (void)viewDidUnload {
	self.gs = nil;
	self.spinnerView = nil;
}

- (void)dealloc {
    [super dealloc];
}


@end
