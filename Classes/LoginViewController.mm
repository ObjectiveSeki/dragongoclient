//
//  LoginViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/2/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "LoginViewController.h"
#import "CurrentGamesController.h"
#import "DGSPhoneAppDelegate.h"
#import "DGS.h"
#import "TableCellFactory.h"

typedef enum _LoginSection {
	kLoginFieldSection,
	kLoginButtonSection,
} AddGameSection;

@implementation LoginViewController

@synthesize username;
@synthesize password;
@synthesize delegate;
@synthesize dgs;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)loggedIn {
	[[self delegate] loggedIn];
}

- (void)notLoggedIn {
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)login
{
	[dgs loginWithUsername:self.username password:self.password];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.dgs = [[[DGS alloc] init] autorelease];
	self.dgs.delegate = self;
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == kLoginFieldSection) {
        return 2;
    } else if (section == kLoginButtonSection) {
        return 1;
    }
    return 1;
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

- (void)setUsernameFromCell:(TextCell *)tableCell {
	NSLog(@"%@", tableCell.textField.text);
	self.username = tableCell.textField.text;
}

- (void)setPasswordFromCell:(TextCell *)tableCell {
	NSLog(@"%@", tableCell.textField.text);
	self.password = tableCell.textField.text;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *cell = [self defaultCell:tableView];
	
	if ([indexPath section] == kLoginFieldSection) {
		if ([indexPath row] == 0) {
			TextCell *cell = [self textCell:tableView];
			cell.label.text = @"Username";
			cell.textField.text = self.username;
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textEditedSelector = @selector(setUsernameFromCell:);
			return cell;
		} else {
			TextCell *cell = [self textCell:tableView];
			cell.label.text = @"Password";
			cell.textField.text = self.password;
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textField.secureTextEntry = YES;
			cell.textEditedSelector = @selector(setPasswordFromCell:);
			return cell;
		}
	} else {
		cell.textLabel.text = @"Login";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == kLoginFieldSection) {
		return @"Please login to continue:";
	} else {
		return nil;
	}

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
	if ([indexPath section] == kLoginButtonSection) {	
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self login];
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.username = nil;
	self.password = nil;
	self.dgs = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
