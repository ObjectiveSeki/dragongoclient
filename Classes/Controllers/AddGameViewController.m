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
#import "PickerTableViewCell.h"

@interface AddGameViewController ()

@property (nonatomic, strong) NSArray *ratingStrings;
@property (nonatomic, strong) SpinnerView *spinner;
@property (nonatomic, strong) NSIndexPath *pickerIndexPath;
@property (nonatomic, assign) CGFloat pickerCellHeight;

@end

@implementation AddGameViewController

#pragma mark -
#pragma mark View lifecycle

typedef NS_ENUM(NSUInteger, AddGameSection) {
	kDescriptionSection,
    kNumberOfGamesSection,
	kBoardSection,
	kTimeSection,
    kRatingSection,
    kActionSection,
    kSectionCount
};

typedef NS_ENUM(NSUInteger, BoardSectionRows) {
    kBoardSectionBoardSizeRow,
    kBoardSectionHandicapPlacementRow,
    kBoardSectionKomiTypeRow,
    kBoardSectionGameStyleRow,
    kBoardSectionManualHandicapRow,
    kBoardSectionManualKomiRow,
    kBoardSectionCount
};

typedef NS_ENUM(NSUInteger, TimeSectionRows) {
    kTimeSectionMainTimeRow,
    kTimeSectionByoYomiTypeRow,
    kTimeSectionExtraTimeRow,
    kTimeSectionExtraPeriodsRow,
    kTimeSectionCount
};

typedef NS_ENUM(NSUInteger, RatingSectionRows) {
    kRatingSectionRankedGameRow,
    kRatingSectionRequireRatedOpponentRow,
    kRatingSectionMinRatingRow,
    kRatingSectionMaxRatingRow,
    kRatingSectionCount
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationController.viewControllers[0] == self) {
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    }

	self.game = [[NewGame alloc] init];
    self.ratingStrings = [self generateRatingStrings];
    self.spinner = [[SpinnerView alloc] initInView:self.view];
    self.pickerCellHeight = CGRectGetHeight([self.tableView dequeueReusableCellWithIdentifier:@"PickerCell"].frame);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player = [Player currentPlayer];
    if (!self.player.rated) {
        self.game.komiType = kKomiTypeManual;
    }
    
    // Default komi is 6.5 for new games
    self.game.komi = 6.5;
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

#pragma mark - Default cells

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

- (UITableViewCell *)dequeueActionCell:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
}

