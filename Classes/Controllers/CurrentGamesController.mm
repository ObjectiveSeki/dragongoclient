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
#import "ODRefreshControl.h"

@interface CurrentGamesController ()
@property (nonatomic, strong) id refreshControl; // Can be either a OD or UIRefreshControl
@end

@implementation CurrentGamesController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Your Move";
	self.navigationItem.leftBarButtonItem = self.logoutButton;
    self.navigationItem.rightBarButtonItem = self.addGameButton;
	if ([UIRefreshControl class]) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [self.gameTableView addSubview:refreshControl];
        self.refreshControl = refreshControl;
    } else {
        ODRefreshControl *refreshControl = [[ODRefreshControl alloc] initInScrollView:self.gameTableView];
        self.refreshControl = refreshControl;
    }
    
    [self.refreshControl addTarget:self action:@selector(forceRefreshGames) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hideSpinner:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    JWLog("Showing current games view and refreshing games...");
	[self refreshGames];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGames) name:UIApplicationDidBecomeActiveNotification object:nil];
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
		[[self logoutButton] setEnabled:YES];
		[[self gameTableView] setUserInteractionEnabled:YES];
	} else {
		[[self logoutButton] setEnabled:NO];
		[[self gameTableView] setUserInteractionEnabled:NO];
	}
}

#pragma mark - Actions

- (IBAction)startNewGame {
    NewGameViewController *newGameViewController = [[NewGameViewController alloc] initWithNibName:@"NewGameViewController" bundle:nil];
    [self.navigationController pushViewController:newGameViewController animated:YES];
}

- (IBAction)forceRefreshGames {
    [self.refreshControl beginRefreshing];
    [self setEnabled:NO];
    [self.gs refreshCurrentGames:^(NSArray *currentGames) {
        self.games = currentGames;
#if TEST_GAMES
        [self addTestGames];
#endif
        [self.refreshControl endRefreshing];
        [self gameListChanged];
        [self setEnabled:YES];
    }];
}

- (IBAction)refreshGames {
    [self.refreshControl beginRefreshing];
	[self setEnabled:NO];
	[self.gs getCurrentGames:^(NSArray *currentGames) {
		self.games = currentGames;
#if TEST_GAMES
        [self addTestGames];
#endif
        [self.refreshControl endRefreshing];
        [self gameListChanged];
		[self setEnabled:YES];
	}];
}



- (IBAction)logout {
	self.logoutConfirmation = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure you want to logout from the Dragon Go Server?" delegate:self cancelButtonTitle:@"Don't logout" otherButtonTitles:@"Logout", nil];
	[self.logoutConfirmation show];
}

#pragma mark - Helper Actions

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

- (void)buildTableCells {
	NSMutableArray *sections = [NSMutableArray array];
	TableSection *firstSection = [[TableSection alloc] init];

	for (Game *game in self.games) {
		TableRow *row = [[TableRow alloc] init];
		row.cellClass = [UITableViewCell class];
		row.cellInit = ^UITableViewCell*() {
			return [[row.cellClass alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass(row.cellClass)];
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

			[self.gs getSgfForGame:game onSuccess:^(Game *game) {
				[self gotSgfForGame:game];
			}];
		};
		[firstSection addRow:row];
	}

	[sections addObject:firstSection];

	self.tableSections = sections;

}

- (void)addTestGames {
    NSArray *testGames = [NSArray arrayWithObjects:@"Start Handicap Game", @"Handicap Stones Placed", @"First Score", @"Multiple Scoring Passes", @"Pass Should Be Move 200", @"Game with Message", @"25x25 Handicap Stones", nil];
    NSMutableArray *mutableCurrentGames = [self.games mutableCopy];
    for (NSString *name in testGames) {
        Game *game = [[Game alloc] init];
        game.opponent = name;
        game.sgfString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sgf"] encoding:NSUTF8StringEncoding error:NULL];
        game.color = kMovePlayerBlack;
        game.time = @"Test";
        [mutableCurrentGames addObject:game];
    }
    self.games = mutableCurrentGames;
}

- (void)gameListChanged {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count]];

    if ([self.games count] == 0) {
        self.view = self.noGamesView;
    } else {
        self.view = self.gameListView;
        [self buildTableCells];
        [self.gameTableView reloadData];
    }
}

- (void)requestCancelled {
	[self hideSpinner:NO];
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	[self setEnabled:YES];
}

- (void)gotSgfForGame:(Game *)game {
	// Navigation logic may go here. Create and push another view controller.
	GameViewController *gameViewController = [[GameViewController alloc] initWithNibName:@"GameView" bundle:nil];
	// ...
	// Pass the selected object to the new view controller.
	[gameViewController setGame:game];
	[self.navigationController pushViewController:gameViewController animated:YES];
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	[self setEnabled:YES];
}

#pragma mark -
#pragma mark Table view delegate

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
	self.gameTableView = nil;
	self.logoutButton = nil;
	self.selectedCell = nil;
	self.logoutConfirmation = nil;
    self.noGamesView = nil;
    self.gameListView = nil;
}

@end
