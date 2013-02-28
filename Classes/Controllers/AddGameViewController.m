//
//  AddGameViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "AddGameViewController.h"

#import "SelectCell.h"
#import "BooleanCell.h"
#import "SpinnerView.h"

@interface AddGameViewController ()

@property (nonatomic, strong) NSArray *ratingStrings;
@property (nonatomic, strong) SpinnerView *spinner;

@end

@implementation AddGameViewController

#pragma mark -
#pragma mark View lifecycle

typedef enum _AddGameSection {
	kDescriptionSection,
	kBoardSection,
	kTimeSection,
    kRatingSection,
    kActionSection,
    kSectionCount
} AddGameSection;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationController.viewControllers[0] == self) {
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    }

	self.game = [[NewGame alloc] init];
    self.ratingStrings = [self generateRatingStrings];
    self.spinner = [[SpinnerView alloc] initInView:self.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player = [Player currentPlayer];
    if (!self.player.rated) {
        self.game.komiType = kKomiTypeManual;
    }
}

#pragma mark - Initialization 
- (NSArray *)generateRatingStrings {
    NSMutableArray *ratingStrings = [[NSMutableArray alloc] initWithCapacity:40];
    for (int i = 30; i > 0; i--) {
        [ratingStrings addObject:[NSString stringWithFormat:@"%d kyu", i]];
    }
    for (int i = 1; i < 10; i++) {
        [ratingStrings addObject:[NSString stringWithFormat:@"%d dan", i]];
    }
    return ratingStrings;
}

#pragma mark - Actions
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == kDescriptionSection) {
		return 1;
	} else if (section == kBoardSection) {
        if (self.game.komiType != kKomiTypeManual) {
			return 3;
		} else {
			return 6;
		}
	} else if (section == kTimeSection) {
		if (self.game.byoYomiType == kByoYomiTypeFischer) {
			return 3;
		} else {
			return 4;
		}
	} else if (section == kRatingSection) {
        if (self.game.requireRatedOpponent) {
            return 4;
        } else {
            return 2;
        }
    } else if (section == kActionSection) {
        return 1;
    }
	return 0;
}

- (UITableViewCell *)dequeueDefaultCell:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
}

- (TextCell *)dequeueTextCell:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"TextCell"];
}

- (SelectCell *)dequeueSelectCell:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"SelectCell"];
}

- (BooleanCell *)dequeueBooleanCell:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"BooleanCell"];
}

- (TextCell *)dequeueActionCell:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
}

- (void)setComment:(TextCell *)commentCell {
	[self.game setComment:[[commentCell textField] text]];
}

- (void)setKomiType:(SelectCell *)cell {
    KomiType oldKomiType = self.game.komiType;
	KomiType komiType = [cell.picker selectedRowInComponent:0];

	NSString *komiTypeString = [self.game komiTypeString:komiType];
	self.game.komiType = komiType;
	cell.value.text = komiTypeString;
	cell.selectedOptions = @[komiTypeString];

    // We want to update the table cells without deselecting
    // the current cell, so no #reloadData for you.
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:3 inSection:kBoardSection], [NSIndexPath indexPathForRow:4 inSection:kBoardSection], [NSIndexPath indexPathForRow:5 inSection:kBoardSection]];

    if (oldKomiType != kKomiTypeManual && komiType == kKomiTypeManual) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    } else if (oldKomiType == kKomiTypeManual && komiType != kKomiTypeManual) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)setByoYomiType:(SelectCell *)cell {
	ByoYomiType oldByoYomiType = self.game.byoYomiType;
	ByoYomiType byoYomiType = [cell.picker selectedRowInComponent:0];
	NSString *byoYomiTypeString = [self.game byoYomiTypeString:byoYomiType];
	self.game.byoYomiType = byoYomiType;
	cell.value.text = byoYomiTypeString;
	cell.selectedOptions = @[byoYomiTypeString];

	// We want to update the table cells without deselecting
	// the current cell, so no #reloadData for you.
	NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:kTimeSection]];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:3 inSection:kTimeSection];
	if (oldByoYomiType == kByoYomiTypeFischer && byoYomiType != kByoYomiTypeFischer) {
		[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
		[indexPaths addObject:indexPath];
	} else if (oldByoYomiType != kByoYomiTypeFischer && byoYomiType == kByoYomiTypeFischer) {
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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

    cell.value.text = [self.game timePeriodString:self.game.timeValue withTimeUnit:self.game.timeUnit];
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.timeUnit]];
}

