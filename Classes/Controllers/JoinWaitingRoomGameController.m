
#import "JoinWaitingRoomGameController.h"
#import "TextCell.h"

@implementation JoinWaitingRoomGameController

@synthesize game;
@synthesize deleteConfirmation;

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
	TableSection *section = [[TableSection alloc] init];
	section.headerString = sectionTitle;
	for (NSArray *rowInfo in rows) {
		TableRow *row = [[TableRow alloc] init];
		row.cellClass = [UITableViewCell class];
		row.cellInit = ^() {
			return (UITableViewCell *)[[row.cellClass alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:NSStringFromClass(row.cellClass)];
		};
		row.cellSetup = ^(UITableViewCell *cell) {
			cell.textLabel.text = [rowInfo objectAtIndex:0];
			if ([rowInfo count] > 1) {
				cell.detailTextLabel.text = [rowInfo lastObject];				
			}
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		};
		[section addRow:row];
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
	[rows addObject:[NSArray arrayWithObjects:@"Rating", self.game.opponentRating ? self.game.opponentRating : @"Not Ranked", nil]];
	
	return [self basicSectionWithTitle:@"Opponent" rows:rows];
}

- (TableSection *)gameSection {
	
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:6];
	
	[rows addObject:[NSArray arrayWithObjects:@"Board Size", [NSString stringWithFormat:@"%dx%d", self.game.boardSize, self.game.boardSize], nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Rated", self.game.ratedString, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Time", self.game.time, nil]];
	[rows addObject:[NSArray arrayWithObjects:@"Weekend Clock", self.game.weekendClockString, nil]];
    if (self.game.handicap != 0) {
        [rows addObject:[NSArray arrayWithObjects:@"Handicap", [NSString stringWithFormat:@"%d", self.game.handicap], nil]];
    }
    [rows addObject:[NSArray arrayWithObjects:@"Type", self.game.komiTypeName, nil]];
    
    if (self.game.komi != 0.0) {
        [rows addObject:[NSArray arrayWithObjects:@"Komi", [NSString stringWithFormat:@"%0.1f", self.game.komi], nil]];
    }
	
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
	
	TableSection *buttonSection = [[TableSection alloc] init];
	TableRow *buttonRow = [[TableRow alloc] init];
	buttonRow.cellClass = [UITableViewCell class];
	buttonRow.identifier = @"DefaultCell";
	buttonRow.cellInit = ^() {
		return (UITableViewCell *)[[buttonRow.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonRow.identifier];
	};
	buttonRow.cellSetup = ^(UITableViewCell *cell) {
		if (self.game.myGame) {
			cell.textLabel.text = @"Delete this game";
		} else {
			cell.textLabel.text = @"Join this game";
		}
		cell.textLabel.textColor = [UIColor colorWithRed:0.251 green:0.4 blue:0.616 alpha:1.0];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	};
	
	buttonRow.cellTouched = ^(UITableViewCell *cell) {
		if (self.game.myGame) {
            [cell setSelected:NO];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete?" message:@"Are you sure you want to delete this game from the server?" delegate:self cancelButtonTitle:@"Don't delete" otherButtonTitles:@"Delete", nil];
			self.deleteConfirmation = alertView;
            [self.deleteConfirmation show];
		} else {
            [self showSpinner:@"Joining..."];
			[self.gs joinWaitingRoomGame:game.gameId onSuccess:^() {
                [self hideSpinner:YES];
				[self.navigationController popToRootViewControllerAnimated:YES];
			}];
		}
	};
	
	[buttonSection addRow:buttonRow];
	[sections addObject:buttonSection];
	
	self.tableSections = sections;
}

// Handles dismissing the logout confirmation.
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView == self.deleteConfirmation) {
		if (buttonIndex != alertView.cancelButtonIndex) {
            [self showSpinner:@"Deleting..."];
			[self.gs deleteWaitingRoomGame:game.gameId onSuccess:^() {
                [self hideSpinner:YES];
				[self.navigationController popToRootViewControllerAnimated:YES];
			}];
		}
		self.deleteConfirmation = nil;
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
