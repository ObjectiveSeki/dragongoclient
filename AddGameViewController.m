//
//  AddGameViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "AddGameViewController.h"
#import "TableCellFactory.h"
#import "LoginViewController.h"


@implementation AddGameViewController

@synthesize spinnerView;

@synthesize descriptionCell, newGame, dgs;

#pragma mark -
#pragma mark View lifecycle

typedef enum _AddGameSection {
	kDescriptionSection,
	kBoardSection,
	kTimeSection
} AddGameSection;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.dgs = [[[DGS alloc] init] autorelease];
	self.dgs.delegate = self;
	
	self.newGame = [[[NewGame alloc] init] autorelease];
    self.navigationItem.title = @"Create a Game";
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
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)notLoggedIn {
	LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
	loginViewController.delegate = self;
	[self presentModalViewController:loginViewController animated:YES];
	[loginViewController notLoggedIn];
	[loginViewController release];
}

- (void)loggedIn {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)addedGame {
	[self.spinnerView dismiss];
	self.spinnerView = nil;
	[[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)addGame {
	self.spinnerView = [SpinnerView showInView:self.view];
	self.spinnerView.label.text = @"Posting...";
	[self.dgs addGame:self.newGame];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kTimeSection + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == kDescriptionSection) {
		return 1;
	} else if (section == kBoardSection) {
		return 2;
	} else if (section == kTimeSection) {
		if (self.newGame.byoYomiType == kByoYomiTypeFischer) {
			return 3;
		} else {
			return 4;
		}
	}
	return 0;
}

- (UITableViewCell *)defaultCell:(UITableView *)tableView {
	static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }	
	return cell;
}

- (TextCell *)textCell:(UITableView *)tableView {
	static NSString *CellIdentifier = @"TextCell";
    
    TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [TableCellFactory textCell];
    }
	
	return cell;
}

- (SelectCell *)selectCell:(UITableView *)tableView {
	static NSString *CellIdentifier = @"SelectCell";
    
    SelectCell *cell = (SelectCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [TableCellFactory selectCell];
    }
	
	return cell;
}

- (void)setComment:(TextCell *)commentCell {
	[self.newGame setComment:[[commentCell textField] text]];
}

- (void)setBoardSize:(SelectCell *)cell {
	NSString *boardSize = [[cell.options objectAtIndex:0] objectAtIndex:[cell.picker selectedRowInComponent:0]];
	[self.newGame setBoardSize:[boardSize intValue]];
	cell.value.text = boardSize;
	cell.selectedOptions = [NSArray arrayWithObject:boardSize];
}

- (void)setKomiType:(SelectCell *)cell {
	KomiType komiType = [cell.picker selectedRowInComponent:0];
	NSString *komiTypeString = [self.newGame komiTypeString:komiType];
	self.newGame.komiType = komiType;
	cell.value.text = komiTypeString;
	cell.selectedOptions = [NSArray arrayWithObject:komiTypeString];
}

- (void)setByoYomiType:(SelectCell *)cell {
	ByoYomiType oldByoYomiType = self.newGame.byoYomiType;
	ByoYomiType byoYomiType = [cell.picker selectedRowInComponent:0];
	NSString *byoYomiTypeString = [self.newGame byoYomiTypeString:byoYomiType];
	self.newGame.byoYomiType = byoYomiType;
	cell.value.text = byoYomiTypeString;
	cell.selectedOptions = [NSArray arrayWithObject:byoYomiTypeString];
	
	// We want to update the table cells without deselecting 
	// the current cell, so no #reloadData for you.
	NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:2]];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:3 inSection:2];
	if (oldByoYomiType == kByoYomiTypeFischer && byoYomiType != kByoYomiTypeFischer) {
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
		[indexPaths addObject:indexPath];
	} else if (oldByoYomiType != kByoYomiTypeFischer && byoYomiType == kByoYomiTypeFischer) {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[indexPaths addObject:indexPath];
	}
	[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setMainTime:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.newGame.timeValue = timeValue;
	self.newGame.timeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.newGame.timeValue, [self.newGame timePeriodValue:self.newGame.timeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.newGame timePeriodValue:self.newGame.timeUnit], nil];
}

- (void)setExtraTimeJapanese:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.newGame.japaneseTimeValue = timeValue;
	self.newGame.japaneseTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.newGame.japaneseTimeValue, [self.newGame timePeriodValue:self.newGame.japaneseTimeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.newGame timePeriodValue:self.newGame.japaneseTimeUnit], nil];
}

- (void)setExtraTimeCanadian:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.newGame.canadianTimeValue = timeValue;
	self.newGame.canadianTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.newGame.canadianTimeValue, [self.newGame timePeriodValue:self.newGame.canadianTimeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.newGame timePeriodValue:self.newGame.canadianTimeUnit], nil];
}

- (void)setExtraTimeFischer:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.newGame.fischerTimeValue = timeValue;
	self.newGame.fischerTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.newGame.fischerTimeValue, [self.newGame timePeriodValue:self.newGame.fischerTimeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.newGame timePeriodValue:self.newGame.fischerTimeUnit], nil];
}

