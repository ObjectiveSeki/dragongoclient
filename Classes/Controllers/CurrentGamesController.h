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
#import "JWTableViewController.h"
#import "GameStatusProtocol.h"


@interface CurrentGamesController : JWTableViewController <LoginProtocol, GameStatusProtocol> {
	NSArray *games;
	IBOutlet UIToolbar *bottomToolbar;
	IBOutlet UIBarButtonItem *refreshButton;
	IBOutlet UIBarButtonItem *logoutButton;
	IBOutlet UITableView *gameTableView;
	UITableViewCell *selectedCell;
	UIAlertView *logoutConfirmation;
	NSDate *nextRefreshTime;
    IBOutlet UIView *noGamesView;
    IBOutlet UIView *gameListView;
}

@property(nonatomic, strong) NSArray *games;
@property(nonatomic, strong) IBOutlet UIToolbar *bottomToolbar;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *refreshButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *logoutButton;
@property(nonatomic, strong) IBOutlet UITableView *gameTableView;
@property(nonatomic, strong) UITableViewCell *selectedCell;
@property(nonatomic, strong) UIAlertView *logoutConfirmation;
@property(nonatomic, strong) UIView *noGamesView;
@property(nonatomic, strong) UIView *gameListView;

// Refresh games list unconditionally
- (IBAction)forceRefreshGames;

- (IBAction)refreshGames;
- (IBAction)logout;
- (IBAction)startNewGame;

- (void)gotSgfForGame:(Game *)game;

- (void)playedMoveInGame:(Game *)game;

@end


