//
//  AddGameViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "AddGameViewController.h"
#import "TableCellFactory.h"
#import "LoginViewController.h"
#import "BooleanCell.h"


@implementation AddGameViewController

@synthesize descriptionCell, game;

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
	
	self.game = [[[NewGame alloc] init] autorelease];
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

- (IBAction)addGame {
	[self showSpinner:@"Posting..."];
	[self.gs addGame:self.game onSuccess:^() {
		[self hideSpinner:YES];
		[[self navigationController] popViewControllerAnimated:YES];
	}];
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
		if (self.game.byoYomiType == kByoYomiTypeFischer) {
			return 3;
		} else {
			return 4;
		}
	}
	return 0;
}

- (UITableViewCell *)defaultCell:(UITableView *)theTableView {
	static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }	
	return cell;
}

- (TextCell *)textCell:(UITableView *)theTableView {
	static NSString *CellIdentifier = @"TextCell";
    
    TextCell *cell = (TextCell *)[theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[[TextCell alloc] init] autorelease];
    }
	
	return cell;
}

- (SelectCell *)selectCell:(UITableView *)theTableView {
	static NSString *CellIdentifier = @"SelectCell";
    
    SelectCell *cell = (SelectCell *)[theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [TableCellFactory selectCell];
    }
	
	return cell;
}

- (BooleanCell *)booleanCell:(UITableView *)theTableView {
    BooleanCell *cell = (BooleanCell *)[theTableView dequeueReusableCellWithIdentifier:@"BooleanCell"];
    if (cell == nil) {
		cell = [[[BooleanCell alloc] init] autorelease];
    }
	
	return cell;
}

- (void)setComment:(TextCell *)commentCell {
	[self.game setComment:[[commentCell textField] text]];
}

- (void)setBoardSize:(SelectCell *)cell {
	NSString *boardSize = [[cell.options objectAtIndex:0] objectAtIndex:[cell.picker selectedRowInComponent:0]];
	[self.game setBoardSize:[boardSize intValue]];
	cell.value.text = boardSize;
	cell.selectedOptions = [NSArray arrayWithObject:boardSize];
}

- (void)setKomiType:(SelectCell *)cell {
	KomiType komiType = [cell.picker selectedRowInComponent:0];
	NSString *komiTypeString = [self.game komiTypeString:komiType];
	self.game.komiType = komiType;
	cell.value.text = komiTypeString;
	cell.selectedOptions = [NSArray arrayWithObject:komiTypeString];
}

- (void)setByoYomiType:(SelectCell *)cell {
	ByoYomiType oldByoYomiType = self.game.byoYomiType;
	ByoYomiType byoYomiType = [cell.picker selectedRowInComponent:0];
	NSString *byoYomiTypeString = [self.game byoYomiTypeString:byoYomiType];
	self.game.byoYomiType = byoYomiType;
	cell.value.text = byoYomiTypeString;
	cell.selectedOptions = [NSArray arrayWithObject:byoYomiTypeString];
	
	// We want to update the table cells without deselecting 
	// the current cell, so no #reloadData for you.
	NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:kTimeSection]];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:3 inSection:kTimeSection];
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
	self.game.timeValue = timeValue;
	self.game.timeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.game.timeValue, [self.game timePeriodValue:self.game.timeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.timeUnit], nil];
}

- (void)setExtraTimeJapanese:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.japaneseTimeValue = timeValue;
	self.game.japaneseTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.game.japaneseTimeValue, [self.game timePeriodValue:self.game.japaneseTimeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.japaneseTimeUnit], nil];
}

- (void)setExtraTimeCanadian:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.canadianTimeValue = timeValue;
	self.game.canadianTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.game.canadianTimeValue, [self.game timePeriodValue:self.game.canadianTimeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.canadianTimeUnit], nil];
}

- (void)setExtraTimeFischer:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.fischerTimeValue = timeValue;
	self.game.fischerTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [NSString stringWithFormat:@"%d %@", self.game.fischerTimeValue, [self.game timePeriodValue:self.game.fischerTimeUnit]];
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.fischerTimeUnit], nil];
}

