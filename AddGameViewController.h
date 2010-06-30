//
//  AddGameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextCell.h"
#import "NewGame.h"
#import "LoginProtocol.h"
#import "DGS.h"

@interface AddGameViewController : UITableViewController <LoginProtocol> {
	TextCell *descriptionCell;
	NewGame *newGame;
	DGS *dgs;
}

@property(nonatomic, retain) TextCell *descriptionCell;
@property(nonatomic, retain) NewGame *newGame;
@property(nonatomic, retain) DGS *dgs;

- (void)notLoggedIn;
- (void)loggedIn;
- (void)addedGame;

- (IBAction)addGame;

@end
