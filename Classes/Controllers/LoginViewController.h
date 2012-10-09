//
//  LoginViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextCell, SpinnerView;

@interface LoginViewController : UITableViewController

@property (weak, nonatomic) IBOutlet TextCell *usernameCell;
@property (weak, nonatomic) IBOutlet TextCell *passwordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *loginCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *signupCell;

@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;

@property(nonatomic, strong) SpinnerView *spinner;

@end

