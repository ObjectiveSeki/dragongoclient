//
//  CurrentGamesController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginProtocol.h"
#import "DGS.h"
#import "SpinnerView.h"
#import "JWTableViewController.h"


@interface CurrentGamesController : JWTableViewController <LoginProtocol> {
	NSArray *games;
	DGS *dgs;
	IBOutlet UIToolbar *bottomToolbar;
	IBOutlet UIBarButtonItem *refreshButton;
	IBOutlet UIBarButtonItem *logoutButton;
	IBOutlet UITableView *gameTableView;
	UITableViewCell *selectedCell;
	SpinnerView *spinnerView;
	UIAlertView *logoutConfirmation;
}

@property (nonatomic, retain) SpinnerView *spinnerView;

@property(nonatomic, retain) NSArray *games;
@property(nonatomic, retain) IBOutlet UIToolbar *bottomToolbar;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *logoutButton;
@property(nonatomic, retain) IBOutlet UITableView *gameTableView;
@property(nonatomic, retain) DGS *dgs;
@property(nonatomic, retain) UITableViewCell *selectedCell;
@property(nonatomic, retain) UIAlertView *logoutConfirmation;


- (IBAction)refreshGames;
- (IBAction)logout;
- (IBAction)addGame;

- (void)notLoggedIn;
- (void)requestCancelled;

@end


