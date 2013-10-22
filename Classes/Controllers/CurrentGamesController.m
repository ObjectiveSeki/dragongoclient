//
// CurrentGamesController
//
// Controller driving the list of games which are ready for moves.
// If TEST_GAMES is set, the game list will also contain a bunch
// of SGFs at various points in the game, for testing the game views.
//

#import "DGSPhoneAppDelegate.h"
#import "CurrentGamesController.h"
#import "ODRefreshControl.h"
#import "SpinnerView.h"
#import "GameViewController.h"
#import "InviteViewController.h"
#import "IBAlertView.h"
#import "LoadingCell.h"
#import "DGSPushServer.h"
#import "Invite.h"

#define kSectionGames       0
#define kSectionInvites     1

@interface CurrentGamesController ()

@property(nonatomic, copy) GameList *games;
@property(nonatomic, copy) GameList *runningGames;
@property(nonatomic) BOOL loadingNewRunningGamesPage;


// Can be either a OD or UIRefreshControl. Named 'myRefreshControl' to avoid
// conflicting with the built-in iOS6 one.
@property (nonatomic, strong) id myRefreshControl;
@property (nonatomic, strong) SpinnerView *spinner;

// Keep track of the refresh operation, so we can make sure only one is running at a time
// (so we don't slam DGS)
@property (nonatomic, strong) NSOperation *refreshOperation;

@end

typedef NS_ENUM(NSUInteger, GameSection) {
    kGameSectionMyMove,
    kGameSectionRunningGames,
    kGameSectionCount
};

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceRefreshGames) name:ReceivedNewGamesNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGames) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearGameList) name:PlayerDidLogoutNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.refreshOperation cancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setEnabled:(BOOL)enabled {
    self.logoutButton.enabled = enabled;
    self.addGameButton.enabled = enabled;
    self.tableView.userInteractionEnabled = enabled;
}

#pragma mark - UI Actions

- (void)didRefreshWithGames:(GameList *)currentGames runningGames:(GameList *)runningGames error:(NSError *)error {
    [self setEnabled:YES];
    [self.myRefreshControl endRefreshing];
    
    if (!error) {
        [self handleGameListChanges:currentGames runningGameListChanges:runningGames];
    }
}

- (void)refreshGames {
    // Block refreshes if we're already in the process of refreshing
    if (self.refreshOperation && !self.refreshOperation.isFinished) {
        return;
    }
    
    [self setEnabled:NO];
    self.refreshOperation = [[GenericGameServer sharedGameServer] getCurrentGames:^(GameList *currentGames) {
        [[GenericGameServer sharedGameServer] getRunningGames:^(GameList *runningGames) {
            [self didRefreshWithGames:currentGames
                         runningGames:runningGames
                                error:nil];
        } onError:^(NSError *error) {
            [self didRefreshWithGames:nil
                         runningGames:nil
                                error:error];
        }];
    } onError:^(NSError *error) {
        [self didRefreshWithGames:nil
                     runningGames:nil
                            error:error];
    }];
}

- (void)forceRefreshGames {
    [self setEnabled:NO];
    self.refreshOperation = [[GenericGameServer sharedGameServer] refreshCurrentGames:^(GameList *currentGames) {
        [[GenericGameServer sharedGameServer] refreshRunningGames:^(GameList *runningGames) {
            [self didRefreshWithGames:currentGames
                         runningGames:runningGames
                                error:nil];
        } onError:^(NSError *error) {
            [self didRefreshWithGames:nil
                         runningGames:nil
                                error:error];
        }];
    } onError:^(NSError *error) {
        [self didRefreshWithGames:nil
                     runningGames:nil
                            error:error];
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
    } else if ([segue.identifier isEqualToString:@"ShowInvite"]) {
        InviteViewController *controller = segue.destinationViewController;
        Invite *invite = (Invite *)sender;
        controller.invite = invite;
    }
}

#pragma mark - Game list management

- (void)clearGameList {
    [self handleGameListChanges:nil runningGameListChanges:nil];
}

- (GameList *)gameListByAppendingTestGamesTo:(GameList *)gameList {
    NSArray *testGames = @[@"Start Handicap Game", @"Handicap Stones Placed", @"First Score", @"Multiple Scoring Passes", @"Pass Should Be Move 200", @"Game with Message", @"25x25 Handicap Stones"];
    NSMutableOrderedSet *mutableGames = [[NSMutableOrderedSet alloc] initWithCapacity:[testGames count]];
    for (int i = 0; i < [testGames count]; i++) {
        Game *game = [[Game alloc] init];
        NSString *name = testGames[i];
        game.opponent = name;
        game.sgfString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"sgf"] encoding:NSUTF8StringEncoding error:NULL];
        game.color = kMovePlayerBlack;
        game.time = @"Test";
        game.gameId = 100000000 + i;
        game.moveId = 100;
        game.myTurn = YES;
        
        [mutableGames addObject:game];
    }
    
    MutableGameList *mutableGameList = [gameList mutableCopy];
    
    [mutableGameList addGames:mutableGames];
    return mutableGameList;
}

