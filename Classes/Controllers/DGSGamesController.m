
#import "DGSGamesController.h"
#import "AddGameViewController.h"
#import "WaitingRoomGamesController.h"

@implementation DGSGamesController

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	NSMutableArray *sections = [NSMutableArray array];
	TableSection *newGameSection = [[TableSection alloc] init];
	newGameSection.headerString = @"New Game";
	TableRow *firstRow = [[TableRow alloc] init];
	firstRow.cellClass = [UITableViewCell class];
	firstRow.cellSetup = ^(UITableViewCell *cell) {
		cell.textLabel.text = @"Create a game";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	};
	firstRow.cellTouched = ^(UITableViewCell *cell) {
		AddGameViewController *addGameController = [[AddGameViewController alloc] initWithNibName:@"AddGameView" bundle:nil];
		[[self navigationController] pushViewController:addGameController animated:YES];
		[addGameController release];
	};
	[newGameSection addRow:firstRow];
	[firstRow release];
	
	TableRow *joinGameRow = [[TableRow alloc] init];
	joinGameRow.cellClass = [UITableViewCell class];
	joinGameRow.cellSetup = ^(UITableViewCell *cell) {
		cell.textLabel.text = @"Join a game";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	};
	joinGameRow.cellTouched = ^(UITableViewCell *cell) {
		[self deselectSelectedCell];
		WaitingRoomGamesController *waitingRoomGamesController = [[WaitingRoomGamesController alloc] initWithNibName:@"WaitingRoomGamesView" bundle:nil];
		
		UIActivityIndicatorView *activityView = 
		[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[activityView startAnimating];
		[cell setAccessoryView:activityView];
		[activityView release];
		
		[self.gs getWaitingRoomGames:^(NSArray *games) {
			[waitingRoomGamesController setGames:games];
			[[self navigationController] pushViewController:waitingRoomGamesController animated:YES];
			[waitingRoomGamesController release];
			[cell setAccessoryView:nil];
		}];
	};
	[newGameSection addRow:joinGameRow];
	[joinGameRow release];
	
	[sections addObject:newGameSection];
	self.tableSections = sections;
	
	[newGameSection release];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