- (void)setJapaneseTimePeriods:(TextCell *)timePeriodCell {
	[self.game setJapaneseTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (void)setCanadianTimePeriods:(TextCell *)timePeriodCell {
	[self.game setCanadianTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (SelectCell *)timeCell:(UITableView *)theTableView timeValue:(int)timeValue timeUnit:(TimePeriod)timeUnit selector:(SEL)setSelector label:(NSString *)label {
	SelectCell *cell = [self selectCell:theTableView];
	NSString *timeString = [NSString stringWithFormat:@"%d %@", timeValue, [self.game timePeriodValue:timeUnit]];
	NSArray *zeroToNine = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil];
	NSArray *timePeriods = [NSArray arrayWithObjects:[self.game timePeriodValue:kTimePeriodHours], [self.game timePeriodValue:kTimePeriodDays], [self.game timePeriodValue:kTimePeriodMonths], nil];
	NSArray *sizes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:80.0],[NSNumber numberWithFloat:80.0], [NSNumber numberWithFloat:140.0], nil];
	cell.label.text = label;
	cell.value.text = timeString;
	cell.changedSelector = setSelector;
	cell.sizes = sizes;
	cell.options = [NSArray arrayWithObjects:zeroToNine, zeroToNine, timePeriods, nil];
	int tens = timeValue / 10;
	int ones = timeValue - (tens * 10);
	cell.selectedOptions = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:timeUnit], nil];
	return cell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self textCell:theTableView];
	if ([indexPath section] == kDescriptionSection) {

		if ([indexPath row] == 0) {
			TextCell *cell = [self textCell:theTableView];
			cell.textLabel.text = @"Comment";
			cell.textField.text = self.game.comment;
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textEditedSelector = @selector(setComment:);
			return cell;
		}
	}
	if ([indexPath section] == kBoardSection) {
		
		if ([indexPath row] == 0) {
			SelectCell *cell = [self selectCell:theTableView];
			NSString *boardSize = [NSString stringWithFormat:@"%d", self.game.boardSize];
			NSArray *options = [NSArray arrayWithObjects:@"9", @"13", @"19", nil];
			cell.label.text = @"Board Size";
			cell.value.text = boardSize;
			cell.changedSelector = @selector(setBoardSize:);
			cell.options = [NSArray arrayWithObject:options];
			cell.sizes = nil;
			cell.selectedOptions = [NSArray arrayWithObject:boardSize];
			return cell;
		} else if ([indexPath row] == 1) {
			SelectCell *cell = [self selectCell:theTableView];
			NSString *komiType = [self.game komiTypeString];
			NSArray *options = [NSArray arrayWithObjects:[self.game komiTypeString:kKomiTypeConventional], [self.game komiTypeString:kKomiTypeProper], nil];
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
			return [self timeCell:theTableView timeValue:self.game.timeValue timeUnit:self.game.timeUnit selector:@selector(setMainTime:) label:@"Main Time"];
		} else if ([indexPath row] == 1) {
			SelectCell *cell = [self selectCell:theTableView];
			NSString *byoYomiType = [self.game byoYomiTypeString];
			NSArray *options = [NSArray arrayWithObjects:[self.game byoYomiTypeString:kByoYomiTypeJapanese], [self.game byoYomiTypeString:kByoYomiTypeCanadian], [self.game byoYomiTypeString:kByoYomiTypeFischer], nil];
			cell.label.text = @"Byo-Yomi";
			cell.value.text = byoYomiType;
			cell.changedSelector = @selector(setByoYomiType:);
			cell.options = [NSArray arrayWithObject:options];
			cell.selectedOptions = [NSArray arrayWithObject:byoYomiType];
			cell.sizes = nil;
			return cell;
		} else if ([indexPath row] == 2) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				return [self timeCell:theTableView timeValue:self.game.japaneseTimeValue timeUnit:self.game.japaneseTimeUnit selector:@selector(setExtraTimeJapanese:) label:@"Extra Time"];
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				return [self timeCell:theTableView timeValue:self.game.canadianTimeValue timeUnit:self.game.canadianTimeUnit selector:@selector(setExtraTimeCanadian:) label:@"Extra Time"];
			} else if (self.game.byoYomiType == kByoYomiTypeFischer) {
				return [self timeCell:theTableView timeValue:self.game.fischerTimeValue timeUnit:self.game.fischerTimeUnit selector:@selector(setExtraTimeFischer:) label:@"Extra Per Move"];
			}
		} else if ([indexPath row] == 3) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				TextCell *cell = [self textCell:theTableView];
				cell.textLabel.text = @"Extra Periods";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.japaneseTimePeriods];
				cell.textEditedSelector = @selector(setJapaneseTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				TextCell *cell = [self textCell:theTableView];
				cell.textLabel.text = @"Extra Stones";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.canadianTimePeriods];
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
}


- (void)dealloc {
	self.game = nil;
    [super dealloc];
}

@end


