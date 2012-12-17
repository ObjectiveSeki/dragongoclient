
#import "WaitingRoomGamesController.h"
#import "JoinWaitingRoomGameController.h"
#import "ODRefreshControl.h"

@interface WaitingRoomGamesController ()
// Can be either a OD or UIRefreshControl. Named 'myRefreshControl' to avoid
// conflicting with the built-in iOS6 one.
@property (nonatomic, strong) id myRefreshControl;
@property (nonatomic) BOOL loadingNewPage;
@property (nonatomic, strong) NewGame *mostRecentlyLoadedGame;
@end

@implementation WaitingRoomGamesController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    if ([UIRefreshControl class]) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.myRefreshControl = self.refreshControl;
    } else {
        ODRefreshControl *refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
        self.myRefreshControl = refreshControl;
    }
    [self.myRefreshControl addTarget:self action:@selector(refreshGameList:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshGameList:nil];
}

- (IBAction)refreshGameList:(id)sender {
    [[GenericGameServer sharedGameServer] getWaitingRoomGames:^(GameList *gameList) {
        self.gameList = gameList;
        [self.tableView reloadData];
        [self.myRefreshControl endRefreshing];
    } onError:^(NSError *error) {
        [self.myRefreshControl endRefreshing];
    }];
}

#pragma mark - UITableViewDataSource actions

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger count = [self.gameList.games count];
    if (!self.gameList || [self.gameList hasMorePages]) {
        count += 1;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.gameList.games.count) {
        NewGame *game = self.gameList.games[indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
        NSString *ratingString = game.opponentRating ? game.opponentRating : @"Not Ranked";
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", game.opponent, ratingString];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%dx%d | %@", game.boardSize, game.boardSize, game.time];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
        if (!self.loadingNewPage) {
            [self.gameList loadNextPage:^(GameList *gameList) {
                self.gameList = gameList;
                [self.tableView reloadData];
                self.loadingNewPage = NO;
            } onError:^(NSError *error) {
                self.loadingNewPage = NO;
#warning TODO: maybe allow the new page link to be tapped in this state?
            }];
            self.loadingNewPage = YES;
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row < self.gameList.games.count) {
        NewGame *game = self.gameList.games[indexPath.row];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        cell.accessoryView = activityView;
        [[GenericGameServer sharedGameServer] getWaitingRoomGameDetailsForGame:game onSuccess:^(NewGame *gameDetails) {
            cell.accessoryView = nil;
            [self.gameList updateGame:gameDetails atIndex:indexPath.row];
            [self performSegueWithIdentifier:@"ShowWaitingRoomDetail" sender:cell];
        } onError:^(NSError *error) {
            cell.accessoryView = nil;
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowWaitingRoomDetail"]) {
        JoinWaitingRoomGameController *controller = [segue destinationViewController];
        controller.game = self.gameList.games[[self.tableView indexPathForCell:sender].row];
    }
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end
