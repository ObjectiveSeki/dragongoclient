
#import "JoinWaitingRoomGameController.h"
#import "IBAlertView.h"
#import "SpinnerView.h"

@interface JoinWaitingRoomGameController ()

@property (nonatomic, strong) NSMutableArray *sectionTitles;

// an array of key-value pairs
@property (nonatomic, strong) NSMutableArray *sections;

@property (nonatomic, strong) SpinnerView *spinner;

@end

@implementation JoinWaitingRoomGameController

- (void)buildCommentSection {
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:1];
	
	[rows addObject:@[@"Comment", self.game.comment]];
    [self.sectionTitles addObject:@""];
    [self.sections addObject:rows];
}

- (void)buildOpponentSection {
	
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:2];
	
	[rows addObject:@[@"Name", self.game.opponent]];
	[rows addObject:@[@"Rating", self.game.opponentRating ? self.game.opponentRating : @"Not Ranked"]];
	[self.sectionTitles addObject:@"Opponent"];
    [self.sections addObject:rows];
}

- (void)buildGameSection {
	
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:6];
	
	[rows addObject:@[@"Board Size", [NSString stringWithFormat:@"%dx%d", self.game.boardSize, self.game.boardSize]]];
	[rows addObject:@[@"Rated", self.game.ratedString]];
	[rows addObject:@[@"Time", self.game.time]];
	[rows addObject:@[@"Weekend Clock", self.game.weekendClockString]];
    if (self.game.handicap != 0) {
        [rows addObject:@[@"Handicap", [NSString stringWithFormat:@"%d", self.game.handicap]]];
    }
    [rows addObject:@[@"Type", self.game.komiTypeName]];
    
    if (self.game.komi != 0.0) {
        [rows addObject:@[@"Komi", [NSString stringWithFormat:@"%0.1f", self.game.komi]]];
    }
    
    [self.sectionTitles addObject:@"Game Information"];
    [self.sections addObject:rows];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    self.sectionTitles = [NSMutableArray array];
    self.sections = [NSMutableArray array];

	if (self.game.comment) {
		[self buildCommentSection];
	}
    [self buildOpponentSection];
    [self buildGameSection];
    
    self.spinner = [[SpinnerView alloc] initInView:self.view];
}

#pragma mark - TableView Delegate actions

- (BOOL)isPropertyCell:(NSInteger)section {
    return section < [self.sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isPropertyCell:section]) {
        return self.sectionTitles[section];
    } else {
        return @"";
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isPropertyCell:section]) {
        return [self.sections[section] count];
    } else {
        return 1; // Action button
    }

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count] + 1; // for action section
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([self isPropertyCell:indexPath.section]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell"];
        NSArray *infoRow = self.sections[indexPath.section][indexPath.row];
        cell.textLabel.text = infoRow[0];
        cell.detailTextLabel.text = infoRow[1];
        return cell;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
        if (self.game.myGame) {
            cell.textLabel.text = @"Delete this game";
        } else {
            cell.textLabel.text = @"Join this game";
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isPropertyCell:indexPath.section]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (self.game.myGame) {
            [IBAlertView showAlertWithTitle:@"Delete?" message:@"Are you sure you want to delete this game from the server?" dismissTitle:@"Don't delete" okTitle:@"Delete" dismissBlock:^{
            } okBlock:^{
                self.spinner.label.text = @"Deleting…";
                [self.spinner show];
                [[GenericGameServer sharedGameServer] deleteWaitingRoomGame:self.game.gameId onSuccess:^() {
                    [self.spinner dismiss:YES];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                } onError:^(NSError *error) {
                    [self.spinner dismiss:YES];
                }];
            }];
        } else {
            self.spinner.label.text = @"Joining…";
            [[GenericGameServer sharedGameServer] joinWaitingRoomGame:self.game.gameId onSuccess:^{
                [self.spinner dismiss:YES];
                [self.navigationController popToRootViewControllerAnimated:YES];
            } onError:^(NSError *error) {
                [self.spinner dismiss:YES];
            }];
        }
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
