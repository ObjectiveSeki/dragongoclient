//
//  LoginViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoginViewController : UIViewController {
    IBOutlet UIView *loggingInStatusView;
	IBOutlet UIView *loginFieldsView;
	IBOutlet UITextField *usernameField;
	IBOutlet UITextField *passwordField;
}

@property(nonatomic, retain) IBOutlet UIView *loggingInStatusView;
@property(nonatomic, retain) IBOutlet UIView *loginFieldsView;
@property(nonatomic, retain) IBOutlet UITextField *usernameField;
@property(nonatomic, retain) IBOutlet UITextField *passwordField;

- (void)login;
- (IBAction)loginWithUsernameAndPassword:(id)sender;

@end