- (void)setExtraTimeJapanese:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.japaneseTimeValue = timeValue;
	self.game.japaneseTimeUnit = [cell.picker selectedRowInComponent:2];

	cell.value.text = [self.game timePeriodString:self.game.japaneseTimeValue withTimeUnit:self.game.japaneseTimeUnit];
    cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.japaneseTimeUnit]];
}

- (void)setExtraTimeCanadian:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.canadianTimeValue = timeValue;
	self.game.canadianTimeUnit = [cell.picker selectedRowInComponent:2];

    cell.value.text = [self.game timePeriodString:self.game.canadianTimeValue withTimeUnit:self.game.canadianTimeUnit];
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.canadianTimeUnit]];
}

- (void)setExtraTimeFischer:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.fischerTimeValue = timeValue;
	self.game.fischerTimeUnit = [cell.picker selectedRowInComponent:2];

	cell.value.text = [self.game timePeriodString:self.game.fischerTimeValue withTimeUnit:self.game.fischerTimeUnit];
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.fischerTimeUnit]];
}

- (void)setJapaneseTimePeriods:(TextCell *)timePeriodCell {
	[self.game setJapaneseTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (void)setCanadianTimePeriods:(TextCell *)timePeriodCell {
	[self.game setCanadianTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (SelectCell *)timeCell:(UITableView *)theTableView timeValue:(int)timeValue timeUnit:(TimePeriod)timeUnit onSelected:(void (^)(SelectCell *selectCell))onSelected label:(NSString *)label {
	SelectCell *cell = [self dequeueSelectCell:theTableView];
	NSString *timeString = [self.game timePeriodString:timeValue withTimeUnit:timeUnit];
	NSArray *zeroToNine = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"];
	NSArray *timePeriods = @[[self.game timePeriodValue:kTimePeriodHours], [self.game timePeriodValue:kTimePeriodDays], [self.game timePeriodValue:kTimePeriodMonths]];
	NSArray *sizes = @[@80.0f,@80.0f, @140.0f];
	cell.label.text = label;
	cell.value.text = timeString;
	cell.onChanged = onSelected;
	cell.sizes = sizes;
	cell.options = @[zeroToNine, zeroToNine, timePeriods];
	int tens = timeValue / 10;
	int ones = timeValue - (tens * 10);
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:timeUnit]];
	return cell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == kDescriptionSection) {
		if ([indexPath row] == 0) {
			TextCell *cell = [self dequeueTextCell:theTableView];
			cell.textLabel.text = @"Comment";
			cell.textField.text = self.game.comment;
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textEditedSelector = @selector(setComment:);
			return cell;
		}
	}
	if ([indexPath section] == kBoardSection) {

		if ([indexPath row] == 0) {
			SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *boardSize = [NSString stringWithFormat:@"%d", self.game.boardSize];
			NSArray *options = @[@"9", @"13", @"19"];
			cell.label.text = @"Board Size";
			cell.value.text = boardSize;
			cell.onChanged = ^(SelectCell *cell) {
                NSString *boardSize = (cell.options)[0][[cell.picker selectedRowInComponent:0]];
                [self.game setBoardSize:[boardSize intValue]];
                cell.value.text = boardSize;
                cell.selectedOptions = @[boardSize];
            };
			cell.options = @[options];
			cell.sizes = nil;
			cell.selectedOptions = @[boardSize];
			return cell;
		} else if ([indexPath row] == 1) {
            BooleanCell *cell = [self dequeueBooleanCell:theTableView];
            cell.textLabel.text = @"Standard Placement";
            cell.toggleSwitch.on = self.game.stdHandicap;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.stdHandicap = cell.toggleSwitch.on;
            };
			return cell;
		} else if ([indexPath row] == 2) {
			SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *komiType = [self.game komiTypeString];
			NSMutableArray *options = [NSMutableArray array];
            if (self.player.rated) {
                [options addObjectsFromArray:@[[self.game komiTypeString:kKomiTypeConventional], [self.game komiTypeString:kKomiTypeProper]]];
            } else {
                cell.userInteractionEnabled = NO;
            }
            [options addObject:[self.game komiTypeString:kKomiTypeManual]];
            cell.label.text = @"Komi Type";
			cell.value.text = komiType;
			cell.onChanged = ^(SelectCell *selectCell) {
                [self setKomiType:selectCell];
            };
			cell.options = @[options];
			cell.selectedOptions = @[komiType];
			cell.sizes = nil;
			return cell;
		} else if ([indexPath row] == 3) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *manualKomiType = [self.game manualKomiTypeString];
            NSMutableArray *options = [NSMutableArray array];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeNigiri]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeDouble]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeBlack]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeWhite]];

			cell.label.text = @"Game Style";
			cell.value.text = manualKomiType;
            cell.onChanged = ^(SelectCell *cell) {
                ManualKomiType manualKomiType = [cell.picker selectedRowInComponent:0];
                NSString *manualKomiTypeString = [self.game manualKomiTypeString:manualKomiType];
                self.game.manualKomiType = manualKomiType;
                cell.value.text = manualKomiTypeString;
                cell.selectedOptions = @[manualKomiTypeString];
            };
			cell.options = @[options];
			cell.selectedOptions = @[manualKomiType];
			cell.sizes = nil;
			return cell;
        } else if ([indexPath row] == 4) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
            NSMutableArray *handicaps = [[NSMutableArray alloc] initWithObjects:@"0", nil];
            for (int i = 2; i < 22; i++) {
                [handicaps addObject:[NSString stringWithFormat:@"%d", i]];
            }

			cell.label.text = @"Handicap";
			cell.value.text = [NSString stringWithFormat:@"%d", self.game.handicap];
            cell.onChanged = ^(SelectCell *cell) {
                NSString *handicapString = [cell selectedValueInComponent:0];
                self.game.handicap = [handicapString intValue];
                cell.value.text = handicapString;
            };
			cell.options = @[handicaps];
			cell.selectedOptions = @[[NSString stringWithFormat:@"%d", self.game.handicap]];
			cell.sizes = nil;
			return cell;
        } else if ([indexPath row] == 5) {
            TextCell *cell = [self dequeueTextCell:theTableView];
            cell.textLabel.text = @"Komi";
            cell.textField.text = [NSString stringWithFormat:@"%0.1f", self.game.komi];
            cell.textField.keyboardType = UIKeyboardTypeDecimalPad;
            cell.onChanged = ^(TextCell *cell) {
                self.game.komi = [cell.textField.text floatValue];
            };
            return cell;
        }
	} else if ([indexPath section] == kTimeSection) {
		if ([indexPath row] == 0) {
			return [self timeCell:theTableView timeValue:self.game.timeValue timeUnit:self.game.timeUnit onSelected:^(SelectCell *selectCell) { [self setMainTime:selectCell]; } label:@"Main Time"];
		} else if ([indexPath row] == 1) {
			SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *byoYomiType = [self.game byoYomiTypeString];
			NSArray *options = @[[self.game byoYomiTypeString:kByoYomiTypeJapanese], [self.game byoYomiTypeString:kByoYomiTypeCanadian], [self.game byoYomiTypeString:kByoYomiTypeFischer]];
			cell.label.text = @"Byo-Yomi";
			cell.value.text = byoYomiType;
			cell.onChanged = ^(SelectCell *selectCell) { [self setByoYomiType:selectCell]; };
			cell.options = @[options];
			cell.selectedOptions = @[byoYomiType];
			cell.sizes = nil;
			return cell;
		} else if ([indexPath row] == 2) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				return [self timeCell:theTableView timeValue:self.game.japaneseTimeValue timeUnit:self.game.japaneseTimeUnit onSelected:^(SelectCell *selectCell) { [self setExtraTimeJapanese:selectCell]; } label:@"Extra Time"];
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				return [self timeCell:theTableView timeValue:self.game.canadianTimeValue timeUnit:self.game.canadianTimeUnit onSelected:^(SelectCell *selectCell) { [self setExtraTimeCanadian:selectCell]; } label:@"Extra Time"];
			} else if (self.game.byoYomiType == kByoYomiTypeFischer) {
				return [self timeCell:theTableView timeValue:self.game.fischerTimeValue timeUnit:self.game.fischerTimeUnit onSelected:^(SelectCell *selectCell) { [self setExtraTimeFischer:selectCell]; } label:@"Extra Per Move"];
			}
		} else if ([indexPath row] == 3) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				TextCell *cell = [self dequeueTextCell:theTableView];
				cell.textLabel.text = @"Extra Periods";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.japaneseTimePeriods];
				cell.textEditedSelector = @selector(setJapaneseTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				TextCell *cell = [self dequeueTextCell:theTableView];
				cell.textLabel.text = @"Extra Stones";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.canadianTimePeriods];
				cell.textEditedSelector = @selector(setCanadianTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			}
		}
	} else if ([indexPath section] == kRatingSection) {
		if ([indexPath row] == 0) {
			BooleanCell *cell = [self dequeueBooleanCell:theTableView];
            cell.textLabel.text = @"Ranked game";
            cell.toggleSwitch.on = self.game.rated;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.rated = cell.toggleSwitch.on;
            };
			return cell;
		} else if ([indexPath row] == 1) {
			BooleanCell *cell = [self dequeueBooleanCell:theTableView];
            cell.textLabel.text = @"Rated opponent";
            cell.toggleSwitch.on = self.game.requireRatedOpponent;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.requireRatedOpponent = cell.toggleSwitch.on;
                // We want to update the table cells without deselecting
                // the current cell, so no #reloadData for you.
                NSArray *indexPaths = @[[NSIndexPath indexPathForRow:2 inSection:kRatingSection], [NSIndexPath indexPathForRow:3 inSection:kRatingSection]];

                if (self.game.requireRatedOpponent) {
                    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                } else {
                    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                }
            };
			return cell;
		} else if ([indexPath row] == 2) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
			cell.label.text = @"Min rating";
			cell.value.text = self.game.minimumRating;
			cell.onChanged = ^(SelectCell *cell) {
                NSString *value = [cell selectedValueInComponent:0];
                self.game.minimumRating = value;
                cell.value.text = value;
            };
			cell.options = @[_ratingStrings];
			cell.selectedOptions = @[self.game.minimumRating];
			cell.sizes = nil;
			return cell;
        } else if ([indexPath row] == 3) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
			cell.label.text = @"Max rating";
			cell.value.text = self.game.maximumRating;
            cell.onChanged = ^(SelectCell *cell) {
                NSString *value = [cell selectedValueInComponent:0];
                self.game.maximumRating = value;
                cell.value.text = value;
            };
			cell.options = @[_ratingStrings];
			cell.selectedOptions = @[self.game.maximumRating];
			cell.sizes = nil;
			return cell;
        }
    } else if (indexPath.section == kActionSection) {
        UITableViewCell *cell = [self dequeueActionCell:theTableView];
        cell.textLabel.text = @"Create Game";
        self.createGameButton = cell;
        return cell;
    }
    return [self dequeueDefaultCell:theTableView];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kActionSection && indexPath.row == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        // break the retain cycle in the block below

        __weak AddGameViewController* blockSelf = self;
        self.spinner.label.text = @"Posting…";
        [self.spinner show];
        [[GenericGameServer sharedGameServer] addGame:self.game onSuccess:^() {
            [blockSelf.spinner dismiss:YES];
            [blockSelf dismissViewControllerAnimated:YES completion:^{
            }];
        } onError:^(NSError *error) {
            [blockSelf.spinner dismiss:YES];
		}];

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
    [self setCancelButton:nil];
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.descriptionCell = nil;
     _ratingStrings = nil;
}

@end
