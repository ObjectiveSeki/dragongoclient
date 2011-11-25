// 
// CurrentGamesController
// 
// Controller driving the list of games which are ready for moves.
// If TEST_GAMES is set, the game list will also contain a bunch
// of SGFs at various points in the game, for testing the game views.
// 

#import "CurrentGamesController.h"
#import "Game.h"
#import "GameViewController.h"
#import "LoginViewController.h"
#import "DGSPhoneAppDelegate.h"
#import "NewGameViewController.h"
#import "DbHelper.h"

#ifdef HOCKEY
#import "BWHockeyManager.h"
#endif

@implementation CurrentGamesController

@synthesize games;
@synthesize refreshButton;
@synthesize gameTableView;
@synthesize logoutButton;
@synthesize selectedCell;
@synthesize logoutConfirmation;
@synthesize bottomToolbar;
@synthesize noGamesView;
@synthesize gameListView;

#pragma mark -
#pragma mark View lifecycle


#ifdef HOCKEY
- (void)openUpdateController {
    BWHockeyViewController *hockeyViewController = [[BWHockeyManager sharedHockeyManager] hockeyViewController:NO];
    [self.navigationController pushViewController:hockeyViewController animated:YES];
}
#endif

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)setEnabled:(BOOL)enabled {
	if (enabled) {
		[[self refreshButton] setEnabled:YES];
		[[self logoutButton] setEnabled:YES];
		[[self gameTableView] setUserInteractionEnabled:YES];
	} else {
		[[self refreshButton] setEnabled:NO];
		[[self logoutButton] setEnabled:NO];
		[[self gameTableView] setUserInteractionEnabled:NO];
	}
}

- (void)buildTableCells {
	NSMutableArray *sections = [NSMutableArray array];
	TableSection *firstSection = [[TableSection alloc] init];
	
	for (Game *game in self.games) {
		TableRow *row = [[TableRow alloc] init];
		row.cellClass = [UITableViewCell class];
		row.cellInit = ^UITableViewCell*() {
			return [[[row.cellClass alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass(row.cellClass)] autorelease];
		};
		row.cellSetup = ^(UITableViewCell *cell) {
			if ([game color] == kMovePlayerBlack) {
				[[cell imageView] setImage:[DGSAppDelegate blackStone]];
			} else {
				[[cell imageView] setImage:[DGSAppDelegate whiteStone]];
			}
			[[cell textLabel] setText: [game opponent]];
			[[cell detailTextLabel] setText:[game time]];
			[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		};
		row.cellTouched = ^(UITableViewCell *cell) {
			self.selectedCell = cell;
			UIActivityIndicatorView *activityView = 
			[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			[activityView startAnimating];
			[cell setAccessoryView:activityView];
			[activityView release];
			if (game.sgfString) {
				[self gotSgfForGame:game];
			} else {
				[self.gs getSgfForGame:game onSuccess:^(Game *game) {
					[self gotSgfForGame:game];
				}];
			}
		};
		[firstSection addRow:row];
		[row release];		
	}
    
	[sections addObject:firstSection];
	[firstSection release];
	
	self.tableSections = sections;
	
}

- (IBAction)refreshGamesWithThrottling {
	if ([DGSAppDelegate refreshThrottled] /*&& [self.games count] != 0*/) {
		// skip automatic refreshing so we don't hurt DGS
	} else {
		[self refreshGames];
	}
}

- (IBAction)startNewGame {
    NewGameViewController *newGameViewController = [[NewGameViewController alloc] initWithNibName:@"NewGameViewController" bundle:nil];
    [self.navigationController pushViewController:newGameViewController animated:YES];
    [newGameViewController release];
}

- (void)loadGamesFromDB {
    sqlite3 *database = [DGSAppDelegate database];
    static sqlite3_stmt *fetchGamesStmt = nil;
    if (fetchGamesStmt == nil) {
        if (sqlite3_prepare_v2(database, "SELECT id, opponent, sgf, ourcolor, timeleft FROM games WHERE ourturn = 1 AND finished = 0", -1, &fetchGamesStmt, NULL) != SQLITE_OK) {
            JWLog("error create fetch games statement '%s'", sqlite3_errmsg(database));
        }
    }

	NSMutableArray *db_games = [NSMutableArray array];

    while (sqlite3_step(fetchGamesStmt) == SQLITE_ROW) {
        // Read the data from the result row
        int gameId = sqlite3_column_int(fetchGamesStmt, 0);
        NSString *opponent = [NSString stringWithUTF8String:(char *)sqlite3_column_text(fetchGamesStmt, 1)];
        NSString *sgf = [NSString stringWithUTF8String:(char *)sqlite3_column_text(fetchGamesStmt, 2)];
        int ourColor = sqlite3_column_int(fetchGamesStmt, 3);
        NSString *timeLeft = [NSString stringWithUTF8String:(char *)sqlite3_column_text(fetchGamesStmt, 4)];
        
        Game *game = [[Game alloc] init];
        [game setGameId:gameId];
        [game setOpponent:opponent];
        [game setColor:(MovePlayer)ourColor];
        [game setTime:timeLeft];
        if (sgf && [sgf length] > 0) {
            [game setSgfString:sgf];
        }
        
        [db_games addObject:game];
        [game release];

    }
    
    sqlite3_reset(fetchGamesStmt);

    self.games = db_games;
    
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count]];
    
    if ([self.games count] == 0) {
        self.view = self.noGamesView;
    } else {
        self.view = self.gameListView;
        [self buildTableCells];
        [[self gameTableView] reloadData];
    }

    // load SGF for unknown games
    [DbHelper loadUnknownSGF:self.gs];
}

- (IBAction)refreshGames {
	[DGSAppDelegate resetThrottle];
	
	[self showSpinnerInView:self.navigationController.view message:@"Reloading..."];
//	[self setEnabled:NO];
	[self.gs getCurrentGames:^(NSArray *currentGames) {
//		self.games = currentGames;
		[self hideSpinner:YES];
        [self loadGamesFromDB];
		
#if TEST_GAMES
		
		NSArray *testGames = [NSArray arrayWithObjects:@"Start Handicap Game", @"Handicap Stones Placed", @"First Score", @"Multiple Scoring Passes", @"Pass Should Be Move 200", @"Game with Message", nil];
		NSMutableArray *mutableCurrentGames = [self.games mutableCopy];
		for (NSString *name in testGames) {
			Game *game = [[Game alloc] init];
			game.opponent = name;
			game.sgfString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sgf"] encoding:NSUTF8StringEncoding error:NULL];
			game.color = kMovePlayerBlack;
			game.time = @"Test";
			[mutableCurrentGames addObject:game];
			[game release];
		}
		self.games = mutableCurrentGames;
		[mutableCurrentGames release];
#endif

//		[self setEnabled:YES];
	}];
}

- (void)requestCancelled {
	[self hideSpinner:NO];
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	[self setEnabled:YES];
}

// Handles dismissing the logout confirmation.
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView == self.logoutConfirmation) {
		if (buttonIndex != alertView.cancelButtonIndex) {
			[self setEnabled:NO];
			[self showSpinner:@"Logging out..."];
			[self.gs logout];
		}
		self.logoutConfirmation = nil;
	}
}

