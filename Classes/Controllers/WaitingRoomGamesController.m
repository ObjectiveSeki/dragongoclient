
#import "WaitingRoomGamesController.h"
#import "JoinWaitingRoomGameController.h"

@implementation WaitingRoomGamesController

@synthesize dgs;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void)refreshGames {
	
	[self.dgs getWaitingRoomGames:^(NSArray *games) {
		NSMutableArray *sections = [NSMutableArray array];
		TableSection *mainSection = [[TableSection alloc] init];
		
		for (NewGame *game in games) {
			TableRow *row = [[TableRow alloc] init];
			row.cellClass = [UITableViewCell class];
			row.cellInit = ^() {
				return (UITableViewCell *)[[[row.cellClass alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass(row.cellClass)] autorelease];
			};
			row.cellSetup = ^(UITableViewCell *cell) {
				NSString *ratingString = game.opponentRating ? game.opponentRating : @"Not Ranked";
				[[cell textLabel] setText:[NSString stringWithFormat:@"%@ - %@", game.opponent, ratingString]];
				[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%dx%d | %@", game.boardSize, game.boardSize, game.time]];
				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
			};
			row.cellTouched = ^(UITableViewCell *cell) {
				[dgs getWaitingRoomGameDetailsForGame:game onSuccess:^(NewGame *gameDetails) {
					
					JoinWaitingRoomGameController *controller = [[JoinWaitingRoomGameController alloc] initWithNibName:@"JoinWaitingRoomGameView" bundle:nil];
					controller.game = gameDetails;
					[self.navigationController pushViewController:controller animated:YES];
					[controller release];
				}];
			};
			[mainSection addRow:row];
			[row release];
		}
		
		[sections addObject:mainSection];
		[mainSection release];
		self.tableSections = sections;
		[self.tableView reloadData];
	}];

}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.dgs = [[DGS alloc] init];
	self.navigationItem.title = @"Join a Game";
	[self refreshGames];
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
	self.dgs = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