- (void)setJapaneseTimePeriods:(TextCell *)timePeriodCell {
	[self.newGame setJapaneseTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (void)setCanadianTimePeriods:(TextCell *)timePeriodCell {
	[self.newGame setCanadianTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (SelectCell *)timeCell:(UITableView *)tableView timeValue:(int)timeValue timeUnit:(TimePeriod)timeUnit selector:(SEL)setSelector label:(NSString *)label {
	SelectCell *cell = [self selectCell:tableView];
	NSString *timeString = [NSString stringWithFormat:@"%d %@", timeValue, [self.newGame timePeriodValue:timeUnit]];
	NSArray *zeroToNine = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil];
	NSArray *timePeriods = [NSArray arrayWithObjects:[self.newGame timePeriodValue:kTimePeriodHours], [self.newGame timePeriodValue:kTimePeriodDays], [self.newGame timePeriodValue:kTimePeriodMonths], nil];
	NSArray *sizes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:80.0],[NSNumber numberWithFloat:80.0], [NSNumber numberWithFloat:140.0], nil];
	cell.label.text = label;
	cell.value.text = timeString;
	cell.changedSelector = setSelector;
	cell.sizes = sizes;
	cell.options = [NSArray arrayWithObjects:zeroToNine, zeroToNine, timePeriods, nil];
	int tens = timeValue / 10;
	int ones = timeValue - (tens * 10);
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.newGame timePeriodValue:timeUnit], nil];
	return cell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self textCell:tableView];
	if ([indexPath section] == kDescriptionSection) {

		if ([indexPath row] == 0) {
			TextCell *cell = [self textCell:tableView];
			cell.label.text = @"Comment";
			cell.textField.text = self.newGame.comment;
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textEditedSelector = @selector(setComment:);
			return cell;
		}
	}
	if ([indexPath section] == kBoardSection) {
		
		if ([indexPath row] == 0) {
			SelectCell *cell = [self selectCell:tableView];
			NSString *boardSize = [NSString stringWithFormat:@"%d", self.newGame.boardSize];
			NSArray *options = [NSArray arrayWithObjects:@"9", @"13", @"19", nil];
			cell.label.text = @"Board Size";
			cell.value.text = boardSize;
			cell.changedSelector = @selector(setBoardSize:);
			cell.options = [NSArray arrayWithObject:options];
			cell.sizes = nil;
			cell.selectedOptions = [NSArray arrayWithObject:boardSize];
			return cell;
		} else if ([indexPath row] == 1) {
			SelectCell *cell = [self selectCell:tableView];
			NSString *komiType = [self.newGame komiTypeString];
			NSArray *options = [NSArray arrayWithObjects:[self.newGame komiTypeString:kKomiTypeConventional], [self.newGame komiTypeString:kKomiTypeProper], nil];
			cell.label.text = @"Komi Type";
			cell.value.text = komiType;
			cell.changedSelector = @selector(setKomiType:);
			cell.options = [NSArray arrayWithObject:options];
			cell.selectedOptions = [NSArray arrayWithObject:komiType];
			cell.sizes = nil;
			return cell;
		}
	} else if ([indexPath section] == kTimeSection) {
		if ([indexPath row] == 0) {
			return [self timeCell:tableView timeValue:self.newGame.timeValue timeUnit:self.newGame.timeUnit selector:@selector(setMainTime:) label:@"Main Time"];
		} else if ([indexPath row] == 1) {
			SelectCell *cell = [self selectCell:tableView];
			NSString *byoYomiType = [self.newGame byoYomiTypeString];
			NSArray *options = [NSArray arrayWithObjects:[self.newGame byoYomiTypeString:kByoYomiTypeJapanese], [self.newGame byoYomiTypeString:kByoYomiTypeCanadian], [self.newGame byoYomiTypeString:kByoYomiTypeFischer], nil];
			cell.label.text = @"Byo-Yomi";
			cell.value.text = byoYomiType;
			cell.changedSelector = @selector(setByoYomiType:);
			cell.options = [NSArray arrayWithObject:options];
			cell.selectedOptions = [NSArray arrayWithObject:byoYomiType];
			cell.sizes = nil;
			return cell;
		} else if ([indexPath row] == 2) {
			if (self.newGame.byoYomiType == kByoYomiTypeJapanese) {
				return [self timeCell:tableView timeValue:self.newGame.japaneseTimeValue timeUnit:self.newGame.japaneseTimeUnit selector:@selector(setExtraTimeJapanese:) label:@"Extra Time"];
			} else if (self.newGame.byoYomiType == kByoYomiTypeCanadian) {
				return [self timeCell:tableView timeValue:self.newGame.canadianTimeValue timeUnit:self.newGame.canadianTimeUnit selector:@selector(setExtraTimeCanadian:) label:@"Extra Time"];
			} else if (self.newGame.byoYomiType == kByoYomiTypeFischer) {
				return [self timeCell:tableView timeValue:self.newGame.fischerTimeValue timeUnit:self.newGame.fischerTimeUnit selector:@selector(setExtraTimeFischer:) label:@"Extra Per Move"];
			}
		} else if ([indexPath row] == 3) {
			if (self.newGame.byoYomiType == kByoYomiTypeJapanese) {
				TextCell *cell = [self textCell:tableView];
				cell.label.text = @"Extra Periods";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.newGame.japaneseTimePeriods];
				cell.textEditedSelector = @selector(setJapaneseTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			} else if (self.newGame.byoYomiType == kByoYomiTypeCanadian) {
				TextCell *cell = [self textCell:tableView];
				cell.label.text = @"Extra Stones";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.newGame.canadianTimePeriods];
				cell.textEditedSelector = @selector(setCanadianTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			}
		}
	}
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
	//[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
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
	self.descriptionCell = nil;
	self.newGame = nil;
	self.dgs = nil;
	self.spinnerView = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end


