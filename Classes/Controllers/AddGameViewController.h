//
//  AddGameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextCell.h"
#import "NewGame.h"
#import "LoginProtocol.h"
#import "DGS.h"
#import "SpinnerView.h"

@interface AddGameViewController : UITableViewController <LoginProtocol> {
	TextCell *descriptionCell;
	NewGame *newGame;
	DGS *dgs;
	SpinnerView *spinnerView;
}

@property (nonatomic, retain) SpinnerView *spinnerView;

@property(nonatomic, retain) TextCell *descriptionCell;
@property(nonatomic, retain) NewGame *newGame;
@property(nonatomic, retain) DGS *dgs;

- (void)notLoggedIn;
- (void)loggedIn;
- (void)requestCancelled;
- (void)addedGame;

- (IBAction)addGame;

@end

