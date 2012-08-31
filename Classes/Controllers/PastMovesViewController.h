//
//  PastMovesViewController.h
//  DGSPhone
//
//  Created by Frank Prößdorf on 8/28/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWTableViewController.h"
#import "Game.h"
#import "FuegoBoard.h"
#import "Player.h"

@interface PastMovesViewController : JWTableViewController {
    Game *game;
    Player *player;
    FuegoBoard *board;
    NSArray *moves;
	IBOutlet UITableView *gameTableView;
	UITableViewCell *selectedCell;
    IBOutlet UIView *moveListView;
}

@property(nonatomic, retain) Game *game;
@property(nonatomic, retain) Player *player;
@property(nonatomic, retain) FuegoBoard *board;
@property(nonatomic, retain) NSArray *moves;
@property(nonatomic, retain) IBOutlet UITableView *gameTableView;
@property(nonatomic, retain) UITableViewCell *selectedCell;
@property(nonatomic, retain) UIView *moveListView;

@end