// 
// CurrentGamesController
// 
// Controller driving the list of games which are ready for moves.
// If TEST_GAMES is defined, the game list will also contain a bunch
// of SGFs at various points in the game, for testing the game views.
// 

#import "CurrentGamesController.h"
#import "DGS.h"
#import "Game.h"
#import "GameViewController.h"
#import "LoginViewController.h"
#import "DGSPhoneAppDelegate.h"
#import "AddGameViewController.h"

@implementation CurrentGamesController

@synthesize spinnerView;

@synthesize games;
@synthesize refreshButton;
@synthesize gameTableView;
@synthesize logoutButton;
@synthesize dgs;
@synthesize selectedCell;
@synthesize logoutConfirmation;


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
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self refreshGames];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
		[[self refreshButton] setEnabled:YES];
		[[self logoutButton] setEnabled:YES];
		[[self gameTableView] setUserInteractionEnabled:YES];
	} else {
		[[self refreshButton] setEnabled:NO];
		[[self logoutButton] setEnabled:NO];
		[[self gameTableView] setUserInteractionEnabled:NO];
	}
}

- (IBAction)refreshGames {
	[self setEnabled:NO];	
	
	[self.spinnerView dismiss:NO];
	self.spinnerView = nil;
	self.spinnerView = [SpinnerView showInView:self.view];
	self.spinnerView.label.text = @"Reloading...";
	[dgs getCurrentGames];
}

- (void)gotCurrentGames:(NSArray *)currentGames {
	self.games = currentGames;
	
#ifdef TEST_GAMES
	
	NSArray *testGames = [NSArray arrayWithObjects:@"Start Handicap Game", @"Handicap Stones Placed", @"First Score", @"Multiple Scoring Passes", @"Pass Should Be Move 200",  nil];
	NSMutableArray *mutableCurrentGames = [self.games mutableCopy];
	for (NSString *name in testGames) {
		Game *game = [[Game alloc] init];
		game.opponent = name;
		game.sgfString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sgf"]];
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
	[[self gameTableView] reloadData];
	[self setEnabled:YES];
}

- (void)notLoggedIn {
	LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
	loginViewController.delegate = self;
	[self presentModalViewController:loginViewController animated:YES];
	[loginViewController notLoggedIn];
	[loginViewController release];
}

- (void)loggedIn {
	[self dismissModalViewControllerAnimated:YES];
	[self refreshGames];
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

- (IBAction)addGame {
	AddGameViewController *addGameController = [[AddGameViewController alloc] initWithNibName:@"AddGameView" bundle:nil];
	[[self navigationController] pushViewController:addGameController animated:YES];
	[addGameController release];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.games) {
		return [self.games count];
	}
	else {
		return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	Game *game = [games objectAtIndex:[indexPath row]];
	if ([game color] == kMovePlayerBlack) {
		[[cell imageView] setImage:[(DGSPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] blackStone]];
	} else {
		[[cell imageView] setImage:[(DGSPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] whiteStone]];
	}
    [[cell textLabel] setText: [game opponent]];
	[[cell detailTextLabel] setText:[game time]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self setEnabled:NO];
#ifdef TEST_GAMES
	Game *game = [self.games objectAtIndex:[indexPath row]];
	if (game.gameId == 0) {
		[self gotSgfForGame:game];
	} else {
#endif
	
	[dgs getSgfForGame:[self.games objectAtIndex:[indexPath row]]];
	
	self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
	UIActivityIndicatorView *activityView = 
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[activityView startAnimating];
	[self.selectedCell setAccessoryView:activityView];
	[activityView release];
#ifdef TEST_GAMES
	}
#endif
}

- (void)gotSgfForGame:(Game *)game {
	[self.selectedCell setAccessoryView:nil];
	self.selectedCell = nil;
	// Navigation logic may go here. Create and push another view controller.
	GameViewController *gameViewController = [[GameViewController alloc] initWithNibName:@"GameView" bundle:nil];
	// ...
	// Pass the selected object to the new view controller.
	[gameViewController setGame:game];
	[self.navigationController pushViewController:gameViewController animated:YES];
	[gameViewController release];
	[self setEnabled:YES];
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
	self.games = nil;
	self.refreshButton = nil;
	self.gameTableView = nil;
	self.logoutButton = nil;
	self.dgs = nil;
	self.selectedCell = nil;
	self.spinnerView = nil;
	self.logoutConfirmation = nil;
}


- (void)dealloc {

    [super dealloc];
}


@end
