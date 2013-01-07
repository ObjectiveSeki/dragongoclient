//
// CurrentGamesController
//
// Controller driving the list of games which are ready for moves.
// If TEST_GAMES is set, the game list will also contain a bunch
// of SGFs at various points in the game, for testing the game views.
//

#import "CurrentGamesController.h"
#import "Game.h"
#import "ODRefreshControl.h"
#import "SpinnerView.h"
#import "GameViewController.h"
#import "IBAlertView.h"

@interface CurrentGamesController ()

@property(nonatomic, strong) NSOrderedSet *games;
@property(nonatomic, strong) NSOrderedSet *runningGames;

// Can be either a OD or UIRefreshControl. Named 'myRefreshControl' to avoid
// conflicting with the built-in iOS6 one.
@property (nonatomic, strong) id myRefreshControl;
@property (nonatomic, strong) SpinnerView *spinner;
@end

enum GameSections {
    kGameSectionMyMove,
    kGameSectionRunningGames,
    kGameSectionCount
};

@implementation CurrentGamesController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	if ([UIRefreshControl class]) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.myRefreshControl = self.refreshControl;
    } else {
        ODRefreshControl *refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
        self.myRefreshControl = refreshControl;
    }
    [self.myRefreshControl addTarget:self action:@selector(forceRefreshGames) forControlEvents:UIControlEventValueChanged];
    self.spinner = [[SpinnerView alloc] initInView:self.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.spinner dismiss:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"Showing current games view and refreshing games...");

	[self refreshGames];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGames) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setEnabled:(BOOL)enabled {
    self.logoutButton.enabled = enabled;
    self.addGameButton.enabled = enabled;
    self.tableView.userInteractionEnabled = enabled;
}

#pragma mark - UI Actions

- (void)refreshGames {
    [self setEnabled:NO];
    [[GenericGameServer sharedGameServer] getCurrentGames:^(NSOrderedSet *currentGames) {
        self.games = currentGames;
#if TEST_GAMES
        [self addTestGames];
#endif
        [[GenericGameServer sharedGameServer] getRunningGames:^(NSOrderedSet *runningGames) {
            self.runningGames = runningGames;
            [self gameListChanged];
            [self.myRefreshControl endRefreshing];
            [self setEnabled:YES];
        } onError:^(NSError *error) {
            [self.myRefreshControl endRefreshing];
            [self setEnabled:YES];
        }];
    } onError:^(NSError *error) {
        [self.myRefreshControl endRefreshing];
        [self setEnabled:YES];
    }];
}

- (void)forceRefreshGames {
    [self setEnabled:NO];
    [[GenericGameServer sharedGameServer] refreshCurrentGames:^(NSOrderedSet *currentGames) {
        self.games = currentGames;
#if TEST_GAMES
        [self addTestGames];
#endif
        [[GenericGameServer sharedGameServer] refreshRunningGames:^(NSOrderedSet *runningGames) {
            self.runningGames = runningGames;
            [self gameListChanged];
            [self.myRefreshControl endRefreshing];
            [self setEnabled:YES];
        } onError:^(NSError *error) {
            [self.myRefreshControl endRefreshing];
            [self setEnabled:YES];
        }];
    } onError:^(NSError *error) {
        [self.myRefreshControl endRefreshing];
        [self setEnabled:YES];
    }];
}

- (IBAction)logout {
    [IBAlertView showAlertWithTitle:@"Logout?" message:@"Are you sure you want to logout from the Dragon Go Server?" dismissTitle:@"Don't logout" okTitle:@"Logout" dismissBlock:^{
        // do nothing
    } okBlock:^{
        [self setEnabled:NO];
        self.spinner.label.text = @"Logging out…";
        [self.spinner show];
        [[GenericGameServer sharedGameServer] logout:^(NSError *error) {
            [self setEnabled:YES];
            [self.spinner dismiss:YES];
        }];
    }];
}

#pragma mark - Helper Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowGame"]) {
        GameViewController *controller = segue.destinationViewController;
        Game *game = (Game *)sender;
        controller.game = game;
        controller.readOnly = !game.myTurn;
    }
}

#pragma mark - Game list management

- (void)addTestGames {
    NSArray *testGames = @[@"Start Handicap Game", @"Handicap Stones Placed", @"First Score", @"Multiple Scoring Passes", @"Pass Should Be Move 200", @"Game with Message", @"25x25 Handicap Stones"];
    NSMutableOrderedSet *mutableCurrentGames = [self.games mutableCopy];
    for (int i = 0; i < [testGames count]; i++) {
        Game *game = [[Game alloc] init];
        NSString *name = testGames[i];
        game.opponent = name;
        game.sgfString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sgf"] encoding:NSUTF8StringEncoding error:NULL];
        game.color = kMovePlayerBlack;
        game.time = @"Test";
        game.gameId = 10000000000 + i;
        game.moveId = 100;
        
        [mutableCurrentGames addObject:game];
    }
    self.games = mutableCurrentGames;
}

- (void)gameListChanged {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count]];
    if ([self.games count] == 0 && [self.runningGames count] == 0) {
        [self.tableView addSubview:self.noGamesView];
    } else {
        [self.noGamesView removeFromSuperview];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kGameSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kGameSectionMyMove) {
        return [self.games count];
    } else if (section == kGameSectionRunningGames) {
        return [self.runningGames count];
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kGameSectionMyMove) {
        return @"Your Move";
    } else if (section == kGameSectionRunningGames) {
        return @"Waiting for Move";
    } else {
        return @"";
    }
}

- (Game *)gameForRowAtIndexPath:(NSIndexPath *)indexPath {
    Game *game = nil;
    
    if (indexPath.section == kGameSectionMyMove) {
        game = self.games[indexPath.row];
    } else if (indexPath.section == kGameSectionRunningGames) {
        game = self.runningGames[indexPath.row];
    }
    return game;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
    
    Game *game = [self gameForRowAtIndexPath:indexPath];
    
    if ([game color] == kMovePlayerBlack) {
        [cell.imageView setImage:[UIImage imageNamed:@"Black.png"]];
    } else {
        [cell.imageView setImage:[UIImage imageNamed:@"White.png"]];
    }
    cell.textLabel.text = game.opponent;
    cell.detailTextLabel.text = game.time;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [theTableView cellForRowAtIndexPath:indexPath];
    [self setEnabled:NO];
    
    UIActivityIndicatorView *activityView =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    [cell setAccessoryView:activityView];
    
    Game *game = [self gameForRowAtIndexPath:indexPath];
    [[GenericGameServer sharedGameServer] getSgfForGame:game onSuccess:^(Game *game) {
        [cell setAccessoryView:nil];
        [self setEnabled:YES];
        [self performSegueWithIdentifier:@"ShowGame" sender:game];
    } onError:^(NSError *error) {
        [cell setAccessoryView:nil];
        [self setEnabled:YES];
    }];
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
	self.logoutButton = nil;
}

@end
