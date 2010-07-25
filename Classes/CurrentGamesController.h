//
//  CurrentGamesController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginProtocol.h"
#import "DGS.h"
#import "SpinnerView.h"


@interface CurrentGamesController : UIViewController <LoginProtocol> {
	NSArray *games;
	DGS *dgs;
	IBOutlet UIBarButtonItem *refreshButton;
	IBOutlet UIBarButtonItem *logoutButton;
	IBOutlet UITableView *gameTableView;
	UITableViewCell *selectedCell;
	SpinnerView *spinnerView;
}

@property (nonatomic, retain) SpinnerView *spinnerView;

@property(nonatomic, retain) NSArray *games;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *logoutButton;
@property(nonatomic, retain) IBOutlet UITableView *gameTableView;
@property(nonatomic, retain) DGS *dgs;
@property(nonatomic, retain) UITableViewCell *selectedCell;
- (IBAction)refreshGames;
- (IBAction)logout;
- (IBAction)addGame;
- (void)notLoggedIn;
- (void)requestCancelled;

@end


