//
//  LoginViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "LoginViewController.h"
#import "TextCell.h"
#import "SpinnerView.h"

@implementation LoginViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    self.usernameCell.textField.text = self.username;
    self.usernameCell.textEditedSelector = @selector(setUsernameFromCell:);
    self.usernameCell.maxTextLength = 16;

    self.passwordCell.textField.text = self.password;
    self.passwordCell.textEditedSelector = @selector(setPasswordFromCell:);
    self.passwordCell.maxTextLength = -1;
    
    self.spinner = [[SpinnerView alloc] initInView:self.view];
    [self updateLoginButton];
}

- (void)updateLoginButton {
    self.loginCell.userInteractionEnabled = self.canLogin;
    self.loginCell.textLabel.textColor = self.canLogin ? self.signupCell.textLabel.textColor : [UIColor grayColor];
}

- (BOOL)canLogin {
    return self.username.length > 0 && self.password.length > 0;
}

- (void)login
{
	[self.view resignFirstResponder];
    self.spinner.label.text = @"Logging in…";
    [self.spinner show];

	[[GenericGameServer sharedGameServer] loginWithUsername:self.username password:self.password onSuccess:^{
        [self.spinner dismiss:YES];
    } onError:^(NSError *error) {
        [self.spinner dismiss:YES];
    }];
}

- (void)setUsernameFromCell:(TextCell *)tableCell {
	self.username = tableCell.textField.text;
    [self updateLoginButton];
}

- (void)setPasswordFromCell:(TextCell *)tableCell {
	self.password = tableCell.textField.text;
    [self updateLoginButton];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [theTableView cellForRowAtIndexPath:indexPath];
	if (cell == self.loginCell) {
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
		[self login];
	} else if (cell == self.signupCell) {
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.dragongoserver.net/register.php"]];
	}
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
    [self setUsernameCell:nil];
    [self setPasswordCell:nil];
    [self setLoginCell:nil];
    [self setSignupCell:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end

