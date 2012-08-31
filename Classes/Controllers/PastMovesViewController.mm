//
//  PastMovesViewController.m
//  DGSPhone
//
//  Created by Frank Prößdorf on 8/28/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import "PastMovesViewController.h"
#import "FuegoBoard.h"
#import "DGSPhoneAppDelegate.h"

@implementation PastMovesViewController

@synthesize game;
@synthesize player;
@synthesize moves;
@synthesize board;
@synthesize gameTableView;
@synthesize selectedCell;
@synthesize moveListView;


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
    FuegoBoard *theBoard = [[FuegoBoard alloc] initWithSGFString:[game sgfString]];
	[self setBoard:theBoard];
    [self buildTableCells];
    [[self gameTableView] reloadData];
}

- (void)buildTableCells {
	NSMutableArray *sections = [NSMutableArray array];
	TableSection *firstSection = [[TableSection alloc] init];
    int numberOfMoves = self.board.moveNumber;

	for (Move *move in self.board.moves) {
        numberOfMoves = numberOfMoves - 1;
		TableRow *row = [[TableRow alloc] init];
		row.cellClass = [UITableViewCell class];
		row.cellInit = ^UITableViewCell*() {
			return [[[row.cellClass alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass(row.cellClass)] autorelease];
		};
		row.cellSetup = ^(UITableViewCell *cell) {
            if ([move player] == kMovePlayerBlack) {
				[[cell imageView] setImage:[DGSAppDelegate blackStone]];
                [[cell textLabel] setText: [self.board name:kMovePlayerBlack]];

			} else {
				[[cell imageView] setImage:[DGSAppDelegate whiteStone]];
                [[cell textLabel] setText: [self.board name:kMovePlayerWhite]];
			}
            
			[[cell detailTextLabel] setText:[NSString stringWithFormat:@"Move %d: %d, %d", numberOfMoves, move.col, move.row]];

			[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		};
		row.cellTouched = ^(UITableViewCell *cell) {
		};
		[firstSection addRow:row];
		[row release];
	}
    
	[sections addObject:firstSection];
	[firstSection release];

	self.tableSections = sections;
}


@end
