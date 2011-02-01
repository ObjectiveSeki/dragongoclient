
#import "RootViewController.h"
#import "DGS.h"


@implementation RootViewController
@synthesize tabViewController;
@synthesize spinnerView;
@synthesize gs;

- (void)viewDidLoad {
	self.gs = [[[DGS alloc] init] autorelease];
	self.gs.delegate = self;
}

- (void)hideSpinner:(BOOL)animated {
	[self.spinnerView dismiss:animated];
	self.spinnerView = nil;
}

- (void)showSpinner:(NSString *)message {
	[self hideSpinner:NO];
	self.spinnerView = [SpinnerView showInView:self.view];
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
