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
#import "Player.h"

@interface AddGameViewController : JWTableViewController <LoginProtocol> {
	TextCell *descriptionCell;
	NewGame *game;
    NSArray *_ratingStrings;
}

@property(nonatomic, strong) TextCell *descriptionCell;
@property(nonatomic, strong) NewGame *game;
@property(nonatomic, strong) Player *player;

- (IBAction)addGame;

@end