- (void)handleGameListChanges:(GameList *)gameList
       runningGameListChanges:(GameList *)runningGameList {
    
#if TEST_GAMES
    gameList = [self gameListByAppendingTestGamesTo:gameList];
#endif
    
    if (gameList && ![self.games isEqual:gameList]) {
        NSLog(@"Game list changed!");
        [[DGSPushServer sharedPushServer] updateGameList:gameList completionHandler:^{ } errorHandler:^(NSError *error) { }];
        ((DGSPhoneAppDelegate *)[[UIApplication sharedApplication] delegate]).lastKnownMove = [gameList.games valueForKeyPath:@"@max.lastMove"];
    }
    
    self.games = gameList;
    self.runningGames = runningGameList;
    [self.tableView reloadData];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count] + [self.games inviteCount]];
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
    if (self.gameListTypeControl.selectedSegmentIndex == kGameSectionMyMove) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    GameList *selectedGameList = [self selectedGameList];

    if (section == 0) {
        NSInteger count = [selectedGameList count];
        if ([selectedGameList hasMorePages]) {
            count += 1; // for the activity indicator
        }
        return count;
    } else {
        //invites
        return [selectedGameList inviteCount];
    }
}

- (Game *)gameForRowAtIndexPath:(NSIndexPath *)indexPath {
    GameList *selectedGameList = [self selectedGameList];
    if (indexPath.row < [selectedGameList.games count]) {
        return (selectedGameList.games)[indexPath.row];
    } else {
        return nil;
    }
}

- (Invite *)inviteForRowAtIndexPath:(NSIndexPath *)indexPath {
    GameList *selectedGameList = [self selectedGameList];
    return [selectedGameList.invites objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.section == kSectionGames) {
        Game *game = [self gameForRowAtIndexPath:indexPath];
        if (game) {

            if ([game color] == kMovePlayerBlack) {
                [cell.imageView setImage:[UIImage imageNamed:@"Black.png"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"White.png"]];
            }
            cell.textLabel.text = game.opponent;
            cell.detailTextLabel.text = game.time;
            return cell;
        } else if ([self selectedGameList] == self.runningGames) {
            LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
            [cell.activityIndicator startAnimating];
            if (self.runningGames && !self.loadingNewRunningGamesPage) {
                self.loadingNewRunningGamesPage = YES;
                [self getMoreRunningGames];
            }
        } else {
            NSAssert(false, @"Trying to show a loading cell for the main game list!");
            return nil;
        }
    } else {
        //invites
        Invite *invite = [self inviteForRowAtIndexPath:indexPath];
        cell.textLabel.text = invite.opponent;
        cell.detailTextLabel.text = @"Invite";
    }

    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [theTableView cellForRowAtIndexPath:indexPath];
    [self setEnabled:NO];

    if (indexPath.section == kSectionGames) {
        Game *game = [self gameForRowAtIndexPath:indexPath];
        UIActivityIndicatorView *activityView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        [cell setAccessoryView:activityView];
        
        [[GenericGameServer sharedGameServer] getSgfForGame:game onSuccess:^(Game *game) {
            [cell setAccessoryView:nil];
            [self setEnabled:YES];
            [self performSegueWithIdentifier:@"ShowGame" sender:game];
        } onError:^(NSError *error) {
            [cell setAccessoryView:nil];
            [self setEnabled:YES];
        }];
    } else {
        //invite
        Invite *i = [self inviteForRowAtIndexPath:indexPath];
        [[GenericGameServer sharedGameServer] getInviteDetails:i onSuccess:^(Invite *invite) {
            [cell setAccessoryView:nil];
            [self setEnabled:YES];
            [self performSegueWithIdentifier:@"ShowInvite" sender:invite];
        } onError:^(NSError *error) {
            [cell setAccessoryView:nil];
            [self setEnabled:YES];
        }];


    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Games";
    } else {
        return @"Invitations";
    }
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
