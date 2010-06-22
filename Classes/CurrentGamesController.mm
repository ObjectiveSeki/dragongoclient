//
//  CurrentGamesController.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "CurrentGamesController.h"
#import "DGS.h"
#import "Game.h"
#import "GameViewController.h"
#import "LoginViewController.h"

@implementation CurrentGamesController

@synthesize games;
@synthesize refreshButton;
@synthesize tableView;
@synthesize logoutButton;
@synthesize dgs;
@synthesize reloadingIndicator;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	self.title = @"Current Games";
	self.navigationItem.leftBarButtonItem = self.logoutButton;
	self.navigationItem.rightBarButtonItem = self.refreshButton;
	self.dgs  = [[DGS alloc] init];
	self.dgs.delegate = self;
	[super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self refreshGames];
}

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

- (IBAction)refreshGames {
	[dgs getCurrentGames];
	[[self reloadingIndicator] startAnimating];
	[[self refreshButton] setEnabled:NO];
	[[self logoutButton] setEnabled:NO];
	[[self tableView] setUserInteractionEnabled:NO];
}

- (void)gotCurrentGames:(NSArray *)currentGames {
	self.games = currentGames;
	[[self reloadingIndicator] stopAnimating];
	[[self refreshButton] setEnabled:YES];
	[[self logoutButton] setEnabled:YES];
	[[self tableView] setUserInteractionEnabled:YES];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[self.games count]];
	[[self tableView] reloadData];
}

- (void)notLoggedIn {
	LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginView" bundle:nil];
	loginViewController.delegate = self;
	[self presentModalViewController:loginViewController animated:YES];
	[loginViewController notLoggedIn];
	[loginViewController release];
}

- (void)loggedIn {
	[self dismissModalViewControllerAnimated:YES];
	[self refreshGames];
}

- (IBAction)logout {
	[dgs logout];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [games count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	Game *game = [games objectAtIndex:[indexPath row]];
	if ([game color] == kMovePlayerBlack) {
		[cell setImage:[[[UIApplication sharedApplication] delegate] blackStone]];
	} else {
		[cell setImage:[[[UIApplication sharedApplication] delegate] whiteStone]];
	}
    [[cell textLabel] setText: [game opponent]];
	[[cell detailTextLabel] setText:[game time]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
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
    // Navigation logic may go here. Create and push another view controller.
	GameViewController *gameViewController = [[GameViewController alloc] initWithNibName:@"GameView" bundle:nil];
	// ...
	// Pass the selected object to the new view controller.
	[gameViewController setGame:[games objectAtIndex:[indexPath row]]];
	[self.navigationController pushViewController:gameViewController animated:YES];
	[gameViewController release];
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
	[games release];
	self.refreshButton = nil;
	self.tableView = nil;
	self.logoutButton = nil;
	self.reloadingIndicator = nil;
	self.dgs = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

