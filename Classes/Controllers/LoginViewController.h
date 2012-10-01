//
//  LoginViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DGS.h"
#import "JWTableViewController.h"

@interface LoginViewController : JWTableViewController <LoginProtocol> {
	NSString *username;
	NSString *password;
	id __weak delegate;
}

@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, weak) id delegate;

- (void)login;
- (void)notLoggedIn;
- (void)requestCancelled;

@end

