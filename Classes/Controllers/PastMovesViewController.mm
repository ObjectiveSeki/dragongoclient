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
    self.navigationItem.title = [NSString stringWithFormat:@"History"];
}

- (void)buildTableCells {
	NSMutableArray *sections = [NSMutableArray array];
	TableSection *firstSection = [[TableSection alloc] init];
    int numberOfMoves = self.board.moveNumber;

	for (Move *move in self.board.orderedMoves) {
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
            self.selectedCell = cell;
			UIActivityIndicatorView *activityView =
			[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			[activityView startAnimating];
			[cell setAccessoryView:activityView];
			[activityView release];

            PastMoveViewController *pastMoveViewController = [[PastMoveViewController alloc] initWithNibName:@"GameView" bundle:nil];
            [pastMoveViewController setMoveNumber:numberOfMoves];
            [pastMoveViewController setGame:game];
            [self.navigationController pushViewController:pastMoveViewController animated:YES];
            [pastMoveViewController release];

            [self.selectedCell setAccessoryView:nil];
            self.selectedCell = nil;
		};
		[firstSection addRow:row];
		[row release];
        numberOfMoves = numberOfMoves - 1;
	}
    
	[sections addObject:firstSection];
	[firstSection release];

	self.tableSections = sections;
}


@end
