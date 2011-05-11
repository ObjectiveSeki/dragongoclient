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
#import "JWTableViewController.h"

@interface AddGameViewController : JWTableViewController <LoginProtocol> {
	TextCell *descriptionCell;
	NewGame *newGame;
}

@property(nonatomic, retain) TextCell *descriptionCell;
@property(nonatomic, retain) NewGame *newGame;

- (IBAction)addGame;

@end

