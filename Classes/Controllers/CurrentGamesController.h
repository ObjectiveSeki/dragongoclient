//
//  CurrentGamesController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentGamesController : UITableViewController

@property(nonatomic, strong) IBOutlet UIBarButtonItem *logoutButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *addGameButton;
@property(nonatomic, strong) IBOutlet UIView *noGamesView;
@property(nonatomic, strong) NSArray *games;
@property(nonatomic, strong) NSArray *runningGames;

- (IBAction)logout;
- (void)setEnabled:(BOOL)enabled;


@end


