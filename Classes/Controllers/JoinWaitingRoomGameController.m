
#import "JoinWaitingRoomGameController.h"
#import "TextCell.h"

@implementation JoinWaitingRoomGameController

@synthesize game;

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

// Builds a table section with the supplied title and rows. Rows are an array of two-
// element arrays, where the first element is a key and the second a value. All rows
// use the TableViewCellStyleValue1 style.
- (TableSection *)basicSectionWithTitle:(NSString *)sectionTitle rows:(NSArray *)rows {
	TableSection *section = [[[TableSection alloc] init] autorelease];
	section.headerString = sectionTitle;
	for (NSArray *rowInfo in rows) {
		TableRow *row = [[TableRow alloc] init];
		row.cellClass = [UITableViewCell class];
		row.cellInit = ^() {
			return (UITableViewCell *)[[[row.cellClass alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:NSStringFromClass(row.cellClass)] autorelease];
		};
		row.cellSetup = ^(UITableViewCell *cell) {
			cell.textLabel.text = [rowInfo objectAtIndex:0];
			if ([rowInfo count] > 1) {
				cell.detailTextLabel.text = [rowInfo lastObject];				
			}
		};
		[section addRow:row];
		[row release];
	}
	return section;
}

- (TableSection *)commentSection {
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:1];
	
	[rows addObject:[NSArray arrayWithObjects:@"Comment", self.game.comment, nil]];
	
	return [self basicSectionWithTitle:nil rows:rows];
}

- (TableSection *)opponentSection {
	
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:2];
	
	[rows addObject:[NSArray arrayWithObjects:@"Name", self.game.opponent, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Rating", self.game.opponentRating, nil]];
	
	return [self basicSectionWithTitle:@"Opponent" rows:rows];
}

- (TableSection *)gameSection {
	
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:6];
	
	[rows addObject:[NSArray arrayWithObjects:@"Board Size", [NSString stringWithFormat:@"%dx%d", self.game.boardSize, self.game.boardSize], nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Rated", self.game.ratedString, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Time", self.game.time, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Weekend Clock", self.game.weekendClockString, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Type", self.game.komiTypeName, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Komi", [NSString stringWithFormat:@"%0.1f", self.game.adjustedKomi], nil]];
	
	return [self basicSectionWithTitle:@"Game Information" rows:rows];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSMutableArray *sections = [NSMutableArray array];
	if (self.game.comment) {
		[sections addObject:[self commentSection]];
	}
	[sections addObject:[self opponentSection]];
	[sections addObject:[self gameSection]];
	
	TableSection *replySection = [[TableSection alloc] init];
	TableRow *replyRow = [[TableRow alloc] init];
	replyRow.cellClass = [TextCell class];
	replyRow.cellInit = ^() {
		return (UITableViewCell *)[[[replyRow.cellClass alloc] init] autorelease];
	};
	replyRow.cellSetup = ^(UITableViewCell *tableCell) {
		TextCell *cell = (TextCell *)tableCell;
		cell.label.text = @"Message";
		cell.textField.placeholder = @"Leave a short message";
	};
	
	[replySection addRow:replyRow];
	[replyRow release];
	[sections addObject:replySection];
	[replySection release];
	
	self.tableSections = sections;
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


- (void)dealloc {
	self.game = nil;
    [super dealloc];
}


@end