- (IBAction)logout {
	self.logoutConfirmation = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure you want to logout from the Dragon Go Server?" delegate:self cancelButtonTitle:@"Don't logout" otherButtonTitles:@"Logout", nil];
	[self.logoutConfirmation show];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    JWLog("Showing current games view and refreshing games...");
    [self loadGamesFromDB];
	[self refreshGamesWithThrottling];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGamesWithThrottling) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLoad {
	self.title = @"Your Move";
	self.navigationItem.leftBarButtonItem = self.logoutButton;
	self.navigationItem.rightBarButtonItem = self.refreshButton;
	[super viewDidLoad];
    	
#ifdef HOCKEY
	NSMutableArray *toolbarItems = [self.bottomToolbar.items mutableCopy];
    
	UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Update..." style:UIBarButtonItemStyleBordered target:self action:@selector(openUpdateController)];
	[toolbarItems insertObject:updateButton atIndex:0];
	[updateButton release];
	
	[self.bottomToolbar setItems:toolbarItems];
	[toolbarItems release];	
#endif
}


#pragma mark -
#pragma mark Table view delegate



- (void)gotSgfForGame:(Game *)game {
	// Navigation logic may go here. Create and push another view controller.
	GameViewController *gameViewController = [[GameViewController alloc] initWithNibName:@"GameView" bundle:nil];
	// ...
	// Pass the selected object to the new view controller.
	[gameViewController setGame:game];
	[self.navigationController pushViewController:gameViewController animated:YES];
	[gameViewController release];
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	[self setEnabled:YES];
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self setEnabled:NO];
	[super tableView:theTableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.refreshButton = nil;
	self.gameTableView = nil;
	self.logoutButton = nil;
	self.selectedCell = nil;
	self.logoutConfirmation = nil;
	self.bottomToolbar = nil;
    self.noGamesView = nil;
    self.gameListView = nil;
}


- (void)dealloc {
	self.games = nil;
    [super dealloc];
}


@end
