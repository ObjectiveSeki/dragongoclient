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
#import <SafariServices/SafariServices.h>

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
    self.usernameCell.onChanged = ^(TextCell *cell) {
        self.username = cell.textField.text;
        [self updateLoginButton];
    };
    self.usernameCell.maxTextLength = 16;

    self.passwordCell.textField.text = self.password;
    self.passwordCell.onChanged = ^(TextCell *cell) {
        self.password = cell.textField.text;
        [self updateLoginButton];
    };
    self.passwordCell.maxTextLength = -1;

    for (UIButton *button in self.informationLinks.arrangedSubviews) {
        button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        button.titleLabel.adjustsFontForContentSizeCategory = YES;
        button.titleLabel.numberOfLines = 0;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    self.spinner = [[SpinnerView alloc] initInView:self.view];
    [self updateLoginButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    UIView *footer = self.tableView.tableFooterView;
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    CGFloat height = [footer systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
                         withHorizontalFittingPriority:UILayoutPriorityRequired
                               verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    if (fabs(CGRectGetHeight(footer.frame) - height) > 0.5) {
        footer.frame = CGRectMake(0, 0, width, height);
        self.tableView.tableFooterView = footer;
    }
}

- (IBAction)showPrivacyPolicy:(id)sender {
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DGSPrivacyPolicyURL"]];
    SFSafariViewController *browser = [[SFSafariViewController alloc] initWithURL:url];
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)updateLoginButton {
    self.loginCell.userInteractionEnabled = self.canLogin;
    self.loginCell.textLabel.textColor = self.canLogin ? self.signupCell.textLabel.textColor : [UIColor secondaryLabelColor];
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

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [theTableView cellForRowAtIndexPath:indexPath];
	if (cell == self.loginCell) {
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
		[self login];
	} else if (cell == self.signupCell) {
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.dragongoserver.net/register.php"]
                                           options:@{}
                                 completionHandler:nil];
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

@end
