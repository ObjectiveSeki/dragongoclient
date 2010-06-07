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

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)login 
{
	if ([DGS loggedIn]) {
		CurrentGamesController *gamesController = [[CurrentGamesController alloc] initWithNibName:@"CurrentGamesView" bundle:nil];

		DGSPhoneAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gamesController];
		[delegate replaceViewController:navigationController];
		[navigationController release];
		[gamesController release];
	} else {
		[[self loggingInStatusView] setHidden:YES];
		[[self loginFieldsView] setHidden:NO];
	}
}

- (IBAction)loginWithUsernameAndPassword:(id)sender
{
	[DGS loginWithUsername:[usernameField text] password:[passwordField text]];
	[self login];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

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
}


- (void)dealloc {
    [super dealloc];
}


@end
