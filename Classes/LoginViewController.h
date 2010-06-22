//
//  LoginViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DGS.h"


@interface LoginViewController : UIViewController {
    IBOutlet UIView *loggingInStatusView;
	IBOutlet UIView *loginFieldsView;
	IBOutlet UITextField *usernameField;
	IBOutlet UITextField *passwordField;
	DGS *dgs;
	id delegate;
}

@property(nonatomic, retain) IBOutlet UIView *loggingInStatusView;
@property(nonatomic, retain) IBOutlet UIView *loginFieldsView;
@property(nonatomic, retain) IBOutlet UITextField *usernameField;
@property(nonatomic, retain) IBOutlet UITextField *passwordField;
@property(nonatomic, retain) DGS *dgs;
@property(nonatomic, assign) id delegate;

- (void)login;
- (IBAction)loginWithUsernameAndPassword:(id)sender;

@end
