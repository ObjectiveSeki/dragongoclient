//
//  LoginViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "LoginViewController.h"
#import "CurrentGamesController.h"
#import "DGSPhoneAppDelegate.h"
#import "DGS.h"

@implementation LoginViewController

@synthesize loggingInStatusView;
@synthesize loginFieldsView;
@synthesize usernameField;
@synthesize passwordField;
@synthesize delegate;
@synthesize dgs;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)loggedIn {
	[[self delegate] loggedIn];
}

- (void)notLoggedIn {
	[[self loggingInStatusView] setHidden:YES];
	[[self loginFieldsView] setHidden:NO];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (IBAction)loginWithUsernameAndPassword:(id)sender
{
	[[self usernameField] resignFirstResponder];
	[[self passwordField] resignFirstResponder];
	[dgs loginWithUsername:[usernameField text] password:[passwordField text]];
	[[self loggingInStatusView] setHidden:NO];
	[[self loginFieldsView] setHidden:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == usernameField) {
		[[self passwordField] becomeFirstResponder];
	} else if (textField == passwordField) {
		[self loginWithUsernameAndPassword:passwordField];
	}
	return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.dgs = [[[DGS alloc] init] autorelease];
	self.dgs.delegate = self;
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.loggingInStatusView = nil;
	self.loginFieldsView = nil;
	self.usernameField = nil;
	self.passwordField = nil;
	self.dgs = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
