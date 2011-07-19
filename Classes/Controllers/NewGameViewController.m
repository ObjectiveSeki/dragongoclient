//
//  NewGameViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/11.
//  Copyright 2011 Justin Weiss. All rights reserved.
//

#import "NewGameViewController.h"

#import "AddGameViewController.h"
#import "WaitingRoomGamesController.h"
#import "GameList.h"

@implementation NewGameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Start a game";
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    TableSection *serverGamesSection = [[TableSection alloc] init];
    
    TableRow *row;
    
    row = [[TableRow alloc] init];
    row.cellClass = [UITableViewCell class];
    row.cellInit = ^UITableViewCell*() {
        return [[[row.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(row.cellClass)] autorelease];
    };
    row.cellSetup = ^(UITableViewCell *cell) {
        [[cell textLabel] setText:@"Join a game"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    };
    row.cellTouched = ^(UITableViewCell *cell) {
        UIActivityIndicatorView *activityView = 
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        [cell setAccessoryView:activityView];
        [activityView release];
        [self.tableView setUserInteractionEnabled:NO];
        
        WaitingRoomGamesController *controller = [[WaitingRoomGamesController alloc] initWithNibName:@"WaitingRoomGamesView" bundle:nil];
        
		[self.gs getWaitingRoomGames:^(GameList *postedGames) {
			[controller setGames:postedGames];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
            [self deselectSelectedCell];
            [self.selectedCell setAccessoryView:nil];
            [self.tableView setUserInteractionEnabled:YES];
		}];
        
    };
    [serverGamesSection addRow:row];
    [row release];
    
    row = [[TableRow alloc] init];
    row.cellClass = [UITableViewCell class];
    row.cellInit = ^UITableViewCell*() {
        return [[[row.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(row.cellClass)] autorelease];
    };
    row.cellSetup = ^(UITableViewCell *cell) {
        [[cell textLabel] setText:@"Create a new game"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    };
    row.cellTouched = ^(UITableViewCell *cell) {
        UIActivityIndicatorView *activityView = 
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        [cell setAccessoryView:activityView];
        [activityView release];
        
        AddGameViewController *controller = [[AddGameViewController alloc] initWithNibName:@"AddGameView" bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
		[controller release];
        [self deselectSelectedCell];
        [self.selectedCell setAccessoryView:nil];
    };
    [serverGamesSection addRow:row];
    [row release];
    
    [sections addObject:serverGamesSection];
    self.tableSections = sections;
    [sections release];
}

- (UITableViewCell *)selectedCell {
    return [[self tableView] cellForRowAtIndexPath:[self selectedIndexPath]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
