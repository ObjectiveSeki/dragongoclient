// 
// CurrentGamesController
// 
// Controller driving the list of games which are ready for moves.
// If TEST_GAMES is set, the game list will also contain a bunch
// of SGFs at various points in the game, for testing the game views.
// 

#import "CurrentGamesController.h"
#import "DGS.h"
#import "Game.h"
#import "GameViewController.h"
#import "LoginViewController.h"
#import "DGSPhoneAppDelegate.h"

#if defined (CONFIGURATION_Adhoc)
#import "BWHockeyController.h"
#endif

@implementation CurrentGamesController

@synthesize spinnerView;

@synthesize games;
@synthesize refreshButton;
@synthesize gameTableView;
@synthesize logoutButton;
@synthesize dgs;
@synthesize selectedCell;
@synthesize logoutConfirmation;
@synthesize bottomToolbar;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	self.title = @"Your Move";
	self.navigationItem.leftBarButtonItem = self.logoutButton;
	self.navigationItem.rightBarButtonItem = self.refreshButton;
	self.dgs = [[[DGS alloc] init] autorelease];
	self.dgs.delegate = self;
	[super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
#if defined(CONFIGURATION_Adhoc)
	NSMutableArray *toolbarItems = [self.bottomToolbar.items mutableCopy];
	
	UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Update..." style:UIBarButtonItemStyleBordered target:self action:@selector(openUpdateController)];
	[toolbarItems insertObject:updateButton atIndex:0];
	[updateButton release];
	
	[self.bottomToolbar setItems:toolbarItems];
	[toolbarItems release];	
#endif
}


#if defined (CONFIGURATION_Adhoc)
- (void)openUpdateController {
	BWHockeyViewController *controller = [[BWHockeyViewController alloc] init:[BWHockeyController sharedHockeyController] modal:NO];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}
#endif

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	JWLog("Showing current games view and refreshing games...");
	[self refreshGamesWithThrottling];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGamesWithThrottling) name:UIApplicationDidBecomeActiveNotification object:nil];
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
		row.cellInit = ^() {
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
				[dgs getSgfForGame:game onSuccess:^(Game *game) {
					[self gotSgfForGame:game];
				}];
			}
		};
		[firstSection addRow:row];
		[row release];		
	}
	
	[sections addObject:firstSection];
	
	self.tableSections = sections;
	
	[firstSection release];	
}

- (IBAction)refreshGamesWithThrottling {
	if ([DGSAppDelegate refreshThrottled]) {
		// skip automatic refreshing so we don't hurt DGS
	} else {
		[self refreshGames];
	}

}

- (IBAction)refreshGames {
	[DGSAppDelegate resetThrottle];
	[self setEnabled:NO];	
	
	[self.spinnerView dismiss:NO];
	self.spinnerView = nil;
	self.spinnerView = [SpinnerView showInView:self.view];
	self.spinnerView.label.text = @"Reloading...";
	[self.dgs getCurrentGames:^(NSArray *currentGames) {
		self.games = currentGames;
		
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
		
		[self.spinnerView dismiss:YES];
		self.spinnerView = nil;
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count]];
		
		[self buildTableCells];
		
		[[self gameTableView] reloadData];
		[self setEnabled:YES];
	}];
}

- (void)notLoggedIn {
	LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
	loginViewController.delegate = self;
	[self.tabViewController presentModalViewController:loginViewController animated:YES];
	[loginViewController notLoggedIn];
	[loginViewController release];
}

- (void)loggedIn {
	[self.tabViewController dismissModalViewControllerAnimated:YES];
}

- (void)requestCancelled {
	[self.spinnerView dismiss:NO];
	self.spinnerView = nil;
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	[self setEnabled:YES];
}

// Handles dismissing the logout confirmation.
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView == self.logoutConfirmation) {
		if (buttonIndex != alertView.cancelButtonIndex) {
			[self setEnabled:NO];
			self.spinnerView = [SpinnerView showInView:self.view];
			self.spinnerView.label.text = @"Logging out...";
			[dgs logout];
		}
		self.logoutConfirmation = nil;
	}
}

- (IBAction)logout {
	self.logoutConfirmation = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure you want to logout from the Dragon Go Server?" delegate:self cancelButtonTitle:@"Don't logout" otherButtonTitles:@"Logout", nil];
	[self.logoutConfirmation show];
}

#pragma mark -
#pragma mark Table view delegate



- (void)gotSgfForGame:(Game *)game {
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	// Navigation logic may go here. Create and push another view controller.
	GameViewController *gameViewController = [[GameViewController alloc] initWithNibName:@"GameView" bundle:nil];
	// ...
	// Pass the selected object to the new view controller.
	[gameViewController setGame:game];
	[self.tabViewController.navigationController pushViewController:gameViewController animated:YES];
	[gameViewController release];
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
	self.spinnerView = nil;
	self.logoutConfirmation = nil;
	self.bottomToolbar = nil;
}


- (void)dealloc {
	self.games = nil;
	self.dgs = nil;
	self.tabViewController = nil;
    [super dealloc];
}


@end
