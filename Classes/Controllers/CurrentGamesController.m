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
#import "GameList.h"
#import "LoadingCell.h"

@interface CurrentGamesController ()

@property(nonatomic, strong) GameList *games;
@property(nonatomic, strong) GameList *runningGames;
@property(nonatomic) BOOL loadingNewRunningGamesPage;


// Can be either a OD or UIRefreshControl. Named 'myRefreshControl' to avoid
// conflicting with the built-in iOS6 one.
@property (nonatomic, strong) id myRefreshControl;
@property (nonatomic, strong) SpinnerView *spinner;
@end

typedef enum {
    kGameSectionMyMove,
    kGameSectionRunningGames,
    kGameSectionCount
} GameSection;

@implementation CurrentGamesController

#pragma mark - Pseudo-properties

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
    [[GenericGameServer sharedGameServer] getCurrentGames:^(GameList *currentGames) {
        [[GenericGameServer sharedGameServer] getRunningGames:^(GameList *runningGames) {
            [self setEnabled:YES];
            [self handleGameListChanges:currentGames runningGameListChanges:runningGames];
        } onError:^(NSError *error) {
            [self setEnabled:YES];
        }];
    } onError:^(NSError *error) {
        [self setEnabled:YES];
    }];
}

- (void)forceRefreshGames {
    [self setEnabled:NO];
    [[GenericGameServer sharedGameServer] refreshCurrentGames:^(GameList *currentGames) {
        [[GenericGameServer sharedGameServer] refreshRunningGames:^(GameList *runningGames) {
            [self.myRefreshControl endRefreshing];
            [self setEnabled:YES];
            [self handleGameListChanges:currentGames runningGameListChanges:runningGames];
        } onError:^(NSError *error) {
            [self.myRefreshControl endRefreshing];
            [self setEnabled:YES];
        }];
    } onError:^(NSError *error) {
        [self.myRefreshControl endRefreshing];
        [self setEnabled:YES];
    }];
}

- (void)getMoreRunningGames {
    [[GenericGameServer sharedGameServer] addGamesToGameList:self.runningGames onSuccess:^(GameList *runningGames) {
        [self handleGameListChanges:self.games runningGameListChanges:runningGames];
        self.loadingNewRunningGamesPage = NO;
    } onError:^(NSError *error) {
#warning TODO: maybe allow the new page link to be tapped in this state?
        self.loadingNewRunningGamesPage = NO;
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

- (IBAction)gameListTypeChanged:(id)sender {
    [self.tableView reloadData];
    if ([self.games count] == 0 && [self selectedGameList] == self.games) {
        [self.tableView addSubview:self.noGamesView];
    } else {
        [self.noGamesView removeFromSuperview];
    }
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

- (void)addTestGamesToGameList:(GameList *)gameList {
    NSArray *testGames = @[@"Start Handicap Game", @"Handicap Stones Placed", @"First Score", @"Multiple Scoring Passes", @"Pass Should Be Move 200", @"Game with Message", @"25x25 Handicap Stones"];
    NSMutableOrderedSet *mutableGameList = [[NSMutableOrderedSet alloc] initWithCapacity:[testGames count]];
    for (int i = 0; i < [testGames count]; i++) {
        Game *game = [[Game alloc] init];
        NSString *name = testGames[i];
        game.opponent = name;
        game.sgfString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sgf"] encoding:NSUTF8StringEncoding error:NULL];
        game.color = kMovePlayerBlack;
        game.time = @"Test";
        game.gameId = 10000000000 + i;
        game.moveId = 100;
        game.myTurn = YES;
        
        [mutableGameList addObject:game];
    }
    [gameList addGames:mutableGameList];
}

- (void)handleGameListChanges:(GameList *)gameList
       runningGameListChanges:(GameList *)runningGameList {
#if TEST_GAMES
    [self addTestGamesToGameList:gameList];
#endif
    self.games = gameList;
    self.runningGames = runningGameList;
    [self.tableView reloadData];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count]];
    if ([self.games count] == 0 && [self selectedGameList] == self.games) {
        [self.tableView addSubview:self.noGamesView];
    } else {
        [self.noGamesView removeFromSuperview];
    }
}

#pragma mark - Table view data source

- (GameList *)selectedGameList {
    if (self.gameListTypeControl.selectedSegmentIndex == kGameSectionMyMove) {
        return self.games;
    } else if (self.gameListTypeControl.selectedSegmentIndex == kGameSectionRunningGames) {
        return self.runningGames;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    GameList *selectedGameList = [self selectedGameList];
    NSInteger count = [selectedGameList count];
    if (!selectedGameList || [selectedGameList hasMorePages]) {
        count += 1; // for the activity indicator
    }
    return count;
}

- (Game *)gameForRowAtIndexPath:(NSIndexPath *)indexPath {
    GameList *selectedGameList = [self selectedGameList];
    if (indexPath.row < [selectedGameList.games count]) {
        return [selectedGameList.games objectAtIndex:indexPath.row];
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Game *game = [self gameForRowAtIndexPath:indexPath];
    if (game) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
        
        if ([game color] == kMovePlayerBlack) {
            [cell.imageView setImage:[UIImage imageNamed:@"Black.png"]];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"White.png"]];
        }
        cell.textLabel.text = game.opponent;
        cell.detailTextLabel.text = game.time;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    } else if ([self selectedGameList] == self.runningGames) {
        LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
        [cell.activityIndicator startAnimating];
        if (self.runningGames && !self.loadingNewRunningGamesPage) {
            self.loadingNewRunningGamesPage = YES;
            [self getMoreRunningGames];
        }
        return cell;
    } else {
        assert(@"Trying to show a loading cell for the main game list!");
        return nil;
    }
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
    [self setGameListTypeControl:nil];
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.logoutButton = nil;
}

@end