- (PickerTableViewCell *)dequeuePickerCell:(UITableView *)tableView withCell:(SelectCell *)selectCell {
    PickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PickerCell"];
    cell.sizes = selectCell.sizes;
    cell.options = selectCell.options;
    cell.selectedOptions = selectCell.selectedOptions;
    cell.onChanged = selectCell.onChanged;
    return cell;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    if (section == kDescriptionSection) {
		rowCount = 1;
	} else if (section == kNumberOfGamesSection) {
        rowCount = 1;
    } else if (section == kBoardSection) {
        if (self.game.komiType == kKomiTypeManual) {
			rowCount = 6;
		} else {
			rowCount = 3;
		}
	} else if (section == kTimeSection) {
		if (self.game.byoYomiType == kByoYomiTypeFischer) {
			rowCount = 3;
		} else {
			rowCount = 4;
		}
	} else if (section == kRatingSection) {
        if (self.game.requireRatedOpponent) {
            rowCount = 4;
        } else {
            rowCount = 2;
        }
    } else if (section == kActionSection) {
        rowCount = 1;
    }
    
    // If we're showing a picker in this section, we need an extra row for it.
    if (self.pickerIndexPath && self.pickerIndexPath.section == section) {
        rowCount++;
    }
	return rowCount;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *logicalIndexPath = [self indexPathIgnoringPicker:indexPath];

    if ([indexPath compare:self.pickerIndexPath] == NSOrderedSame) {
        NSAssert((indexPath.row - 1) >= 0, @"The row of the picker's associated cell is out of bounds.");
        NSIndexPath *associatedCellIndexPath = [self indexPathForOpenPickerCell];
        SelectCell *associatedCell = (SelectCell *)[self tableView:theTableView cellForRowAtIndexPath:associatedCellIndexPath];
        NSAssert([associatedCell.reuseIdentifier isEqualToString:@"SelectCell"], @"PickerCell's associated cell is not a SelectCell: %@", associatedCell);
        PickerTableViewCell *cell = [self dequeuePickerCell:theTableView withCell:associatedCell];
        cell.delegate = self;
        return cell;
    }
    
    NSInteger section = logicalIndexPath.section;
    NSInteger row = logicalIndexPath.row;
    
	if (section == kDescriptionSection) {
        TextCell *cell = [self dequeueTextCell:theTableView];
        cell.label.text = @"Comment";
        cell.textField.text = self.game.comment;
        cell.textField.keyboardType = UIKeyboardTypeDefault;
        cell.onChanged = ^(TextCell *cell) {
            self.game.comment = cell.textField.text;
        };
        return cell;
	}
    
    if (section == kNumberOfGamesSection) {
        SelectCell *cell = [self dequeueSelectCell:theTableView];
        cell.label.text = @"Number of Games";
        cell.value.text = [@(self.game.numberOfGames) stringValue];
        cell.onChanged = ^(SelectCell *cell, PickerTableViewCell *pickerCell) {
            self.game.numberOfGames = [[pickerCell selectedValue] intValue];
        };
        cell.options = @[@[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"]];
        cell.selectedOptions = @[cell.value.text];
        cell.sizes = nil;
        return cell;
    }
    
	if (section == kBoardSection) {
		if (row == kBoardSectionBoardSizeRow) {
			SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *boardSize = [NSString stringWithFormat:@"%d", self.game.boardSize];
			NSArray *options = @[@"9", @"13", @"19"];
			cell.label.text = @"Board Size";
			cell.value.text = boardSize;
			cell.onChanged = ^(SelectCell *cell, PickerTableViewCell *pickerCell) {
                self.game.boardSize = [[pickerCell selectedValue] intValue];
            };
			cell.options = @[options];
			cell.sizes = nil;
			cell.selectedOptions = @[boardSize];
			return cell;
		} else if (row == kBoardSectionHandicapPlacementRow) {
            BooleanCell *cell = [self dequeueBooleanCell:theTableView];
            cell.textLabel.text = @"Standard Placement";
            cell.toggleSwitch.on = self.game.stdHandicap;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.stdHandicap = cell.toggleSwitch.on;
            };
			return cell;
		} else if (row == kBoardSectionKomiTypeRow) {
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
			cell.onChanged = ^(SelectCell *selectCell, PickerTableViewCell *pickerCell) {
                KomiType oldKomiType = self.game.komiType;
                self.game.komiType = [pickerCell selectedRow];
                [self komiTypeDidChange:oldKomiType toKomiType:self.game.komiType];
            };
			cell.options = @[options];
			cell.selectedOptions = @[komiType];
			cell.sizes = nil;
			return cell;
		} else if (row == kBoardSectionGameStyleRow) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *manualKomiType = [self.game manualKomiTypeString];
            NSMutableArray *options = [NSMutableArray array];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeNigiri]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeDouble]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeBlack]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeWhite]];

			cell.label.text = @"Game Style";
			cell.value.text = manualKomiType;
            cell.onChanged = ^(SelectCell *cell, PickerTableViewCell *pickerCell) {
                self.game.manualKomiType = [pickerCell selectedRow];
            };
			cell.options = @[options];
			cell.selectedOptions = @[manualKomiType];
			cell.sizes = nil;
			return cell;
        } else if (row == kBoardSectionManualHandicapRow) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
            NSMutableArray *handicaps = [[NSMutableArray alloc] initWithObjects:@"0", nil];
            for (int i = 2; i < 22; i++) {
                [handicaps addObject:[NSString stringWithFormat:@"%d", i]];
            }

			cell.label.text = @"Handicap";
			cell.value.text = [NSString stringWithFormat:@"%d", self.game.handicap];
            cell.onChanged = ^(SelectCell *cell, PickerTableViewCell *pickerCell) {
                self.game.handicap = [[pickerCell selectedValue] intValue];
            };
			cell.options = @[handicaps];
			cell.selectedOptions = @[[NSString stringWithFormat:@"%d", self.game.handicap]];
			cell.sizes = nil;
			return cell;
        } else if (row == kBoardSectionManualKomiRow) {
            TextCell *cell = [self dequeueTextCell:theTableView];
            cell.label.text = @"Komi";
            cell.textField.text = [NSString stringWithFormat:@"%0.1f", self.game.komi];
            cell.textField.keyboardType = UIKeyboardTypeDecimalPad;
            cell.onChanged = ^(TextCell *cell) {
                self.game.komi = [cell.textField.text floatValue];
            };
            return cell;
        }
	} else if (section == kTimeSection) {
		if (row == kTimeSectionMainTimeRow) {
			return [self timeCell:theTableView timeValue:self.game.timeValue timeUnit:self.game.timeUnit onSelected:^(SelectCell *selectCell, PickerTableViewCell *pickerCell) {
                    self.game.timeValue = [self timeValueFromPickerCell:pickerCell];
                    self.game.timeUnit = [self timePeriodFromPickerCell:pickerCell];
                } label:@"Main Time"];
		} else if (row == kTimeSectionByoYomiTypeRow) {
			SelectCell *cell = [self dequeueSelectCell:theTableView];
			NSString *byoYomiType = [self.game byoYomiTypeString];
			NSArray *options = @[[self.game byoYomiTypeString:kByoYomiTypeJapanese], [self.game byoYomiTypeString:kByoYomiTypeCanadian], [self.game byoYomiTypeString:kByoYomiTypeFischer]];
			cell.label.text = @"Byo-Yomi";
			cell.value.text = byoYomiType;
			cell.onChanged = ^(SelectCell *selectCell, PickerTableViewCell *pickerCell) {
                ByoYomiType oldByoYomiType = self.game.byoYomiType;
                self.game.byoYomiType = [pickerCell selectedRow];
                [self byoYomiTypeDidChange:oldByoYomiType toByoYomiType:self.game.byoYomiType];
            };
			cell.options = @[options];
			cell.selectedOptions = @[byoYomiType];
			cell.sizes = nil;
			return cell;
		} else if (row == kTimeSectionExtraTimeRow) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
                
				return [self timeCell:theTableView
                            timeValue:self.game.japaneseTimeValue
                             timeUnit:self.game.japaneseTimeUnit
                           onSelected:^(SelectCell *selectCell, PickerTableViewCell *pickerCell) {
                               self.game.japaneseTimeValue = [self timeValueFromPickerCell:pickerCell];
                               self.game.japaneseTimeUnit = [self timePeriodFromPickerCell:pickerCell];
                           }
                                label:@"Extra Time"];
                
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
                
				return [self timeCell:theTableView
                            timeValue:self.game.canadianTimeValue
                             timeUnit:self.game.canadianTimeUnit
                           onSelected:^(SelectCell *selectCell, PickerTableViewCell *pickerCell) {
                               self.game.canadianTimeValue = [self timeValueFromPickerCell:pickerCell];
                               self.game.canadianTimeUnit = [self timePeriodFromPickerCell:pickerCell];
                               
                           }
                                label:@"Extra Time"];
                
			} else if (self.game.byoYomiType == kByoYomiTypeFischer) {
				return [self timeCell:theTableView
                            timeValue:self.game.fischerTimeValue
                             timeUnit:self.game.fischerTimeUnit
                           onSelected:^(SelectCell *selectCell, PickerTableViewCell *pickerCell) {
                               self.game.fischerTimeValue = [self timeValueFromPickerCell:pickerCell];
                               self.game.fischerTimeUnit = [self timePeriodFromPickerCell:pickerCell];
                           }
                                label:@"Extra Per Move"];
			}
		} else if (row == kTimeSectionExtraPeriodsRow) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				TextCell *cell = [self dequeueTextCell:theTableView];
				cell.label.text = @"Periods";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.japaneseTimePeriods];
                cell.onChanged = ^(TextCell *cell) {
                    self.game.japaneseTimePeriods = [cell.textField.text intValue];
                };
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				TextCell *cell = [self dequeueTextCell:theTableView];
				cell.label.text = @"Stones";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.canadianTimePeriods];
                cell.onChanged = ^(TextCell *cell) {
                    self.game.canadianTimePeriods = [cell.textField.text intValue];
                };
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			}
		}
	} else if (section == kRatingSection) {
		if (row == kRatingSectionRankedGameRow) {
			BooleanCell *cell = [self dequeueBooleanCell:theTableView];
            cell.textLabel.text = @"Ranked game";
            cell.toggleSwitch.on = self.game.rated;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.rated = cell.toggleSwitch.on;
            };
			return cell;
		} else if (row == kRatingSectionRequireRatedOpponentRow) {
			BooleanCell *cell = [self dequeueBooleanCell:theTableView];
            cell.textLabel.text = @"Rated opponent";
            cell.toggleSwitch.on = self.game.requireRatedOpponent;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.requireRatedOpponent = cell.toggleSwitch.on;
                // We want to update the table cells without deselecting
                // the current cell, so no #reloadData for you.
                NSArray *indexPaths = @[
                                        [self indexPathIgnoringPickerForRow:kRatingSectionMinRatingRow inSection:kRatingSection],
                                        [self indexPathIgnoringPickerForRow:kRatingSectionMaxRatingRow inSection:kRatingSection]
                                        ];

                if (self.game.requireRatedOpponent) {
                    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                } else {
                    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                }
            };
			return cell;
		} else if (row == kRatingSectionMinRatingRow) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
			cell.label.text = @"Min rating";
			cell.value.text = self.game.minimumRating;
			cell.onChanged = ^(SelectCell *cell, PickerTableViewCell *pickerCell) {
                self.game.minimumRating = [pickerCell selectedValue];
            };
			cell.options = @[_ratingStrings];
			cell.selectedOptions = @[self.game.minimumRating];
			cell.sizes = nil;
			return cell;
        } else if (row == kRatingSectionMaxRatingRow) {
            SelectCell *cell = [self dequeueSelectCell:theTableView];
			cell.label.text = @"Max rating";
			cell.value.text = self.game.maximumRating;
            cell.onChanged = ^(SelectCell *cell, PickerTableViewCell *pickerCell) {
                self.game.maximumRating = [pickerCell selectedValue];
            };
			cell.options = @[_ratingStrings];
			cell.selectedOptions = @[self.game.maximumRating];
			cell.sizes = nil;
			return cell;
        }
    } else if (section == kActionSection) {
        UITableViewCell *cell = [self dequeueActionCell:theTableView];
        cell.textLabel.text = @"Create Game";
        self.createGameButton = cell;
        return cell;
    }
    return [self dequeueDefaultCell:theTableView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath compare:self.pickerIndexPath] == NSOrderedSame) {
        return self.pickerCellHeight;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
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
    } else {
        [self.tableView beginUpdates];
        
        BOOL pickerAlreadyOpen = (self.pickerIndexPath &&
                                  [[self indexPathForOpenPickerCell] compare:indexPath] == NSOrderedSame);
        BOOL shouldShowPicker = [[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"SelectCell"];
        NSIndexPath *logicalIndexPath = [self indexPathIgnoringPicker:indexPath];
        
        if (self.pickerIndexPath) {
            [tableView deleteRowsAtIndexPaths:@[self.pickerIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            self.pickerIndexPath = nil;
        }
        
        if (shouldShowPicker && !pickerAlreadyOpen) {
            NSIndexPath *pickerIndexPath = [NSIndexPath indexPathForRow:(logicalIndexPath.row + 1) inSection:logicalIndexPath.section];
            self.pickerIndexPath = pickerIndexPath;
            [tableView insertRowsAtIndexPaths:@[pickerIndexPath] withRowAnimation:UITableViewRowAnimationTop];
        }
        
        [self.tableView endUpdates];
    }
}

#pragma mark -
#pragma mark Row adjustments

- (void)komiTypeDidChange:(KomiType)oldKomiType toKomiType:(KomiType)newKomiType {
    // We want to update the table cells without deselecting
    // the current cell, so no #reloadData for you.
    NSArray *indexPaths = @[
                            [self indexPathIgnoringPickerForRow:kBoardSectionGameStyleRow inSection:kBoardSection],
                            [self indexPathIgnoringPickerForRow:kBoardSectionManualHandicapRow inSection:kBoardSection],
                            [self indexPathIgnoringPickerForRow:kBoardSectionManualKomiRow inSection:kBoardSection]
                            ];
    
    if (oldKomiType != kKomiTypeManual && newKomiType == kKomiTypeManual) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    } else if (oldKomiType == kKomiTypeManual && newKomiType != kKomiTypeManual) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)byoYomiTypeDidChange:(ByoYomiType)oldByoYomiType toByoYomiType:(ByoYomiType)newByoYomiType {
    // We want to update the table cells without deselecting
    // the current cell, so no #reloadData for you.
    NSMutableArray *indexPathsToReload = [NSMutableArray arrayWithObject:[self indexPathIgnoringPickerForRow:kTimeSectionExtraTimeRow inSection:kTimeSection]];
    NSIndexPath *extraPeriodsIndexPath = [self indexPathIgnoringPickerForRow:kTimeSectionExtraPeriodsRow inSection:kTimeSection];
    
    if (oldByoYomiType == kByoYomiTypeFischer && newByoYomiType != kByoYomiTypeFischer) {
        [self.tableView insertRowsAtIndexPaths:@[extraPeriodsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [indexPathsToReload addObject:extraPeriodsIndexPath];
    } else if (oldByoYomiType != kByoYomiTypeFischer && newByoYomiType == kByoYomiTypeFischer) {
        [self.tableView deleteRowsAtIndexPaths:@[extraPeriodsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else if (oldByoYomiType != newByoYomiType){
        [indexPathsToReload addObject:extraPeriodsIndexPath];
    }
    
    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Time period cell handling

- (SelectCell *)timeCell:(UITableView *)theTableView timeValue:(int)timeValue timeUnit:(TimePeriod)timeUnit onSelected:(void (^)(SelectCell *selectCell, PickerTableViewCell *pickerCell))onSelected label:(NSString *)label {
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

- (int)timeValueFromPickerCell:(PickerTableViewCell *)pickerCell {
    int tens = [[pickerCell selectedValueInComponent:0] intValue];
    int ones = [[pickerCell selectedValueInComponent:1] intValue];
    return tens * 10 + ones;
}

- (TimePeriod)timePeriodFromPickerCell:(PickerTableViewCell *)pickerCell {
    return [pickerCell selectedRowInComponent:2];
}


#pragma mark -
#pragma mark Picker cell management

- (NSIndexPath *)indexPathIgnoringPickerForRow:(NSInteger)row inSection:(NSInteger)section {
    if (self.pickerIndexPath &&
        self.pickerIndexPath.section == section &&
        self.pickerIndexPath.row <= row) {
        return [NSIndexPath indexPathForRow:row + 1 inSection:section];
    } else {
        return [NSIndexPath indexPathForRow:row inSection:section];
    }
}

- (NSIndexPath *)indexPathIgnoringPicker:(NSIndexPath *)originalIndexPath {
    if (self.pickerIndexPath &&
        self.pickerIndexPath.section == originalIndexPath.section &&
        self.pickerIndexPath.row <= originalIndexPath.row) {
        return [NSIndexPath indexPathForRow:originalIndexPath.row - 1 inSection:originalIndexPath.section];
    } else {
        return originalIndexPath;
    }
}

- (NSIndexPath *)indexPathForOpenPickerCell {
    if (self.pickerIndexPath) {
        return [NSIndexPath indexPathForRow:self.pickerIndexPath.row - 1 inSection:self.pickerIndexPath.section];
    } else {
        return nil;
    }
}

- (void)pickerTableViewCell:(PickerTableViewCell *)pickerCell didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSIndexPath *selectCellIndexPath = [self indexPathForOpenPickerCell];
    SelectCell *cell = [self.tableView cellForRowAtIndexPath:selectCellIndexPath];
    pickerCell.onChanged(cell, pickerCell);
    [self.tableView reloadRowsAtIndexPaths:@[selectCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc that aren't in use.
}

@end
